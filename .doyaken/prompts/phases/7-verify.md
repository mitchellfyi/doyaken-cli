# Phase 7: VERIFY

You are verifying the task is complete and CI passes.

## Methodology

{{include:library/ci.md}}

## Phase Instructions

1. **Prove completion** - Each criterion needs concrete evidence, not just claims
2. **Run final quality check** - All gates must pass
3. **Push and verify CI** - Task is NOT complete until CI passes
4. **Capture learnings** - Document what failed and what worked
5. **Improve knowledge** - Update AGENTS.md with project discoveries; optionally improve prompts

## Prove It

Before saying "done", you need **proof**, not claims.

"Looks right" ≠ "Is right"

For each criterion, provide concrete evidence:

| Criterion | Claim | Proof |
|-----------|-------|-------|
| [criterion] | [what we claim] | [command + output / test result / file reference] |

**Evidence types:**
- Command output: `npm test` → "42 tests passed"
- Test result: `tests/feature.test.ts` passes
- File reference: "See line 45 of `config.ts`"
- Manual verification: "Ran locally, saw expected behavior"

**NO criterion marked complete without evidence.**

If you can't verify something, say so: "UNABLE TO VERIFY: [reason]"

## CI Verification

```bash
git push && gh run watch
# If CI fails:
gh run view --log-failed
```

**Do NOT mark complete if CI fails.** Fix and iterate until green.

## Retrospective

Before closing, capture what you learned. **Failed approaches first** - they're read more than successes.

### Failed Approaches
| Approach | Why It Failed | Time Spent |
|----------|---------------|------------|
| [What was tried] | [Specific reason it didn't work] | [~estimate] |

### What Worked
- **Final approach:** [One sentence summary]
- **Key insight:** [The "aha" moment, if any]

### Learnings
- **Would do differently:** [What to change next time]
- **Surprised by:** [Unexpected findings]

*Skip retrospective for trivial tasks. Required for tasks >30 min or with failed approaches.*

## Improve Knowledge

After completing significant work, consider if learnings should be captured permanently.

### Update AGENTS.md (Project Context)

If you discovered something important about this codebase that future agents should know:

- **Architecture patterns:** "Auth is handled in route handlers, not middleware"
- **Gotchas:** "Config requires restart after changes"
- **Conventions:** "Use kebab-case for file names"
- **Dead ends:** "Don't use X library, it conflicts with Y"

### Update Prompts (Reusable Patterns)

If you discovered a pattern that would help across ALL projects (not just this one):

1. **Identify the pattern** - Is this specific to this repo, or universal?
2. **If universal** - Consider updating `.doyaken/prompts/library/` or phase prompts
3. **If project-specific** - Add to AGENTS.md instead

**Be conservative:** Only update prompts for patterns you've seen work multiple times.

## Output

Summarize:
- Evidence of completion (criterion + proof for each)
- Quality gates result
- CI status (pass/fail with link)
- Retrospective (failed approaches, key insight, lessons)
- Knowledge updates made (AGENTS.md and/or prompts, or "none needed")

## Rules

- **PROVE don't claim** - evidence required for every criterion
- **CI passing is a hard requirement**
- **CAPTURE failures** - they're valuable for next time
- **IMPROVE knowledge** - update AGENTS.md with project discoveries
- **BE CONSERVATIVE with prompt updates** - only for proven patterns
- Do NOT mark complete if CI fails
- "Almost done" is not done - be honest
