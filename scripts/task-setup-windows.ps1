# Taskfile setup (Windows) — Unix の cp/mkdir と同等
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath ".env")) {
    Copy-Item -LiteralPath ".env.example" -Destination ".env"
}
if (-not (Test-Path -LiteralPath "mcp/gateway.env")) {
    Copy-Item -LiteralPath "mcp/gateway.env.example" -Destination "mcp/gateway.env"
}

foreach ($d in @("prompts", "skills", "storage/postgres", "storage/rust-inference-models", "mcp/vault", "wiki/notion", "wiki/confluence")) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

Write-Host "建国準備完了。各 .env にAPIキーを入力後、'task up' を実行してください。"
