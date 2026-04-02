-- docker-entrypoint-initdb.d 実行時に psql が解釈する（.sql は実行ビット不要）
--
-- 注意: 公式イメージは init スクリプトより先に POSTGRES_DB（= ZEROCLAW_DB_NAME と一致させる）を作成する。
--       そのためゼロクロー用 DB はここでは CREATE しない（重複で失敗する）。
--       ZEROCLAW_DB_NAME は docker-compose の postgres サービス環境変数から参照する。

\connect postgres

\set zeroclaw_db_name :ENV{ZEROCLAW_DB_NAME}

-- 補助 DB（PG 9.1+ 互換: IF NOT EXISTS は CREATE DATABASE に無い版でも動く）
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'openwebui_db') THEN
    EXECUTE 'CREATE DATABASE openwebui_db';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'langfuse_db') THEN
    EXECUTE 'CREATE DATABASE langfuse_db';
  END IF;
END $$;

-- pgvector 拡張を各 DB にインストール
\connect :zeroclaw_db_name
CREATE EXTENSION IF NOT EXISTS vector;

\connect openwebui_db
CREATE EXTENSION IF NOT EXISTS vector;

\connect langfuse_db
CREATE EXTENSION IF NOT EXISTS vector;
