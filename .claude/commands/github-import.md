---
description: List and summarize GitHub issues for the repository
---

Run the doyaken skill: github-import

```bash
doyaken skill github-import $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# GitHub Issue Review

You are reviewing GitHub issues for the repository to understand open work.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Repository: {{GIT_REMOTE}}
Filter: {{ARGS.filter}} issues
Labels filter: {{ARGS.labels}}
Limit: {{ARGS.limit}} issues

## Instructions

1. **List GitHub Issues**
   Use `gh` CLI to list issues from the repository:
   - Filter by state: {{ARGS.filter}}
   - Filter by labels: {{ARGS.labels}} (if specified)
   - Limit to {{ARGS.limit}} most recent issues

2. **Summarize Issues**
   For each issue, provide:
   - Issue number and title
   - Labels and priority indicators
   - Brief summary of the issue body
   - Link to the GitHub issue

3. **Categorize by Priority**
   Group issues by priority based on labels:
   - **Critical**: `bug`, `critical`, `security`
   - **High**: `important`, `priority`
   - **Medium**: `enhancement`, `feature`
   - **Low**: others

4. **Report Summary**
   After reviewing, report:
   - Total issues found
   - Breakdown by priority
   - Any issues that need immediate attention

## Output Format

```
GitHub Issue Summary
====================
Repository: owner/repo
Filter: open issues

Found: N issues

Critical:
  - #123: Fix login bug (bug, security)
  - #789: Data corruption on save (critical)

High:
  - #234: Improve auth flow (priority)

Medium:
  - #456: Add dark mode (enhancement)

Low:
  - #567: Update README links
```

## Rules

- Present issues clearly with their GitHub URLs
- Highlight any issues that seem urgent or blocking
- Note any issues that reference each other (dependencies)
