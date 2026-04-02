# Crew collaboration routing

Canonical handoff rules: `collaboration_contract.md`. Phase gates and supervisor review: `workflow_contract.md`.

## Baseline workflow vs local efficiency

The **baseline** program flow is fixed: **Intake -> Plan (local `TASKS_*.MD` + supervisor review -> `approved`) -> Execute -> Validate -> Handoff -> Close** (`workflow_contract.md`, `base_instruction.md`, each crew section 7/7b).

**Within** that baseline, each crew should **actively** improve efficiency: parallel clarifications, clearer handoff payloads, sensible batching (with supervisor agreement), and early escalation - **without** skipping approvals, phase DoR/DoD, or `collaboration_contract.md` minimums.

Runtime variables **`{{upstream_inputs}}`**, **`{{downstream_agent_or_human}}`**, and **`{{supervisor_agent_or_human}}`** override static routing when the active task chain differs.

## Per-crew routing (typical partners)

| Crew | Pod / subgroup | Typical upstream | Typical downstream | Same-pod peers |
|------|----------------|------------------|--------------------|----------------|
| `product_manager` | `management` | `project_manager`; executive / human sponsor as assigned; `customer_success_analyst` (feedback) | `planner`; `ux_researcher`; `cto`; `mobile_market_strategist`; `platform_policy_liaison`; `pmo_logic`; `pmo_empathy`; `general_counsel` (legal touchpoints) | `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy` |
| `ux_researcher` | `management` | `product_manager`; `planner`; `project_manager` | `ui_ux_specialist`; `ui_logic_architect`; `human_interface_auditor`; `planner` | `product_manager`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy` |
| `mobile_market_strategist` | `management` | `product_manager`; `planner` | `platform_policy_liaison`; `client_lead`; `store_submission_gatekeeper`; `ux_researcher` | `product_manager`, `ux_researcher`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy` |
| `platform_policy_liaison` | `management` | `product_manager`; `general_counsel`; `mobile_market_strategist` | `planner`; `store_submission_gatekeeper`; `client_lead` | `product_manager`, `ux_researcher`, `mobile_market_strategist`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy` |
| `planner` | `management` | `product_manager`; `project_manager`; `ux_researcher` | `cto`; `system_architect`; `api_interface_designer`; `data_modeling_expert`; `client_lead`; `backend_lead`; `pmo_logic` | `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy` |
| `project_manager` | `management` | Executive / program intake; `{{upstream_inputs}}` | `product_manager`; `cto`; `pmo_logic`; `pmo_empathy`; `integration_lead`; `release_manager`; initiative-specific leads | `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `cto`, `pmo_logic`, `pmo_empathy` |
| `cto` | `management` | `product_manager`; `project_manager`; `pmo_logic` | `system_architect`; `backend_lead`; `client_lead`; `infra_lead`; `security_design_specialist`; `technical_spec_reviewer` | `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `pmo_logic`, `pmo_empathy` |
| `pmo_logic` | `management` | `project_manager`; `cto` | All initiative crews (oversight); `integration_lead`; `release_manager`; `planner` | `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_empathy` |
| `pmo_empathy` | `management` | `project_manager`; `pmo_logic` | All pods (coordination, comms); notification skills per policy (`team_notify_discord` / `team_notify_slack`) | `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic` |
| `general_counsel` | `legal` | `product_manager`; `project_manager`; `cto` | `ip_trademark_specialist`; `contract_architect`; `privacy_sovereign`; `legal_risk_simulator`; build & release crews for compliance questions | `ip_trademark_specialist`, `contract_architect`, `privacy_sovereign`, `legal_risk_simulator` |
| `ip_trademark_specialist` | `legal` | `general_counsel`; `product_manager` | `contract_architect`; `store_submission_gatekeeper`; `technical_writer` | `general_counsel`, `contract_architect`, `privacy_sovereign`, `legal_risk_simulator` |
| `contract_architect` | `legal` | `general_counsel`; `planner`; `product_manager` | `backend_lead`; `client_lead`; `privacy_sovereign`; `grc_officer`; `store_submission_gatekeeper` | `general_counsel`, `ip_trademark_specialist`, `privacy_sovereign`, `legal_risk_simulator` |
| `privacy_sovereign` | `legal` | `general_counsel`; `contract_architect`; `data_modeling_expert` | `backend_lead`; `grc_officer`; `data_modeling_expert`; `security_design_specialist` | `general_counsel`, `ip_trademark_specialist`, `contract_architect`, `legal_risk_simulator` |
| `legal_risk_simulator` | `legal` | `general_counsel`; `security_auditor` | `general_counsel`; `product_manager`; `grc_officer` | `general_counsel`, `ip_trademark_specialist`, `contract_architect`, `privacy_sovereign` |
| `tech_trend_scout` | `intel` | `cto`; `system_architect` | `compliance_wiki_editor`; `system_architect`; `technical_writer` | `security_intel_analyst`, `compliance_wiki_editor`, `incident_response_advisor` |
| `security_intel_analyst` | `intel` | `security_auditor`; `cto`; `sre_engineer` | `compliance_wiki_editor`; `incident_response_advisor`; `security_design_specialist` | `tech_trend_scout`, `compliance_wiki_editor`, `incident_response_advisor` |
| `compliance_wiki_editor` | `intel` | `general_counsel`; `tech_trend_scout`; `security_intel_analyst` | All crews consuming wiki / standards; `technical_writer` | `tech_trend_scout`, `security_intel_analyst`, `incident_response_advisor` |
| `incident_response_advisor` | `intel` | `security_intel_analyst`; `sre_engineer`; `on-call` directives | `cto`; `infra_lead`; `security_auditor`; `project_manager`; affected leads | `tech_trend_scout`, `security_intel_analyst`, `compliance_wiki_editor` |
| `system_architect` | `design` | `cto`; `product_manager`; `planner` | `api_interface_designer`; `data_modeling_expert`; `ui_logic_architect`; `security_design_specialist`; `backend_lead`; `client_lead`; `infra_lead` | `api_interface_designer`, `data_modeling_expert`, `ui_logic_architect`, `security_design_specialist`, `technical_spec_reviewer` |
| `api_interface_designer` | `design` | `system_architect`; `planner`; `technical_spec_reviewer` | `backend_lead`; `client_lead`; `contract_test_dev`; `consistency_checker`; `middleware_tuner` | `system_architect`, `data_modeling_expert`, `ui_logic_architect`, `security_design_specialist`, `technical_spec_reviewer` |
| `data_modeling_expert` | `design` | `system_architect`; `planner` | `backend_lead`; `db_architect`; `api_interface_designer` | `system_architect`, `api_interface_designer`, `ui_logic_architect`, `security_design_specialist`, `technical_spec_reviewer` |
| `ui_logic_architect` | `design` | `ux_researcher`; `system_architect`; `planner` | `client_lead`; `ui_ux_specialist`; `human_interface_auditor` | `system_architect`, `api_interface_designer`, `data_modeling_expert`, `security_design_specialist`, `technical_spec_reviewer` |
| `security_design_specialist` | `design` | `system_architect`; `security_intel_analyst` | `backend_lead`; `client_lead`; `infra_lead`; `protocol_guardian` | `system_architect`, `api_interface_designer`, `data_modeling_expert`, `ui_logic_architect`, `technical_spec_reviewer` |
| `technical_spec_reviewer` | `design` | `system_architect`; all design pod outputs | `system_architect`; `cto`; `integration_lead`; design authors (return with findings) | `system_architect`, `api_interface_designer`, `data_modeling_expert`, `ui_logic_architect`, `security_design_specialist` |
| `client_lead` | `build/client` | `ui_logic_architect`; `api_interface_designer`; `planner` | `js_ts_wizard`; `ui_ux_specialist`; `integration_lead` | `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester` |
| `ui_ux_specialist` | `build/client` | `ux_researcher`; `ui_logic_architect`; `client_lead` | `client_lead`; `human_interface_auditor`; `visual_regression_tester` | `client_lead`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester` |
| `js_ts_wizard` | `build/client` | `client_lead`; `api_interface_designer` | `js_ts_guardian`; `client_pr_optimizer`; `client_test_dev` | `client_lead`, `ui_ux_specialist`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester` |
| `js_ts_guardian` | `build/client` | `client_lead`; `js_ts_wizard` | `client_pr_standardizer`; `client_test_dev`; `security_auditor` (on demand) | `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester` |
| `client_pr_optimizer` | `build/client` | `client_lead`; `js_ts_wizard`; `js_ts_guardian` | `client_lead`; `integration_lead`; `release_manager` | `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester` |
| `client_pr_standardizer` | `build/client` | `client_lead`; JS pod implementers | `integration_lead`; `release_manager` | `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_test_dev`, `visual_regression_tester` |
| `client_test_dev` | `build/client` | `client_lead`; `js_ts_wizard` | `visual_regression_tester`; `integration_lead`; `qa_engineer` | `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `visual_regression_tester` |
| `visual_regression_tester` | `build/client` | `client_test_dev`; `ui_ux_specialist` | `integration_lead`; `qa_engineer` | `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev` |
| `backend_lead` | `build/backend` | `api_interface_designer`; `system_architect`; `data_modeling_expert` | `php_artisan`; `php_hardener`; `go_specialist`; `go_sentinel`; `rust_evangelist`; `rust_governor`; `db_architect`; `middleware_tuner` | `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `db_architect` | `build/backend` | `data_modeling_expert`; `backend_lead` | `backend_lead`; `php_artisan`; `go_specialist`; `api_unit_tester` | `backend_lead`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `php_artisan` | `build/backend` | `backend_lead` | `php_hardener`; `backend_pr_optimizer`; `api_unit_tester` | `backend_lead`, `db_architect`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `php_hardener` | `build/backend` | `backend_lead`; `php_artisan` | `backend_pr_securitizer`; `api_unit_tester` | `backend_lead`, `db_architect`, `php_artisan`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `go_specialist` | `build/backend` | `backend_lead` | `go_sentinel`; `backend_pr_optimizer`; `api_unit_tester` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `go_sentinel` | `build/backend` | `backend_lead`; `go_specialist` | `backend_pr_securitizer`; `api_unit_tester` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `rust_evangelist` | `build/backend` | `backend_lead` | `rust_governor`; `backend_pr_optimizer`; `api_unit_tester` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `rust_governor` | `build/backend` | `backend_lead`; `rust_evangelist` | `backend_pr_securitizer`; `api_unit_tester` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `backend_pr_optimizer` | `build/backend` | `backend_lead`; language specialists | `backend_lead`; `integration_lead` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `backend_pr_securitizer` | `build/backend` | `backend_lead`; language specialists | `integration_lead`; `security_auditor` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner` |
| `api_unit_tester` | `build/backend` | `backend_lead`; implementers | `resilience_tester`; `integration_lead`; `contract_test_dev` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `resilience_tester`, `middleware_tuner` |
| `resilience_tester` | `build/backend` | `api_unit_tester`; `backend_lead` | `integration_lead`; `qa_engineer` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `middleware_tuner` |
| `middleware_tuner` | `build/backend` | `backend_lead`; `sre_engineer`; `system_architect` | `backend_lead`; `sre_engineer`; `infra_lead` | `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester` |
| `infra_lead` | `build/infra` | `cto`; `system_architect` | `sre_engineer`; `infra_pr_optimizer`; `infra_pr_hardener`; `iac_validator`; `devops_assistant` | `sre_engineer`, `infra_pr_optimizer`, `infra_pr_hardener`, `iac_validator`, `chaos_tester` |
| `sre_engineer` | `build/infra` | `infra_lead`; `cto` | `backend_lead`; `client_lead`; `middleware_tuner`; `chaos_tester` | `infra_lead`, `infra_pr_optimizer`, `infra_pr_hardener`, `iac_validator`, `chaos_tester` |
| `infra_pr_optimizer` | `build/infra` | `infra_lead`; IaC authors | `infra_lead`; `release_manager` | `infra_lead`, `sre_engineer`, `infra_pr_hardener`, `iac_validator`, `chaos_tester` |
| `infra_pr_hardener` | `build/infra` | `infra_lead`; IaC authors | `integration_lead`; `security_auditor` | `infra_lead`, `sre_engineer`, `infra_pr_optimizer`, `iac_validator`, `chaos_tester` |
| `iac_validator` | `build/infra` | `infra_lead` | `integration_lead`; `chaos_tester` | `infra_lead`, `sre_engineer`, `infra_pr_optimizer`, `infra_pr_hardener`, `chaos_tester` |
| `chaos_tester` | `build/infra` | `infra_lead`; `sre_engineer` | `integration_lead`; `release_manager` | `infra_lead`, `sre_engineer`, `infra_pr_optimizer`, `infra_pr_hardener`, `iac_validator` |
| `integration_lead` | `integration` | Pod leads (`client_lead`, `backend_lead`, `infra_lead`, …); `cto`; `project_manager` | `release_manager`; `qa_engineer`; `store_submission_gatekeeper`; `consistency_checker` | `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `consistency_checker` | `integration` | `integration_lead`; `api_interface_designer` | `integration_lead`; `contract_test_dev` | `integration_lead`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `contract_test_dev` | `integration` | `integration_lead`; `api_interface_designer` | `integration_lead`; `backend_lead`; `client_lead` | `integration_lead`, `consistency_checker`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `protocol_guardian` | `integration` | `integration_lead`; `security_design_specialist` | `integration_lead`; `release_manager` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `human_interface_auditor` | `integration` | `ui_ux_specialist`; `ux_researcher` | `store_submission_gatekeeper`; `client_lead`; `product_manager` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `store_submission_gatekeeper` | `integration` | `platform_policy_liaison`; `general_counsel`; `human_interface_auditor` | `release_manager`; `grc_officer` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `release_manager` | `integration` | `integration_lead`; `qa_engineer`; `security_auditor`; `grc_officer` | `devops_assistant`; `project_manager`; `customer_support` (comms) | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `qa_engineer` | `integration` | `integration_lead`; `client_test_dev`; `api_unit_tester`; `visual_regression_tester` | `release_manager`; `integration_lead` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `security_auditor` | `integration` | `security_design_specialist`; `backend_pr_securitizer`; `grc_officer` | `release_manager`; `grc_officer`; `security_intel_analyst` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead` |
| `grc_officer` | `integration` | `general_counsel`; `privacy_sovereign`; `legal_risk_simulator` | `release_manager`; `product_manager`; `ai_observability_lead` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `customer_success_analyst`, `ai_observability_lead` |
| `customer_success_analyst` | `integration` | `customer_support`; `error_monitoring` signals | `product_manager`; `planner`; `pmo_empathy` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `ai_observability_lead` |
| `ai_observability_lead` | `integration` | `cto`; `product_manager`; `integration_lead` | `pmo_logic`; `grc_officer`; `security_auditor` | `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst` |
| `devops_assistant` | `ops` | `release_manager`; `infra_lead` | All crews (CI/CD, pipelines); `sre_engineer` | `customer_support`, `technical_writer` |
| `customer_support` | `ops` | `technical_writer`; `knowledge_base`; user intake | `product_manager`; `planner`; `technical_writer` | `devops_assistant`, `technical_writer` |
| `technical_writer` | `ops` | All crews (artifacts) | All crews (docs); `compliance_wiki_editor` | `devops_assistant`, `customer_support` |

