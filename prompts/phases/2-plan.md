# Phase 2: PLAN

You are planning the implementation.

## Methodology

{{include:library/planning.md}}

## Phase Instructions

1. **Gap analysis** - For each acceptance criterion, assess: full/partial/none
2. **Pre-mortem** - Imagine it failed. Why? Address HIGH risks first.
3. **Implementation steps** - Ordered, atomic, with verification for each
4. **Time estimate** - How long will this take? Set checkpoints for long tasks.
5. **Test strategy** - What tests are needed?
6. **Documentation** - What docs need updating?

## Pre-Mortem

Before planning steps, imagine it's 2 weeks later and this task failed. Ask: **"Why did it fail?"**

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Specific failure scenario] | HIGH/MED/LOW | [What breaks] | [How to prevent] |

**Severity guide:**
- **HIGH** (must address): Data loss, security, silent failures, no rollback
- **MED** (should address): Poor UX, performance issues, manual intervention needed
- **LOW** (note and proceed): Cosmetic, easy to fix post-launch

**Reorder implementation steps to address HIGH risks first.**

## Time Estimate

| Phase | Estimate | Confidence |
|-------|----------|------------|
| Implementation | ~X min | HIGH/MED/LOW |
| Testing | ~Y min | HIGH/MED/LOW |
| Verification | ~Z min | HIGH/MED/LOW |
| **Total** | ~[range] min | |

If total >30 minutes, set explicit checkpoint(s).

## Output

Produce a plan with these sections:

- **Gap Analysis**: Criterion / status (full/partial/none) / what's missing
- **Pre-Mortem**: Risk table with likelihood, impact, mitigation
- **Estimate**: Total time range, checkpoint if >30 min
- **Steps** (ordered by risk): Each with file, specific change, verification
- **Test Plan**: Unit and integration tests needed
- **Docs to Update**: Files and changes needed

## Rules

- Do NOT write implementation code
- Do NOT skip pre-mortem for "simple" tasks - simple tasks cause complex failures
- Be SPECIFIC - "security issues" is useless, "missing auth check on endpoint X" is actionable
- If something already exists and is complete, note it and move on
- Include rollback strategy for risky changes
