Before stopping, verify all completion criteria are met.

## Step 1: CI status

Run: `gh pr checks $(gh pr view --json number -q .number)`

Are ALL status checks green? If any check is failing or pending:
- Investigate the failure
- Fix the issue
- Push the fix
- Wait for checks to re-run and verify they pass

Do not proceed if any check is red or pending.

## Step 2: Reviews

Check review status:
- Are all requested reviews submitted?
- Are all reviews approved (no "changes requested")?
- Are there any unresolved review comments or threads?

If there are unresolved comments, address them, push fixes, and re-check.

## Step 3: Ticket status

If a tracker is configured (see doyaken.md):
- Is the ticket updated to "Done" or equivalent?
- Is a final summary added to the ticket?

If no tracker is configured, skip this step.

## Step 4: Completion signal

If all checks above pass, run /dkcomplete to generate the final summary and signal completion.

/dkcomplete writes the `.complete` signal file that the Stop hook checks. If for any reason /dkcomplete did not write the signal file, write it manually:

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh" && touch "$(dk_complete_file "$(dk_session_id)")"
```

## Completion criteria

Only output DOYAKEN_TICKET_COMPLETE when:
- All CI checks are green
- All reviews are approved with no unresolved comments
- Ticket is updated (if tracker configured)
- /dkcomplete has been run successfully
- The completion signal file exists (verify with the bash command above if unsure)
