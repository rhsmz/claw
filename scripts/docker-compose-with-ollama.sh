#!/usr/bin/env bash
# Compose 起動用ラッパー: OLLAMA_LAUNCH_LOCATION に応じて ollama-docker プロファイルを付与する。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

LOC="${OLLAMA_LAUNCH_LOCATION:-docker}"
LOC="$(echo "$LOC" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
if [[ "$LOC" == "windows" ]]; then
  LOC="host"
fi

if [[ "$LOC" == "host" ]]; then
  export OLLAMA_API_BASE="${OLLAMA_API_BASE:-http://host.docker.internal:11434}"
  exec docker compose "$@"
else
  export OLLAMA_API_BASE="${OLLAMA_API_BASE:-http://ollama:11434}"
  exec docker compose --profile ollama-docker "$@"
fi
