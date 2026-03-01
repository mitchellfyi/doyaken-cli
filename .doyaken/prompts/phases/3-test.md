# Phase 3: TEST

You are testing and documenting the implementation for task **{{TASK_ID}}**.

## Context from Previous Phases

**Read the task file's Work Log** for what Phase 1 (Plan) and Phase 2 (Implement) accomplished.

Files changed on this branch:
```
{{CHANGED_FILES}}
```

Commits for this task:
```
{{TASK_COMMITS}}
```

Use the changed files list to determine which tests are most relevant. Find the corresponding test files for modified source files. Run those first for fast feedback, then run the full suite as a regression check.

## Methodology

{{include:library/testing.md}}

{{include:library/docs.md}}

## Phase Instructions

1. **Run relevant tests first** — Identify test files for changed source files. Run them first. If they pass, run the full suite. If the change is widespread, run the full suite immediately.
2. **Write new tests** — Cover new/modified public functions. Tests must cover happy path, edge cases, and error cases.
3. **Update documentation** — API docs, README, inline comments. Priority: API → README → Architecture → Inline. Ensure code and docs tell the same story.
4. **Run quality gates** — lint, format, typecheck, tests, build
5. **Validate CI compatibility** — Scripts executable, no macOS-specific commands, no hardcoded paths, no flaky tests

## CI Compatibility Checklist

- [ ] Scripts are executable (`chmod +x`)
- [ ] No macOS-specific commands (BSD sed, etc.)
- [ ] No hardcoded paths
- [ ] Tests don't require unavailable secrets
- [ ] No flaky tests (timing/order dependent)

## What to Document

| Change Type | Documentation Needed |
|-------------|---------------------|
| New API endpoint | API docs, possibly README |
| New feature | README if user-facing |
| Changed behaviour | Update existing docs |
| Complex logic | Inline code comments |

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Testing and Docs Complete

Tests written:
- `path/to/test` - N tests (unit/integration)

Docs updated:
- `path/to/doc` - [change]

Quality gates:
- Lint: [pass/fail]
- Format: [pass/fail]
- Tests: [pass/fail] (X total, Y new)
- Build: [pass/fail]

CI ready: [yes/no]
```

## Completion Signal

When you are done, include:

```
DOYAKEN_STATUS:
  PHASE_COMPLETE: true/false
  FILES_MODIFIED: <count>
  TESTS_STATUS: pass/fail/skip/unknown
  CONFIDENCE: high/medium/low
  REMAINING_WORK: <brief description or "none">
```

## Rules

- **COMMIT tests and docs as you write them**
- Do NOT add new features
- Fix bugs found, but don't expand scope
- Every new public function needs a test
- If a test is flaky, fix the root cause
- Do NOT change functionality — only tests and docs

{{VERIFICATION_CONTEXT}}

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
