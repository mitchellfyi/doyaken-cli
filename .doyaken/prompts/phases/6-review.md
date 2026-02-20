# Phase 6: REVIEW

You are performing final review for task **{{TASK_ID}}**.

## Context from Previous Phases

**Read the task file's Work Log first** for the full history of this task across all phases.

Files changed on this branch:
```
{{CHANGED_FILES}}
```

Commits for this task:
```
{{TASK_COMMITS}}
```

Review these specific files and commits. Do not waste time re-discovering what changed.

## Methodology

{{include:library/review.md}}

{{include:library/review-security.md}}

## Phase Instructions

1. **Build findings ledger** - Track all issues by severity
2. **Multi-pass review** - Correctness → Design → Security → Performance → Tests
3. **Fix blockers/high** - Address immediately
4. **Create follow-ups** - For medium/low improvements
5. **Complete task** - Only if ALL acceptance criteria are met

## Task Completion

**Only if ALL criteria met:**
- Check all acceptance criteria boxes
- Update status to `done`
- Set completed timestamp
- Move task file to `.doyaken/tasks/4.done/`

**For out-of-scope improvements:**
- Create tasks in `.doyaken/tasks/2.todo/`
- Reference this task in context

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Review Complete

Findings:
- Blockers: [count] - fixed
- High: [count] - fixed
- Medium: [count] - [fixed/deferred]
- Low: [count] - [fixed/deferred]

Review passes:
- Correctness: [pass/issues]
- Design: [pass/issues]
- Security: [pass/issues]
- Performance: [pass/issues]
- Tests: [pass/issues]

All criteria met: [yes/no]
Follow-up tasks: [list or none]

Status: [COMPLETE/INCOMPLETE - reason]
```

## Completion Signal

When you are done with this phase, include a structured status block in your output:

```
DOYAKEN_STATUS:
  PHASE_COMPLETE: true/false
  FILES_MODIFIED: <count>
  TESTS_STATUS: pass/fail/skip/unknown
  CONFIDENCE: high/medium/low
  REMAINING_WORK: <brief description or "none">
```

## Rules

- Fix blockers and high severity immediately
- Create tasks for medium/low (don't scope creep)
- Be honest about what's done vs remaining
- If incomplete, leave in `3.doing/`

{{VERIFICATION_CONTEXT}}

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
Recent commits: {{RECENT_COMMITS}}
