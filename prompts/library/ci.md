# CI/CD

## Mindset

- **CI is the source of truth** - If it passes locally but fails in CI, it's not done
- **CI environments differ** - Different OS, versions, missing tools
- **Fail fast, fix fast** - Verify before committing
- **CI failures are blockers** - Task is not complete until CI passes
- **Supply chain security matters** - Pin actions, scope permissions, audit dependencies

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

## CI/CD Hardening

### Supply Chain Security
- Pin all third-party actions to full SHA hashes (not tags)
- Example: `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`
- Never use `@main` or `@master` for third-party actions

### Least-Privilege Permissions
- Declare explicit `permissions:` at the job level
- Only grant what each job needs (e.g., `contents: read`)
- Never use top-level `permissions: write-all`

### Deploy Safety
- Use concurrency groups to prevent parallel deploys
- Add deploy summary steps with commit SHA and timestamp
- Require CI to pass before deploy
- Maintain a rollback workflow for emergencies

### Branch Protection
- Require CI status checks to pass before merge
- Require at least one approval
- Disable force pushes to main
- Prefer squash or rebase merges for linear history

## CI Compatibility Checklist

- [ ] Scripts have shebang (`#!/usr/bin/env bash`)
- [ ] No OS-specific commands without fallback
- [ ] No hardcoded paths
- [ ] Tests don't require unavailable secrets
- [ ] No flaky tests (timing/order dependent)
- [ ] Actions pinned to full SHA hashes
- [ ] Job-level permissions declared
