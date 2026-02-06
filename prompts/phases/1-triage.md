# Phase 1: TRIAGE

You are validating task **{{TASK_ID}}** before work begins.

## Phase Instructions

1. **Clarify scope** - Can you state the goal in one sentence? What's OUT of scope?
2. **Validate assumptions** - List what you're assuming. Verify key assumptions before proceeding.
3. **Discover quality gates** - Check CI, lint/format/test/build commands
4. **Validate task file** - Context clear? Criteria testable? Scope defined?
5. **Check dependencies** - Are blockers resolved?
6. **Assess complexity** - Files affected, risk level, test coverage needed

## Scope Clarification

Before proceeding, verify you can answer:

- **What are we building?** → [One sentence goal]
- **What's the definition of done?** → [Verifiable criteria from task]
- **What's explicitly OUT of scope?** → [Things we're NOT doing]

If any of these are unclear, note the ambiguity. Vague scope leads to wasted work.

## Assumption Validation

List key assumptions about this task:

| Assumption | How to Verify | Status |
|------------|---------------|--------|
| [e.g., "API endpoint exists"] | grep/read code | ✓ Verified / ✗ Wrong |
| [e.g., "Config supports X"] | check config | ✓ Verified / ✗ Wrong |

**STOP if a key assumption is wrong.** Don't build on false foundations.

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Triage Complete

Scope:
- Goal: [one sentence]
- Done when: [verifiable criteria]
- Out of scope: [explicit exclusions]

Assumptions validated:
- [assumption]: [verified/wrong]

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
- Do NOT proceed with vague scope - clarify first
- Do NOT build on unverified assumptions - check them
- If task is not ready, explain why and STOP
- If blocked, report the blocker and do not proceed
- If quality gates are missing, flag as risk

Task file: {{TASK_FILE}}
