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
   - Look for related task files in `.doyaken/tasks/3.doing/` or recently moved to `4.done/`
   - Check commit messages for task references `[task-id]`
   - Read the task file(s) for context

3. **Generate PR Content**

   **Title** (if not provided):
   - Use task title if single task
   - Summarize changes if multiple tasks
   - Keep under 72 characters

   **Body**:
   ```markdown
   ## Summary

   [Brief description of changes]

   ## Changes

   - [Change 1]
   - [Change 2]

   ## Related Tasks

   - [task-id]: [task title]

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
   - Add labels if task had labels/priority

5. **Update Task Files**
   For each related task, add to Links section:
   ```
   - PR: #NNN
   ```

6. **Report Result**
   Output the PR URL and number

## Output Format

```
Pull Request Created
====================
Branch: feature-branch → main
PR: #123
URL: https://github.com/owner/repo/pull/123
Status: [ready|draft]

Related tasks updated:
- 003-001-add-feature.md
```

## Rules

- Do NOT create PR if on main/master branch
- Do NOT create PR if there are uncommitted changes (warn first)
- Include task references in PR body
- Link PR back to task files
