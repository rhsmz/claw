# Generates prompts/common/crew_collaboration_routing.md from crew_collaboration.tsv
# and inserts ## 2b) + Required Read entry into each crew prompt (prompts/*.md except base_instruction).

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ConfigPath = Join-Path $RepoRoot 'zeroclaw\config.toml'
$TsvPath = Join-Path $PSScriptRoot 'crew_collaboration.tsv'
$RoutingPath = Join-Path $RepoRoot 'prompts\common\crew_collaboration_routing.md'
$PromptsDir = Join-Path $RepoRoot 'prompts'

# --- Parse config: name -> prompt basename, peer groups ---
# Pod assignment follows fixed [[crews]] order in zeroclaw/config.toml (ASCII-only; no comment parsing).
$nameToFile = @{}
$crewKey = @{}
$groups = @{}

$allNames = [System.Collections.Generic.List[string]]::new()
$inCrews = $false
foreach ($line in [System.IO.File]::ReadAllLines($ConfigPath)) {
    if ($line -match '^\[\[crews\]\]') { $inCrews = $true; continue }
    if ($line -match '^\[\[skills\]\]') { $inCrews = $false; continue }
    if ($inCrews -and ($line -match '^name\s*=\s*"([^"]+)"')) { $allNames.Add($Matches[1]) | Out-Null }
}

$segments = @(
    @{ Key = 'management'; Count = 9 }
    @{ Key = 'legal'; Count = 5 }
    @{ Key = 'intel'; Count = 4 }
    @{ Key = 'design'; Count = 6 }
    @{ Key = 'build/client'; Count = 8 }
    @{ Key = 'build/backend'; Count = 13 }
    @{ Key = 'build/infra'; Count = 6 }
    @{ Key = 'integration'; Count = 12 }
    @{ Key = 'ops'; Count = 3 }
)
$expected = 0
foreach ($s in $segments) { $expected += $s.Count }
if ($allNames.Count -ne $expected) {
    throw "config.toml [[crews]] name count $($allNames.Count) != expected $expected"
}

$idx = 0
foreach ($seg in $segments) {
    $key = $seg.Key
    if (-not $groups[$key]) { $groups[$key] = [System.Collections.Generic.List[string]]::new() }
    for ($i = 0; $i -lt $seg.Count; $i++) {
        $n = $allNames[$idx++]
        $crewKey[$n] = $key
        $groups[$key].Add($n) | Out-Null
    }
}

# Map crew name -> prompt filename (only inside [[crews]] blocks)
$pendingName = $null
$inCrews = $false
foreach ($line in [System.IO.File]::ReadAllLines($ConfigPath)) {
    if ($line -match '^\[\[crews\]\]') { $inCrews = $true; continue }
    if ($line -match '^\[\[skills\]\]') { $inCrews = $false; $pendingName = $null; continue }
    if (-not $inCrews) { continue }
    if ($line -match '^name\s*=\s*"([^"]+)"') { $pendingName = $Matches[1]; continue }
    if ($pendingName -and ($line -match 'prompt_file\s*=\s*"prompts/([^"]+)"')) {
        $nameToFile[$pendingName] = $Matches[1]
        $pendingName = $null
    }
}

$rows = Import-Csv -LiteralPath $TsvPath -Delimiter "`t"
$namesInTsv = $rows | ForEach-Object { $_.name }
foreach ($n in $namesInTsv) {
    if (-not $nameToFile.ContainsKey($n)) { throw "TSV name not in config: $n" }
}

# --- Write crew_collaboration_routing.md ---
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# Crew collaboration routing')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Canonical handoff rules: `collaboration_contract.md`. Phase gates and supervisor review: `workflow_contract.md`.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Baseline workflow vs local efficiency')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('The **baseline** program flow is fixed: **Intake -> Plan (local `TASKS_*.MD` + supervisor review -> `approved`) -> Execute -> Validate -> Handoff -> Close** (`workflow_contract.md`, `base_instruction.md`, each crew section 7/7b).')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('**Within** that baseline, each crew should **actively** improve efficiency: parallel clarifications, clearer handoff payloads, sensible batching (with supervisor agreement), and early escalation - **without** skipping approvals, phase DoR/DoD, or `collaboration_contract.md` minimums.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Runtime variables **`{{upstream_inputs}}`**, **`{{downstream_agent_or_human}}`**, and **`{{supervisor_agent_or_human}}`** override static routing when the active task chain differs.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Per-crew routing (typical partners)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Crew | Pod / subgroup | Typical upstream | Typical downstream | Same-pod peers |')
[void]$sb.AppendLine('|------|----------------|------------------|--------------------|----------------|')

