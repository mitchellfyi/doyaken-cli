# Phase 4: TEST (Quality Assurance)

You are testing the implementation for task {{TASK_ID}}.

## Testing Methodology

{{include:modules/testing.md}}

## Phase-Specific Instructions

1. **Run existing tests first** - All must pass before writing new tests
2. **Check implementation coverage** - Every new public function needs a test
3. **Run full quality suite** - lint, typecheck, tests all must pass

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Testing Complete

Tests written:
- `path/to/test_file` - N tests (unit)
- `path/to/other_test` - N tests (integration)

Coverage:
- [new/modified code]: X%

What's protected:
- [behaviour 1]
- [behaviour 2]

Quality gates:
- Lint: [pass/fail]
- Types: [pass/fail]
- Tests: [pass/fail] (X total, Y new)
```

## Rules

- **COMMIT tests as you write them** - don't wait until the end
- Do NOT add new features in this phase
- Fix bugs found during testing, but don't expand scope
- Every new public function needs a test
- Test file organization should mirror source file organization
- If a test is flaky, fix the root cause (don't add retries)

Task file: {{TASK_FILE}}
