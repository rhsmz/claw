# Windows から WSL で scripts/check-wsl-intel-gpu.sh を実行するラッパー。
$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$UnixRepo = (wsl wslpath -u $RepoRoot).Trim()
wsl -e bash -lc "cd `"$UnixRepo`" && sed -i 's/\r$//' scripts/check-wsl-intel-gpu.sh 2>/dev/null; bash scripts/check-wsl-intel-gpu.sh"
