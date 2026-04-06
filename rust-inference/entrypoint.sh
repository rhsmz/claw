#!/usr/bin/env bash
set -eo pipefail

# oneAPI ランタイム（SYCL / Level Zero）。setvars が未定義変数を参照するため nounset は使わない。
# shellcheck source=/dev/null
source /opt/intel/oneapi/setvars.sh --force

# WSL + Intel iGPU 等で libggml-sycl が大型テンソルを GPU に載せられず落ちる場合、
# RUST_INFERENCE_DISABLE_SYCL_PLUGIN=1 でプラグインを外し CPU のみで起動する（同一イメージのまま）。
if [[ "${RUST_INFERENCE_DISABLE_SYCL_PLUGIN:-}" == "1" ]]; then
  echo "rust-inference: RUST_INFERENCE_DISABLE_SYCL_PLUGIN=1 — libggml-sycl を読み込まず CPU バックエンドのみ" >&2
  rm -f /app/lib/libggml-sycl.so /app/lib/libggml-sycl.so.* 2>/dev/null || true
fi

MODEL="${LLAMA_MODEL_PATH:-}"
if [[ -z "${MODEL}" ]]; then
  MODEL="$(find /app/models -type f \( -name '*.gguf' -o -name '*.GGUF' \) 2>/dev/null | sort | head -1 || true)"
fi
if [[ -z "${MODEL}" ]]; then
  echo "rust-inference: .gguf が見つかりません。${RUST_INFERENCE_MODELS_HINT:-/app/models} に配置するか LLAMA_MODEL_PATH を設定してください。" >&2
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
