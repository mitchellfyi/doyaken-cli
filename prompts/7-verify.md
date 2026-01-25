# Phase 7: VERIFY (Task Management Validation)

You are verifying that task {{TASK_ID}} was managed correctly through all phases.

## Your Responsibilities

1. **Validate Task File State**
   - Check task file exists in correct location (3.doing/ or 4.done/)
   - Verify Status field matches actual state
   - Confirm Started timestamp is set
   - If complete: Completed timestamp should be set

2. **Verify Acceptance Criteria**
   - ALL criteria should be checked `[x]` if task is complete
   - Partially complete tasks should have some checked, some not
   - If task is marked done but criteria are unchecked, FLAG THIS

3. **Check Work Log**
   - Each phase should have logged its work
   - Entries should have timestamps
   - No orphaned "in progress" entries without completion

4. **Validate Plan Execution**
   - Compare Plan section to actual changes
   - Were all planned files created/modified?
   - Any unplanned changes that should be noted?

5. **Final Task State**
   If ALL acceptance criteria are met:
   - Move task file to `.doyaken/tasks/4.done/`
   - Set Status to `done`
   - Set Completed timestamp

   If NOT all criteria are met:
   - Keep task in `.doyaken/tasks/3.doing/`
   - Document what remains in Work Log
   - Create follow-up task if needed

6. **Commit Task Files**
   After finalizing task state, commit ALL task-related changes:

   ```bash
   # Regenerate taskboard
   doyaken tasks

   # Stage and commit task files
   git add .doyaken/tasks/ TASKBOARD.md
   git commit -m "chore: Complete task {{TASK_ID}} [{{TASK_ID}}]" || true
   ```

   This ensures task progress is tracked in git history.

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Verification Complete

Task location: [3.doing/4.done]
Status field: [matches/mismatched]
Acceptance criteria: [X/Y checked]

Issues found:
- [list any discrepancies or "none"]

Actions taken:
- [moved to 4.done/ | kept in 3.doing/ | created follow-up]
- [committed task files to git]

Task verified: [PASS/FAIL]
```

## Rules

- Do NOT write any code
- Do NOT modify source files
- ONLY verify and update task file state
- Be strict: incomplete tasks should NOT be in 4.done/
- If verification fails, do not mark task as complete
- **ALWAYS commit task file changes at the end**

Task file: {{TASK_FILE}}
