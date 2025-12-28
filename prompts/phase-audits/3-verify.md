Before stopping, audit the verification results and commit quality.

## Step 1: Verification checks

Confirm every quality gate passed:
- Format: PASS? If not, run the formatter and re-check.
- Lint: PASS? If not, fix lint errors (don't disable rules).
- Typecheck: PASS? If not, fix type errors.
- Tests: ALL passing? No skipped tests, no flaky failures? If any test was skipped or failed intermittently, investigate and fix the root cause.

Run /dkverify if you haven't already, or if you've made changes since the last run.

## Step 2: Commit quality

Review your commit history (`git log --oneline origin/<default-branch>..HEAD`):
- Are commits atomic? Each commit should contain one logical change.
- Do commit messages follow conventional format? (`type(scope): description`)
- Are there any commits that should be split or combined?
- Are there any files that should NOT have been committed?
  - Generated files that should be in .gitignore
  - Debug logs or temporary files
  - Files containing secrets or credentials

## Step 2.5: `.doyaken/` in commits

Check if `.doyaken/` files were modified during implementation:
- If yes, ensure they're committed (ideally in a separate `docs(.doyaken): sync project config` commit).
- If `.doyaken/` changes are mixed into code commits, split them out.
- If `.doyaken/` changes are unstaged/uncommitted, stage and commit them now.

## Step 3: Diff review

Run `git diff --stat origin/<default-branch>` and review:
- Does the overall diff look clean and focused?
- Are there any unexpected files in the diff?
- Is the total scope of changes proportional to the task?

## Step 4: Push

Has the code been pushed to origin? If not, push it.

If you pushed and got errors (e.g., remote rejection, hook failures), fix the issues and push again.

## Completion criteria

Only output PHASE_3_COMPLETE when:
- All quality checks pass (format, lint, typecheck, tests)
- Commits are clean and atomic with conventional messages
- No unwanted files in the diff
- Any `.doyaken/` changes are committed cleanly
- Code is pushed to origin successfully

Before outputting PHASE_3_COMPLETE, write the completion signal file so the Stop hook detects it:

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh" && touch "$(dk_complete_file "$(dk_session_id)")"
```
