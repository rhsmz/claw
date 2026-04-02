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

$model = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { "gemma4:e2b" }
$loc = $env:OLLAMA_LAUNCH_LOCATION
if ([string]::IsNullOrWhiteSpace($loc)) { $loc = "docker" }
$loc = $loc.Trim().ToLowerInvariant()
if ($loc -eq "windows") { $loc = "host" }

if ($loc -eq "host") {
    & ollama pull $model
} else {
    & docker compose --profile ollama-docker exec ollama ollama pull $model
}
