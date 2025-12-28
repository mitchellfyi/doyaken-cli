Before stopping, audit the pull request quality.

## Step 1: PR description

Read the PR description you generated and check:
- Does it explain WHAT changed? (Brief summary of the implementation)
- Does it explain WHY? (Link to ticket, business context, motivation)
- Are key technical decisions documented? (Why this approach over alternatives)
- Are there testing instructions? (How a reviewer can verify the changes)
- Is the description clear and concise? (No filler, no unnecessary detail)

If the description is weak in any area, improve it now.

## Step 2: PR scope

Review the PR diff against the original plan:
- Does the diff match the planned scope? Nothing more, nothing less.
- Are there any unrelated changes that crept in? (Formatting changes in untouched files, refactors outside scope)
- Are there any missing changes that should be included? (Did you forget to commit something?)

If there are unrelated changes, revert them. If there are missing changes, add them.

## Step 3: PR metadata

Check:
- Is the PR targeting the correct base branch?
- Are labels or tags applied if the project uses them?
- Is the ticket linked (if tracker configured)?

## Step 4: User approval

Has the user explicitly approved the PR description and confirmed it's ready to be marked for review?

If the user hasn't responded, wait. Do not proceed without their approval.

## Completion criteria

Only output PHASE_4_COMPLETE when:
- PR description is clear, complete, and explains what/why
- PR scope matches the plan — no unrelated changes, nothing missing
- The user has explicitly approved

Before outputting PHASE_4_COMPLETE, write the completion signal file so the Stop hook detects it:

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh" && touch "$(dk_complete_file "$(dk_session_id)")"
```