### product_manager

- **Pod / subgroup**: `management`
- **Typical upstream**: `project_manager`; executive / human sponsor as assigned; `customer_success_analyst` (feedback)
- **Typical downstream**: `planner`; `ux_researcher`; `cto`; `mobile_market_strategist`; `platform_policy_liaison`; `pmo_logic`; `pmo_empathy`; `general_counsel` (legal touchpoints)
- **Same-pod peers**: `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy`

### ux_researcher

- **Pod / subgroup**: `management`
- **Typical upstream**: `product_manager`; `planner`; `project_manager`
- **Typical downstream**: `ui_ux_specialist`; `ui_logic_architect`; `human_interface_auditor`; `planner`
- **Same-pod peers**: `product_manager`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy`

### mobile_market_strategist

- **Pod / subgroup**: `management`
- **Typical upstream**: `product_manager`; `planner`
- **Typical downstream**: `platform_policy_liaison`; `client_lead`; `store_submission_gatekeeper`; `ux_researcher`
- **Same-pod peers**: `product_manager`, `ux_researcher`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy`

### platform_policy_liaison

- **Pod / subgroup**: `management`
- **Typical upstream**: `product_manager`; `general_counsel`; `mobile_market_strategist`
- **Typical downstream**: `planner`; `store_submission_gatekeeper`; `client_lead`
- **Same-pod peers**: `product_manager`, `ux_researcher`, `mobile_market_strategist`, `planner`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy`

### planner

- **Pod / subgroup**: `management`
- **Typical upstream**: `product_manager`; `project_manager`; `ux_researcher`
- **Typical downstream**: `cto`; `system_architect`; `api_interface_designer`; `data_modeling_expert`; `client_lead`; `backend_lead`; `pmo_logic`
- **Same-pod peers**: `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `project_manager`, `cto`, `pmo_logic`, `pmo_empathy`

