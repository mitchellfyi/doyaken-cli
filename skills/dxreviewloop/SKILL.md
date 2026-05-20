---
name: "dxreviewloop"
description: "Run adaptive full-scope Dex review waves until the resolved clean-pass gate succeeds."
---

# Skill: dxreviewloop

Run `/dxreview --single-pass` in fresh review-wave sessions until the resolved
review profile reaches its consecutive `CLEAN` gate. This is the default Review
phase used by `dx`.

## Workspace Boundary

`/dkreviewloop` is a one-off review command unless it is invoked from an active
`dk` lifecycle. Run it in the current checkout exactly as found.

Do not run `dk <ticket-or-description>`, `dk --no-worktree`, Phase 0 setup, or
any branch/worktree setup from this skill. Do not create, switch, rename, or
delete branches or worktrees. "Fresh review-wave session" means a fresh review
context for the same checkout; it does not mean a fresh git workspace.

## Profiles

The shell wrapper starts with `DEX_REVIEW_PROFILE` or `auto`:

- `light`: 1 clean pass, max 4 iterations, core domain sweep.
- `standard`: 2 clean passes, max 6 iterations, core sweep plus targeted domain
  sweeps.
- `thorough`: 3 clean passes, max 10 iterations, all domain sweeps.

Exact gates still override profiles:

```bash
DEX_REVIEW_CLEAN_PASSES=3 DEX_REVIEW_MAX_ITERATIONS=20 dxreviewloop
```

A wave may write `ESCALATE_THOROUGH:reason` when the current profile is too
shallow. The outer loop resets the clean counter and continues with thorough
defaults unless exact gates were pinned.

## Scope

Review the full current change set when one exists:

- committed branch changes, preferably `git diff origin/<default>...HEAD`
- staged changes via `git diff --cached`
- unstaged changes via `git diff`
- untracked files represented with `git diff --no-index -- /dev/null <file>`

If no changes or comparable branch diff exist, default to reviewing the entire
tracked codebase. Do not stop only because `git diff` is empty; use the
caller-supplied file inventory commands as the authoritative scope.

## Per-Pass Contract

Each iteration is a fresh review-wave CLI session. It must fix verified findings
that are safe to fix in the caller-supplied scope.

A pass that only reports findings is incomplete. If a wave finds verified issues,
the orchestrator fixes them, re-runs the affected checks/review, writes
`FINDINGS_FIXED:N`, resets the clean counter, and immediately continues the loop.
Do not stop after a finding report. Stop only after the clean-pass gate succeeds,
or when a real blocker remains after attempted local resolution.

When running inside a `dx` lifecycle, mark the pass busy before waiting on the
fresh wave and remove the marker immediately after it returns:

```bash
source "${DEX_DIR:-$HOME/work/dex}/lib/common.sh"
SESSION_ID="${DEX_SESSION_ID:-$(dx_session_id)}"
BUSY_FILE="$(dx_phase_busy_file "$SESSION_ID" 3)"
printf '%s\t%s\n' "$(date +%s)" "dxreviewloop pass ${ITERATION}/${MAX_ITERATIONS}; clean ${CLEAN_COUNT}/${REQUIRED_CLEAN}" > "$BUSY_FILE"
# launch and wait for exactly one fresh review-wave CLI session
rm -f "$BUSY_FILE" "$(dx_phase_busy_notice_file "$SESSION_ID" 3)"
```

The review-session prompt must include the full-scope commands, review profile,
context-pack path from `dx_review_context_file`, result path, and instruction to
follow `prompts/review-wave.md`.

The fresh wave session is already the independent reviewer; profiles determine
how many domain sweeps it performs.

If fresh review-wave CLI sessions are unavailable, stop with
`BLOCKED:review-session-unavailable`; do not simulate fresh passes in the same
context.

## Counting

- `CLEAN`: increment clean count.
- `FINDINGS_FIXED:N`, `FINDINGS:N`, `BLOCKED:reason`: reset clean count and continue unless a real blocker remains.
- `ESCALATE_THOROUGH:reason`: reset clean count and continue as thorough.
- Missing/unknown result: treat as non-clean and stop if unrecoverable.

Only `CLEAN` can increment the counter.

## Report

Print:

```markdown
## dxreviewloop Result

- Scope: full current change set | entire codebase
- Profile: light | standard | thorough
- Iterations: N / max
- Consecutive clean: M / required
- Result: SUCCESS | SAFETY-NET-EXIT | BLOCKED
- Findings fixed this run: K
```

If the loop exits without success, list residual or recurring findings. Do not
commit, push, create or update PRs, or request external reviewers.
