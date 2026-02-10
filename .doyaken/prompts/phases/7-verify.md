# Phase 7: VERIFY

You are verifying task **{{TASK_ID}}** is complete and CI passes.

## Methodology

{{include:library/ci.md}}

## Phase Instructions

1. **Validate acceptance criteria** - Each criterion verified with evidence
2. **Verify work log** - All phases documented
3. **Run final quality check** - All gates must pass
4. **Push and verify CI** - Task is NOT complete until CI passes
5. **Finalize task state** - Move to done only if everything passes

## Acceptance Criteria Check

Go through EACH criterion:

| Criterion | Status | Evidence |
|-----------|--------|----------|
| [criterion] | [x]/[ ] | [how verified] |

**ALL criteria must be [x] for task to be complete.**

## CI Verification

```bash
# Push and watch CI
git push && gh run watch

# If CI fails - get details and fix
gh run view --log-failed
```

**Do NOT mark complete if CI fails.** Fix and iterate until green.

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Verification Complete

Criteria: [all met / X of Y met]
Quality gates: [all pass / failures]
CI: [pass/fail - run link]

Task location: [3.doing → 4.done / kept in 3.doing]
Reason: [complete / incomplete - what remains]
```

If complete:
- Status: `done`
- Completed: `{{TIMESTAMP}}`
- Clear Assigned To/At
- Move to `.doyaken/tasks/4.done/`
- Commit: `chore: Complete task {{TASK_ID}}`

## Completion Signal

When you are done with this phase, include a structured status block in your output:

```
DOYAKEN_STATUS:
  PHASE_COMPLETE: true/false
  FILES_MODIFIED: <count>
  TESTS_STATUS: pass/fail/skip/unknown
  CONFIDENCE: high/medium/low
  REMAINING_WORK: <brief description or "none">
```

## Rules

- **CI passing is a hard requirement**
- Do NOT mark complete if CI fails
- "Almost done" is not done - be honest
- Incomplete tasks stay in `3.doing/`

Task file: {{TASK_FILE}}
