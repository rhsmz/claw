\connect postgres

-- docker-entrypoint-initdb.d 実行時に psql が解釈する（.sql は実行ビット不要）
-- ZEROCLAW_DB_NAME は docker-compose の POSTGRES サービス環境変数から参照する
\set zeroclaw_db_name :ENV{ZEROCLAW_DB_NAME}

CREATE DATABASE :zeroclaw_db_name;
CREATE DATABASE openwebui_db;
CREATE DATABASE langfuse_db;

-- pgvector 拡張を各 DB にインストール
\connect :zeroclaw_db_name
CREATE EXTENSION IF NOT EXISTS vector;

\connect openwebui_db
CREATE EXTENSION IF NOT EXISTS vector;

\connect langfuse_db
CREATE EXTENSION IF NOT EXISTS vector;

