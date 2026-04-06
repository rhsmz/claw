# Compose 起動ラッパー（引数をそのまま docker compose に渡す）
# 使い方: powershell -File scripts/docker-compose-stack.ps1 up -d --wait
$ErrorActionPreference = "Stop"
& docker compose @args
