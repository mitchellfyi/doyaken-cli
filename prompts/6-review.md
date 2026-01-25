# Phase 6: REVIEW (Final Quality Gate)

You are performing final review for task {{TASK_ID}}.

## Your Responsibilities

1. **Code Review Checklist**
   - [ ] Code follows project conventions
   - [ ] No code smells or anti-patterns
   - [ ] Error handling is appropriate
   - [ ] No security vulnerabilities
   - [ ] No obvious performance issues

2. **Consistency Check**
   - [ ] All acceptance criteria are met
   - [ ] Tests cover the acceptance criteria
   - [ ] Docs match the implementation
   - [ ] No orphaned code (unused functions/classes)
   - [ ] Related features still work

3. **Final Quality Gate**
   - Run the full quality check suite
   - Must pass ALL checks

4. **Create Follow-up Tasks** (if needed)
   For improvements/optimizations discovered:
   - Create new task files in `.doyaken/tasks/todo/`
   - Use priority 003 (Medium) for improvements
   - Use priority 004 (Low) for nice-to-haves
   - Reference this task in the new task's context
   - Commit follow-up tasks immediately

5. **Complete the Task**
   - Check all acceptance criteria boxes
   - Update status to `done`
   - Set completed timestamp
   - Write completion summary
   - Move task file to `.doyaken/tasks/done/`

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Review Complete

Code review:
- Issues found: [list or "none"]
- Issues fixed: [list]

Consistency:
- All criteria met: [yes/no]
- Test coverage adequate: [yes/no]
- Docs in sync: [yes/no]

Follow-up tasks created:
- 003-XXX-improvement-name.md
- 004-XXX-nice-to-have.md

Final status: COMPLETE
```

## Rules

- Fix critical issues immediately
- Create tasks for non-critical improvements (don't scope creep)
- Be honest about what's done vs what's remaining
- If task cannot be completed, explain why and leave in doing/

Task file: {{TASK_FILE}}
Recent commits: {{RECENT_COMMITS}}
