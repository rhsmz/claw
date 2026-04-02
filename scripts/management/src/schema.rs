//! 管理 CLI 用の最小スキーマ（`CREATE IF NOT EXISTS` で冪等）。

use anyhow::Result;
use sqlx::PgPool;

const STMTS: &[&str] = &[
    r#"CREATE TABLE IF NOT EXISTS documents (
    id          BIGSERIAL PRIMARY KEY,
    content     TEXT NOT NULL,
    source_path TEXT,
    embedding   JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
)"#,
    r#"CREATE TABLE IF NOT EXISTS audit_logs (
    id         BIGSERIAL PRIMARY KEY,
    crew_name  TEXT,
    action     TEXT,
    details    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
)"#,
    // hexa-rag-mcp の ingest が参照する incremental 同期用
    r#"CREATE TABLE IF NOT EXISTS sync_state (
    source_path TEXT PRIMARY KEY,
    last_mtime  TIMESTAMPTZ,
    file_hash   TEXT
)"#,
    "CREATE INDEX IF NOT EXISTS audit_logs_created_at_idx ON audit_logs (created_at DESC)",
    "CREATE INDEX IF NOT EXISTS documents_created_at_idx ON documents (created_at DESC)",
    // ON CONFLICT 側に同じ述語が必要（部分ユニークの推論用）
    "CREATE UNIQUE INDEX IF NOT EXISTS documents_source_path_uidx ON documents (source_path) WHERE source_path IS NOT NULL",
];

pub async fn ensure_schema(pool: &PgPool) -> Result<()> {
    for stmt in STMTS {
        sqlx::query(stmt).execute(pool).await?;
    }
    Ok(())
}
