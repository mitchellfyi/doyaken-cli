# Skill: dkcomplete

Final verification and ticket closure.

## When to Use

- After CI and review monitoring both report success
- When all checks are green and all reviews are approved

## Steps

### 1. Final Verification

Confirm all conditions are met:

1. **CI**: All checks green.
   ```bash
   gh pr checks $(gh pr view --json number -q .number)
   ```

2. **Reviews**: All reviews approved, no unresolved comments.
   ```bash
   REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
   PR_NUM=$(gh pr view --json number -q .number)
   gh api repos/$REPO/pulls/$PR_NUM/reviews
   ```

3. **Tasks**: All tasks marked as completed (iterate through task list).

If any condition is not met, report what's outstanding and stop.

### 2. Update Ticket (if tracker configured)

Mark the ticket as done via the configured tracker (see doyaken.md § Integrations). Add a final summary — what was implemented, key decisions, follow-up work. If no tracker is configured, skip — the PR and conversation serve as the record.

### 3. Print Summary

Output a completion summary to the terminal:

```
Ticket: <id> — <title>       (or "No ticket — <branch name>")
URL:    <ticket-url>          (if available)
PR:     <pr-url>
Status: Work complete — awaiting merge (user's decision)

Files changed: X
Lines: +Y / -Z
Commits: N
Tests: M new test cases

Reviews:
  - <reviewer>: <status> (N comments addressed)
  ...

CI: All checks green (X/X passed)
```

### 4. Signal Completion

If the phase audit loop is active (`DOYAKEN_LOOP_ACTIVE=1` in environment):

1. Write a completion signal file so the Stop hook detects it reliably (uses `dk_session_id` from `lib/session.sh` — same logic as `phase-loop.sh`):
   ```bash
   source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
   mkdir -p "$DK_LOOP_DIR"
   touch "$(dk_complete_file "${DOYAKEN_SESSION_ID:-$(dk_session_id)}")"
   ```

2. Output the completion promise string:
   ```
   DOYAKEN_TICKET_COMPLETE
   ```

Both mechanisms signal the Stop hook that the ticket lifecycle is finished and Claude can stop.

### 5. Worktree Cleanup Reminder

Set a one-shot reminder to prompt for worktree cleanup:

```
remind me in 10 minutes to check for stale worktrees — run dkls and dkrm for any that are no longer needed
```

## Notes

- Do not merge the PR — that's the user's decision.
- If follow-up work was identified during implementation, mention it in the summary but do not create new tickets unless asked.
- The ticket should be marked "Done" (if a tracker is available) even if the PR hasn't been merged yet — the work is complete from the agent's perspective.
- The completion promise (`DOYAKEN_TICKET_COMPLETE`) must only be output AFTER all verification in step 1 passes. Never output it prematurely.
