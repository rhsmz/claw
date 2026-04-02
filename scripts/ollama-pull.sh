#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

MODEL="${1:-gemma4:e2b}"
LOC="${OLLAMA_LAUNCH_LOCATION:-docker}"
LOC="$(echo "$LOC" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
if [[ "$LOC" == "windows" ]]; then
  LOC="host"
fi

if [[ "$LOC" == "host" ]]; then
  exec ollama pull "$MODEL"
else
  exec docker compose --profile ollama-docker exec ollama ollama pull "$MODEL"
fi
