---
name: github-import
description: Import GitHub issues as local doyaken tasks
requires:
  - github
args:
  - name: filter
    description: Issue state filter (open, closed, all)
    default: "open"
  - name: labels
    description: Comma-separated labels to filter by
  - name: limit
    description: Maximum number of issues to import
    default: "10"
---

# GitHub Issue Import

You are importing GitHub issues as local doyaken tasks.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Repository: {{GIT_REMOTE}}
Filter: {{ARGS.filter}} issues
Labels filter: {{ARGS.labels}}
Limit: {{ARGS.limit}} issues

## Instructions

1. **List GitHub Issues**
   Use the GitHub MCP tools to list issues from the repository:
   - Filter by state: {{ARGS.filter}}
   - Filter by labels: {{ARGS.labels}} (if specified)
   - Limit to {{ARGS.limit}} most recent issues

2. **Check Existing Tasks**
   Look in `.doyaken/tasks/` (all folders) for existing tasks that reference GitHub issues.
   Skip any issues that already have a corresponding task.

3. **Create Task Files**
   For each new issue, create a task file in `.doyaken/tasks/2.todo/`:

   File naming: `PPP-SSS-slug.md` where:
   - PPP = Priority based on labels:
     - `bug`, `critical`, `security` → 001 (Critical)
     - `important`, `priority` → 002 (High)
     - `enhancement`, `feature` → 003 (Medium)
     - others → 003 (Medium)
   - SSS = Sequence (001, 002, etc.)
   - slug = Issue title (kebab-case, max 50 chars)

   Include in the task file:
   - Title from issue title
   - Context from issue body
   - External Ref: `github:owner/repo#issue_number`
   - Link to the GitHub issue

4. **Report Summary**
   After importing, report:
   - Total issues found
   - Issues imported (new tasks created)
   - Issues skipped (already tracked)
   - Any errors encountered

## Output Format

```
GitHub Issue Import Summary
===========================
Repository: owner/repo
Filter: open issues

Found: N issues
Imported: N new tasks
  - 003-001-fix-login-bug.md (from #123)
  - 003-002-add-dark-mode.md (from #456)
Skipped: N already tracked
Errors: N (list if any)
```

## Rules

- Do NOT modify existing task files
- Do NOT create duplicate tasks for the same issue
- Include the GitHub issue URL in the Links section
- Use the issue body as the initial Context (truncate if very long)
