---
description: Apply testing methodology
---

# Testing

## Principles

- **Test behaviour, not implementation** - Tests should survive refactoring
- **One assertion per concept** - Each test proves one thing clearly
- **Fast and deterministic** - No flaky tests, no slow I/O in unit tests
- **Readable as documentation** - Test names describe the behaviour

## Test Pyramid

| Level | Speed | Scope | Use when |
|-------|-------|-------|----------|
| **Unit** | Fast (ms) | Single function/class | Pure logic, algorithms |
| **Integration** | Medium (s) | Multiple units + deps | Database, API calls |
| **E2E** | Slow (10s+) | Full system | Critical user journeys only |

**Default to unit tests.** Move up only when lower levels can't catch the bug.

## What to Test

**Always test:**
- Happy path (normal inputs → expected outputs)
- Edge cases (empty, null, boundary values)
- Error cases (invalid input, failures)
- State transitions (if stateful)

**Skip testing:**
- Framework/library internals
- Simple getters/setters with no logic
- Private methods (test through public interface)

## AAA Pattern

Structure every test:
1. **Arrange** - set up test data
2. **Act** - call the function
3. **Assert** - verify the result

## Test Names

**Good:** `should return empty array when input is empty`
**Bad:** `test1`, `works`, `handles stuff`

## Mocking

- Mock external dependencies (APIs, databases)
- Don't mock the thing you're testing
- Prefer fakes over mocks when possible
- Reset mocks between tests

## Coverage

- Aim for 80%+ on critical paths
- Don't chase 100% - diminishing returns
- Coverage ≠ quality

## Test Smells

| Smell | Problem | Fix |
|-------|---------|-----|
| **Flaky** | Pass/fail randomly | Remove time dependencies |
| **Slow** | > 100ms for unit | Mock I/O |
| **Interdependent** | Fail when run alone | Isolate each test |
| **No assertions** | Proves nothing | Add meaningful assertions |

## Checklist

- [ ] All existing tests pass
- [ ] New code has tests
- [ ] Edge cases covered
- [ ] Error paths tested
- [ ] Tests are deterministic
- [ ] No debug output in tests

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
