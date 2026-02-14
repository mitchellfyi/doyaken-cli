You are performing a scheduled maintenance review of **test coverage and quality**. Your goal is to leave the test suite better than you found it.

## Phase 1: Review

1. Read `CLAUDE.md` and `AGENTS.md` for project conventions
2. Read `package.json` for test scripts and `vitest.config.ts` for test configuration
3. Run `pnpm test:coverage` to see current coverage numbers
4. Identify:
   - Source files with no corresponding test file
   - Test files with weak assertions (no real checks, just "it runs")
   - Critical paths (auth, data mutations, API routes) without tests
   - Tests that don't test edge cases (empty inputs, null values, error paths)
   - Flaky tests (non-deterministic, time-dependent, order-dependent)
   - Slow tests that could be faster
   - Test file organization (do test files mirror source structure?)

## Phase 2: Fix

Fix existing test issues:

- Fix broken or skipped tests
- Fix flaky tests (mock time, remove order dependencies)
- Fix tests with incorrect assertions (testing the wrong thing)
- Remove duplicate test cases

## Phase 3: Sync

Ensure test consistency:

- All test files use the same patterns (describe/it structure, setup/teardown)
- Mocking is done consistently (same approach for similar dependencies)
- Test file locations mirror source file locations
- Remove test files for source files that no longer exist

## Phase 4: Improve

Enhance existing tests:

- Add missing edge case tests to existing test files (null, empty, boundary values)
- Add error path testing where only happy path is tested
- Improve test descriptions to be clearer about what's being tested
- Improve assertions to be more specific (not just "truthy" — check exact values)

## Phase 5: Add

Fill test gaps — prioritize by impact:

1. API routes and server actions (highest impact — data mutations)
2. Utility functions and shared helpers (high reuse, easy to test)
3. Business logic functions (core domain logic)
4. Component integration tests for critical user flows

For each new test file, follow the existing test patterns in the codebase.

## Instructions

1. Read `CLAUDE.md` and `AGENTS.md` first
2. Read existing test files to understand the project's test patterns before writing new ones
3. Work through Phases 1-5 in order
4. Run ALL quality gates before committing: `pnpm format`, `pnpm lint:fix`, `pnpm typecheck`, `pnpm test`
5. Commit changes with descriptive messages — group by phase where practical
6. Push to the current branch
7. Do NOT create a new PR — just push to this branch

## Rules

- Test behavior, not implementation details
- One concept per test — keep tests focused
- Use descriptive test names that read like documentation
- Mock external dependencies, not the code being tested
- Do NOT add tests that just assert `true` — every test should verify real behavior
- Do NOT modify source code — only test files (unless fixing an obvious bug found during testing)
- Prioritize critical path coverage over 100% line coverage
