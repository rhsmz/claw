"""Patch crew prompts under prompts/*.md: MC vars, LP block, JSON extras, team_notify path."""
from __future__ import annotations

import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1] / "prompts"
SKIP = {"base_instruction.md"}

MC = """- Agent ID (folder key): {{agent_id}}
- Supervisor (Plan → Execute approver): {{supervisor_agent_or_human}}
"""

LP = """

## 7b) Local plan, work logs & supervisor approval (all crews)
- Follow `prompts/common/workflow_contract.md` — *Crew execution artifacts & supervisor approval*.
- During **Plan**: create `crew/<agent_id>/TASKS_<timestamp_utc>_<task_name>.MD` with all required headings; obtain **recorded approval** from `{{supervisor_agent_or_human}}` before **Execute**.
- **Progress**: update that task plan at least three times (start, mid-point, completion or major blocker).
- **Work logs**: under `crew/<agent_id>/work_logs/`, use UTC filenames `YYYYMMDDThhmmssZ_<task>_worklog.md` and include required sections (including discussion log).
- **Gate**: do not begin substantive tool-backed execution until approval is recorded in the task plan.
"""

JSON_TAIL = (
    '"first_step": "string"\n  }\n}'
)
JSON_TAIL_NEW = (
    '"first_step": "string"\n  },\n'
    '  "open_questions": [],\n'
    '  "citations": [],\n'
    '  "self_check": {\n'
    '    "schema_valid": true,\n'
    '    "policy_compliant": true,\n'
    '    "assumptions_listed": true\n'
    '  }\n}'
)


def main() -> None:
    for path in sorted(ROOT.glob("*.md")):
        if path.name in SKIP:
            continue
        text = path.read_text(encoding="utf-8")
        if "# [SYSTEM] Crew Prompt:" not in text:
            continue
        original = text
        text = text.replace(
            "prompts/skills/team_notify.md", "prompts/skills/team_notify_discord.md"
        )
        if "{{agent_id}}" not in text:
            text = text.replace("## 2) Mission Context\n", f"## 2) Mission Context\n{MC}\n", 1)
        if "7b) Local plan" not in text:
            text = text.replace("## 8) Output Contract", f"{LP}\n## 8) Output Contract", 1)
        if '"open_questions"' not in text and JSON_TAIL in text:
            text = text.replace(JSON_TAIL, JSON_TAIL_NEW, 1)
        if text != original:
            path.write_text(text, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
