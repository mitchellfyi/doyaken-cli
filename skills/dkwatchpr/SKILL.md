# Skill: dkwatchpr

Monitor PR review comments and address feedback from automated and human reviewers.

## When to Use

- Scheduled via `/loop 5m /dkwatchpr` from `/dkpr` after `gh pr ready`
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

### 3. Address Comments

If there are unaddressed comments (comments not yet replied to or resolved):

Run `/dkprreview` to critically evaluate and respond to each comment.

`/dkprreview` will:
- Classify each comment (bug, security, request-change, question, suggestion, nitpick, approval)
- Critically evaluate whether to fix, push back, answer, or escalate
- Implement and push fixes for accepted comments
- Reply to every comment with reasoning
- Return a list of escalations (if any)

If `/dkprreview` reports escalations, proceed to Step 5 (Escalation).

### 4. Evaluate Completion

**All reviews approved, no unresolved comments:**
1. Cancel the review monitoring loop: use `CronDelete` with the job ID.
2. Report:
   - Total reviews: X (Y approved, Z with comments)
   - Comments addressed: N
   - Source breakdown: automated vs human
3. If `/dkwatchci` loop is also done (all checks green), proceed to `/dkcomplete`.

**Reviews still pending or comments unresolved:**
- Do nothing further. Wait for the next loop invocation.

### 5. Escalation

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
- If a human review comes in later, the user can re-run `/loop 5m /dkwatchpr` or address it manually.
- Do not dismiss review comments — always reply, even if the fix is trivial.