### project_manager

- **Pod / subgroup**: `management`
- **Typical upstream**: Executive / program intake; `{{upstream_inputs}}`
- **Typical downstream**: `product_manager`; `cto`; `pmo_logic`; `pmo_empathy`; `integration_lead`; `release_manager`; initiative-specific leads
- **Same-pod peers**: `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `cto`, `pmo_logic`, `pmo_empathy`

### cto

- **Pod / subgroup**: `management`
- **Typical upstream**: `product_manager`; `project_manager`; `pmo_logic`
- **Typical downstream**: `system_architect`; `backend_lead`; `client_lead`; `infra_lead`; `security_design_specialist`; `technical_spec_reviewer`
- **Same-pod peers**: `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `pmo_logic`, `pmo_empathy`

### pmo_logic

- **Pod / subgroup**: `management`
- **Typical upstream**: `project_manager`; `cto`
- **Typical downstream**: All initiative crews (oversight); `integration_lead`; `release_manager`; `planner`
- **Same-pod peers**: `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_empathy`

### pmo_empathy

- **Pod / subgroup**: `management`
- **Typical upstream**: `project_manager`; `pmo_logic`
- **Typical downstream**: All pods (coordination, comms); notification skills per policy (`team_notify_discord` / `team_notify_slack`)
- **Same-pod peers**: `product_manager`, `ux_researcher`, `mobile_market_strategist`, `platform_policy_liaison`, `planner`, `project_manager`, `cto`, `pmo_logic`

