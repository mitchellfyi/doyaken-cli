---
description: Create a GitHub pull request from recent commits
---

Run the doyaken skill: github-pr

```bash
doyaken skill github-pr $ARGUMENTS
```

If doyaken is not available, apply this methodology:

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
   - Review commit messages on the branch for context
   - Check for referenced GitHub issues in commit messages

3. **Generate PR Content**

   **Title** (if not provided):
   - Summarize the changes concisely
   - Keep under 72 characters

   **Body**:
   ```markdown
   ## Summary

   [Brief description of changes]

   ## Changes

   - [Change 1]
   - [Change 2]

   ## Related Issues

   - Closes #[issue-number] (if applicable)

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
   - Add labels if applicable

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
```

## Rules

- Do NOT create PR if on main/master branch
- Do NOT create PR if there are uncommitted changes (warn first)
- Include GitHub issue references in PR body when applicable
