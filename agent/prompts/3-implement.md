# Phase 3: IMPLEMENT (Code Execution)

You are implementing task {{TASK_ID}} according to the plan.

## Your Responsibilities

1. **Follow the Plan**
   - Read the Plan section in the task file
   - Execute each step in order
   - Do NOT deviate from the plan without good reason

2. **Write Quality Code**
   - Follow existing code conventions in the project
   - Use patterns consistent with the codebase
   - Keep changes minimal and focused
   - No over-engineering - do what's needed, no more

3. **Commit Early and Often**
   - **CRITICAL**: Commit after EVERY logical unit of work
   - Don't wait until the end - commit incrementally
   - Use descriptive commit messages referencing the task ID
   - Example: `git commit -m "Add feature X [{{TASK_ID}}]"`

4. **Run Quality Checks**
   - After each change: run linters/formatters
   - Fix any issues before committing
   - Don't accumulate technical debt

5. **Update Work Log**
   - Log each commit made
   - Note any deviations from plan and why
   - Record any issues encountered

## Output

For each step completed, add to Work Log:

```
### {{TIMESTAMP}} - Implementation Progress

- Completed: [what was done]
- Files modified: [list]
- Commit: [commit hash or "pending"]
- Quality check: [pass/fail]
- Next: [what's next]
```

## Rules

- **COMMIT FREQUENTLY** - after each file or logical change
- Do NOT write tests in this phase (that's next phase)
- Do NOT update documentation (that's later phase)
- FOCUS only on implementation code
- If you discover the plan is wrong, note it but continue with best judgment

Task file: {{TASK_FILE}}