### general_counsel

- **Pod / subgroup**: `legal`
- **Typical upstream**: `product_manager`; `project_manager`; `cto`
- **Typical downstream**: `ip_trademark_specialist`; `contract_architect`; `privacy_sovereign`; `legal_risk_simulator`; build & release crews for compliance questions
- **Same-pod peers**: `ip_trademark_specialist`, `contract_architect`, `privacy_sovereign`, `legal_risk_simulator`

### ip_trademark_specialist

- **Pod / subgroup**: `legal`
- **Typical upstream**: `general_counsel`; `product_manager`
- **Typical downstream**: `contract_architect`; `store_submission_gatekeeper`; `technical_writer`
- **Same-pod peers**: `general_counsel`, `contract_architect`, `privacy_sovereign`, `legal_risk_simulator`

### contract_architect

- **Pod / subgroup**: `legal`
- **Typical upstream**: `general_counsel`; `planner`; `product_manager`
- **Typical downstream**: `backend_lead`; `client_lead`; `privacy_sovereign`; `grc_officer`; `store_submission_gatekeeper`
- **Same-pod peers**: `general_counsel`, `ip_trademark_specialist`, `privacy_sovereign`, `legal_risk_simulator`

### privacy_sovereign

- **Pod / subgroup**: `legal`
- **Typical upstream**: `general_counsel`; `contract_architect`; `data_modeling_expert`
- **Typical downstream**: `backend_lead`; `grc_officer`; `data_modeling_expert`; `security_design_specialist`
- **Same-pod peers**: `general_counsel`, `ip_trademark_specialist`, `contract_architect`, `legal_risk_simulator`

