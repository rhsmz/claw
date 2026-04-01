#!/bin/bash
set -euo pipefail

# compose の postgres サービスから渡す（未設定時は報告書どおりの既定名）
: "${ZEROCLAW_DB_NAME:=zeroclaw_memory}"
: "${WEBUI_DB_NAME:=openwebui_db}"
: "${LANGFUSE_DB_NAME:=langfuse_db}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
	CREATE DATABASE ${ZEROCLAW_DB_NAME};
	CREATE DATABASE ${WEBUI_DB_NAME};
	CREATE DATABASE ${LANGFUSE_DB_NAME};
EOSQL

for db in "${ZEROCLAW_DB_NAME}" "${WEBUI_DB_NAME}" "${LANGFUSE_DB_NAME}"; do
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" -c "CREATE EXTENSION IF NOT EXISTS vector;"
done
