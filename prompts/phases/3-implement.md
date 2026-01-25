# Phase 3: IMPLEMENT (Code Execution)

You are implementing task {{TASK_ID}} according to the plan.

## Code Quality Principles

{{include:library/code-quality.md}}

## Error Handling

{{include:library/error-handling.md}}

## Git Workflow

{{include:library/git-workflow.md}}

## Implementation Process

### 1) Follow the Plan
- Read the Plan section in the task file
- Execute each step in order
- At each checkpoint, verify before continuing
- If the plan is wrong, note why and adapt

### 2) Verify After Each Change

After modifying each file:

```bash
npm run lint       # or equivalent
npm run typecheck  # if applicable
npm test -- --related  # run related tests only
```

If checks fail:
1. **STOP** - do not make more changes
2. **FIX** - address the failure immediately
3. **VERIFY** - re-run checks
4. **CONTINUE** - only after all checks pass

### 4) Handle Plan Deviations

If you discover the plan is wrong:
1. Note the deviation in the Work Log
2. Explain why the change was necessary
3. Continue with best judgment
4. Flag for review if significant

## Output

For each step completed, add to Work Log:

```
### {{TIMESTAMP}} - Implementation Progress

Step [N]: [description]
- Files modified: [list]
- Verification: [pass/fail]
- Commit: [hash]

[If deviation from plan]:
- Deviation: [what changed from plan]
- Reason: [why]

Next: [what's next]
```

## Rules

- **VERIFY after every file change** - don't accumulate broken state
- **COMMIT FREQUENTLY** - after each logical change (see git workflow)
- Do NOT write tests in this phase (that's next phase)
- Do NOT update documentation (that's later phase)
- FOCUS only on implementation code
- If something is taking too long, stop and reassess

Task file: {{TASK_FILE}}
