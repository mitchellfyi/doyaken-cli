---
description: Sync completed doyaken tasks back to GitHub issues
---

Run the doyaken skill: github-sync

```bash
doyaken skill github-sync $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# GitHub Issue Sync

You are syncing completed doyaken tasks back to their linked GitHub issues.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Repository: {{GIT_REMOTE}}
Close issues: {{ARGS.close-issues}}
Add comments: {{ARGS.add-comment}}

## Instructions

1. **Find Completed Tasks with GitHub References**
   Look in `.doyaken/tasks/4.done/` for task files that have:
   - External Ref field containing `github:` reference
   - Status = `done`
   - A Completed timestamp

2. **For Each Linked Task**
   Parse the External Ref to get the issue number, then:

   a) **Add Comment** (if enabled):
      Post a comment on the GitHub issue summarizing:
      - That the task was completed via doyaken
      - Key commits (from the Work Log if available)
      - Link to any PR created

   b) **Close Issue** (if enabled):
      Close the GitHub issue with a closing comment

3. **Track Synced Tasks**
   To avoid re-syncing, add a note to the task's Work Log:
   ```
   ### YYYY-MM-DD HH:MM - GitHub Synced
   - Issue #N updated
   - Status: [closed/commented]
   ```

4. **Report Summary**
   After syncing, report:
   - Tasks checked
   - Issues updated
   - Issues closed
   - Any errors

## Output Format

```
GitHub Sync Summary
===================
Repository: owner/repo

Tasks checked: N
Issues updated: N
  - #123: Closed with comment
  - #456: Comment added
Already synced: N
Errors: N (list if any)
```

## Rules

- Do NOT sync tasks that don't have a GitHub reference
- Do NOT re-sync tasks that already have "GitHub Synced" in Work Log
- Be cautious about closing issues - only close if explicitly enabled
- Include relevant commit hashes in comments when available
