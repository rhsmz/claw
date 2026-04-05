mod schema;

use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use serde::Deserialize;
use sqlx::postgres::PgPoolOptions;
use sqlx::Row;
use std::env;
use std::path::Path;
use std::time::Duration;
use tracing::{error, info, warn};

#[derive(Parser)]
#[command(name = "imperial-management")]
#[command(about = "ZeroClaw スタック用の管理 CLI（知識同期・監査ログ・生存確認）", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 指定ディレクトリの Markdown を読み取り、documents テーブルへ格納（任意で LiteLLM /v1/embeddings）
    Sync,
    /// audit_logs を走査し、機密らしい出力を検知
    Audit,
    /// rust-inference / LiteLLM / PostgreSQL の生存確認
    Status,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    dotenvy::dotenv().ok();

    let cli = Cli::parse();
    let db_url = resolve_database_url();

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&db_url)
        .await
        .context("PostgreSQL への接続に失敗しました（DATABASE_URL または POSTGRES_* / ZEROCLAW_DB_NAME を確認）")?;

    // status は読み取り専用チェックに留め、DDL を走らせない（最小権限の DB ユーザーでも動かす）
    match &cli.command {
        Commands::Sync | Commands::Audit => {
            schema::ensure_schema(&pool)
                .await
                .context("スキーマの適用に失敗しました")?;
        }
        Commands::Status => {}
    }

    match &cli.command {
        Commands::Sync => sync_knowledge_base(&pool).await?,
        Commands::Audit => run_security_audit(&pool).await?,
        Commands::Status => check_imperial_status(&pool).await?,
    }

    Ok(())
}

fn resolve_database_url() -> String {
    if let Ok(url) = env::var("DATABASE_URL") {
        return url;
    }
    let user = env::var("POSTGRES_USER").unwrap_or_else(|_| "imperial_admin".into());
    let pass = env::var("POSTGRES_PASSWORD").unwrap_or_else(|_| "secure_password_999".into());
    let host = env::var("POSTGRES_HOST").unwrap_or_else(|_| "localhost".into());
    let port = env::var("POSTGRES_PORT").unwrap_or_else(|_| "5432".into());
    let db = env::var("ZEROCLAW_DB_NAME").unwrap_or_else(|_| "zeroclaw_enterprise".into());
    format!("postgresql://{user}:{pass}@{host}:{port}/{db}")
}

fn http_base(var: &str, default: &str) -> String {
    env::var(var).unwrap_or_else(|_| default.to_string())
}

const MAX_FILE_BYTES: usize = 512 * 1024;
const MAX_FILES_PER_SYNC: usize = 500;
const EMBED_INPUT_CHARS: usize = 16_384;

#[derive(Deserialize)]
struct OpenAiEmbedItem {
    embedding: Vec<f32>,
}

#[derive(Deserialize)]
struct OpenAiEmbedResponse {
    data: Vec<OpenAiEmbedItem>,
}

/// LiteLLM（OpenAI 互換 `/v1/embeddings`）経由。`LITELLM_MASTER_KEY` を Authorization に使う。
async fn fetch_litellm_embedding(
    client: &reqwest::Client,
    base: &str,
    api_key: &str,
    model: &str,
    text: &str,
) -> Option<serde_json::Value> {
    let input: String = text.chars().take(EMBED_INPUT_CHARS).collect();
    let url = format!("{}/v1/embeddings", base.trim_end_matches('/'));
    let body = serde_json::json!({ "model": model, "input": input });
    let res = client
        .post(&url)
        .header("Authorization", format!("Bearer {api_key}"))
        .json(&body)
        .send()
        .await
        .ok()?;
    if !res.status().is_success() {
        warn!(status = %res.status(), "LiteLLM 埋め込み API がエラーを返しました");
        return None;
    }
    let parsed: OpenAiEmbedResponse = res.json().await.ok()?;
    let emb = parsed.data.first()?.embedding.clone();
    serde_json::to_value(emb).ok()
}

