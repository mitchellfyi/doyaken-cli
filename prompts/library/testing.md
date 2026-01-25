# Testing Methodology

## Principles

- **Test behaviour, not implementation** - Tests should survive refactoring
- **One assertion per concept** - Each test proves one thing clearly
- **Fast and deterministic** - No flaky tests, no slow I/O in unit tests
- **Readable as documentation** - Test names describe the behaviour

## Test Pyramid

Choose the right level of test:

| Level | Speed | Scope | Use when |
|-------|-------|-------|----------|
| **Unit** | Fast (ms) | Single function/class | Pure logic, algorithms, transformations |
| **Integration** | Medium (s) | Multiple units + deps | Database, API calls, component interactions |
| **E2E** | Slow (10s+) | Full system | Critical user journeys only |

**Default to unit tests.** Move up only when lower levels can't catch the bug.

## What to Test

**Always test:**
- Happy path (normal inputs → expected outputs)
- Edge cases (empty, null, boundary values, max/min)
- Error cases (invalid input, failures, exceptions)
- State transitions (if stateful)

**Skip testing:**
- Framework code / library internals
- Simple getters/setters with no logic
- Private methods (test through public interface)

## AAA Pattern (Arrange-Act-Assert)

Structure every test clearly:

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

## Good Test Names

**Good:**
- `should return empty array when input is empty`
- `should throw ValidationError when email is invalid`
- `should retry 3 times before failing`

**Bad:**
- `test1`, `works`, `handles stuff`

## Mocking Strategy

Use mocks sparingly:

- **Mock external dependencies** (APIs, databases, file system)
- **Don't mock the thing you're testing**
- **Prefer fakes over mocks** when possible (in-memory DB, test server)
- **Reset mocks between tests** to avoid state leakage

## Coverage Guidance

- **Line coverage** - Aim for 80%+ on critical paths
- **Branch coverage** - All if/else branches exercised
- **Don't chase 100%** - Diminishing returns after ~85%
- **Coverage ≠ quality** - You can have 100% coverage and miss bugs

## Test Smells to Avoid

| Smell | Problem | Fix |
|-------|---------|-----|
| **Flaky tests** | Pass/fail randomly | Remove time dependencies, use deterministic data |
| **Slow tests** | > 100ms for unit test | Mock I/O, reduce setup |
| **Test interdependence** | Tests fail when run alone | Ensure each test is isolated |
| **Assertion-free tests** | Test runs but proves nothing | Add meaningful assertions |
| **Magic numbers** | `expect(result).toBe(42)` | Use named constants or explain |

## Test File Organization

Mirror source file structure:
```
src/
  services/
    UserService.js
tests/
  services/
    UserService.test.js
```

## Checklist

Before marking tests complete:

- [ ] All existing tests still pass
- [ ] New code has corresponding tests
- [ ] Edge cases are covered
- [ ] Error paths are tested
- [ ] Tests are deterministic (no random failures)
- [ ] Test names describe behaviour
- [ ] No console.log or debug output left in tests
