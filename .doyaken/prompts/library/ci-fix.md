# CI/CD — Diagnose and Fix Failures

## Mindset

- **Fix the root cause** — no workarounds, no skipping tests, no `continue-on-error`
- **Read the actual error** — don't guess, don't pattern-match on the first line
- **Reproduce locally first** — if you can't reproduce it, you don't understand it
- **One fix at a time** — don't shotgun multiple changes hoping one sticks

## Diagnosis Process

### 1. Get the Failure Logs

```bash
# Latest failed run
gh run list --status failure --limit 1

# View failed job logs
gh run view <run-id> --log-failed

# Full logs if needed
gh run view <run-id> --log
```

### 2. Classify the Failure

| Category | Signals | Approach |
|----------|---------|----------|
| **Build** | Compile errors, missing deps, syntax | Fix source or dependency config |
| **Test** | Assertion failures, test errors | Fix code or fix the test if it's wrong |
| **Lint/Format** | Style violations, lint errors | Run formatter/linter locally, commit |
| **Environment** | Works locally, fails in CI | Check OS, tool versions, paths |
| **Permissions** | Permission denied, EACCES | chmod, token scopes, workflow permissions |
| **Timeout** | Job cancelled, exceeded time limit | Optimize or adjust timeout |
| **Flaky** | Passes on retry, non-deterministic | Make deterministic or add retry with backoff |
| **Config** | YAML parse errors, bad workflow syntax | Validate workflow files |

### 3. Analyze Root Cause

For each failed job:

1. Read the **full error output** — not just the last line
2. Check the **step before** the failing step — setup failures cascade
3. Compare **CI environment vs local** — OS, shell, tool versions, env vars
4. Check **recent commits** — `git log --oneline main~5..main`
5. Check if it's a **known flaky test** — has this failed before?

### 4. Common CI Failure Patterns

**Environment differences (most common):**
- Case-sensitive filesystem (Linux CI vs macOS local)
- GNU vs BSD tools (sed, grep, date behave differently)
- Different default shell (sh vs bash)
- Missing tools not in CI image

**Dependency issues:**
- Lockfile out of sync with package manifest
- Transitive dependency updated and broke
- Private registry auth not configured in CI

**Timing issues:**
- Service not ready when tests start (DB, API)
- Race conditions in parallel test execution
- Network timeouts to external services

**Permission issues:**
- Scripts not marked executable in git
- `GITHUB_TOKEN` missing required scopes
- Workflow `permissions:` too restrictive

### 5. Apply the Fix

- Fix the actual code, test, or configuration — not the CI check
- If a test is wrong, fix the test. If the code is wrong, fix the code
- Run the full check suite locally before pushing:
  ```bash
  # Run whatever CI runs
  npm test        # or make test, pytest, etc.
  npm run lint    # or equivalent
  npm run build   # if applicable
  ```

### 6. Verify

```bash
# Push the fix
git push

# Watch the run
gh run watch
```

If it fails again, go back to step 1 with the **new** error. Don't assume it's the same problem.

## Constraints

- Do NOT skip, disable, or `xfail` tests to make CI green
- Do NOT add `continue-on-error: true` to mask failures
- Do NOT weaken or remove existing checks
- Do NOT retry flaky tests without also fixing the root cause
- If a failure requires external action (adding a secret, fixing a third-party service), document it clearly and stop — don't hack around it
