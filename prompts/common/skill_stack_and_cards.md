# Skill stack & skill cards (additive specification)

## Skill stack (Mandatory Prompt Stack)

Order is defined in `prompts/base_instruction.md`. When listing **Required Read Order** in a crew prompt, use this sequence without inversion:

1. `prompts/base_instruction.md`  
2. `prompts/common/workflow_contract.md`  
3. `prompts/common/output_contract.md`  
4. `prompts/common/collaboration_contract.md`  
5. `prompts/sections/<section>.md` (one section file for the crew’s org unit)  
6. Every `prompts/skills/<id>.md` for each `id` in `zeroclaw/config.toml` → `[[crews]]` → `skills = [...]` for this crew  
7. Runtime loads the crew prompt file itself (do not duplicate the crew path inside Required Read Order)

## Skill cards

- One file per skill: `prompts/skills/<id>.md` where `<id>` equals `[[skills]].name` in `zeroclaw/config.toml`.
- Each card should state: purpose, inputs/preconditions, procedure, expected artifacts, verification, and MCP/tool boundary (which server or tool family implements the skill).

## Skill activation

Crew prompts include **Skill Activation Notes**: use only needed skills, minimize calls, and record which skill influenced the output (for work logs).

## Index

Skill files live under `prompts/skills/`. Section files under `prompts/sections/`. Maintain consistency when adding new `[[skills]]` entries.
