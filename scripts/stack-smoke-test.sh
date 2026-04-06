#!/usr/bin/env bash
# Docker Compose スタックがホストの公開ポートで応答するか確認する（起動済み前提）。
# 使い方: bash scripts/stack-smoke-test.sh
#
# 既定: コアのみ失敗で exit 1。profile 系は未起動なら SKIP。
# 厳密: STACK_SMOKE_STRICT=1 で全チェック必須。

set -u

fail=0
strict=0
if [[ "${STACK_SMOKE_STRICT:-}" == "1" ]]; then
  strict=1
fi

check_http() {
  local name="$1" url="$2" optional="${3:-0}"
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 4 --max-time 15 "$url" 2>/dev/null || echo "000")
  if [[ "$code" =~ ^(200|201|204|301|302|303|307|308)$ ]]; then
    echo "OK   $name (HTTP $code)"
  else
    if [[ "$strict" -eq 0 && "$optional" -eq 1 ]]; then
      echo "SKIP $name (HTTP $code, optional) $url"
    else
      echo "FAIL $name (HTTP $code) $url"
      fail=1
    fi
  fi
}

check_tcp() {
  local name="$1" port="$2" optional="${3:-0}"
  if command -v nc >/dev/null 2>&1; then
    if nc -z -w 4 127.0.0.1 "$port" 2>/dev/null; then
      echo "OK   $name (TCP $port)"
    else
      if [[ "$strict" -eq 0 && "$optional" -eq 1 ]]; then
        echo "SKIP $name (TCP $port optional)"
      else
        echo "FAIL $name (TCP $port)"
        fail=1
      fi
    fi
  else
    echo "SKIP $name (nc 未インストール)"
  fi
}

echo "=== stack smoke (127.0.0.1) strict=$strict ==="
STACK_PORTAL_PORT="${STACK_PORTAL_PORT:-8042}"
RUST_INFERENCE_HOST_PORT="${RUST_INFERENCE_HOST_PORT:-9080}"
OPENCL_INFERENCE_HOST_PORT="${OPENCL_INFERENCE_HOST_PORT:-9081}"
LLUMEN_HOST_PORT="${LLUMEN_HOST_PORT:-8079}"
LLM_GATEWAY_RUST_HOST_PORT="${LLM_GATEWAY_RUST_HOST_PORT:-4100}"

# コア
check_http "Stack Portal" "http://127.0.0.1:${STACK_PORTAL_PORT}/" 0
check_http "LiteLLM liveness" "http://127.0.0.1:4000/health/liveness" 0
check_http "rust-inference /health" "http://127.0.0.1:${RUST_INFERENCE_HOST_PORT}/health" 0
check_tcp "MCP Gateway" "8811" 0

# 任意プロファイル
check_http "opencl-inference /health" "http://127.0.0.1:${OPENCL_INFERENCE_HOST_PORT}/health" 1
check_http "llm-gateway-rust /health" "http://127.0.0.1:${LLM_GATEWAY_RUST_HOST_PORT}/health" 1
check_http "ZeroClaw /health" "http://127.0.0.1:42617/health" 1
check_http "Llumen" "http://127.0.0.1:${LLUMEN_HOST_PORT}/" 1
check_http "Open WebUI" "http://127.0.0.1:8080/" 1
check_http "Langfuse" "http://127.0.0.1:3000/" 1

if [[ "$fail" -ne 0 ]]; then
  echo "=== コア疎通に失敗（Docker 未起動・GGUF 未配置・ヘルス待ち等）==="
  exit 1
fi
if [[ "$strict" -eq 1 ]]; then
  echo "=== すべて応答あり（厳密モード）==="
else
  echo "=== コア OK（任意プロファイルは SKIP 可）==="
fi
exit 0