async fn sync_knowledge_base(pool: &sqlx::PgPool) -> Result<()> {
    info!("知識同期: documents テーブルへ取り込みを開始します");

    let litellm_base = http_base("IMPERIAL_LITELLM_URL", "http://127.0.0.1:4000");
    let embed_model = env::var("IMPERIAL_EMBEDDING_MODEL").unwrap_or_default();
    let api_key = env::var("LITELLM_MASTER_KEY").unwrap_or_default();
    let dirs_raw = env::var("IMPERIAL_KNOWLEDGE_DIRS").unwrap_or_default();
    let dirs: Vec<String> = dirs_raw
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(120))
        .build()
        .context("HTTP クライアントの生成に失敗しました")?;

    if dirs.is_empty() {
        info!("IMPERIAL_KNOWLEDGE_DIRS が空です。接続確認用のプレースホルダ 1 件を書き込みます（カンマ区切りでディレクトリを指定可能）");
        let emb = if embed_model.is_empty() || api_key.is_empty() {
            None
        } else {
            fetch_litellm_embedding(
                &client,
                &litellm_base,
                &api_key,
                &embed_model,
                "placeholder sync ping",
            )
            .await
        };
        sqlx::query(
            r#"INSERT INTO documents (content, source_path, embedding)
               VALUES ($1, $2, $3)
               ON CONFLICT (source_path) WHERE source_path IS NOT NULL DO UPDATE SET
                 content = EXCLUDED.content,
                 embedding = EXCLUDED.embedding,
                 created_at = now()"#,
        )
        .bind("IMPERIAL_KNOWLEDGE_DIRS 未設定時のプレースホルダ。Markdown ディレクトリを指定して再実行してください。")
        .bind("__imperial_sync__/placeholder")
        .bind(emb)
        .execute(pool)
        .await?;
        info!("プレースホルダを upsert しました");
        return Ok(());
    }

    let mut count = 0usize;
    'dirs: for dir in &dirs {
        let root = Path::new(dir);
        if !root.is_dir() {
            warn!(path = %dir, "ディレクトリが存在しないためスキップします");
            continue;
        }
        for entry in walkdir::WalkDir::new(root).into_iter().filter_map(Result::ok) {
            if !entry.file_type().is_file() {
                continue;
            }
            let path = entry.path();
            let is_md = path
                .extension()
                .and_then(|e| e.to_str())
                .is_some_and(|e| e.eq_ignore_ascii_case("md"));
            if !is_md {
                continue;
            }
            if count >= MAX_FILES_PER_SYNC {
                warn!(max = MAX_FILES_PER_SYNC, "ファイル数上限に達したため打ち切ります");
                break 'dirs;
            }
            let meta = std::fs::metadata(path).with_context(|| format!("メタデータ取得: {}", path.display()))?;
            if meta.len() as usize > MAX_FILE_BYTES {
                warn!(path = %path.display(), "ファイルが大きすぎるためスキップします");
                continue;
            }
            let content = std::fs::read_to_string(path).with_context(|| format!("読み込み: {}", path.display()))?;
            let rel = path.to_string_lossy().to_string();
            let emb = if embed_model.is_empty() || api_key.is_empty() {
                None
            } else {
                fetch_litellm_embedding(&client, &litellm_base, &api_key, &embed_model, &content).await
            };

            sqlx::query(
                r#"INSERT INTO documents (content, source_path, embedding)
                   VALUES ($1, $2, $3)
                   ON CONFLICT (source_path) WHERE source_path IS NOT NULL DO UPDATE SET
                     content = EXCLUDED.content,
                     embedding = EXCLUDED.embedding,
                     created_at = now()"#,
            )
            .bind(&content)
            .bind(&rel)
            .bind(emb)
            .execute(pool)
            .await
            .with_context(|| format!("INSERT 失敗: {rel}"))?;

            count += 1;
            info!(path = %rel, "取り込み完了");
        }
    }

    info!(files = count, "知識同期が完了しました");
    Ok(())
}

