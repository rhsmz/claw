# Docker Compose スタックの公開ポート疎通（起動済み前提）
# 使い方: powershell -NoProfile -File scripts/stack-smoke-test.ps1
#
# 既定: コア（portal / LiteLLM / rust-inference / MCP）のみ失敗で exit 1。
#       profile 系（rust-gateway / zeroclaw / Llumen / Open WebUI / Langfuse）は
#       未起動なら SKIP（終了コード 0）。
# 厳密: 環境変数 STACK_SMOKE_STRICT=1 で全チェック必須（従来挙動）。
$ErrorActionPreference = "Continue"
$fail = 0
$strict = ($env:STACK_SMOKE_STRICT -eq "1")

function Test-HttpOk {
    param(
        [string]$Name,
        [string]$Url,
        [switch]$Optional
    )
    $isOptional = $Optional.IsPresent -and -not $strict
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 15 -MaximumRedirection 0 -ErrorAction Stop
        $code = [int]$r.StatusCode
        if ($code -in @(200, 201, 204, 301, 302, 303, 307, 308)) {
            Write-Host "OK   $Name (HTTP $code)"
        } else {
            if ($isOptional) {
                Write-Host "SKIP $Name (HTTP $code, optional) $Url"
            } else {
                Write-Host "FAIL $Name (HTTP $code) $Url"
                $script:fail = 1
            }
        }
    } catch {
        if ($isOptional) {
            Write-Host "SKIP $Name (optional, not reachable) $Url"
        } else {
            Write-Host "FAIL $Name $($_.Exception.Message) $Url"
            $script:fail = 1
        }
    }
}

function Test-TcpOpen {
    param(
        [string]$Name,
        [int]$Port,
        [switch]$Optional
    )
    $isOptional = $Optional.IsPresent -and -not $strict
    try {
        $c = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue
        if ($c.TcpTestSucceeded) {
            Write-Host "OK   $Name (TCP $Port)"
        } else {
            if ($isOptional) {
                Write-Host "SKIP $Name (TCP $Port optional)"
            } else {
                Write-Host "FAIL $Name (TCP $Port)"
                $script:fail = 1
            }
        }
    } catch {
        if ($isOptional) {
            Write-Host "SKIP $Name (TCP optional, check failed)"
        } else {
            Write-Host "SKIP $Name (TCP チェック不可)"
        }
    }
}

Write-Host "=== stack smoke (127.0.0.1) strict=$strict ==="
$portal = if ($env:STACK_PORTAL_PORT) { $env:STACK_PORTAL_PORT } else { "8042" }
$rustPort = if ($env:RUST_INFERENCE_HOST_PORT) { $env:RUST_INFERENCE_HOST_PORT } else { "9080" }
$openclPort = if ($env:OPENCL_INFERENCE_HOST_PORT) { $env:OPENCL_INFERENCE_HOST_PORT } else { "9081" }
$llumenPort = if ($env:LLUMEN_HOST_PORT) { $env:LLUMEN_HOST_PORT } else { "8079" }
$gwRustPort = if ($env:LLM_GATEWAY_RUST_HOST_PORT) { $env:LLM_GATEWAY_RUST_HOST_PORT } else { "4100" }

# --- コア（既定スタック task up）---
Test-HttpOk "Stack Portal" "http://127.0.0.1:${portal}/"
Test-HttpOk "LiteLLM liveness" "http://127.0.0.1:4000/health/liveness"
Test-HttpOk "rust-inference /health" "http://127.0.0.1:${rustPort}/health"
Test-TcpOpen "MCP Gateway" 8811

# --- 任意プロファイル ---
Test-HttpOk "opencl-inference /health" "http://127.0.0.1:${openclPort}/health" -Optional
Test-HttpOk "llm-gateway-rust /health" "http://127.0.0.1:${gwRustPort}/health" -Optional
Test-HttpOk "ZeroClaw /health" "http://127.0.0.1:42617/health" -Optional
Test-HttpOk "Llumen" "http://127.0.0.1:${llumenPort}/" -Optional
Test-HttpOk "Open WebUI" "http://127.0.0.1:8080/" -Optional
Test-HttpOk "Langfuse" "http://127.0.0.1:3000/" -Optional

if ($fail -ne 0) {
    Write-Host "=== コア疎通に失敗（Docker 未起動・GGUF 未配置・ヘルス待ち等）==="
    exit 1
}
if ($strict) {
    Write-Host "=== すべて応答あり（厳密モード）==="
} else {
    Write-Host "=== コア OK（任意プロファイルは SKIP 可）==="
}
exit 0
