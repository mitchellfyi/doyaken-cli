# AI Automation

Automated CI repair, code review, interactive assistance, and test coverage reporting using Claude Code.

## How It Works

### CI Fix & Retry Loop

```
CI fails on main
       │
       ▼
┌──────────────────┐
│  Create issue    │  ← Tracking issue with error logs, failed run link
│  Create draft PR │  ← Linked to issue, labels auto-created if missing
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Claude fixes    │  ← Reads CI workflow, reproduces errors, fixes code
│  Mark PR ready   │  ← Updates PR body with changes summary
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  CI runs on PR   │  ← Quality gates run on the fix PR
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 CI fails  CI passes ──► Waits for reviewer
    │                        │
    ▼                   ┌────┴────┐
┌────────┐              │         │
│ Move   │         Requests    Approves /
│ to     │         changes     comments
│ draft  │              │         │
│ Claude │              ▼         ▼
│ retries│         ┌────────┐ ┌──────────┐
│ (max 3)│         │ Move   │ │ Auto-    │
└────┬───┘         │ to     │ │ merge    │
     │             │ draft  │ └──────────┘
     │             │ Claude │
     │             │ fixes  │
     │             └────┬───┘
     │                  │
     └──────────────────┴──► Mark ready → CI runs again (loop)

Retry limit reached → issue labelled "needs-human" → PR closed → fresh cycle on next failure
```

### @claude Mentions

```
Team member comments "@claude ..." on issue or PR
       │
       ▼
┌──────────────────┐
│  React with 👀   │  ← Acknowledges the mention
│  Read thread     │  ← Gathers full conversation context
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
  Issue      PR
    │         │
    ▼         ▼
 Read-only   Full access
 Respond as  Make changes,
 comment     push, comment
```

## Workflows

All workflow files live in `.github/workflows/` (required by GitHub Actions) and are prefixed with `ai-automation-` for namespacing.

### `ai-automation-ci-fix.yml` — Detect & Fix

Triggers when the CI workflow fails on `main`.

1. **Checks** for an existing open fix PR (skips if one exists)
2. **Creates** labels (`ai-fix`, `automation`, `ci`, `needs-human`) if they don't exist
3. **Collects** failure details: failed jobs, failed steps, error logs (8KB)
4. **Creates** a tracking issue with full error output
5. **Creates** a draft PR linked to the issue
6. **Runs** Claude Code to diagnose and fix the errors
7. **Marks** the PR ready for review (triggers CI on the fix)

### `ai-automation-code-review.yml` — Code Review

Reviews all PRs after CI passes successfully.

- Triggers on `workflow_run` (CI success)
- Skips: main/master branch, draft PRs, already-reviewed commits
- Uses concurrency groups to cancel in-progress reviews when new commits are pushed
- Reads the PR description and linked issues for context
- Checks for documentation sync when source code changes
- Submits a GitHub review: approves, requests changes, or leaves comments
- The review event triggers the auto-merge check in the PR handler

### `ai-automation-maintenance.yml` — Scheduled Maintenance

Proactive codebase maintenance on a daily schedule.

- Each domain runs daily at its own hour (12am–7am UTC) and via `workflow_dispatch`
- Skips if an open issue or PR already exists for the domain
- Creates a tracking issue → draft PR → Claude reviews and improves → marks PR ready
- If no changes needed, closes the PR and issue automatically

| Domain        | Schedule | Focus                                                             |
| ------------- | -------- | ----------------------------------------------------------------- |
| `code`        | 12am UTC | Code quality, architecture, patterns, dead code, error handling   |
| `tests`       | 1am UTC  | Test coverage gaps, test quality, flaky tests, missing edge cases |
| `docs`        | 2am UTC  | README accuracy, stale docs, broken links, missing documentation  |
| `ci`          | 3am UTC  | CI pipeline efficiency, quality scripts, dependency audit         |
| `agents`      | 4am UTC  | CLAUDE.md, AGENTS.md, prompt library, skill definitions           |
| `security`    | 5am UTC  | OWASP patterns, input validation, auth, secrets, headers          |
| `deps`        | 6am UTC  | Vulnerabilities, outdated packages, unused deps, license audit    |
| `performance` | 7am UTC  | Bundle size, images, rendering, data fetching, code splitting     |

