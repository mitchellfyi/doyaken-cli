# Phase 6: REVIEW

You are performing final review for task **{{TASK_ID}}**.

## Methodology

{{include:library/review.md}}

{{include:library/review-security.md}}

## Phase Instructions

1. **Sweep for loose ends** - Check for cruft before declaring complete
2. **Build findings ledger** - Track all issues by severity
3. **Multi-pass review** - Correctness → Design → Security → Performance → Tests
4. **Fix blockers/high** - Address immediately
5. **Create follow-ups** - For medium/low improvements
6. **Complete task** - Only if ALL acceptance criteria are met

## Loose Ends Sweep

Before declaring complete, check for cruft in changed files:

```bash
# Find common cruft in changed files
git diff --name-only HEAD~3 | xargs grep -n "TODO\|FIXME\|console.log\|debugger" 2>/dev/null
```

### Code Hygiene
- [ ] No unused imports added
- [ ] No console.log/print/debugger statements left
- [ ] No commented-out code (unless intentional with explanation)

### TODOs
- [ ] Any TODOs created during this task are addressed or have issue references
- [ ] No "TODO: fix later" without a plan

### References
- [ ] No broken imports from refactoring
- [ ] No stale comments referring to old code
- [ ] Variable/function renames updated everywhere

### Error Handling
- [ ] New error paths handled appropriately
- [ ] No silent failures (catch blocks that swallow errors)

**Fix loose ends before proceeding to findings review.**

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

Loose ends:
- [ ] Code hygiene: [clean / fixed X issues]
- [ ] TODOs: [none / X addressed]
- [ ] References: [clean / fixed X]
- [ ] Error handling: [appropriate / fixed X]

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

## Rules

- **SWEEP for loose ends first** - don't let cruft slip through
- Fix blockers and high severity immediately
- Create tasks for medium/low (don't scope creep)
- Be honest about what's done vs remaining
- If incomplete, leave in `3.doing/`

Task file: {{TASK_FILE}}
Recent commits: {{RECENT_COMMITS}}
