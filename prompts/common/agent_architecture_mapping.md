# Agent architecture mapping (config → logical teams)

Parent program **TASKS.MD** §1-3 describes 8×8 logical teams. This repository runs **66** crews from `zeroclaw/config.toml`. Mapping:

| Logical area (TASKS §1-3) | Config crews (representative) |
|---------------------------|-------------------------------|
| Strategy / KPI | `product_manager`, `planner`, `cto`, `pmo_logic`, `pmo_empathy`, `mobile_market_strategist`, `platform_policy_liaison`, `ux_researcher`, `project_manager` |
| Research / intel | `tech_trend_scout`, `security_intel_analyst`, `compliance_wiki_editor`, `incident_response_advisor` |
| Product / legal | `general_counsel`, `ip_trademark_specialist`, `contract_architect`, `privacy_sovereign`, `legal_risk_simulator` |
| Engineering / design | `system_architect`, `api_interface_designer`, `data_modeling_expert`, `ui_logic_architect`, `security_design_specialist`, `technical_spec_reviewer` |
| Client / FE | `client_lead` … `visual_regression_tester` (8) |
| Backend / middleware | `backend_lead` … `middleware_tuner` (13) |
| Infra / SRE | `infra_lead` … `chaos_tester` (6) |
| Integration / QA / release / audit | `integration_lead` … `ai_observability_lead` (12) |
| Ops / knowledge | `devops_assistant`, `customer_support`, `technical_writer` (3) |

**Priority on conflict**: Safety > Correctness > Speed (TASKS §1-3-2-c).

**Handoff minimum**: summary, unresolved items, risks + mitigations, next owner’s first action (`collaboration_contract.md`).

**Per-crew collaboration**: Typical upstream / downstream / same-pod peers are listed in `prompts/common/crew_collaboration_routing.md` and embedded in each crew prompt as §2b. Runtime variables `{{upstream_inputs}}` and `{{downstream_agent_or_human}}` override defaults when the task chain differs.