### legal_risk_simulator

- **Pod / subgroup**: `legal`
- **Typical upstream**: `general_counsel`; `security_auditor`
- **Typical downstream**: `general_counsel`; `product_manager`; `grc_officer`
- **Same-pod peers**: `general_counsel`, `ip_trademark_specialist`, `contract_architect`, `privacy_sovereign`

### tech_trend_scout

- **Pod / subgroup**: `intel`
- **Typical upstream**: `cto`; `system_architect`
- **Typical downstream**: `compliance_wiki_editor`; `system_architect`; `technical_writer`
- **Same-pod peers**: `security_intel_analyst`, `compliance_wiki_editor`, `incident_response_advisor`

### security_intel_analyst

- **Pod / subgroup**: `intel`
- **Typical upstream**: `security_auditor`; `cto`; `sre_engineer`
- **Typical downstream**: `compliance_wiki_editor`; `incident_response_advisor`; `security_design_specialist`
- **Same-pod peers**: `tech_trend_scout`, `compliance_wiki_editor`, `incident_response_advisor`

### compliance_wiki_editor

- **Pod / subgroup**: `intel`
- **Typical upstream**: `general_counsel`; `tech_trend_scout`; `security_intel_analyst`
- **Typical downstream**: All crews consuming wiki / standards; `technical_writer`
- **Same-pod peers**: `tech_trend_scout`, `security_intel_analyst`, `incident_response_advisor`

### incident_response_advisor

- **Pod / subgroup**: `intel`
- **Typical upstream**: `security_intel_analyst`; `sre_engineer`; `on-call` directives
- **Typical downstream**: `cto`; `infra_lead`; `security_auditor`; `project_manager`; affected leads
- **Same-pod peers**: `tech_trend_scout`, `security_intel_analyst`, `compliance_wiki_editor`

### system_architect

