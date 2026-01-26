# Phase 7: VERIFY (Task Management & CI Validation)

You are verifying that task {{TASK_ID}} was managed correctly and CI passes.

## Code Quality Standards

{{include:library/code-quality.md}}

## CI/CD Best Practices

{{include:library/ci-workflow.md}}

## Purpose

This phase ensures:
1. The task is actually complete (not just "mostly done")
2. All work is properly documented
3. Task management is consistent
4. Changes are committed and tracked
5. **CI passes on the pushed changes**

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

## 5) Push Changes and Verify CI

**CRITICAL: A task is NOT complete until CI passes.**

### 5a) Push Changes

```bash
# Ensure all changes are committed
git status

# Push to remote
git push
```

### 5b) Monitor CI Status

```bash
# Watch the CI run
gh run watch

# Or check status
gh run list --limit 1
```

### 5c) If CI Fails - Fix It

**Do NOT mark the task complete if CI fails.**

1. **Get failure details:**
   ```bash
   gh run view --log-failed
   ```

2. **Identify the failure type:**
   - Syntax error?
   - Missing dependency in CI?
   - Environment difference (Linux vs macOS)?
   - Test failure?
   - Permission issue?

3. **Fix the issue:**
   - Make the necessary changes
   - Commit with message: `fix(ci): [description]`
   - Push and watch CI again

4. **Iterate until CI is green:**
   ```bash
   git push && gh run watch
   ```

**Common CI fixes:**
- Add `chmod +x` for scripts in workflow
- Use portable bash commands (not macOS-specific)
- Add missing tool installation steps
- Fix case-sensitivity issues (Linux is case-sensitive)
- Add proper error handling

### 5d) CI Verification Checklist

- [ ] Changes pushed to remote
- [ ] CI workflow triggered
- [ ] All CI jobs pass:
  - [ ] Lint job
  - [ ] Test job (all matrix combinations)
  - [ ] Build job
  - [ ] Any deployment jobs

**If CI doesn't pass, go back to step 5c. Do not proceed.**

## 6) Finalize Task State

**Only if ALL criteria are met AND CI passes:**
- Set Status to `done`
- Set Completed timestamp
- Clear Assigned To and Assigned At
- Move task file to `.doyaken/tasks/4.done/`

**If NOT all criteria are met OR CI fails:**
- Keep task in `.doyaken/tasks/3.doing/`
- Document what remains in Work Log
- Create follow-up task if needed
- Be explicit about what's incomplete

## 7) Commit Task Files

After finalizing:

```bash
# Regenerate taskboard
doyaken tasks

# Stage and commit task files
git add .doyaken/tasks/ TASKBOARD.md
git commit -m "chore: Complete task {{TASK_ID}} [{{TASK_ID}}]" || true

# Push and verify CI one more time
git push
gh run watch
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

CI Verification:
- Push: [done]
- CI Run: [link to run or run ID]
- CI Status: [pass/fail]
- CI Jobs:
  - lint: [pass/fail]
  - test (ubuntu): [pass/fail]
  - test (macos): [pass/fail]
  - build: [pass/fail]
- CI Fixes Applied: [count or "none needed"]

Task state:
- Location: [3.doing/ → 4.done/ | kept in 3.doing/]
- Reason: [complete | incomplete - what remains]

Commits:
- Task files committed: [yes/no]
- Final push verified: [yes/no]

Verification: [PASS/FAIL]
```

## Rules

- Do NOT mark task complete if CI fails
- Fix CI failures before completing
- Be strict: incomplete tasks should NOT be in 4.done/
- If CI cannot be fixed quickly, document blockers and keep in 3.doing/
- "Almost done" is not done - be honest
- **CI passing is a hard requirement for completion**

Task file: {{TASK_FILE}}
