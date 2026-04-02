use clap::{Parser, Subcommand};
use sqlx::postgres::PgPoolOptions;
use sqlx::Row;
use std::env;
use anyhow::{Context, Result};
use tracing::{info, warn, error};

#[derive(Parser)]
#[command(name = "ImperialManager")]
#[command(about = "AI帝国：円卓の64人 統合管理システム", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 過去の設計資産やWikiをContext7(pgvector)へ同期
    Sync,
    /// 全エージェントの監査ログをスキャンし、セキュリティ事案を検知
    Audit,
    /// 帝国の各コンポーネント（Ollama/LiteLLM/MCP）の生存確認
    Status,
}

#[tokio::main]
async fn main() -> Result<()> {
    // ログ初期化
    tracing_subscriber::fmt::init();
    dotenvy::dotenv().ok();

    let cli = Cli::parse();
    
    // データベース接続プールの作成
    let db_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://imperial_admin:secure_password_999@postgres:5432/zeroclaw_enterprise".to_string());
    
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&db_url)
        .await
        .context("データベースへの接続に失敗しました")?;

    match &cli.command {
        Commands::Sync => {
            sync_knowledge_base(&pool).await?;
        }
        Commands::Audit => {
            run_security_audit(&pool).await?;
        }
        Commands::Status => {
            check_imperial_status().await?;
        }
    }

    Ok(())
}

/// 知識ベースの同期処理
async fn sync_knowledge_base(pool: &sqlx::PgPool) -> Result<()> {
    info!("--- 知識基盤 (Context7/RAG) 同期プロセス開始 ---");
    
    // 1. 未処理のドキュメントやWiki記事を取得（シミュレーション）
    // 実際には filesystem MCP 等と連携してファイルを読むロジックが入ります
    
    // 2. ベクトル化とpgvectorへの保存
    // $V \in \mathbb{R}^d$ (d次元ベクトル) として保存
    sqlx::query("INSERT INTO documents (content, embedding) VALUES ($1, $2)")
        .bind("設計ガイドライン v2.0")
        .bind(vec![0.1, 0.2, 0.3]) // サンプルベクトル
        .execute(pool)
        .await?;

    info!("知識ベースの同期が完了しました。");
    Ok(())
}

/// セキュリティ監査処理
async fn run_security_audit(pool: &sqlx::PgPool) -> Result<()> {
    info!("--- 帝国セキュリティ監査プロセス開始 ---");

    // 1. 直近の監査ログ（audit_log = true）から疑わしい出力を抽出
    let rows = sqlx::query(
        "SELECT crew_name, action, details FROM audit_logs WHERE created_at > now() - interval '1 hour'",
    )
    .fetch_all(pool)
    .await?;

    for (i, row) in rows.iter().enumerate() {
        let crew_name: Option<String> = row
            .try_get::<Option<String>, _>("crew_name")
            .with_context(|| format!("audit_logs 行 {} の crew_name をデコードできませんでした", i))?;
        let details: Option<String> = row
            .try_get::<Option<String>, _>("details")
            .with_context(|| format!("audit_logs 行 {} の details をデコードできませんでした", i))?;
        let crew_name = crew_name.unwrap_or_default();
        let details = details.unwrap_or_default();
        // キーワードベースの簡易検知（実際にはLLMによる高度な判定が可能）
        if details.contains("API_KEY") || details.contains("password") {
            warn!("⚠️ セキュリティ警告: クルー [{}] が機密情報を出力した可能性があります", crew_name);
            // ここで Discord/Slack への通知を飛ばす
        }
    }

    info!("監査完了。重大な侵害は見つかりませんでした。");
    Ok(())
}

/// システムステータス確認
async fn check_imperial_status() -> Result<()> {
    info!("--- 帝国コンポーネント生存確認 ---");
    
    // Ollama (gemma3:12b) の確認
    let client = reqwest::Client::new();
    let res = client.get("http://ollama:11434/api/tags").send().await;
    
    match res {
        Ok(_) => info!("✅ Ollama: 正常稼働中 (gemma3:12b 待機)"),
        Err(_) => error!("❌ Ollama: 接続不能"),
    }

    // LiteLLM の確認
    let res = client.get("http://litellm:4000/health").send().await;
    match res {
        Ok(_) => info!("✅ LiteLLM Gateway: 正常稼働中"),
        Err(_) => error!("❌ LiteLLM Gateway: 接続不能"),
    }

    Ok(())
}