- **Pod / subgroup**: `design`
- **Typical upstream**: `cto`; `product_manager`; `planner`
- **Typical downstream**: `api_interface_designer`; `data_modeling_expert`; `ui_logic_architect`; `security_design_specialist`; `backend_lead`; `client_lead`; `infra_lead`
- **Same-pod peers**: `api_interface_designer`, `data_modeling_expert`, `ui_logic_architect`, `security_design_specialist`, `technical_spec_reviewer`

### api_interface_designer

- **Pod / subgroup**: `design`
- **Typical upstream**: `system_architect`; `planner`; `technical_spec_reviewer`
- **Typical downstream**: `backend_lead`; `client_lead`; `contract_test_dev`; `consistency_checker`; `middleware_tuner`
- **Same-pod peers**: `system_architect`, `data_modeling_expert`, `ui_logic_architect`, `security_design_specialist`, `technical_spec_reviewer`

### data_modeling_expert

- **Pod / subgroup**: `design`
- **Typical upstream**: `system_architect`; `planner`
- **Typical downstream**: `backend_lead`; `db_architect`; `api_interface_designer`
- **Same-pod peers**: `system_architect`, `api_interface_designer`, `ui_logic_architect`, `security_design_specialist`, `technical_spec_reviewer`

### ui_logic_architect

- **Pod / subgroup**: `design`
- **Typical upstream**: `ux_researcher`; `system_architect`; `planner`
- **Typical downstream**: `client_lead`; `ui_ux_specialist`; `human_interface_auditor`
- **Same-pod peers**: `system_architect`, `api_interface_designer`, `data_modeling_expert`, `security_design_specialist`, `technical_spec_reviewer`

### security_design_specialist

- **Pod / subgroup**: `design`
- **Typical upstream**: `system_architect`; `security_intel_analyst`
- **Typical downstream**: `backend_lead`; `client_lead`; `infra_lead`; `protocol_guardian`
- **Same-pod peers**: `system_architect`, `api_interface_designer`, `data_modeling_expert`, `ui_logic_architect`, `technical_spec_reviewer`

### technical_spec_reviewer

- **Pod / subgroup**: `design`
- **Typical upstream**: `system_architect`; all design pod outputs
- **Typical downstream**: `system_architect`; `cto`; `integration_lead`; design authors (return with findings)
- **Same-pod peers**: `system_architect`, `api_interface_designer`, `data_modeling_expert`, `ui_logic_architect`, `security_design_specialist`

### client_lead

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `ui_logic_architect`; `api_interface_designer`; `planner`
- **Typical downstream**: `js_ts_wizard`; `ui_ux_specialist`; `integration_lead`
- **Same-pod peers**: `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester`

### ui_ux_specialist

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `ux_researcher`; `ui_logic_architect`; `client_lead`
- **Typical downstream**: `client_lead`; `human_interface_auditor`; `visual_regression_tester`
- **Same-pod peers**: `client_lead`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester`

### js_ts_wizard

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `client_lead`; `api_interface_designer`
- **Typical downstream**: `js_ts_guardian`; `client_pr_optimizer`; `client_test_dev`
- **Same-pod peers**: `client_lead`, `ui_ux_specialist`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester`

### js_ts_guardian

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `client_lead`; `js_ts_wizard`
- **Typical downstream**: `client_pr_standardizer`; `client_test_dev`; `security_auditor` (on demand)
- **Same-pod peers**: `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester`

### client_pr_optimizer

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `client_lead`; `js_ts_wizard`; `js_ts_guardian`
- **Typical downstream**: `client_lead`; `integration_lead`; `release_manager`
- **Same-pod peers**: `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_standardizer`, `client_test_dev`, `visual_regression_tester`

### client_pr_standardizer

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `client_lead`; JS pod implementers
- **Typical downstream**: `integration_lead`; `release_manager`
- **Same-pod peers**: `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_test_dev`, `visual_regression_tester`

