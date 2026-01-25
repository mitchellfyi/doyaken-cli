# Phase 4: TEST (Quality Assurance)

You are testing the implementation for task {{TASK_ID}}.

## Principles

- **Test behaviour, not implementation** - Tests should survive refactoring
- **One assertion per concept** - Each test proves one thing clearly
- **Fast and deterministic** - No flaky tests, no slow I/O in unit tests
- **Readable as documentation** - Test names describe the behaviour

## 1) Run Existing Tests First

Before writing new tests:

```bash
npm test  # or equivalent
```

- All existing tests MUST pass
- If any fail, fix them before proceeding
- This confirms implementation didn't break anything

## 2) Test Pyramid Placement

Choose the right level of test:

| Level | Speed | Scope | Use when |
|-------|-------|-------|----------|
| **Unit** | Fast (ms) | Single function/class | Pure logic, algorithms, transformations |
| **Integration** | Medium (s) | Multiple units + deps | Database, API calls, component interactions |
| **E2E** | Slow (10s+) | Full system | Critical user journeys only |

**Default to unit tests.** Move up only when lower levels can't catch the bug.

## 3) What to Test

**Always test:**
- Happy path (normal inputs → expected outputs)
- Edge cases (empty, null, boundary values, max/min)
- Error cases (invalid input, failures, exceptions)
- State transitions (if stateful)

**Skip testing:**
- Framework code / library internals
- Simple getters/setters with no logic
- Private methods (test through public interface)

## 4) Test Structure (AAA Pattern)

Use Arrange-Act-Assert for clarity:

```javascript
describe('ModuleName', () => {
  describe('functionName', () => {
    it('should [expected behaviour] when [condition]', () => {
      // Arrange - set up test data
      const input = createTestInput();

      // Act - call the function
      const result = functionUnderTest(input);

      // Assert - verify the result
      expect(result).toEqual(expectedOutput);
    });
  });
});
```

**Good test names:**
- `should return empty array when input is empty`
- `should throw ValidationError when email is invalid`

**Bad test names:**
- `test1`, `works`, `handles stuff`

## 5) Mocking Strategy

Use mocks sparingly:

- **Mock external dependencies** (APIs, databases, file system)
- **Don't mock the thing you're testing**
- **Prefer fakes over mocks** when possible (in-memory DB, test server)
- **Reset mocks between tests** to avoid state leakage

## 6) Coverage Guidance

- **Line coverage** - Aim for 80%+ on critical paths
- **Branch coverage** - All if/else branches exercised
- **Don't chase 100%** - Diminishing returns after ~85%
- **Coverage ≠ quality** - You can have 100% coverage and miss bugs

## 7) Run Full Quality Suite

After writing tests:

```bash
npm run lint      # or equivalent
npm run typecheck # if applicable
npm test          # full suite
```

All must pass.

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
