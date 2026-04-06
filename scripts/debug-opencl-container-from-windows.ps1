$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$UnixRepo = (wsl wslpath -u $RepoRoot).Trim()
wsl -e bash -lc "cd `"$UnixRepo`" && sed -i 's/\r$//' scripts/debug-opencl-container.sh 2>/dev/null; bash scripts/debug-opencl-container.sh"