async fn run_security_audit(pool: &sqlx::PgPool) -> Result<()> {
    info!("監査ログをスキャンしています");

    let rows = sqlx::query(
        "SELECT crew_name, action, details FROM audit_logs WHERE created_at > now() - interval '1 hour'",
    )
    .fetch_all(pool)
    .await?;

    let mut findings = 0usize;
    for (i, row) in rows.iter().enumerate() {
        let crew_name: Option<String> = row
            .try_get::<Option<String>, _>("crew_name")
            .with_context(|| format!("audit_logs 行 {i} の crew_name をデコードできませんでした"))?;
        let action: Option<String> = row
            .try_get::<Option<String>, _>("action")
            .with_context(|| format!("audit_logs 行 {i} の action をデコードできませんでした"))?;
        let details: Option<String> = row
            .try_get::<Option<String>, _>("details")
            .with_context(|| format!("audit_logs 行 {i} の details をデコードできませんでした"))?;

        let crew_name = crew_name.unwrap_or_default();
        let details_lc = details.unwrap_or_default().to_lowercase();
        let suspicious = details_lc.contains("api_key")
            || details_lc.contains("password")
            || details_lc.contains("secret")
            || details_lc.contains("bearer ")
            || details_lc.contains("xoxb-")
            || details_lc.contains("ghp_");
        if suspicious {
            findings += 1;
            warn!(
                crew = %crew_name,
                action = ?action,
                "機密情報が含まれる可能性のある監査ログを検知しました"
            );
        }
    }

    if findings == 0 {
        info!("直近 1 時間の監査ログに、簡易ルール上の警告はありませんでした（{} 件を確認）", rows.len());
    } else {
        warn!(findings, "上記件数の警告行がありました。人手で確認してください");
    }
    Ok(())
}

async fn check_imperial_status(pool: &sqlx::PgPool) -> Result<()> {
    info!("コンポーネント生存確認を実行します");

    let rust_base = http_base("IMPERIAL_RUST_INFERENCE_URL", "http://127.0.0.1:9080");
    let litellm_base = http_base("IMPERIAL_LITELLM_URL", "http://127.0.0.1:4000");

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(10))
        .build()
        .context("HTTP クライアントの生成に失敗しました")?;

    let mut any_fail = false;

    let ri_health = format!("{}/health", rust_base.trim_end_matches('/'));
    match client.get(&ri_health).send().await {
        Ok(r) if r.status().is_success() => info!("rust-inference: 応答あり ({})", ri_health),
        Ok(r) => {
            any_fail = true;
            error!(status = %r.status(), "rust-inference: 異常ステータス ({})", ri_health);
        }
        Err(e) => {
            any_fail = true;
            error!(error = %e, "rust-inference: 接続失敗 ({})", ri_health);
        }
    }

    let ll_ready = format!("{}/health/liveness", litellm_base.trim_end_matches('/'));
    match client.get(&ll_ready).send().await {
        Ok(r) if r.status().is_success() => info!("LiteLLM: 応答あり ({})", ll_ready),
        Ok(r) => {
            any_fail = true;
            error!(status = %r.status(), "LiteLLM: 異常ステータス ({})", ll_ready);
        }
        Err(e) => {
            any_fail = true;
            error!(error = %e, "LiteLLM: 接続失敗 ({})", ll_ready);
        }
    }

    match sqlx::query_scalar::<_, i64>("SELECT 1::bigint")
        .fetch_one(pool)
        .await
    {
        Ok(1) => info!("PostgreSQL: クエリ成功"),
        Ok(n) => {
            any_fail = true;
            error!(n, "PostgreSQL: 予期しないスカラー");
        }
        Err(e) => {
            any_fail = true;
            error!(error = %e, "PostgreSQL: クエリ失敗");
        }
    }

    if any_fail {
        anyhow::bail!("一つ以上のコンポーネントが正常に応答しませんでした");
    }
    info!("全チェックが成功しました");
    Ok(())
}
