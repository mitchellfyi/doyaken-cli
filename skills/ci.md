---
name: ci
description: Manage and harden CI/CD workflows
args:
  - name: action
    description: Action to perform (audit, harden, status)
    default: "audit"
---

# CI/CD Management

Audit, harden, and manage CI/CD workflows.

## Context

Project: {{DOYAKEN_PROJECT}}
Action: {{ARGS.action}}

## CI/CD Best Practices

{{include:library/ci.md}}

## Instructions

### Audit (`audit`)

1. Review all workflow files in `.github/workflows/`
2. Check for:
   - Actions pinned to full SHA hashes (not tags)
   - Job-level permissions with least-privilege scoping
   - Concurrency groups on deploy workflows
   - Deploy summary steps
   - Security audit steps
   - Branch protection requirements documented
3. Report findings

### Harden (`harden`)

1. Pin all third-party actions to SHA hashes
2. Add job-level permissions to all jobs
3. Add concurrency groups to deploy workflows
4. Add deploy summary steps
5. Add security audit steps
6. Ensure rollback mechanism exists

### Status (`status`)

1. Check recent workflow run status
2. Report any failures
3. Suggest fixes for common issues

## Output

```
## CI/CD Report

### Workflow Files
| File | Status | Issues |
|------|--------|--------|
| ci.yml | ✅/⚠️ | [issues] |

### Security
- [ ] Actions pinned to SHA
- [ ] Job-level permissions
- [ ] Secrets properly scoped
- [ ] Security audit step present

### Deploy Safety
- [ ] Concurrency group configured
- [ ] Deploy summary step
- [ ] Rollback mechanism available
- [ ] Branch protection configured

### Recommendations
[List of improvements]
```
