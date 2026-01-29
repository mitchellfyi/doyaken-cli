---
name: github:issue-triage
description: Triage and label GitHub issues
requires:
  - github
args:
  - name: repo
    description: Repository (owner/repo format)
    default: ""
  - name: limit
    description: Maximum issues to triage
    default: "10"
---

# Issue Triage

You are triaging GitHub issues using GitHub MCP tools.

## Context

Project: {{DOYAKEN_PROJECT}}
Repository: {{ARGS.repo}}
Limit: {{ARGS.limit}}

## Triage Process

### 1. Fetch Open Issues

Use GitHub MCP to list issues:
- Filter: open issues without labels (or minimal labels)
- Sort: oldest first (backlog) or newest first (inbox)
- Limit: {{ARGS.limit}} issues

### 2. For Each Issue

Analyze and categorize:

**Issue Type**
- `bug` - Something isn't working
- `feature` - New feature request
- `enhancement` - Improvement to existing feature
- `question` - Support or clarification
- `documentation` - Docs improvement needed

**Priority**
- `priority: critical` - Security, data loss, crash
- `priority: high` - Major feature broken
- `priority: medium` - Important but not urgent
- `priority: low` - Nice to have

**Area**
- Identify affected component/module
- Apply relevant area labels

**Status**
- `needs-info` - Requires more details
- `duplicate` - Already reported
- `wont-fix` - Not planned
- `good-first-issue` - Good for newcomers

### 3. Apply Labels

Use GitHub MCP to:
- Add appropriate labels
- Add comment if `needs-info`
- Close if `duplicate` (reference original)

{{include:vendors/github/issues-prs.md}}

## Output

Provide triage summary:

```markdown
## Issue Triage Summary

**Triaged**: [count] issues
**Repository**: {{ARGS.repo}}

### Breakdown

| Issue | Title | Type | Priority | Labels Added |
|-------|-------|------|----------|--------------|
| #123  | [title] | bug | high | `bug`, `priority: high`, `area: api` |
| ...   | ...   | ...  | ...      | ... |

### Actions Taken
- Requested info on: #123, #456
- Marked as duplicate: #789 (duplicate of #100)
- Closed as wont-fix: #101

### Needs Attention
- [Issues requiring human decision]
```
