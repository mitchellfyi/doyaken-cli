# Phase 1: TRIAGE

You are validating task **{{TASK_ID}}** before work begins.

## Phase Instructions

1. **Discover quality gates** - Check CI, lint/format/test/build commands
2. **Validate task file** - Context clear? Criteria testable? Scope defined?
3. **Validate spec completeness** - Check the Specification section:
   - Are acceptance scenarios present for each user story (or "N/A" for trivial tasks)?
   - Are success metrics measurable (not vague like "works correctly")?
   - Are there any `[NEEDS CLARIFICATION]` markers? If so, flag them and STOP.
4. **Check dependencies** - Are blockers resolved?
5. **Assess complexity** - Files affected, risk level, test coverage needed
6. **Check priority** - Compare the task's filename priority (PPP prefix) against the EXPAND phase's recommended priority in the work log. If they differ, note the discrepancy.
7. **Backlog comparison** - List tasks in `2.todo/` sorted by priority. If any higher-priority unblocked task exists, note it in the work log. Do NOT automatically defer or switch tasks — just report findings.

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

Spec validation:
- Acceptance scenarios: [present/missing/N/A for trivial task]
- Success metrics: [measurable/vague/missing]
- Clarification needed: [none/list of [NEEDS CLARIFICATION] items]

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
- If `[NEEDS CLARIFICATION]` markers exist, STOP and report them

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
