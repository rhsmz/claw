-- docker-entrypoint-initdb.d 実行時に psql が解釈する（.sql は実行ビット不要）
--
-- エントリポイントは各 .sql を「POSTGRES_DB（= ZEROCLAW_DB_NAME）」に接続した状態で実行する。
-- 注意: PostgreSQL では CREATE DATABASE を DO/関数の中から実行できない（トップレベルのみ）。

-- メインアプリ DB（接続済み）に pgvector
CREATE EXTENSION IF NOT EXISTS vector;

\connect postgres

-- 補助 DB（init は初回のみ実行されるため冪等の DO ブロックは不要）
CREATE DATABASE openwebui_db;
CREATE DATABASE langfuse_db;

\connect openwebui_db
CREATE EXTENSION IF NOT EXISTS vector;

\connect langfuse_db
CREATE EXTENSION IF NOT EXISTS vector;
