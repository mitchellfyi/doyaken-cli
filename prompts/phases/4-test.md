# Phase 4: TEST (Quality Assurance)

You are testing the implementation for task {{TASK_ID}}.

## Testing Methodology

{{include:library/testing.md}}

## Code Quality Standards

{{include:library/code-quality.md}}

## Phase-Specific Instructions

1. **Run existing tests first** - All must pass before writing new tests
2. **Check implementation coverage** - Every new public function needs a test
3. **Run full quality suite** - lint, typecheck, tests all must pass
4. **Validate CI compatibility** - Ensure tests will pass in CI environment

## Testing Checklist

### 1) Run Existing Tests

```bash
# Run full test suite
npm test        # JavaScript/TypeScript
pytest          # Python
go test ./...   # Go
```

All existing tests must pass before proceeding.

### 2) Write New Tests

For each new/modified public function:
- Unit test for happy path
- Unit test for edge cases
- Unit test for error handling
- Integration test if it interacts with other systems

### 3) Run Quality Gates

```bash
# All must pass
npm run lint          # or: ruff check .
npm run typecheck     # or: mypy .
npm run test          # or: pytest
npm run build         # if applicable
```

### 4) CI Compatibility Check

**Before considering tests complete, validate CI compatibility:**

- [ ] Scripts are executable (`chmod +x scripts/*.sh`)
- [ ] No macOS-specific commands (check for BSD sed, etc.)
- [ ] No hardcoded paths that won't work in CI
- [ ] No reliance on tools not installed in CI
- [ ] Tests don't require secrets not available in CI
- [ ] No flaky tests (timing-dependent, order-dependent)

**Common CI compatibility issues to check:**

```bash
# Check for BSD-specific commands
grep -r "sed -i ''" .  # macOS sed syntax

# Check for hardcoded paths
grep -r "/Users/" .
grep -r "/home/runner/" .

# Check script permissions
ls -la scripts/*.sh

# Validate bash syntax on all scripts
for f in scripts/*.sh lib/*.sh; do bash -n "$f"; done

# Validate YAML files
yq '.' .github/workflows/*.yml > /dev/null
```

### 5) Cross-Platform Considerations

If the project supports multiple platforms:

| Check | Linux | macOS | Notes |
|-------|-------|-------|-------|
| Tests pass | [ ] | [ ] | Run locally if possible |
| No platform-specific code | [ ] | [ ] | Or properly conditioned |
| File paths work | [ ] | [ ] | Case sensitivity |

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
- Build: [pass/fail]

CI Compatibility:
- Scripts executable: [yes/no]
- Platform-agnostic: [yes/no]
- YAML valid: [yes/no]
- No hardcoded paths: [yes/no]

Ready for CI: [yes/no]
```

## Rules

- **COMMIT tests as you write them** - don't wait until the end
- Do NOT add new features in this phase
- Fix bugs found during testing, but don't expand scope
- Every new public function needs a test
- Test file organization should mirror source file organization
- If a test is flaky, fix the root cause (don't add retries)
- **Ensure tests will pass in CI, not just locally**

Task file: {{TASK_FILE}}
