# Self-Healing CI Workflow

## Goal

Create a self-healing CI system that automatically creates a GitHub issue and assigns it to Copilot when CI fails on the main branch, so Copilot's coding agent can autonomously fix the failure and open a PR.

This is a safety net for regressions — not a replacement for proper CI hygiene.

## Implementation

### 1. Create `.github/workflows/self-healing-ci.yml`

The workflow must:

- Trigger on completion of the main CI workflow using `workflow_run` with `types: [completed]`
- Only run when the CI workflow conclusion is `failure`
- Only run for failures on the default branch (`main` or `master`) — feature branch failures are the developer's problem
- Pull failure logs from the failed run via GitHub API (`actions.listJobsForWorkflowRun`, `actions.downloadJobLogsForWorkflowRun`)
- Truncate logs to last 150-200 lines per failed job to stay within issue body limits
- Check for existing open issues with `ci-fix` and `automated` labels before creating — never create duplicates
- Create a well-structured issue (see template below)

### 2. Issue Body Template

The issue body is effectively a prompt for Copilot's coding agent. Use this structure:

```markdown
## CI Failure — Auto-generated

The CI workflow failed on branch `main` at commit `<SHA>`.

**Failed run:** <link to workflow run>

## Task

Analyze the failure logs below and fix the code that is causing CI to fail.

**Rules:**
- Fix the root cause in the source code, tests, or configuration
- Do NOT skip, disable, or mark any tests as expected failures
- Do NOT add `continue-on-error` or any other workaround that masks the failure
- Run the full test suite locally before submitting your PR
- Keep your changes minimal and focused on the fix

## Failure Logs

<logs from each failed job in fenced code blocks>
```

Issue metadata:
- **Title:** `[CI Fix] Build failure on \`main\` (<short SHA>)`
- **Labels:** `ci-fix`, `automated`
- **Assignee:** `copilot`

### 3. Create Labels

Ensure these labels exist (create via setup step or script):

- `ci-fix` — color `#d73a4a`, description "Automated CI failure fix request"
- `automated` — color `#0e8a16`, description "Created by automation"

### 4. Rate Limiting and Safety

- **Duplicate check** is critical — if an open `ci-fix` issue already exists, do NOT create a new one
- **Append on repeat failure** — if CI fails again on main while an issue is open, add a comment with the new failure logs instead of creating a new issue. Copilot will see the comment and iterate.
- **Escalation limit** — if there are already 3+ comments on the open `ci-fix` issue from this workflow, stop adding more and add a `needs-human` label instead
- **No infinite loops** — never assign issues to Copilot for failures in the self-healing workflow itself. Filter by workflow name.

### 5. Permissions

Minimal permissions only:

```yaml
permissions:
  issues: write
  actions: read
  checks: read
```

### 6. Optional: Auto-merge Copilot's Fix

Add a second workflow that:

- Triggers on PRs from branches matching `copilot/**`
- Waits for CI to pass on the Copilot PR
- If CI passes AND the PR only touches files involved in the original failure, auto-approves and enables auto-merge
- If CI fails on Copilot's PR, adds a comment asking Copilot to try again

**Important:** Auto-approval requires a second identity (a user cannot approve their own PR). Options:
- Create a GitHub App for auto-approval
- Use a bot account with reviewer permissions
- Skip auto-merge and rely on manual review

Document whichever approach you choose and explain the tradeoffs.

### 7. Testing

- Intentionally break a test on a branch, merge it, verify the issue gets created with correct logs and Copilot assignment
- Push a second failing commit before Copilot fixes the first — verify duplicate detection works
- Verify `needs-human` escalation fires after 3 failed iterations

## Constraints

- Do NOT run on feature branches — only the default branch
- Do NOT create issues for cancelled workflows, only failed ones
- Do NOT bypass branch protection or deploy safety mechanisms
- Do NOT auto-merge without CI passing on the fix PR
- Do NOT create issues for failures in non-CI workflows (especially not the self-healing workflow itself)
- The workflow file and issue template must be generic — not hardcoded to any specific project
