# Phase 1: TRIAGE

You are validating task **{{TASK_ID}}** before work begins.

## Phase Instructions

1. **Discover quality gates** - Check CI, lint/format/test/build commands
2. **Validate task file** - Context clear? Criteria testable? Scope defined?
3. **Check dependencies** - Are blockers resolved?
4. **Assess complexity** - Files affected, risk level, test coverage needed
5. **Check priority** - Compare the task's filename priority (PPP prefix) against the EXPAND phase's recommended priority in the work log. If they differ, note the discrepancy.
6. **Backlog comparison** - List tasks in `2.todo/` sorted by priority. If any higher-priority unblocked task exists, note it in the work log. Do NOT automatically defer or switch tasks — just report findings.

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

Backlog check:
- [list of todo tasks by priority, or "no tasks in todo"]
- [note if higher-priority unblocked tasks exist]

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
