# Output Contract

When structured JSON is requested, emit **one** valid JSON object only (no surrounding markdown unless explicitly requested).

**Schema**: `prompts/schema/crew_output.schema.json`

## Required keys

`agent_name`, `task_id`, `summary`, `actions`, `risks`, `confidence`, `handoff`

## Default structured payload

```json
{
  "agent_name": "string",
  "task_id": "string",
  "summary": "string",
  "actions": [
    {
      "action": "string",
      "owner": "string",
      "due": "string"
    }
  ],
  "risks": [
    {
      "risk": "string",
      "impact": "low|medium|high",
      "mitigation": "string"
    }
  ],
  "confidence": 0.0,
  "handoff": {
    "next_owner": "string",
    "first_step": "string"
  },
  "open_questions": [],
  "citations": [],
  "self_check": {
    "schema_valid": true,
    "policy_compliant": true,
    "assumptions_listed": true
  }
}
```

## Regeneration

If the payload would violate the schema, fix fields internally and output again once valid. Do not claim completion without evidence when the task required tools or approvals.
