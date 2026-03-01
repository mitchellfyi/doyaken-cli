# Phase 6: REVIEW

You are performing final review of the implementation.

## Methodology

{{include:library/review.md}}

{{include:library/review-security.md}}

## Phase Instructions

1. **Sweep for loose ends** - Check for cruft before declaring complete
2. **Build findings ledger** - Track all issues by severity
3. **Multi-pass review** - Correctness → Design → Security → Performance → Tests
4. **Fix blockers/high** - Address immediately
5. **Note follow-ups** - For medium/low improvements

## Loose Ends Sweep

Before declaring complete, check for cruft in changed files:

```bash
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

## Output

Summarize:
- Loose ends found and fixed
- Findings by severity (blocker/high/medium/low) and what was done
- Review pass results (correctness, design, security, performance, tests)
- All acceptance criteria met: yes/no
- Follow-up items for out-of-scope improvements

## Rules

- **SWEEP for loose ends first** - don't let cruft slip through
- Fix blockers and high severity immediately
- Note medium/low as follow-ups (don't scope creep)
- Be honest about what's done vs remaining

Recent commits: {{RECENT_COMMITS}}
