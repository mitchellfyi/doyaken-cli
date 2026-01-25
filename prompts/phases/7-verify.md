# Phase 7: VERIFY (Task Management Validation)

You are verifying that task {{TASK_ID}} was managed correctly through all phases.

## Code Quality Standards

{{include:library/code-quality.md}}

## Purpose

This phase ensures:
1. The task is actually complete (not just "mostly done")
2. All work is properly documented
3. Task management is consistent
4. Changes are committed and tracked

## 1) Validate Acceptance Criteria

**CRITICAL**: Go through EACH acceptance criterion and verify:

| Criterion | Status | Evidence |
|-----------|--------|----------|
| [criterion 1] | [x] / [ ] | [how verified] |
| [criterion 2] | [x] / [ ] | [how verified] |

- ALL criteria must be checked `[x]` for task to be complete
- If any criterion is not met, task is NOT complete
- "Mostly done" is not done

## 2) Verify Work Log Completeness

Check that each phase logged its work:

- [ ] EXPAND: Task specification documented
- [ ] TRIAGE: Quality gates identified, dependencies checked
- [ ] PLAN: Gap analysis, implementation steps documented
- [ ] IMPLEMENT: Progress logged, commits referenced
- [ ] TEST: Test results, coverage documented
- [ ] DOCS: Documentation changes noted
- [ ] REVIEW: Findings ledger, review passes documented

## 3) Validate Plan Execution

Compare the Plan section to actual changes:

- Were all planned files created/modified?
- Were any unplanned changes made? (should be documented)
- Were all planned tests written?

## 4) Run Final Quality Check

```bash
# Run all quality gates one more time
npm run lint          # Lint check
npm run typecheck     # Type check
npm run test          # Tests
npm run build         # Build
npm audit --audit-level=high  # Security audit
```

**All must pass. If any fail, task is NOT complete.**

Quality checklist:
- [ ] Lint passes with no errors
- [ ] Type checking passes
- [ ] All tests pass
- [ ] Build succeeds
- [ ] No high/critical security vulnerabilities
- [ ] No debug code (console.log, debugger, etc.)
- [ ] No commented-out code
- [ ] Code follows KISS, YAGNI, DRY, SOLID principles

## 5) Finalize Task State

**If ALL criteria are met:**
- Set Status to `done`
- Set Completed timestamp
- Clear Assigned To and Assigned At
- Move task file to `.doyaken/tasks/4.done/`

**If NOT all criteria are met:**
- Keep task in `.doyaken/tasks/3.doing/`
- Document what remains in Work Log
- Create follow-up task if needed
- Be explicit about what's incomplete

## 6) Commit Task Files

After finalizing:

```bash
# Regenerate taskboard
doyaken tasks

# Stage and commit task files
git add .doyaken/tasks/ TASKBOARD.md
git commit -m "chore: Complete task {{TASK_ID}} [{{TASK_ID}}]" || true
```

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Verification Complete

Acceptance criteria:
| Criterion | Status | Evidence |
|-----------|--------|----------|
| [criterion 1] | [x] | [evidence] |
| [criterion 2] | [x] | [evidence] |

Work log completeness:
- Phases documented: [X/7]
- Missing: [list or "none"]

Plan execution:
- Planned files modified: [X/Y]
- Unplanned changes: [list or "none"]

Final quality check:
- Lint: [pass/fail]
- Types: [pass/fail]
- Tests: [pass/fail]
- Build: [pass/fail]
- Security audit: [pass/fail]
- Debug code removed: [yes/no]
- Follows quality principles: [yes/no]

Task state:
- Location: [3.doing/ → 4.done/ | kept in 3.doing/]
- Reason: [complete | incomplete - what remains]

Commits:
- Task files committed: [yes/no]

Verification: [PASS/FAIL]
```

## Rules

- Do NOT write any code
- Do NOT modify source files
- ONLY verify and update task file state
- Be strict: incomplete tasks should NOT be in 4.done/
- If verification fails, do not mark task as complete
- **ALWAYS commit task file changes at the end**
- "Almost done" is not done - be honest

Task file: {{TASK_FILE}}
