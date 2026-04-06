# Windows から WSL で scripts/wsl-setup-gpu.sh を実行するラッパー。
# 使い方: リポジトリルートで powershell -File scripts/wsl-setup-gpu-from-windows.ps1
# 環境変数 PERSIST_VGEM=1 を渡す例:
#   $env:PERSIST_VGEM = '1'; powershell -File scripts/wsl-setup-gpu-from-windows.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$UnixRepo = (wsl wslpath -u $RepoRoot).Trim()
$persist = $env:PERSIST_VGEM
if ($persist -eq "1") {
  wsl -e bash -lc "cd `"$UnixRepo`" && PERSIST_VGEM=1 bash scripts/wsl-setup-gpu.sh"
} else {
  wsl -e bash -lc "cd `"$UnixRepo`" && bash scripts/wsl-setup-gpu.sh"
}
