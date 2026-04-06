#!/usr/bin/env bash
# Compose 起動ラッパー（引数をそのまま docker compose に渡す）
set -euo pipefail
exec docker compose "$@"
