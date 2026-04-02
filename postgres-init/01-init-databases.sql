-- docker-entrypoint-initdb.d 実行時に psql が解釈する（.sql は実行ビット不要）
--
-- エントリポイントは各 .sql を「POSTGRES_DB（= ZEROCLAW_DB_NAME）」に接続した状態で実行する。
-- そのためメイン DB 上の処理は先に済ませ、補助 DB だけ postgres DB に切り替えて作成する。
-- （\set :ENV{...} は psql 標準外で init 失敗の原因になり得るため使わない）

-- メインアプリ DB（接続済み）に pgvector
CREATE EXTENSION IF NOT EXISTS vector;

\connect postgres

-- 補助 DB（PG 9.1+ 互換）
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'openwebui_db') THEN
    EXECUTE 'CREATE DATABASE openwebui_db';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'langfuse_db') THEN
    EXECUTE 'CREATE DATABASE langfuse_db';
  END IF;
END $$;

\connect openwebui_db
CREATE EXTENSION IF NOT EXISTS vector;

\connect langfuse_db
CREATE EXTENSION IF NOT EXISTS vector;
