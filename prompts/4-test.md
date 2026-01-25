# Phase 4: TEST (Quality Assurance)

You are testing the implementation for task {{TASK_ID}}.

## Your Responsibilities

1. **Run Existing Tests**
   - Run the project's test suite
   - All tests MUST pass before proceeding
   - Fix any failing tests from the implementation

2. **Add Missing Test Coverage**
   - Check the Test Plan from Phase 2
   - Write tests for each new feature/change
   - Cover edge cases and error conditions

3. **Test Categories to Consider**
   - Unit tests for functions/methods
   - Integration tests for workflows
   - Edge cases: nil values, empty collections, invalid input

4. **Run Full Quality Suite**
   - Run linters, formatters, type checkers
   - Must pass all quality gates
   - Fix any issues found

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Testing Complete

Tests written:
- path/to/test_file.py - N tests
- path/to/other_test.js - N tests

Test results:
- Total: X tests, Y failures
- Coverage: Z%

Quality gates:
- Linter: [pass/fail]
- Formatter: [pass/fail]
- Tests: [pass/fail]
```

## Rules

- **COMMIT tests as you write them** - don't wait until the end
- Do NOT add new features in this phase
- Fix bugs found during testing, but don't expand scope
- Every new public function needs a test
- Test file organization should mirror source file organization
- Commit message format: `Add tests for X [{{TASK_ID}}]`

Task file: {{TASK_FILE}}
