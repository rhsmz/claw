# Crew workspace (`crew/<agent_id>/`)

- **`agent_id`** matches `name` in `zeroclaw/config.toml` for each crew unless operations assigns a different folder key (record the mapping in the first real work log if they differ).
- **Deliverable boundary**: This repository does **not** commit per-agent `TASKS_*.MD` or `work_logs/*.md`. Those files are **created and owned by each crew** when they run the common workflow (`prompts/common/workflow_contract.md`, parent `TASKS.MD` §4).
- **Templates only**: Use `crew/_template/` to copy formats when starting a task; create `crew/<agent_id>/` on first use if it does not exist yet.
