#!/usr/bin/env bash
# Hugging Face から GGUF を storage/rust-inference-models へ取得する。
#
# 単一ファイル（既定 Q8）:
#   bash scripts/download-hf-gguf.sh
# すべての .gguf（Q8 + F16 + mmproj など）:
#   ALL=1 bash scripts/download-hf-gguf.sh
#
# 環境変数: REPO, FILE, REVISION, HF_TOKEN, ALL=1
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/storage/rust-inference-models"
mkdir -p "${DEST}"
REPO="${REPO:-ggml-org/gemma-4-E2B-it-GGUF}"
FILE="${FILE:-gemma-4-e2b-it-Q8_0.gguf}"
REVISION="${REVISION:-main}"
ALL="${ALL:-0}"

VENV="${ROOT}/.venv-hf-download"
if [[ ! -x "${VENV}/bin/python" ]]; then
  echo "Creating venv: ${VENV}"
  python3 -m venv "${VENV}"
fi
PYTHON="${VENV}/bin/python"
"${VENV}/bin/pip" install -q --upgrade "huggingface_hub>=0.20"

echo "Repo: ${REPO}  Dest: ${DEST}"
export HF_HUB_ENABLE_HF_TRANSFER="${HF_HUB_ENABLE_HF_TRANSFER:-0}"

if [[ "$ALL" == "1" ]]; then
  echo "Mode: ALL *.gguf in repo (large download)"
  export HF_DL_REPO="$REPO"
  export HF_DL_REVISION="$REVISION"
  export HF_DL_DEST="$DEST"
  "${PYTHON}" -c "
import os
from huggingface_hub import snapshot_download
path = snapshot_download(
    repo_id=os.environ['HF_DL_REPO'],
    revision=os.environ['HF_DL_REVISION'],
    local_dir=os.environ['HF_DL_DEST'],
    allow_patterns=['*.gguf'],
    local_dir_use_symlinks=False,
    token=os.environ.get('HF_TOKEN'),
)
print('OK:', path)
"
  echo "Done. LLAMA_MODEL_PATH で推論用 .gguf を指定。mmproj はマルチモーダル時。"
else
  echo "File: ${FILE}"
  "${PYTHON}" -c "
from huggingface_hub import hf_hub_download
import os
p = hf_hub_download(
    repo_id='${REPO}',
    filename='${FILE}',
    revision='${REVISION}',
    local_dir=r'${DEST}',
    local_dir_use_symlinks=False,
    token=os.environ.get('HF_TOKEN'),
)
print('OK:', p)
"
  echo "Done. Multiple .gguf のときは .env で LLAMA_MODEL_PATH=/app/models/${FILE} を指定できます。"
fi
