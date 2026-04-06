# Hugging Face から GGUF を storage/rust-inference-models へ取得する。
#
# 単一ファイル（既定 Q8）:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/download-hf-gguf.ps1
# 別ファイルのみ:
#   powershell -File scripts/download-hf-gguf.ps1 -File "gemma-4-e2b-it-f16.gguf"
# リポジトリ内のすべての .gguf（Q8 + F16 + mmproj など、合計約 15GB 級）:
#   powershell -File scripts/download-hf-gguf.ps1 -All
#
# ゲート付きモデル: $env:HF_TOKEN = "hf_..."
#
param(
    [string]$Repo = "ggml-org/gemma-4-E2B-it-GGUF",
    [string]$File = "gemma-4-e2b-it-Q8_0.gguf",
    [switch]$All,
    [string]$Revision = "main"
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Dest = Join-Path $Root "storage\rust-inference-models"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Write-Host "Repo:    $Repo"
Write-Host "Dest:    $Dest"
Write-Host "Installing huggingface_hub if needed..."
python -m pip install -q --upgrade "huggingface_hub>=0.20"

$env:HF_DL_REPO = $Repo
$env:HF_DL_REVISION = $Revision
$env:HF_DL_DEST = $Dest

if ($All) {
    Write-Host "Mode:    ALL *.gguf in repo (large download)"
    python -c @'
import os
from huggingface_hub import snapshot_download
path = snapshot_download(
    repo_id=os.environ["HF_DL_REPO"],
    revision=os.environ["HF_DL_REVISION"],
    local_dir=os.environ["HF_DL_DEST"],
    allow_patterns=["*.gguf"],
    local_dir_use_symlinks=False,
    token=os.environ.get("HF_TOKEN"),
)
print("OK:", path)
'@
} else {
    Write-Host "File:    $File"
    $env:HF_DL_FILE = $File
    python -c @'
import os
from huggingface_hub import hf_hub_download
p = hf_hub_download(
    repo_id=os.environ["HF_DL_REPO"],
    filename=os.environ["HF_DL_FILE"],
    revision=os.environ["HF_DL_REVISION"],
    local_dir=os.environ["HF_DL_DEST"],
    local_dir_use_symlinks=False,
    token=os.environ.get("HF_TOKEN"),
)
print("OK:", p)
'@
}

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if ($All) {
    Write-Host "Done. 推論用に使うファイルを .env の LLAMA_MODEL_PATH=/app/models/<名前>.gguf で指定してください（mmproj はマルチモーダル時）。"
} else {
    Write-Host "Done. 複数 .gguf がある場合は .env で LLAMA_MODEL_PATH=/app/models/$File を指定してください。"
}
