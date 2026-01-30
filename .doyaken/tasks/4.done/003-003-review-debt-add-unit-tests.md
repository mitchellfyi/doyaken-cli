# Add Comprehensive Unit Test Suite

## Category
Periodic Review Finding - debt

## Severity
high

## Description
The current test suite (scripts/test.sh) only checks:
- File existence
- Bash syntax validation
- Basic command execution

Missing test coverage for:
- Version comparison logic (upgrade_compare_versions)
- Config loading and merging
- Task ID generation
- Registry operations
- Lock acquisition/release
- Phase timeout handling
- Fallback to sonnet logic

Critical functions have zero unit tests.

## Location
scripts/test.sh - needs expansion

## Recommended Fix
1. Adopt bats-core (Bash Automated Testing System) for proper unit testing
2. Create test files per module:
   - test/unit/upgrade.bats
   - test/unit/config.bats
   - test/unit/registry.bats
   - test/unit/core.bats
3. Add integration tests for full workflows
4. Target 80% coverage on critical paths

## Impact
- High risk of regressions when modifying code
- Difficult to verify behavior changes
- No confidence in refactoring

## Acceptance Criteria
- [ ] bats-core integrated into test suite
- [ ] Unit tests for upgrade_compare_versions()
- [ ] Unit tests for config loading
- [ ] Unit tests for task ID generation
- [ ] Unit tests for lock acquisition
- [ ] Integration test for init -> run workflow
- [ ] npm test runs all test types
