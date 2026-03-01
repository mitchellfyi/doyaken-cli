# Testing

**Test behaviour, not implementation** — tests should survive refactoring. Write tests alongside implementation, not after.

## Principles

- **Tests must be able to fail** — if a test can't catch a bug, it's not a real test. Write the test first, see it fail, then make it pass
- **One assertion per concept** — each test proves one thing clearly
- **Fast and deterministic** — no flaky tests, no real I/O in unit tests, no timing dependencies
- **Readable as documentation** — test names describe the behaviour: `should return empty array when input is empty`
- **Error-case tests are mandatory** — for every happy-path test, write at least one error-case test

## Test Pyramid

| Level | Speed | Scope | Use when |
|-------|-------|-------|----------|
| **Unit** | Fast (ms) | Single function/class | Pure logic, algorithms, data transformations |
| **Integration** | Medium (s) | Multiple units + real deps | API handlers with database, service interactions |
| **E2E** | Slow (10s+) | Full system | Critical user journeys only |

**Default to unit tests.** Move up only when lower levels can't catch the bug.

## What to Test

**Always test:**
- Happy path (normal inputs → expected outputs)
- Edge cases (empty, null, zero, boundary values, maximum lengths, Unicode, special characters)
- Error cases (invalid input, missing resources, permission denied, external failures, timeouts)
- State transitions (if stateful)
- Backward compatibility (existing callers still work after changes)
- Concurrency scenarios (if the code handles concurrent access)

**Skip testing:**
- Framework/library internals
- Simple getters/setters with no logic
- Private methods (test through the public interface)

## AAA Pattern

Structure every test:
1. **Arrange** — set up test data
2. **Act** — call the function
3. **Assert** — verify the result

## Test Quality

- **Isolated** — each test runs independently, no shared mutable state between tests, order-independent
- **Question your own tests** — ask: "Would this test still pass if I introduced a subtle bug in the implementation?" If yes, the test is too weak
- **Don't mock away the thing you should be testing** — if you mock so extensively that no real logic executes, the test proves nothing. Be especially suspicious when mocks perfectly match new code — this can mask nonexistent APIs, wrong method signatures, or incorrect schemas
- Mock external dependencies (APIs, databases, file system), not the thing you're testing
- Prefer fakes (in-memory implementations) over mocks where practical
- Reset mocks and state between tests

## Test Names

**Good:** `should return empty array when input is empty`
**Bad:** `test1`, `works`, `handles stuff`

## Coverage

- 80%+ on critical paths
- Every new public function has tests
- Every bug fix has a regression test
- Don't chase 100% — diminishing returns
- Coverage measures execution, not correctness — high coverage with weak assertions is worthless
- **Error-path coverage matters more than line coverage** — test what happens when things go wrong, not just when they go right

## Specialised Testing (when applicable)

- **Contract tests**: verify that API producers satisfy consumer expectations, especially across service boundaries
- **Property-based tests**: for algorithms or data transformations, generate random inputs and verify invariants hold
- **Snapshot tests**: sparingly, for complex serialisation output where manual assertion is impractical
- **Accessibility tests**: automated checks for WCAG violations in UI components
- **Performance tests**: for performance-sensitive paths, assert that operations complete within acceptable thresholds

## CI Compatibility

- Scripts are executable, no OS-specific commands (BSD vs GNU differences)
- No hardcoded paths, no flaky timing dependencies
- Tests don't require unavailable secrets, services, or network access
- Tests clean up after themselves (temp files, test databases, ports)

## Test Smells

| Smell | Problem | Fix |
|-------|---------|-----|
| **Flaky** | Pass/fail randomly | Remove time dependencies, make deterministic |
| **Slow** | > 100ms for unit | Mock I/O |
| **Interdependent** | Fail when run alone | Isolate each test |
| **No assertions** | Proves nothing | Add meaningful assertions |
| **Mirror implementation** | Tests that just replay code structure | Test observable behaviour independently |
| **Over-mocked** | No real logic executes | Reduce mocks, use fakes |

## Test Selection Strategy

When working in a project with many test files, run tests in this order:

1. **Targeted first** — run only tests for changed modules (map source files to their test files by naming convention and directory structure)
2. **Full suite second** — run the complete test suite to catch regressions
3. **Integration last** — run integration tests only after unit tests pass

When in doubt about which tests are relevant, run everything.

## Checklist

- [ ] All existing tests pass (before and after changes)
- [ ] New code has tests
- [ ] Edge cases covered
- [ ] Error paths tested (at least one per happy-path test)
- [ ] Tests are deterministic and isolated
- [ ] No debug output in tests
- [ ] Bug fixes include a regression test
- [ ] Tests can run in CI without special environment
