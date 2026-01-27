---
description: Diagnose and fix CI/CD failures
---

Run the doyaken skill: ci-fix

```bash
doyaken skill ci-fix $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# CI/CD Failure Diagnosis and Fix

Diagnose and fix GitHub Actions CI failures.

## Context

Project: {{DOYAKEN_PROJECT}}
Run ID: {{ARGS.run-id}}
Auto-fix: {{ARGS.auto-fix}}

## CI Best Practices

{{include:library/ci.md}}

## Diagnosis Process

### Step 1: Get Failure Information

```bash
# If run-id not specified, get latest
gh run list --limit 1

# View the failed run
gh run view {{ARGS.run-id}} --log-failed

# Get detailed job logs
gh run view {{ARGS.run-id}} --log
```

### Step 2: Identify Failure Type

Categorize the failure:

| Type | Indicators | Common Fix |
|------|------------|------------|
| **Syntax Error** | "syntax error", "unexpected token" | Fix bash/YAML syntax |
| **Missing Tool** | "command not found" | Add install step |
| **Permission** | "Permission denied" | chmod +x scripts |
| **Environment** | Works on macOS, fails on Linux | Use portable commands |
| **Test Failure** | Test assertions fail | Fix code or test |
| **Timeout** | "Job exceeded time limit" | Optimize or increase timeout |
| **Network** | Connection refused, timeout | Add retry or wait |

### Step 3: Analyze Root Cause

For each failed job:

1. **Read the full error message** - Don't skip context
2. **Check the step before the failure** - Often setup issues
3. **Compare to local behavior** - What's different in CI?
4. **Check recent changes** - What changed since last green?

### Step 4: Apply Fix

{{#if auto-fix == "true"}}
**Auto-fix enabled**: Will attempt to fix common issues automatically.

Common auto-fixes:
- Add missing `chmod +x` for scripts
- Fix bash shebang lines
- Add missing tool installation
- Fix YAML syntax
- Add missing environment variables (non-secret)
{{/if}}

### Step 5: Verify Fix

After making changes:

```bash
# Run local tests first
npm test  # or appropriate command

# Push and watch CI
git add -A
git commit -m "fix(ci): [description of fix]"
git push
gh run watch
```

## Common Fixes

### Missing chmod

```yaml
- name: Make scripts executable
  run: chmod +x scripts/*.sh bin/*
```

### BSD vs GNU sed

Replace:
```bash
sed -i 's/old/new/' file  # GNU
sed -i '' 's/old/new/' file  # BSD
```

With portable:
```bash
sed 's/old/new/' file > file.tmp && mv file.tmp file
```

Or use awk:
```bash
awk '{gsub(/old/,"new")}1' file > file.tmp && mv file.tmp file
```

### Missing Tool Installation

```yaml
- name: Install dependencies
  run: |
    if command -v apt-get &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y shellcheck yq
    elif command -v brew &>/dev/null; then
      brew install shellcheck yq
    fi
```

### Bash Shebang

Change:
```bash
#!/bin/sh
```

To:
```bash
#!/usr/bin/env bash
```

### Case Sensitivity

Linux filesystems are case-sensitive. Check:
```bash
git ls-files | sort -f | uniq -di
```

### Path Issues

Use explicit paths:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

## Output

```
## CI Diagnosis Report

### Run Information
- Run ID: [id]
- Workflow: [name]
- Trigger: [push/pull_request]
- Branch: [branch]
- Commit: [sha]

### Failed Jobs

#### Job: [job-name]
- Status: failed
- Runner: [ubuntu-latest/macos-latest]
- Duration: [time]

**Error:**
\`\`\`
[error message]
\`\`\`

**Root Cause:**
[analysis of what went wrong]

**Fix Applied:**
[what was changed to fix it]

### Verification

- [ ] Fix committed
- [ ] CI re-run triggered
- [ ] CI passes

### Commands Used

\`\`\`bash
# Diagnosis
gh run view [id] --log-failed

# Fix
[commands used to fix]

# Verify
git push && gh run watch
\`\`\`

### Final Status
[FIXED / NEEDS MORE WORK / BLOCKED - reason]
```

## Iterative Fixing

If the first fix doesn't work:

1. Don't give up after one attempt
2. Read the NEW error message carefully
3. The fix might have revealed a deeper issue
4. Keep iterating until CI is green

**Remember: A task is NOT complete until CI passes.**
