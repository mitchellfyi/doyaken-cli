# Phase 4: TEST

You are testing the implementation for task **{{TASK_ID}}**.

## Context from Previous Phases

**Read the task file's Work Log first** for what EXPAND, TRIAGE, PLAN, and IMPLEMENT accomplished.

Files changed on this branch:
```
{{CHANGED_FILES}}
```

Commits for this task:
```
{{TASK_COMMITS}}
```

Use the changed files list to determine which tests are most relevant. Find the corresponding test files for modified source files (check the project's test directory structure and naming conventions). Run those first for fast feedback, then run the full suite as a regression check.

## Methodology

{{include:library/testing.md}}

## Phase Instructions

1. **Run relevant tests first** - Identify test files that correspond to the changed source files listed above. Run those specific tests first. If they pass, run the full test suite as a regression check. If the change is widespread or you can't determine the mapping, run the full suite immediately.
2. **Write new tests** - Cover new/modified public functions
3. **Run quality gates** - lint, typecheck, tests, build
4. **Validate CI compatibility** - Ensure tests will pass in CI

## CI Compatibility Checklist

- [ ] Scripts are executable (`chmod +x`)
- [ ] No macOS-specific commands (BSD sed, etc.)
- [ ] No hardcoded paths
- [ ] Tests don't require unavailable secrets
- [ ] No flaky tests (timing/order dependent)

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Testing Complete

Tests written:
- `path/to/test` - N tests (unit/integration)

Quality gates:
- Lint: [pass/fail]
- Types: [pass/fail]
- Tests: [pass/fail] (X total, Y new)
- Build: [pass/fail]

CI ready: [yes/no]
```

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

- **COMMIT tests as you write them**
- Do NOT add new features
- Fix bugs found, but don't expand scope
- Every new public function needs a test
- If a test is flaky, fix the root cause

Task file: {{TASK_FILE}}
