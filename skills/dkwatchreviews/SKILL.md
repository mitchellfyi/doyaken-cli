# Skill: dkwatchreviews

Monitor PR review comments and address feedback from automated and human reviewers.

## When to Use

- Scheduled via `/loop 5m /dkwatchreviews` from `/dkpr` after `gh pr ready`
- Can also be invoked manually for a one-off review check

## How It Works

Each invocation is a **single check cycle** — `/loop` handles the scheduling. The session context carries state between invocations naturally.

## Steps

### 1. Get PR Info

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
PR_NUM=$(gh pr view --json number -q .number)
```

### 2. Check for Reviews and Comments

```bash
gh api repos/$REPO/pulls/$PR_NUM/reviews
gh api repos/$REPO/pulls/$PR_NUM/comments
```

### 3. Classify Each New Comment

For each unaddressed comment (comments not yet replied to or resolved):

| Type | Action |
|------|--------|
| **Request-change** | Implement the fix, verify, commit, push, reply |
| **Question** | Reply with an answer based on code context |
| **Nitpick** | Fix if trivial (< 2 minutes), reply explaining the fix |
| **Suggestion** | Evaluate — apply if it improves the code, reply either way |
| **Approval** | Note it, no action needed |

### 4. Address Request-Changes

For each request-change comment:

1. Read the referenced code and understand the concern.
2. Implement the fix.
3. Run targeted verification (only the affected check — scope to the relevant package/app).
4. Commit with `fix(review): <description>`.
5. Push.
6. Reply to the PR comment explaining what was changed:
   ```bash
   gh api repos/$REPO/pulls/$PR_NUM/comments/<comment-id>/replies -f body="Fixed in <commit-sha>. <brief explanation>"
   ```

### 5. Evaluate Completion

**All reviews approved, no unresolved comments:**
1. Cancel the review monitoring loop: use `CronDelete` with the job ID.
2. Report:
   - Total reviews: X (Y approved, Z with comments)
   - Comments addressed: N
   - Source breakdown: automated vs human
3. If `/dkwatchci` loop is also done (all checks green), proceed to `/dkcomplete`.

**Reviews still pending or comments unresolved:**
- Do nothing further. Wait for the next loop invocation.

### 6. Escalation

**STOP, cancel all loops, and escalate to the user when:**
- A reviewer requests a significant **architectural change** (affects multiple files, changes the approach).
- There's a **disagreement** with a reviewer on the correct approach.
- A reviewer's comment is **unclear** and you can't determine the right fix.
- A **human reviewer** explicitly requests changes — address the feedback but flag it for the user's awareness.

## Timeout

The monitoring loop should be set up alongside a **one-shot 30-minute timeout** via `/dkpr` Step 7 (shared with `/dkwatchci`). The timeout uses `CronCreate` to schedule a one-shot job. When it fires, it cancels both monitoring loops (using `CronDelete` with their job IDs) and outputs a status report:
- Which reviewers have responded and their verdict (approved/changes requested/commented)
- Which reviewers haven't responded yet
- Outstanding unresolved comments with links
- Whether CI is still pending

The 30-minute window is tuned for automated reviewers (typically respond in 5-10 minutes). Human reviewers may take longer — see Notes below.

## Notes

- Automated reviewers typically respond within 5-10 minutes.
- Human reviewers may take hours — the 30m timeout is designed for automated reviews.
- If a human review comes in later, the user can re-run `/loop 5m /dkwatchreviews` or address it manually.
- Do not dismiss review comments — always reply, even if the fix is trivial.
