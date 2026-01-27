---
description: Apply ci methodology
---

# CI/CD

## Mindset

- **CI is the source of truth** - If it passes locally but fails in CI, it's not done
- **CI environments differ** - Different OS, versions, missing tools
- **Fail fast, fix fast** - Verify before committing
- **CI failures are blockers** - Task is not complete until CI passes

## Common Failure Patterns

### Environment Differences
- Case-sensitive filesystem (Linux vs macOS)
- Different shells and tools (GNU vs BSD)
- Path differences

### Missing Dependencies
- Check tools exist before using
- Install explicitly in CI workflows

### Permission Issues
- Ensure scripts are executable
- Check file permissions in git

### Secrets and Environment
- Never hardcode secrets
- Handle missing secrets gracefully

### Timing Issues
- Add explicit waits for services
- Use retries for flaky external calls

## Pre-Push Checklist

- [ ] All tests pass
- [ ] Linting passes
- [ ] Build succeeds
- [ ] Scripts are executable
- [ ] No hardcoded secrets or paths
- [ ] Config files are valid

## Fixing CI Failures

1. **Get the logs** - Check CI output
2. **Identify failure type** - Syntax? Dependency? Environment? Test?
3. **Reproduce locally** if possible
4. **Fix and verify** - Push and watch CI
5. **Iterate until green**

## CI Compatibility Checklist

- [ ] Scripts have shebang (`#!/usr/bin/env bash`)
- [ ] No OS-specific commands without fallback
- [ ] No hardcoded paths
- [ ] Tests don't require unavailable secrets
- [ ] No flaky tests (timing/order dependent)

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
