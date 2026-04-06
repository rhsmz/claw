#!/usr/bin/env bash
set -eo pipefail

MODEL="${LLAMA_MODEL_PATH:-}"
if [[ -z "${MODEL}" ]]; then
  MODEL="$(find /app/models -type f \( -name '*.gguf' -o -name '*.GGUF' \) 2>/dev/null | sort | head -1 || true)"
fi
if [[ -z "${MODEL}" ]]; then
  echo "opencl-inference: .gguf が見つかりません。/app/models に配置するか LLAMA_MODEL_PATH を設定してください。" >&2
  exit 1
fi

HOST="${LLAMA_HOST:-0.0.0.0}"
PORT="${LLAMA_PORT:-8080}"
NGL="${N_GPU_LAYERS:--1}"

exec /app/llama-server \
  --host "${HOST}" \
  --port "${PORT}" \
  -m "${MODEL}" \
  -ngl "${NGL}" \
  ${LLAMA_EXTRA_ARGS:-}