### `ai-automation-pr-handler.yml` — Review, Retry & Merge

Manages the lifecycle of AI-managed PRs (both `ai-fix` and `ai-maintenance`).

**Job: handle-review-comments**

- Triggers on `pull_request_review` (changes requested)
- Acts on PRs with `ai-fix` or `ai-maintenance` label
- Moves PR to draft → Claude reads review feedback and fixes → marks PR ready

**Job: fix-pr-ci-failure**

- Triggers on `workflow_run` (CI failure on `ai/fix-ci-*` or `ai/maintain-*` branches)
- Moves PR to draft → Claude retries fix → marks PR ready
- Tracks retries by counting workflow runs (max 3)
- When retry limit is reached: labels the tracking issue `needs-human`, posts a comment, closes the PR, and deletes the branch

**Job: check-auto-merge**

- Triggers on `workflow_run` (CI success) and `pull_request_review` (submitted)
- Finds PRs with `ai-fix` or `ai-maintenance` label
- Merges when **both** conditions are met: CI passing AND at least one review submitted (not requesting changes)
- Whichever event fires last (CI passing or review submission) will find both conditions met and merge
- No scheduler needed — purely event-driven
- Works with any reviewer: AI tools (CodeRabbit, Copilot, etc.) or humans

### `ai-automation-mention.yml` — Interactive @claude

Responds to `@claude` mentions in issue and PR comments.

- Triggers on `issue_comment` (created)
- Only responds to repository collaborators (OWNER, MEMBER, COLLABORATOR)
- Reacts with eyes emoji to acknowledge the mention
- Gathers full thread context (issue/PR body + recent comments)
- **On PRs:** Full write access — can make code changes, run quality gates, push commits
- **On issues:** Read-only — investigates and responds as a comment
- Uses concurrency groups per issue/PR to handle rapid re-mentions

### `ai-automation-test-coverage.yml` — Test Coverage Report

Generates a weekly test coverage analysis.

- Triggers on schedule (Monday 9am UTC) and manual `workflow_dispatch`
- Claude discovers the test setup from the CI workflow — no hardcoded commands
- Runs tests with coverage, analyses results, identifies gaps
- Creates or updates a GitHub issue with prioritised findings
- Deduplicates: updates an existing open `test-coverage` issue if one exists

## Draft/Ready Cycle

The system uses GitHub's draft PR mechanism to prevent CI from running while Claude works:

1. PR handler detects work needed (CI failure or review comments)
2. PR is moved to **draft** (CI skips draft PRs)
3. Claude makes fixes and pushes commits
4. PR is marked **ready for review** (triggers CI)
5. If CI fails again, the cycle repeats (up to the retry limit)

## Setup

### 1. Configure Secrets

Add these secrets to your repository (Settings → Secrets and variables → Actions):

#### `GH_PAT` — GitHub Personal Access Token

A fine-grained PAT with permissions to create branches, PRs, and issues.

1. Go to https://github.com/settings/tokens?type=beta
2. Click "Generate new token"
3. Select the repository (or all repositories)
4. Grant these permissions:
   - **Contents**: Read and write
   - **Issues**: Read and write
   - **Pull requests**: Read and write
   - **Actions**: Read
   - **Workflows**: Read and write
5. Copy the token and add it as a repository secret named `GH_PAT`

> **Why not `GITHUB_TOKEN`?** The built-in `GITHUB_TOKEN` cannot trigger other workflows (e.g., CI on the fix PR). A PAT is required to create the feedback loop.
>
> **Why `GH_PAT`?** GitHub blocks secrets starting with `GITHUB_`.

#### Claude Code Authentication

Configure **one** of these secrets. The workflows accept both — whichever is set will be used.

**Option 1: `CLAUDE_CODE_OAUTH_TOKEN`** (recommended)

1. Install Claude Code CLI: `npm install -g @anthropic-ai/claude-code`
2. Run `claude setup-token` and follow the prompts
3. Add the token as a repository secret named `CLAUDE_CODE_OAUTH_TOKEN`

