# AI Automation — Agent Guidelines

This directory contains GitHub Actions workflows for automated CI repair, code review, and maintenance using Claude Code.

## Directory Structure

```
.github/ai-automation/
├── AGENTS.md          ← You are here
├── README.md          ← Full documentation
├── prompts/           ← Claude instruction files
│   ├── ci-fix.md
│   ├── ci-retry.md
│   ├── code-review.md
│   ├── mention.md
│   ├── review-fix.md
│   ├── test-coverage.md
│   └── maintain-*.md
└── templates/         ← Reusable text content
    ├── ci-fix-issue.md
    ├── ci-fix-pr-draft.md
    ├── ci-fix-pr-done.md
    ├── conflict-detected.md
    └── ...
```

The workflow files live in `.github/workflows/` (GitHub requirement) and are prefixed `ai-automation-*`.

## What Each Workflow Does

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci-fix` | CI fails on main | Creates issue + draft PR, Claude fixes, marks ready |
| `pr-handler` | CI complete / review submitted | Retries failed fixes, handles review comments, auto-merges |
| `code-review` | CI passes on PR | Reviews all PRs automatically |
| `mention` | `@claude` in comment | Responds to direct mentions from collaborators |
| `conflict-resolution` | PR opened/synced | Detects merge conflicts, asks Copilot to resolve |
| `dependabot-automerge` | Dependabot PR + CI passes | Auto-merges security/patch updates |
| `maintenance` | Daily schedule | Proactive codebase maintenance by domain |
| `test-coverage` | Weekly schedule | Generates test coverage report |

## Working with Prompts

**Location:** `.github/ai-automation/prompts/`

Each prompt file contains instructions for Claude. Workflows load these at runtime and combine them with dynamic context (error logs, branch names, etc.).

**When to edit prompts:**
- Changing Claude's behaviour or approach
- Adding new checks or validations
- Improving fix quality or consistency

**Prompt conventions:**
- Use Markdown headings for sections
- Include concrete examples where helpful
- Keep instructions actionable and specific
- Reference project files by path when relevant

## Working with Templates

**Location:** `.github/ai-automation/templates/`

Templates contain reusable text content for issues, PRs, and comments. They use `{{VARIABLE}}` placeholders that workflows substitute at runtime.

**When to edit templates:**
- Changing message formatting or wording
- Adding new information fields
- Improving clarity for humans reading the output

**Template conventions:**
- Use `{{VARIABLE}}` for substitution (uppercase, underscores)
- Keep Markdown formatting simple and readable
- Include context that helps humans understand the automation

## Modifying Workflows

The workflow files are in `.github/workflows/ai-automation-*.yml`. Key patterns:

**Loading prompts:**
```yaml
- name: Build prompt
  run: |
    cat .github/ai-automation/prompts/ci-fix.md
```

**Loading templates:**
```yaml
- name: Build PR body
  run: |
    sed -e "s|{{RUN_URL}}|$RUN_URL|g" \
        -e "s|{{ISSUE_NUM}}|$ISSUE_NUM|g" \
        .github/ai-automation/templates/ci-fix-pr-draft.md > /tmp/pr_body.md
```

**Concurrency to prevent conflicts:**
```yaml
concurrency:
  group: ai-fix-${{ github.repository }}
  cancel-in-progress: false
```

## Adding a New Workflow

1. Create the workflow file: `.github/workflows/ai-automation-{name}.yml`
2. Create a prompt file: `.github/ai-automation/prompts/{name}.md`
3. Create any needed templates in `.github/ai-automation/templates/`
4. Update the README.md with documentation
5. Test on a single repo before syncing to all repos

## Key Constraints

- **No duplicate issues/PRs:** Always check for existing open items before creating new ones
- **Draft/Ready cycle:** Move PRs to draft while Claude works, ready when done
- **Retry limits:** Cap retries (default: 3) to prevent infinite loops
- **Label-based filtering:** Use `ai-fix`, `ai-maintenance` labels to identify AI-managed PRs
- **Concurrency groups:** Prevent multiple workflow runs from conflicting

## Syncing Across Repos

These workflows are used across multiple project repos. When making changes:

1. Test changes on one repo first
2. Verify CI passes and automation works as expected
3. Apply the same changes to all project repos
4. Commit with a clear message describing the change

Project repos (keep in sync):
- curated.cx
- doyaken.ai
- evald.ai
- lofield.fm
- mitchellbryson.com
- wemakesense.ai
- kell.cx
- doyaken-cli

## Debugging

- **Workflow logs:** Actions tab → Select run → View logs
- **Claude output:** Look for the Claude Code action step
- **Skipped runs:** Check the initial "Check for existing..." steps
- **Retry tracking:** The PR handler counts workflow runs, not commits

## Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Duplicate issues created | Missing deduplication check | Add existing issue check before creation |
| Workflow not triggering | Wrong event/branch filter | Check `on:` section in workflow |
| Claude not pushing | Git auth lost after action | Add `git remote set-url` with token |
| Infinite CI loop | Draft not skipping CI | Add `if: github.event.pull_request.draft != true` |
| Auto-merge not working | Missing review or failing CI | Check both conditions are met |
