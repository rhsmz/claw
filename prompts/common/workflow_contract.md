# Workflow Contract

## Phase gates (mandatory)

Use phase gates strictly: **Intake → Plan → Execute → Validate → Handoff → Close**.

Each phase must emit at least one auditable output (summary line, artifact path, or structured field).

- **DoR/DoD**: Advance only when the current phase’s minimum outputs exist. If not met, return to the previous phase and list missing items.
- **Plan includes supervisor review & approval wait**: Plan is not complete until the local task plan file exists **and** a **supervisor review** has completed with **approved** recorded (see *Supervisor review & approval gate* below). **Execute** (including substantive tool use toward delivery) starts only after that gate.

---

## Crew execution artifacts & supervisor approval

Applies to **every** crew agent. Details align with the parent program `TASKS.MD` §4.

### Repository vs runtime (important)

**`TASKS_<UTC>_<task>.MD` and `work_logs/*.md` under `crew/<agent_id>/` are not part of the prompt-pack deliverable.** The repository may ship only **templates** (e.g. `crew/_template/`). Each crew **creates** its own task plan and work logs when executing work, following this contract. Do not expect pre-filled personal files in git for every agent.

### Agent identity & paths

- **`agent_id`**: Use `{{agent_id}}` from runtime context. **Canonical folder key** matches `name` in `zeroclaw/config.toml` for this crew unless operations defines a separate numeric id; if both exist, record the mapping once in work logs.
- **Supervisor**: Use `{{supervisor_agent_or_human}}` (human owner or designated approver crew, e.g. `project_manager` / `pmo_logic`). Runtime must inject the correct value.

### Local task plan (before Execute)

During **Plan**, create:

`crew/<agent_id>/TASKS_<timestamp_utc>_<task_name>.MD`

Use UTC timestamp in the filename (recommended: `YYYYMMDDThhmmssZ`). The document **must** include these headings (English):

1. Purpose  
2. Inputs  
3. Sub-tasks (nested as needed)  
4. Deliverables  
5. Deadline  
6. Dependencies  
7. Supervisor report & approval (see *Supervisor review & approval gate* for required fields)  
8. Progress history (timestamp, percent complete, blockers)  
9. Definition of Done  

### Supervisor review & approval gate (mandatory sequence)

1. **Draft** the local task plan with sections 1–6 and 9 complete enough for review (9 may list draft DoD until refined after feedback).  
2. **Submit for supervisor review**: explicitly hand the plan to `{{supervisor_agent_or_human}}` (per operations: message, ticket, or runtime handoff). Status in section 7 remains `pending` until the review finishes.  
3. **Supervisor reviews** scope, risks, dependencies, DoD, and alignment with intake; they record an outcome in section 7.  
4. **Record in section 7** (no fabrication):  
   - **Submitted for review at** (UTC)  
   - **Reviewer / approver** (identity)  
   - **Review outcome**: one of `pending` | `approved` | `rejected` | `changes_requested`  
   - If `approved`: **Approved at** (UTC) and any **conditions**  
   - If `rejected` or `changes_requested`: **Reviewer notes** and what must change  
5. **If not `approved`**: revise the plan, append a new review cycle in section 7 (or clearly dated sub-bullets), and **re-submit** until outcome is `approved`.  
6. **Execute** (substantive work toward deliverables, including tool-backed implementation) starts **only** when section 7 shows **`approved`** with approver identity and **Approved at** timestamp.

**Allowed before `approved`**: Intake, reading repo/docs for planning, clarifying questions, and editing the local `TASKS_*.MD` / work-log entries that support the review.  

**Forbidden before `approved`**: substantive delivery work (code changes, bulk edits, production-impacting actions, or other tool use whose primary purpose is to produce the task outcome). If unsure, treat the action as Execute and wait for approval.

**Do not** enter **Execute** until step 6 is satisfied.

### Progress updates

Update the local task plan file at least **three** times: at start, mid-point, and completion (or when material blockers appear).

### Work logs

Under `crew/<agent_id>/work_logs/`, append a log per session or day:

`YYYYMMDDThhmmssZ_<task_name>_worklog.md` (UTC)

Each work log **must** include:

- Timestamp (match filename) / owner  
- What was done  
- Rationale for decisions  
- Issues encountered  
- Next actions  
- Evidence links (paths to the local `TASKS_*.MD`, PRs, artifacts)  
- Discussion log (topics raised, participants, conclusions, open points)

Close daily work with an end-of-session entry when applicable.

### Discussions

When clarification or sign-off is needed, run the discussion, then record outcomes under **Discussion log** in the work log and link from the task plan progress section.

---

## Intake → Plan → Execute → Validate → Handoff → Close (minimum outputs)

| Phase | Minimum output |
|-------|------------------|
| Intake | `task_id`, acceptance criteria, constraints |
| Plan | Local `TASKS_<UTC>_<task>.MD` drafted; **submitted for supervisor review**; section 7 shows **`approved`** with approver + UTC timestamp |
| Execute | Traceable steps; tool use only per policy; evidence captured |
| Validate | Checklist result + links to evidence |
| Handoff | Summary, unresolved items, risks/mitigations, next owner’s first action |
| Close | Work log updated; task plan marked complete |

---

## Escalation

On blockers, dependency delay, or policy change: escalate via the path defined by operations, document in work log, and do not bypass the **supervisor review → approved** gate for materially scoped work. Never self-approve or mark `approved` without the designated supervisor’s review.
