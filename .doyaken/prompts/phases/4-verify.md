# Phase 4: VERIFY

You are performing final review and verification that the task is complete and ready to ship.

## Methodology

{{include:library/review.md}}

{{include:library/review-security.md}}

{{include:library/ci.md}}

## Phase Instructions

1. **Sweep for loose ends** — Check for cruft before declaring complete
2. **Prove completion** — Each criterion needs concrete evidence, not claims
3. **Multi-pass review** — Correctness → Design → Security → Performance → Tests
4. **Run final quality check** — All gates must pass
5. **Push and verify CI** — Task is NOT complete until CI passes
6. **Capture learnings** — Document what failed and what worked
7. **Improve knowledge** — Update AGENTS.md with project discoveries if appropriate

## Loose Ends Sweep

Before declaring complete, check for cruft in changed files:

```bash
git diff --name-only HEAD~5 | xargs grep -n "TODO\|FIXME\|console.log\|debugger" 2>/dev/null
```

### Code Hygiene
- [ ] No unused imports
- [ ] No console.log/print/debugger left
- [ ] No commented-out code (unless intentional with explanation)
- [ ] Any TODOs have issue references or a plan
- [ ] No broken imports or stale comments
- [ ] New error paths handled; no silent failures

## Prove It

Before saying "done", you need **proof**, not claims.

For each acceptance criterion, provide concrete evidence:

| Criterion | Claim | Proof |
|-----------|-------|-------|
| [criterion] | [what we claim] | [command + output / test result / file reference] |

Evidence types: command output, test result, file reference, manual verification.

**NO criterion marked complete without evidence.**

## CI Verification

```bash
git push && gh run watch
# If CI fails: gh run view --log-failed
```

**Do NOT mark complete if CI fails.** Fix and iterate until green.

## Retrospective (for non-trivial tasks)

### Failed Approaches
| Approach | Why It Failed | Time |
|----------|---------------|------|
| [What was tried] | [Reason] | [~estimate] |

### What Worked
- **Final approach:** [Summary]
- **Key insight:** [If any]

### Learnings
- **Would do differently:** [What to change]
- **Surprised by:** [Unexpected findings]

## Improve Knowledge

### Update AGENTS.md

If you discovered something important about this codebase:
- Architecture patterns
- Gotchas
- Conventions
- Dead ends (libraries that conflict, etc.)

### Update Prompts

Only for patterns proven across multiple projects. Be conservative.

## Output

Summarize:
- Evidence of completion (criterion + proof for each)
- Loose ends found and fixed
- Quality gates result
- CI status (pass/fail with link)
- Retrospective (if applicable)
- Knowledge updates made (or "none needed")

## Rules

- **SWEEP for loose ends first**
- **PROVE don't claim** — evidence required
- **CI passing is a hard requirement**
- Fix blockers and high severity immediately
- "Almost done" is not done

Recent commits: {{RECENT_COMMITS}}

{{VERIFICATION_CONTEXT}}

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
