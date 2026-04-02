# Compose 起動用ラッパー: .env の OLLAMA_LAUNCH_LOCATION に応じて ollama-docker プロファイルを付与する。
# 使い方: powershell -File scripts/docker-compose-with-ollama.ps1 up -d --wait
# Task から dotenv で渡された環境変数を引き継ぐ。直接実行時は .env を読み込む。
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$EnvFile = Join-Path $Root ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $k = $Matches[1]
            $v = $Matches[2].Trim()
            if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
            elseif ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }
            [Environment]::SetEnvironmentVariable($k, $v, "Process")
        }
    }
}

$loc = $env:OLLAMA_LAUNCH_LOCATION
if ([string]::IsNullOrWhiteSpace($loc)) { $loc = "docker" }
$loc = $loc.Trim().ToLowerInvariant()
if ($loc -eq "windows") { $loc = "host" }

if ($loc -eq "host") {
    if ([string]::IsNullOrWhiteSpace($env:OLLAMA_API_BASE)) {
        $env:OLLAMA_API_BASE = "http://host.docker.internal:11434"
    }
    & docker compose @args
} else {
    if ([string]::IsNullOrWhiteSpace($env:OLLAMA_API_BASE)) {
        $env:OLLAMA_API_BASE = "http://ollama:11434"
    }
    $composeArgs = @("--profile", "ollama-docker") + $args
    & docker compose @composeArgs
}
