# Phase 1: TRIAGE

You are validating task **{{TASK_ID}}** before work begins.

## Phase Instructions

1. **Discover quality gates** - Check CI, lint/format/test/build commands
2. **Validate task file** - Context clear? Criteria testable? Scope defined?
3. **Check dependencies** - Are blockers resolved?
4. **Assess complexity** - Files affected, risk level, test coverage needed

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Triage Complete

Quality gates:
- Lint: [command or "missing"]
- Types: [command or "missing"]
- Tests: [command or "missing"]
- Build: [command or "missing"]

Task validation:
- Context: [clear/unclear]
- Criteria: [specific/vague]
- Dependencies: [none/satisfied/blocked by X]

Complexity:
- Files: [few/some/many]
- Risk: [low/medium/high]

Ready: [yes/no - reason]
```

If ready, update task metadata:
- Status: `doing`
- Started: `{{TIMESTAMP}}`
- Assigned To: `{{AGENT_ID}}`

## Rules

- Do NOT write code - only update the task file
- If task is not ready, explain why and STOP
- If blocked, report the blocker and do not proceed
- If quality gates are missing, flag as risk

Task file: {{TASK_FILE}}
