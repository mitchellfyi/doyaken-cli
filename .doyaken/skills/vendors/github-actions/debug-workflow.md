---
name: github-actions:debug-workflow
description: Debug a failing GitHub Actions workflow
args:
  - name: run
    description: Workflow run ID
    default: ""
  - name: workflow
    description: Workflow filename
    default: ""
---

# Debug GitHub Actions Workflow

You are debugging a failing GitHub Actions workflow.

## Context

Project: {{DOYAKEN_PROJECT}}
Run ID: {{ARGS.run}}
Workflow: {{ARGS.workflow}}

## Debugging Process

### 1. Identify the Failure

{{#if run}}
Analyze the specific run:
- Fetch run logs for run ID: {{ARGS.run}}
- Identify which job failed
- Find the failing step
{{else}}
Find recent failures:
- List recent workflow runs
- Filter by status: failure
- Get the latest failed run
{{/if}}

### 2. Analyze Error

Common failure categories:

**Syntax Errors**
- YAML parsing errors
- Invalid workflow syntax
- Expression errors

**Runtime Errors**
- Command failures (exit code non-zero)
- Timeout exceeded
- Out of memory

**Environment Issues**
- Missing secrets/variables
- Runner availability
- Network/connectivity

**Dependency Issues**
- Package installation failures
- Version conflicts
- Cache corruption

### 3. Common Solutions

**Timeout Issues**
```yaml
jobs:
  build:
    timeout-minutes: 30  # Increase timeout
```

**Caching Issues**
```yaml
- uses: actions/cache@v4
  with:
    key: ${{ runner.os }}-${{ hashFiles('**/lockfile') }}
    restore-keys: |
      ${{ runner.os }}-  # Fallback keys
```

**Flaky Tests**
```yaml
- run: npm test
  continue-on-error: true  # For investigation

- run: npm test -- --retry=3  # Add retries
```

**Permission Issues**
```yaml
permissions:
  contents: read
  packages: write  # Add required permissions
```

### 4. Test Fix

- Re-run the workflow
- Or push a fix to trigger new run

## Output

```markdown
## Workflow Debug Report

**Workflow**: {{ARGS.workflow}}
**Run**: {{ARGS.run}}
**Status**: Failed

### Failure Analysis

**Failed Job**: [job name]
**Failed Step**: [step name]
**Error Type**: [category]

### Error Details
```
[error message/logs]
```

### Root Cause
[Explanation of why it failed]

### Solution
[How to fix it]

### Code Changes
```yaml
# Before
[original code]

# After
[fixed code]
```

### Verification
- [ ] Re-run workflow
- [ ] Confirm fix works
- [ ] Update if similar issues elsewhere
```
