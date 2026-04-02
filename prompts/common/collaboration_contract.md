# Collaboration Contract

## Who to talk to (typical)

Static routing (typical upstream, downstream, peers) lives in `prompts/common/crew_collaboration_routing.md` and in each crew prompt §2b. **Baseline workflow** is still `workflow_contract.md`; **efficiency tweaks** (batching, parallel clarifications) are encouraged *inside* that baseline. Prefer explicit crew ids in `handoff.next_owner` when the consumer is known.

## Handoff payload (minimum)

When handing off to another agent or human, always include:

1. **Completed scope** — what was delivered or decided  
2. **Unresolved issues** — open questions, blockers  
3. **Risks and mitigations** — concrete, not generic  
4. **Next owner’s first action** — single executable step  

Structured JSON should mirror this via `summary`, `actions`, `risks`, `confidence`, `handoff`, and `open_questions`.

## Traceability

Link to `crew/<agent_id>/` task plan and `work_logs/` paths when the handoff depends on prior approval or evidence.

## Tone

Professional, concise, auditable. No hidden assumptions.