**Option 2: `ANTHROPIC_API_KEY`**

1. Get an API key from https://console.anthropic.com/
2. Add it as a repository secret named `ANTHROPIC_API_KEY`

### 2. Configure CI Workflow

The automation triggers on completion of a workflow named **`CI`**. If your CI workflow has a different name, update the `workflows:` field in `ai-automation-ci-fix.yml`, `ai-automation-code-review.yml`, and `ai-automation-pr-handler.yml`:

```yaml
on:
  workflow_run:
    workflows:
      - Your CI Workflow Name # ← Change this
```

### 3. Draft PR Behavior

The CI workflow should skip draft PRs so the automation doesn't create a feedback loop before Claude finishes fixing. Add this condition to your CI jobs:

```yaml
jobs:
  your-job:
    if: github.event.pull_request.draft != true
```

And include `ready_for_review` in PR event types:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
```

### 4. Code Review

The `ai-automation-code-review.yml` workflow automatically reviews all PRs after CI passes. This provides the review needed for auto-merge without any external tools.

You can also use additional AI reviewers alongside Claude:

- [CodeRabbit](https://coderabbit.ai/) — submits GitHub reviews with approve/request changes
- [GitHub Copilot](https://github.com/features/copilot) — built-in code review
- [Sourcery](https://sourcery.ai/) — automated code review

Any reviewer's `pull_request_review` event triggers the auto-merge check. If a reviewer requests changes on an `ai-fix` or `ai-maintenance` PR, Claude addresses them automatically.

Without any reviewer configured, PRs will wait until a human reviews them.

### 5. Labels (Optional)

Labels are created automatically on first run. If you prefer to create them manually:

| Label               | Description                                                                     | Color     |
| ------------------- | ------------------------------------------------------------------------------- | --------- |
| `ai-fix`            | Automated CI fix by AI                                                          | `#7057ff` |
| `ai-maintenance`    | Automated maintenance by AI                                                     | `#0e8a16` |
| `automation`        | Automated workflow                                                              | `#ededed` |
| `ci`                | CI/CD related                                                                   | `#fbca04` |
| `needs-human`       | Automated fix failed — needs human intervention                                 | `#d73a4a` |
| `test-coverage`     | Weekly test coverage report                                                     | `#0e8a16` |
| `maintain:{domain}` | Maintenance domain (code, tests, docs, ci, agents, security, deps, performance) | `#c5def5` |

## Prompt Files

AI prompts are stored as separate Markdown files in `.github/ai-automation/prompts/` so they can be edited without touching the workflow YAML:

| File                      | Used by                       | Purpose                                      |
| ------------------------- | ----------------------------- | -------------------------------------------- |
| `ci-fix.md`               | `ai-automation-ci-fix`        | Instructions for diagnosing and fixing CI    |
| `ci-retry.md`             | `ai-automation-pr-handler`    | Instructions for retrying after a failed fix |
| `review-fix.md`           | `ai-automation-pr-handler`    | Instructions for addressing review comments  |
| `code-review.md`          | `ai-automation-code-review`   | Instructions for reviewing PRs               |
| `mention.md`              | `ai-automation-mention`       | Instructions for responding to @claude       |
| `test-coverage.md`        | `ai-automation-test-coverage` | Instructions for generating coverage reports |
| `maintain-code.md`        | `ai-automation-maintenance`   | Maintenance: code quality and patterns       |
| `maintain-tests.md`       | `ai-automation-maintenance`   | Maintenance: test coverage and quality       |
| `maintain-docs.md`        | `ai-automation-maintenance`   | Maintenance: documentation sync              |
| `maintain-ci.md`          | `ai-automation-maintenance`   | Maintenance: CI/CD and quality scripts       |
| `maintain-agents.md`      | `ai-automation-maintenance`   | Maintenance: AI agent configuration          |
| `maintain-security.md`    | `ai-automation-maintenance`   | Maintenance: application security            |
| `maintain-deps.md`        | `ai-automation-maintenance`   | Maintenance: dependency audit and updates    |
| `maintain-performance.md` | `ai-automation-maintenance`   | Maintenance: performance optimization        |

