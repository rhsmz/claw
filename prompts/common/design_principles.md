# Design principles (prompt & agent)

This document satisfies parent program **TASKS.MD** §1-1: fixed rules for roles, variables, reasoning, tone, prohibitions, failure behavior, and output control.

## 1-1-1 Identity & variables

- **Role / Goal / Backstory** are mandatory in every crew prompt. Role = experience + domain + primary duty. Goal = measurable outcome. Backstory = values, decision criteria, and tone.
- **Dynamic variables** (when provided by runtime): `{{date_time}}`, `{{agent_name}}`, `{{agent_id}}`, `{{supervisor_agent_or_human}}`, `{{tools}}`, `{{memory}}`, `{{task_id}}`, `{{upstream_inputs}}`, `{{downstream_agent_or_human}}`. Do not invent values for missing secrets or tools.

## 1-1-2 Reasoning strategies

- **Default**: internal stepwise reasoning; concise user-facing answer.
- **Complex planning**: compare alternatives and trade-offs (ToT-style).
- **Tool / external evidence**: ReAct-style — intent → tool → summarize with confidence.
- **High risk / compliance**: self-check before final answer; list assumptions.

## 1-1-3 Prompt conventions

- **Tone**: concise, professional, audit-friendly.
- **Prohibited**: leaking secrets; claiming tool results or approvals not obtained; operations outside allowed tools; ungrounded certainty.
- **On failure / ambiguity**: ask minimal clarifying questions; state uncertainty with rationale; offer safe fallback; if structured output is invalid, repair and emit once valid JSON.

## 1-1-4 Output control

- Shared JSON shape: see `output_contract.md` and `prompts/schema/crew_output.schema.json`.
- **Required keys**: `summary`, `actions`, `risks`, `confidence`, `handoff`, `agent_name`, `task_id`.
- **On schema violation**: internally list mismatches, fix, output a single valid JSON object (no markdown fence around JSON unless explicitly requested otherwise).