### client_test_dev

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `client_lead`; `js_ts_wizard`
- **Typical downstream**: `visual_regression_tester`; `integration_lead`; `qa_engineer`
- **Same-pod peers**: `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `visual_regression_tester`

### visual_regression_tester

- **Pod / subgroup**: `build/client`
- **Typical upstream**: `client_test_dev`; `ui_ux_specialist`
- **Typical downstream**: `integration_lead`; `qa_engineer`
- **Same-pod peers**: `client_lead`, `ui_ux_specialist`, `js_ts_wizard`, `js_ts_guardian`, `client_pr_optimizer`, `client_pr_standardizer`, `client_test_dev`

### backend_lead

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `api_interface_designer`; `system_architect`; `data_modeling_expert`
- **Typical downstream**: `php_artisan`; `php_hardener`; `go_specialist`; `go_sentinel`; `rust_evangelist`; `rust_governor`; `db_architect`; `middleware_tuner`
- **Same-pod peers**: `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### db_architect

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `data_modeling_expert`; `backend_lead`
- **Typical downstream**: `backend_lead`; `php_artisan`; `go_specialist`; `api_unit_tester`
- **Same-pod peers**: `backend_lead`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### php_artisan

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`
- **Typical downstream**: `php_hardener`; `backend_pr_optimizer`; `api_unit_tester`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### php_hardener

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`; `php_artisan`
- **Typical downstream**: `backend_pr_securitizer`; `api_unit_tester`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### go_specialist

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`
- **Typical downstream**: `go_sentinel`; `backend_pr_optimizer`; `api_unit_tester`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### go_sentinel

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`; `go_specialist`
- **Typical downstream**: `backend_pr_securitizer`; `api_unit_tester`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### rust_evangelist

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`
- **Typical downstream**: `rust_governor`; `backend_pr_optimizer`; `api_unit_tester`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### rust_governor

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`; `rust_evangelist`
- **Typical downstream**: `backend_pr_securitizer`; `api_unit_tester`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### backend_pr_optimizer

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`; language specialists
- **Typical downstream**: `backend_lead`; `integration_lead`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### backend_pr_securitizer

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`; language specialists
- **Typical downstream**: `integration_lead`; `security_auditor`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `api_unit_tester`, `resilience_tester`, `middleware_tuner`

### api_unit_tester

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`; implementers
- **Typical downstream**: `resilience_tester`; `integration_lead`; `contract_test_dev`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `resilience_tester`, `middleware_tuner`

### resilience_tester

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `api_unit_tester`; `backend_lead`
- **Typical downstream**: `integration_lead`; `qa_engineer`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `middleware_tuner`

### middleware_tuner

- **Pod / subgroup**: `build/backend`
- **Typical upstream**: `backend_lead`; `sre_engineer`; `system_architect`
- **Typical downstream**: `backend_lead`; `sre_engineer`; `infra_lead`
- **Same-pod peers**: `backend_lead`, `db_architect`, `php_artisan`, `php_hardener`, `go_specialist`, `go_sentinel`, `rust_evangelist`, `rust_governor`, `backend_pr_optimizer`, `backend_pr_securitizer`, `api_unit_tester`, `resilience_tester`

### infra_lead

- **Pod / subgroup**: `build/infra`
- **Typical upstream**: `cto`; `system_architect`
- **Typical downstream**: `sre_engineer`; `infra_pr_optimizer`; `infra_pr_hardener`; `iac_validator`; `devops_assistant`
- **Same-pod peers**: `sre_engineer`, `infra_pr_optimizer`, `infra_pr_hardener`, `iac_validator`, `chaos_tester`

### sre_engineer

- **Pod / subgroup**: `build/infra`
- **Typical upstream**: `infra_lead`; `cto`
- **Typical downstream**: `backend_lead`; `client_lead`; `middleware_tuner`; `chaos_tester`
- **Same-pod peers**: `infra_lead`, `infra_pr_optimizer`, `infra_pr_hardener`, `iac_validator`, `chaos_tester`

### infra_pr_optimizer

- **Pod / subgroup**: `build/infra`
- **Typical upstream**: `infra_lead`; IaC authors
- **Typical downstream**: `infra_lead`; `release_manager`
- **Same-pod peers**: `infra_lead`, `sre_engineer`, `infra_pr_hardener`, `iac_validator`, `chaos_tester`

### infra_pr_hardener

- **Pod / subgroup**: `build/infra`
- **Typical upstream**: `infra_lead`; IaC authors
- **Typical downstream**: `integration_lead`; `security_auditor`
- **Same-pod peers**: `infra_lead`, `sre_engineer`, `infra_pr_optimizer`, `iac_validator`, `chaos_tester`

### iac_validator

- **Pod / subgroup**: `build/infra`
- **Typical upstream**: `infra_lead`
- **Typical downstream**: `integration_lead`; `chaos_tester`
- **Same-pod peers**: `infra_lead`, `sre_engineer`, `infra_pr_optimizer`, `infra_pr_hardener`, `chaos_tester`

### chaos_tester

- **Pod / subgroup**: `build/infra`
- **Typical upstream**: `infra_lead`; `sre_engineer`
- **Typical downstream**: `integration_lead`; `release_manager`
- **Same-pod peers**: `infra_lead`, `sre_engineer`, `infra_pr_optimizer`, `infra_pr_hardener`, `iac_validator`

### integration_lead

- **Pod / subgroup**: `integration`
- **Typical upstream**: Pod leads (`client_lead`, `backend_lead`, `infra_lead`, …); `cto`; `project_manager`
- **Typical downstream**: `release_manager`; `qa_engineer`; `store_submission_gatekeeper`; `consistency_checker`
- **Same-pod peers**: `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### consistency_checker

