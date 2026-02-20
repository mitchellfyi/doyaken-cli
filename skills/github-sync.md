---
name: github-sync
description: Sync dk run results back to GitHub issues
requires:
  - github
args:
  - name: close-issues
    description: Whether to close GitHub issues when work is complete
    default: "true"
  - name: add-comment
    description: Whether to add a comment when updating issues
    default: "true"
---

# GitHub Issue Sync

You are syncing dk run results back to their linked GitHub issues.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Repository: {{GIT_REMOTE}}
Close issues: {{ARGS.close-issues}}
Add comments: {{ARGS.add-comment}}

## Instructions

1. **Find Recent Commits with GitHub References**
   Look at recent git commits for messages containing:
   - `Fixes #N` or `Closes #N` patterns
   - `github:owner/repo#N` references
   - Any `#N` issue references

2. **For Each Referenced Issue**
   Parse the issue number, then:

   a) **Add Comment** (if enabled):
      Post a comment on the GitHub issue summarizing:
      - That the work was completed via doyaken
      - Key commits that address the issue
      - Link to any PR created

   b) **Close Issue** (if enabled):
      Close the GitHub issue with a closing comment

3. **Report Summary**
   After syncing, report:
   - Commits checked
   - Issues updated
   - Issues closed
   - Any errors

## Output Format

```
GitHub Sync Summary
===================
Repository: owner/repo

Commits checked: N
Issues updated: N
  - #123: Closed with comment
  - #456: Comment added
Already closed: N
Errors: N (list if any)
```

## Rules

- Do NOT re-close issues that are already closed
- Be cautious about closing issues - only close if explicitly enabled
- Include relevant commit hashes in comments when available
