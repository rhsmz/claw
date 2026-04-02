# Validation Report v1 (2026-04-02 UTC, revised)

## Scope

- `prompts/base_instruction.md` v5 + Mandatory Prompt Stack
- `prompts/common/*` including **Crew execution artifacts & supervisor approval** (`workflow_contract.md`) and **crew collaboration routing** (`crew_collaboration_routing.md`, crew §2b)
- Skill stack / skill cards spec (`skill_stack_and_cards.md`, `skill_card_template.md`)
- Design principles (`design_principles.md`) vs TASKS §1-1
- All **66** crew prompts under `prompts/*.md` (excluding `base_instruction.md`)
- `prompts/schema/crew_output.schema.json` vs embedded JSON examples
- `zeroclaw/config.toml` crew `skills` ↔ `prompts/skills/*.md` paths
- `crew/<agent_id>/` — **no** per-agent TASKS/work_logs in repo; crews create them at runtime per `workflow_contract.md` (templates in `crew/_template/`)

## Summary

| Check | Result |
|-------|--------|
| Crew prompt file count vs config `prompt_file` | **PASS** — 66 files, 0 missing |
| Sections 0–9 present (Required Read → Skill Activation) | **PASS** |
| `{{agent_id}}`, `{{supervisor_agent_or_human}}` in Mission Context | **PASS** (post-patch) |
| §7b Local plan / approval / work_logs reference | **PASS** |
| §2b Collaboration & `crew_collaboration_routing.md` in Required Read | **PASS** |
| JSON example includes `open_questions`, `citations`, `self_check` | **PASS** |
| `team_notify` undefined skill id | **FIXED** — config uses `team_notify_discord`; legacy `team_notify.md` documents alias |
| Schema `handoff.next_owner` / `first_step` vs prompts | **PASS** |
| English primary prompts | **PARTIAL** — Identity lines may still contain Japanese charter text; follow-up localization in Identity section recommended |
| Safety / injection test execution | **NOT RUN** (manual test track) |
| `/ja` translations | **PARTIAL** — `prompts/ja/README.md` mapping only |

## Skill stack / LP checks (plan additive requirements)

- **PASS**: `workflow_contract.md` defines Plan → Execute gate with **supervisor review** (submit → review outcome → **`approved`** in section 7 before Execute) and artifact paths.
- **PASS**: Crew prompts reference the contract in §7b.
- **PASS**: `skill_stack_and_cards.md` documents stack ordering.

## Improvement cycle (TASKS §1-7)

1. **Change**: Normalized `team_notify` → `team_notify_discord` in config; expanded common contracts; patched 66 prompts.
2. **Metric**: Structural lint (sections + JSON tail + variables) — 66/66 files compliant.
3. **Next cycle**: Translate Identity/Backstory to English; run injection test suite; fill `prompts/ja/` mirrors.

## Sign-off (role play per plan)

| Role | Status |
|------|--------|
| technical_spec_reviewer | Structural schema alignment **approved** (2026-04-02 UTC) |
| consistency_checker | Cross-file naming **approved** |
| pmo_logic / system_architect | Architecture mapping doc **approved** |
| ai_observability_lead / release_manager / pmo_empathy | Pending full JP rollout + live safety tests |
