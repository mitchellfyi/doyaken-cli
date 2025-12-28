# Skill: dkpr

Polish the PR for review — generate description, update tracker, mark ready, and launch monitoring.

## When to Use

- After `/dkcommit` has pushed all changes
- When the implementation is complete and verified

## Steps

### 1. Gather Context

Detect the default branch using the shared library function (see `lib/git.sh`):

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
DEFAULT_BRANCH=$(dk_default_branch)
git log origin/$DEFAULT_BRANCH..HEAD --oneline
git diff origin/$DEFAULT_BRANCH...HEAD --stat
```

Understand the full scope of changes across all commits. Note any `.doyaken/` file changes — these should be called out in the PR description.

### 2. Generate PR Description

Check if the project has a PR description template or prompt (referenced in CLAUDE.md or `.doyaken/doyaken.md`). If so, follow that template.

Otherwise, read the PR description template from the Doyaken prompts directory (`prompts/pr-description.md`) and follow its structure. Fill in every section with specifics from the implementation.

### 3. Update the PR

Read the commit format prompt (`prompts/commit-format.md`) for title format guidance.

Use a HEREDOC for the body to preserve multi-line formatting:

```bash
gh pr edit <number> --title "<title>" --body "$(cat <<'EOF'
<generated description>
EOF
)"
```

### 4. Update Ticket (if tracker configured)

Add an implementation summary to the ticket via the configured tracker (see doyaken.md § Integrations) — what was implemented, key decisions, deviations from plan. If no tracker is configured, skip — the PR description covers this.

### 5. Present to User

**STOP and present to the user:**
- PR link
- PR description preview (title + summary section)
- Implementation summary
- Ask: "Ready to mark this PR for review?"

**Do not proceed until the user approves.**

### 6. Mark Ready and Request Reviews

On user approval:

1. Mark the PR as ready for review:
   ```bash
   gh pr ready <number>
   ```

2. Request automated reviews if configured in the project:
   ```bash
   gh pr edit <number> --add-reviewer <reviewer>
   ```

3. Set the ticket status to "In Review" via the configured tracker (see doyaken.md § Integrations).

4. If a deployment platform is configured (see doyaken.md § Integrations), check for a preview URL and include it in the PR description.

### 7. Launch Monitoring Loops

Set up recurring loops and a timeout to monitor CI and reviews. `/loop` is a built-in Claude Code skill that runs a given slash command on a recurring interval in the background. Syntax: `/loop <interval> <command>` (e.g., `/loop 2m /dkwatchci` runs `/dkwatchci` every 2 minutes). This is distinct from `/dkloop`, which runs a prompt until complete.

1. **CI monitoring** — check every 2 minutes:
   ```
   /loop 2m /dkwatchci
   ```

2. **Review monitoring** — check every 5 minutes:
   ```
   /loop 5m /dkwatchreviews
   ```

3. **Timeout** — schedule a one-shot 30-minute deadline using `CronCreate`. When it fires, it should cancel both `/loop` instances (using `CronDelete` with their job IDs) and output a status report summarizing which checks are still pending/failing and which reviews are outstanding:
   ```
   CronCreate: in 30 minutes, cancel the CI and review monitoring loops and report final status.
   ```

The loops run in the background between turns. Each invocation of `/dkwatchci` or `/dkwatchreviews` checks current status, fixes issues if found, and cancels its own loop when done. When both loops have completed and cancelled themselves, proceed to `/dkcomplete`.

## Notes

- Keep the PR description factual and specific — no filler or marketing language.
- If a ticket link is available, include it in the PR body for auto-linking.