foreach ($r in $rows) {
    $n = $r.name
    $key = $crewKey[$n]
    $peers = (($groups[$key] | Where-Object { $_ -ne $n }) | ForEach-Object { "``$_``" }) -join ', '
    if (-not $peers) { $peers = '-' }
    $u = $r.upstream
    $d = $r.downstream
    [void]$sb.AppendLine("| ``$n`` | ``$key`` | $u | $d | $peers |")
}

[void]$sb.AppendLine('')
foreach ($r in $rows) {
    $n = $r.name
    $key = $crewKey[$n]
    $peerList = (($groups[$key] | Where-Object { $_ -ne $n }) | ForEach-Object { "``$_``" }) -join ', '
    if (-not $peerList) { $peerList = '-' }
    [void]$sb.AppendLine("### $n")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- **Pod / subgroup**: ``$key``")
    [void]$sb.AppendLine("- **Typical upstream**: $($r.upstream)")
    [void]$sb.AppendLine("- **Typical downstream**: $($r.downstream)")
    [void]$sb.AppendLine("- **Same-pod peers**: $peerList")
    [void]$sb.AppendLine('')
}

[System.IO.File]::WriteAllText($RoutingPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))

# --- Patch each crew prompt ---
$readLine = '- prompts/common/crew_collaboration_routing.md'
foreach ($r in $rows) {
    $n = $r.name
    $rel = $nameToFile[$n]
    $path = Join-Path $PromptsDir $rel
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing prompt file: $path" }

    $text = [System.IO.File]::ReadAllText($path)
    if ($text -notmatch [regex]::Escape('collaboration_contract.md')) { throw "Unexpected prompt layout: $rel" }

    if ($text -notmatch [regex]::Escape($readLine)) {
        $text = $text -replace '(- prompts/common/collaboration_contract\.md\r?\n)', "`$1$readLine`n"
    }

    $peerListForBlock = (($groups[$crewKey[$n]] | Where-Object { $_ -ne $n }) | ForEach-Object { "``$_``" }) -join ', '
    if (-not $peerListForBlock) { $peerListForBlock = '-' }

    $block = @"
## 2b) Collaboration & workflow (this crew)
- **Crew id (``{{agent_id}}``)**: ``$n`` - full routing: ``prompts/common/crew_collaboration_routing.md`` section **$n** (and summary table).
- **Typical upstream** (inputs / context / approvals): $($r.upstream)
- **Typical downstream** (consumers of your handoffs): $($r.downstream)
- **Same-pod peers** (coordinate, de-duplicate): $peerListForBlock
- **Workflow**: **Baseline** = ``workflow_contract.md`` + this file section 7/7b (phase gates + supervisor review). **You must** keep that baseline. **You should** proactively optimize *inside* it (parallel questions, tighter payloads per ``collaboration_contract.md``, early escalation) - never skip gates or approvals.
- **Overrides**: ``{{upstream_inputs}}``, ``{{downstream_agent_or_human}}``, ``{{supervisor_agent_or_human}}`` take precedence when the live chain differs.

"@

    if ($text -match '## 2b\) Collaboration') {
        $text = [regex]::Replace($text, '(?ms)^## 2b\) Collaboration & workflow \(this crew\).*?(?=^## 3\))', $block)
    }
    else {
        $needle = "- Expected Downstream Consumer: {{downstream_agent_or_human}}"
        if ($text -notlike "*$needle*") { throw "Missing Mission Context tail: $rel" }
        $text = $text.Replace($needle, "$needle`n`n$block")
    }

    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

Write-Host "Wrote $RoutingPath and patched $($rows.Count) crew prompts."
