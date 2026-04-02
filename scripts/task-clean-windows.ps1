# Taskfile clean (Windows) — storage/postgres 配下の削除 + docker prune
$ErrorActionPreference = "Continue"

if (Test-Path -LiteralPath "storage/postgres") {
    Get-ChildItem -LiteralPath "storage/postgres" -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

docker system prune -f
Write-Host "帝国の全領域を浄化しました。"