Each workflow loads its prompt file at runtime using a "Build prompt" step that combines the static instructions from the file with dynamic context (error logs, branch name, PR number, etc.).

## Customization

### Retry Limit

The default retry limit is 3 attempts (tracked by workflow run count). To change it, edit `MAX_RETRIES` in `ai-automation-pr-handler.yml`:

```yaml
MAX_RETRIES=3
```

### Claude Max Turns

Adjust how many turns Claude gets per task:

- Initial fix: `--max-turns 50` (in `ai-automation-ci-fix.yml`)
- CI retry: `--max-turns 30` (in `ai-automation-pr-handler.yml`)
- @claude mention: `--max-turns 25` (in `ai-automation-mention.yml`)
- Review fix: `--max-turns 20` (in `ai-automation-pr-handler.yml`)
- Test coverage: `--max-turns 20` (in `ai-automation-test-coverage.yml`)
- Code review: `--max-turns 15` (in `ai-automation-code-review.yml`)
- Maintenance: `--max-turns 30` (in `ai-automation-maintenance.yml`)

### Branch Naming

- Fix branches: `ai/fix-ci-YYYYMMDD-HHMMSS`
- Maintenance branches: `ai/maintain-{domain}-YYYYMMDD`

The PR handler retry job detects both `ai/fix-ci-*` and `ai/maintain-*` prefixes. If you change these, update the workflow files accordingly.

### Maintenance Schedule

Each domain runs daily at its own hour (12am–4am UTC). To change the schedule, edit the cron expressions in `ai-automation-maintenance.yml`:

```yaml
schedule:
  - cron: "0 0 * * *" # 12am UTC — code
  - cron: "0 1 * * *" # 1am UTC  — tests
  - cron: "0 2 * * *" # 2am UTC  — docs
  - cron: "0 3 * * *" # 3am UTC  — ci
  - cron: "0 4 * * *" # 4am UTC  — agents
  - cron: "0 5 * * *" # 5am UTC  — security
  - cron: "0 6 * * *" # 6am UTC  — deps
  - cron: "0 7 * * *" # 7am UTC  — performance
```

Each domain skips if an open issue or PR already exists for it, so runs only produce work when the previous run's PR has been merged or closed.

You can also trigger any domain manually via `workflow_dispatch` in the GitHub Actions UI.

To add a new domain, create a prompt file at `.github/ai-automation/prompts/maintain-{domain}.md` and add the domain to the `case` statements in the workflow.

### Test Coverage Schedule

The default schedule is Monday 9am UTC. To change it, edit the cron expression in `ai-automation-test-coverage.yml`:

```yaml
schedule:
  - cron: "0 9 * * 1" # ← Change this
```

You can also trigger it manually via `workflow_dispatch` in the GitHub Actions UI.

## Troubleshooting

### CI still runs on draft PRs

Add `if: github.event.pull_request.draft != true` to your CI jobs.

### Auto-merge not triggering

- Check that the PR has the `ai-fix` or `ai-maintenance` label
- Check that the PR is not a draft
- Check that CI has passed (all checks green)
- Check that at least one review has been submitted (not requesting changes)
- If no AI reviewer is configured, a human must review the PR

### Claude keeps failing

- Check the Actions logs for Claude's output
- The issue will have the original error logs
- After 3 failed retry attempts, the PR is closed and the tracking issue is labelled `needs-human`
- A fresh fix cycle will start automatically on the next CI failure on main

### @claude not responding

- Check the comment author has OWNER, MEMBER, or COLLABORATOR association
- Check that the comment contains `@claude` (case-sensitive)
- Check the Actions logs for the mention workflow run

### Infinite loop / too many runs

- The `ai-automation-ci-fix` job skips if there's already an open `ai-fix` PR
- The retry job caps at 3 attempts (MAX_RETRIES=3)
- CI is skipped on draft PRs, preventing runs before Claude finishes
- When retries are exhausted, the PR is closed to break the loop
