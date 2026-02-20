---
name: github-import
description: Import GitHub issues as prompts for dk run
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

You are importing GitHub issues as prompts that can be executed with `dk run`.

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

2. **Generate Prompts**
   For each issue, generate a `dk run` prompt that captures the issue intent:

   - Summarize the issue title and body into a clear, actionable prompt
   - Include the GitHub issue reference (e.g., `Fixes #123`)
   - Prioritize based on labels:
     - `bug`, `critical`, `security` → High priority
     - `important`, `priority` → Medium priority
     - `enhancement`, `feature` → Normal priority

3. **Report Summary**
   After importing, report:
   - Total issues found
   - Prompts generated
   - Any errors encountered

   For each issue, output the ready-to-use `dk run` command.

## Output Format

```
GitHub Issue Import Summary
===========================
Repository: owner/repo
Filter: open issues

Found: N issues

Ready-to-run prompts:
  1. #123 - Fix login bug
     dk run "Fix the login bug where users get a 500 error on invalid email. Fixes #123"

  2. #456 - Add dark mode
     dk run "Add dark mode support to the UI. Fixes #456"

Errors: N (list if any)
```

## Rules

- Include the GitHub issue URL in the prompt context
- Use the issue body to craft a clear, actionable prompt
- Prompts should be self-contained (include enough context from the issue)
- Prioritize bugs and security issues first in the output list
