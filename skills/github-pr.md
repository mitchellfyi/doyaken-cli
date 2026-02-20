---
name: github-pr
description: Create a GitHub pull request from recent commits
requires:
  - github
args:
  - name: base
    description: Base branch to merge into
    default: "main"
  - name: title
    description: PR title (auto-generated if not provided)
  - name: draft
    description: Create as draft PR
    default: "false"
---

# Create Pull Request

You are creating a GitHub pull request from recent commits.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Repository: {{GIT_REMOTE}}
Base branch: {{ARGS.base}}
Draft: {{ARGS.draft}}

## Instructions

1. **Analyze Current Branch**
   - Get current branch name
   - If on main/master, warn and stop
   - List commits that differ from base branch

2. **Gather Context**
   - Check commit messages for issue references (e.g., `Fixes #N`)
   - Read the commit log to understand the scope of changes

3. **Generate PR Content**

   **Title** (if not provided):
   - Summarize changes from commit messages
   - Keep under 72 characters

   **Body**:
   ```markdown
   ## Summary

   [Brief description of changes]

   ## Changes

   - [Change 1]
   - [Change 2]

   ## Related Issues

   - Fixes #N: [issue title]

   ## Testing

   - [ ] Tests pass locally
   - [ ] Linting passes
   - [ ] Manual testing done

   ---
   *Created via doyaken*
   ```

4. **Create the PR**
   Use GitHub MCP to create the pull request:
   - Set base branch: {{ARGS.base}}
   - Set draft status: {{ARGS.draft}}
   - Add labels based on commit content if appropriate

5. **Report Result**
   Output the PR URL and number

## Output Format

```
Pull Request Created
====================
Branch: feature-branch → main
PR: #123
URL: https://github.com/owner/repo/pull/123
Status: [ready|draft]

Related issues: #123, #456
```

## Rules

- Do NOT create PR if on main/master branch
- Do NOT create PR if there are uncommitted changes (warn first)
- Include issue references in PR body when available
