#!/usr/bin/env bash
# Docker Compose スタックがホストの公開ポートで応答するか確認する（起動済み前提）。
# 使い方: bash scripts/stack-smoke-test.sh
# 終了コード: いずれか失敗で 1（CI 向け）

set -u

fail=0

check_http() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 4 --max-time 15 "$url" 2>/dev/null || echo "000")
  if [[ "$code" =~ ^(200|201|204|301|302|303|307|308)$ ]]; then
    echo "OK   $name (HTTP $code)"
  else
    echo "FAIL $name (HTTP $code) $url"
    fail=1
  fi
}

check_tcp() {
  local name="$1" port="$2"
  if command -v nc >/dev/null 2>&1; then
    if nc -z -w 4 127.0.0.1 "$port" 2>/dev/null; then
      echo "OK   $name (TCP $port)"
    else
      echo "FAIL $name (TCP $port)"
      fail=1
    fi
  else
    echo "SKIP $name (nc 未インストール)"
  fi
}

echo "=== stack smoke (127.0.0.1) ==="
STACK_PORTAL_PORT="${STACK_PORTAL_PORT:-8042}"
RUST_INFERENCE_HOST_PORT="${RUST_INFERENCE_HOST_PORT:-9080}"
check_http "Stack Portal" "http://127.0.0.1:${STACK_PORTAL_PORT}/"
check_http "LiteLLM liveness" "http://127.0.0.1:4000/health/liveness"
check_http "rust-inference /health" "http://127.0.0.1:${RUST_INFERENCE_HOST_PORT}/health"
check_http "ZeroClaw /health" "http://127.0.0.1:42617/health"
check_http "Open WebUI" "http://127.0.0.1:8080/"
check_http "Langfuse" "http://127.0.0.1:3000/"
check_tcp "MCP Gateway" "8811"

if [[ "$fail" -ne 0 ]]; then
  echo "=== 一部失敗（未起動・profile 未適用・ヘルス起動中の可能性）==="
  exit 1
fi
echo "=== すべて応答あり ==="
exit 0
