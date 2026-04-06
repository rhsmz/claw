-- scripts/management（imperial-management CLI）が利用するテーブル。
-- 初回起動時は compose の POSTGRES_DB（ZEROCLAW_DB_NAME）に対して実行される。

CREATE TABLE IF NOT EXISTS documents (
    id          BIGSERIAL PRIMARY KEY,
    content     TEXT NOT NULL,
    source_path TEXT,
    embedding   JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id         BIGSERIAL PRIMARY KEY,
    crew_name  TEXT,
    action     TEXT,
    details    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- hexa-rag-mcp の incremental ingest が参照するテーブル（CREATE IF NOT EXISTS で冪等化）
CREATE TABLE IF NOT EXISTS sync_state (
    source_path TEXT PRIMARY KEY,
    last_mtime  TIMESTAMPTZ,
    file_hash   TEXT
);

CREATE INDEX IF NOT EXISTS audit_logs_created_at_idx ON audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS documents_created_at_idx ON documents (created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS documents_source_path_uidx ON documents (source_path) WHERE source_path IS NOT NULL;
