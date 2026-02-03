# Phase 7: VERIFY

You are verifying task **{{TASK_ID}}** is complete and CI passes.

## Methodology

{{include:library/ci.md}}

## Phase Instructions

1. **Prove completion** - Each criterion needs concrete evidence, not just claims
2. **Verify work log** - All phases documented
3. **Run final quality check** - All gates must pass
4. **Push and verify CI** - Task is NOT complete until CI passes
5. **Capture learnings** - Document what failed and what worked
6. **Improve knowledge** - Update AGENTS.md with project discoveries; optionally improve prompts
7. **Finalize task state** - Move to done only if everything passes

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

**Verification commands run:**
```bash
# Actually run these and record output
[command] → [actual result]
```

**NO criterion marked complete without evidence.**

If you can't verify something, say so: "UNABLE TO VERIFY: [reason]"

## CI Verification

```bash
# Push and watch CI
git push && gh run watch

# If CI fails - get details and fix
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

**Add to AGENTS.md** in the appropriate section:

```markdown
## Project Knowledge

### Patterns
- [Pattern discovered]: [Where/how it's used]

### Gotchas
- [Thing that's surprising]: [Why it matters]

### Don't Do
- [Approach that doesn't work]: [Why it fails]
```

### Update Prompts (Reusable Patterns)

If you discovered a pattern that would help across ALL projects (not just this one):

1. **Identify the pattern** - Is this specific to this repo, or universal?
2. **If universal** - Consider updating `.doyaken/prompts/library/` or phase prompts
3. **If project-specific** - Add to AGENTS.md instead

**Prompt improvement examples:**
- A verification step that caught a common bug
- A planning pattern that prevented rework
- A debugging technique that was effective

**To update prompts:**
```bash
# Edit the relevant prompt
edit .doyaken/prompts/[library|phases]/[file].md

# Commit the improvement
git commit -m "Improve [prompt]: [what was learned]"
```

**Be conservative:** Only update prompts for patterns you've seen work multiple times.

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Verification Complete

Evidence of completion:
| Criterion | Proof |
|-----------|-------|
| [criterion] | [evidence] |

Verification commands:
- `[command]` → [result]

Quality gates: [all pass / failures]
CI: [pass/fail - run link]

Retrospective:
- Failed approaches: [count or "none"]
- Key insight: [what was learned]
- Would do differently: [lesson]

Knowledge updates:
- AGENTS.md: [updated with X / no updates needed]
- Prompts: [updated X / no updates needed]

Task location: [3.doing → 4.done / kept in 3.doing]
Reason: [complete / incomplete - what remains]
```

If complete:
- Status: `done`
- Completed: `{{TIMESTAMP}}`
- Clear Assigned To/At
- Move to `.doyaken/tasks/4.done/`
- Commit: `chore: Complete task {{TASK_ID}}`

## Rules

- **PROVE don't claim** - evidence required for every criterion
- **CI passing is a hard requirement**
- **CAPTURE failures** - they're valuable for next time
- **IMPROVE knowledge** - update AGENTS.md with project discoveries
- **BE CONSERVATIVE with prompt updates** - only for proven patterns
- Do NOT mark complete if CI fails
- "Almost done" is not done - be honest
- Incomplete tasks stay in `3.doing/`

Task file: {{TASK_FILE}}
