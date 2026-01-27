# Phase 4: TEST

You are testing the implementation for task **{{TASK_ID}}**.

## Methodology

{{include:library/testing.md}}

## Phase Instructions

1. **Run existing tests** - All must pass before writing new tests
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

## Rules

- **COMMIT tests as you write them**
- Do NOT add new features
- Fix bugs found, but don't expand scope
- Every new public function needs a test
- If a test is flaky, fix the root cause

Task file: {{TASK_FILE}}