- **Pod / subgroup**: `integration`
- **Typical upstream**: `integration_lead`; `api_interface_designer`
- **Typical downstream**: `integration_lead`; `contract_test_dev`
- **Same-pod peers**: `integration_lead`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### contract_test_dev

- **Pod / subgroup**: `integration`
- **Typical upstream**: `integration_lead`; `api_interface_designer`
- **Typical downstream**: `integration_lead`; `backend_lead`; `client_lead`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### protocol_guardian

- **Pod / subgroup**: `integration`
- **Typical upstream**: `integration_lead`; `security_design_specialist`
- **Typical downstream**: `integration_lead`; `release_manager`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### human_interface_auditor

- **Pod / subgroup**: `integration`
- **Typical upstream**: `ui_ux_specialist`; `ux_researcher`
- **Typical downstream**: `store_submission_gatekeeper`; `client_lead`; `product_manager`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### store_submission_gatekeeper

- **Pod / subgroup**: `integration`
- **Typical upstream**: `platform_policy_liaison`; `general_counsel`; `human_interface_auditor`
- **Typical downstream**: `release_manager`; `grc_officer`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### release_manager

- **Pod / subgroup**: `integration`
- **Typical upstream**: `integration_lead`; `qa_engineer`; `security_auditor`; `grc_officer`
- **Typical downstream**: `devops_assistant`; `project_manager`; `customer_support` (comms)
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### qa_engineer

- **Pod / subgroup**: `integration`
- **Typical upstream**: `integration_lead`; `client_test_dev`; `api_unit_tester`; `visual_regression_tester`
- **Typical downstream**: `release_manager`; `integration_lead`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `security_auditor`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### security_auditor

- **Pod / subgroup**: `integration`
- **Typical upstream**: `security_design_specialist`; `backend_pr_securitizer`; `grc_officer`
- **Typical downstream**: `release_manager`; `grc_officer`; `security_intel_analyst`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `grc_officer`, `customer_success_analyst`, `ai_observability_lead`

### grc_officer

- **Pod / subgroup**: `integration`
- **Typical upstream**: `general_counsel`; `privacy_sovereign`; `legal_risk_simulator`
- **Typical downstream**: `release_manager`; `product_manager`; `ai_observability_lead`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `customer_success_analyst`, `ai_observability_lead`

### customer_success_analyst

- **Pod / subgroup**: `integration`
- **Typical upstream**: `customer_support`; `error_monitoring` signals
- **Typical downstream**: `product_manager`; `planner`; `pmo_empathy`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `ai_observability_lead`

### ai_observability_lead

- **Pod / subgroup**: `integration`
- **Typical upstream**: `cto`; `product_manager`; `integration_lead`
- **Typical downstream**: `pmo_logic`; `grc_officer`; `security_auditor`
- **Same-pod peers**: `integration_lead`, `consistency_checker`, `contract_test_dev`, `protocol_guardian`, `human_interface_auditor`, `store_submission_gatekeeper`, `release_manager`, `qa_engineer`, `security_auditor`, `grc_officer`, `customer_success_analyst`

### devops_assistant

- **Pod / subgroup**: `ops`
- **Typical upstream**: `release_manager`; `infra_lead`
- **Typical downstream**: All crews (CI/CD, pipelines); `sre_engineer`
- **Same-pod peers**: `customer_support`, `technical_writer`

### customer_support

- **Pod / subgroup**: `ops`
- **Typical upstream**: `technical_writer`; `knowledge_base`; user intake
- **Typical downstream**: `product_manager`; `planner`; `technical_writer`
- **Same-pod peers**: `devops_assistant`, `technical_writer`

### technical_writer

- **Pod / subgroup**: `ops`
- **Typical upstream**: All crews (artifacts)
- **Typical downstream**: All crews (docs); `compliance_wiki_editor`
- **Same-pod peers**: `devops_assistant`, `customer_support`

