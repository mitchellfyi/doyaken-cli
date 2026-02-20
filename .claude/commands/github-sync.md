---
description: Sync completed work back to GitHub issues
---

Run the doyaken skill: github-sync

```bash
doyaken skill github-sync $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# GitHub Issue Sync

You are syncing completed work back to linked GitHub issues.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Repository: {{GIT_REMOTE}}
Close issues: {{ARGS.close-issues}}
Add comments: {{ARGS.add-comment}}

## Instructions

1. **Find Completed Work with GitHub References**
   Search recent git history for commits that reference GitHub issues (e.g., `#123`, `fixes #123`, `closes #123`).

2. **For Each Referenced Issue**
   Check the issue status on GitHub, then:

   a) **Add Comment** (if enabled):
      Post a comment on the GitHub issue summarizing:
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

- Do NOT update issues that are already closed (unless adding a comment)
- Be cautious about closing issues - only close if explicitly enabled
- Include relevant commit hashes in comments when available
