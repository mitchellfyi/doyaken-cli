# CI/CD Workflow Best Practices

## Mindset

- **CI is the source of truth** - If it passes locally but fails in CI, it's not done
- **CI environments differ** - Different OS, versions, missing tools
- **Fail fast, fix fast** - Don't push and hope; verify before committing
- **CI failures are blockers** - A task is not complete until CI passes

## Common CI Failure Patterns

### 1. Environment Differences

**Linux vs macOS:**
- Case-sensitive filesystem on Linux
- Different default shells (`/bin/sh` vs `/bin/bash`)
- Different installed tools (GNU vs BSD)
- Path differences

**Solutions:**
```bash
# Use bash explicitly
#!/usr/bin/env bash

# Use cross-platform compatible commands
# Bad: sed -i '' (macOS) vs sed -i (Linux)
# Good: Use variable for in-place flag
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="-i ''"
else
  SED_INPLACE="-i"
fi

# Or use temporary file approach (portable)
sed 's/old/new/g' file > file.tmp && mv file.tmp file
```

### 2. Missing Dependencies

**Check tools exist before using:**
```bash
command -v yq &>/dev/null || {
  echo "Error: yq is required but not installed"
  exit 1
}
```

**In CI workflows, install explicitly:**
```yaml
- name: Install yq
  run: |
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
```

### 3. Permission Issues

**Make scripts executable:**
```yaml
- name: Make scripts executable
  run: chmod +x scripts/*.sh bin/*
```

**Check file permissions in git:**
```bash
# Add execute permission to git
git update-index --chmod=+x scripts/my-script.sh
```

### 4. Path and Working Directory

**Always use explicit paths:**
```yaml
- name: Run tests
  run: ./scripts/test.sh
  working-directory: ${{ github.workspace }}
```

**Reference files from known locations:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
```

### 5. Secrets and Environment Variables

**Never hardcode secrets:**
```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  API_KEY: ${{ secrets.API_KEY }}
```

**Handle missing secrets gracefully:**
```bash
if [ -z "${API_KEY:-}" ]; then
  echo "Warning: API_KEY not set, skipping integration tests"
  exit 0
fi
```

### 6. Caching Issues

**Clear caches when debugging:**
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

**Force rebuild if needed:**
```yaml
- name: Fresh install
  run: rm -rf node_modules && npm ci
```

### 7. Timing and Async Issues

**Add explicit waits where needed:**
```bash
# Wait for service to be ready
timeout 30 bash -c 'until curl -s localhost:3000/health; do sleep 1; done'
```

**Use CI retry for flaky external calls:**
```yaml
- name: Deploy
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: ./deploy.sh
```

## GitHub Actions Best Practices

### Workflow Structure

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        run: npm run lint

  test:
    runs-on: ubuntu-latest
    needs: lint  # Run after lint passes
    steps:
      - uses: actions/checkout@v4
      - name: Test
        run: npm test

  deploy:
    runs-on: ubuntu-latest
    needs: test  # Run after test passes
    if: github.ref == 'refs/heads/main'  # Only on main
    steps:
      - name: Deploy
        run: ./deploy.sh
```

### Matrix Testing

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [18, 20]
      fail-fast: false  # Continue other jobs if one fails
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

### Debugging CI Failures

```yaml
- name: Debug info
  run: |
    echo "OS: $RUNNER_OS"
    echo "PWD: $(pwd)"
    echo "Files: $(ls -la)"
    which bash
    bash --version
```

**Enable debug logging:**
```yaml
env:
  ACTIONS_STEP_DEBUG: true
```

## Pre-Push Checklist

Before pushing, verify locally:

- [ ] All tests pass: `npm test` / `pytest` / etc.
- [ ] Linting passes: `npm run lint` / `ruff check` / etc.
- [ ] Build succeeds: `npm run build` / etc.
- [ ] Scripts are executable: `chmod +x scripts/*.sh`
- [ ] No hardcoded secrets or paths
- [ ] YAML files are valid: `yq '.' file.yaml`

## Checking CI Status

Using GitHub CLI:

```bash
# Watch current run
gh run watch

# List recent runs
gh run list --limit 5

# View specific run
gh run view <run-id>

# View logs for failed job
gh run view <run-id> --log-failed

# Re-run failed jobs
gh run rerun <run-id> --failed
```

## Fixing CI Failures

### Process

1. **Get the logs:**
   ```bash
   gh run view --log-failed
   ```

2. **Identify the failure type:**
   - Syntax error?
   - Missing dependency?
   - Environment difference?
   - Test failure?
   - Permission issue?

3. **Reproduce locally if possible:**
   ```bash
   # Use act for local GitHub Actions testing
   act -j test
   ```

4. **Fix and verify:**
   ```bash
   # Make fix
   # Run local tests
   npm test
   # Push and watch
   git push && gh run watch
   ```

5. **Iterate until green:**
   - Don't give up after one fix
   - CI passing is required for completion

## CI Verification Template

```
## CI Verification

Workflow run: [link to run]

| Job | Status | Notes |
|-----|--------|-------|
| lint | pass/fail | |
| test (ubuntu) | pass/fail | |
| test (macos) | pass/fail | |
| build | pass/fail | |

Failures:
- [job]: [error message]
  - Root cause: [analysis]
  - Fix: [what was done]

Final status: [ALL PASS / BLOCKED]
```
