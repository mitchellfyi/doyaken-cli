# Phase 6: REVIEW (Final Quality Gate)

You are performing final review for task {{TASK_ID}}.

## Code Quality Standards

{{include:library/code-quality.md}}

## Code Review Methodology

{{include:library/code-review.md}}

## Security Review

{{include:library/security.md}}

## Phase-Specific Instructions

For this task:
1. Build a findings ledger tracking all issues
2. Perform multi-pass review (correctness, design, security, performance, tests)
3. Fix blockers and high severity issues immediately
4. Create follow-up tasks for medium/low improvements
5. Complete the task if ALL acceptance criteria are met

## Task Completion

Only if ALL acceptance criteria are met:
- Check all acceptance criteria boxes
- Update status to `done`
- Set completed timestamp
- Move task file to `.doyaken/tasks/4.done/`

For improvements that are out of scope:
- Create task files in `.doyaken/tasks/2.todo/`
- Priority 003 (Medium) for improvements
- Priority 004 (Low) for nice-to-haves
- Reference this task in the new task's context

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Review Complete

Findings ledger:
- Blockers: [count] - all fixed
- High: [count] - all fixed
- Medium: [count] - [fixed/deferred to follow-up]
- Low: [count] - [fixed/deferred]

Review passes:
- A (Correctness): [pass/issues found]
- B (Design): [pass/issues found]
- C (Security): [pass/issues found]
- D (Performance): [pass/issues found]
- E (Tests/Docs): [pass/issues found]

Verification:
- All quality gates: [pass/fail]
- All criteria met: [yes/no]

Follow-up tasks:
- [task-id]: [description]

Final status: [COMPLETE/INCOMPLETE - reason]
```

## Rules

- Fix blockers and high severity issues immediately
- Create tasks for medium/low improvements (don't scope creep)
- Be honest about what's done vs remaining
- If task cannot be completed, explain why and leave in 3.doing/

Task file: {{TASK_FILE}}
Recent commits: {{RECENT_COMMITS}}
