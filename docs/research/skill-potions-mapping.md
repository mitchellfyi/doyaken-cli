# Skill Potions → Doyaken CLI Mapping

**Source:** [Claude Skill Potions](https://github.com/ElliotJLT/Claude-Skill-Potions)  
**Target:** Doyaken CLI prompts/phases  
**Date:** 2026-02-03

---

## Overview

This document maps skills from Claude Skill Potions to the existing Doyaken CLI prompt structure, identifying:
- What already exists and just needs enhancement
- What's missing and should be integrated
- What patterns can be adopted wholesale
- What needs adaptation for the phase-based workflow

---

## Skill-by-Skill Mapping

### 🎯 Planning & Risk Skills

| Skill | Maps To | Status | Action |
|-------|---------|--------|--------|
| **battle-plan** | Phase 2 (Plan) | Partial | Enhance with orchestration pattern |
| **pre-mortem** | Phase 2 (Plan) → Risk section | Weak | Add structured pre-mortem template |
| **rubber-duck** | Phase 1 (Triage) | Missing | Add scope clarification step |
| **eta** | Phase 2 (Plan) | Missing | Add time estimation with breakdown |
| **split-decision** | New | Missing | Add for architectural decisions |
| **you-sure** | Phase 3 (Implement) | Partial | Strengthen confirmation gates |

### 🔍 Debugging & Problem Solving Skills

| Skill | Maps To | Status | Action |
|-------|---------|--------|--------|
| **debug-to-fix** | prompts/library/debugging.md | Good | Integrate as orchestrated elixir |
| **rubber-duck** | New phase | Missing | Add clarification step before debugging |
| **zero-in** | prompts/library/debugging.md | Partial | Add search focus template |
| **sanity-check** | prompts/library/base.md | Weak | Add assumption validation step |

### ✅ Quality & Verification Skills

| Skill | Maps To | Status | Action |
|-------|---------|--------|--------|
| **prove-it** | Phase 7 (Verify) | Weak | Add evidence requirements |
| **loose-ends** | Phase 6 (Review) | Partial | Add cleanup checklist |
| **trace-it** | Phase 3 (Implement) | Missing | Add caller tracing before changes |

### 🚧 Code Discipline Skills

| Skill | Maps To | Status | Action |
|-------|---------|--------|--------|
| **stay-in-lane** | prompts/library/base.md | Weak | Add scope check template |
| **keep-it-simple** | prompts/library/quality.md | Good | Already has KISS/YAGNI |
| **sanity-check** | New | Missing | Add assumption validation |

### 📝 Context & Memory Skills

| Skill | Maps To | Status | Action |
|-------|---------|--------|--------|
| **breadcrumbs** | Work Log in tasks | Partial | Enhance with structured breadcrumbs |
| **retrospective** | Phase 7 (Verify) | Missing | Add retrospective template |
| **learn-from-this** | New | Missing | Add skill generation from failures |

### 🔄 Orchestration Skills (Elixirs)

| Skill | Maps To | Status | Action |
|-------|---------|--------|--------|
| **debug-to-fix** | Debugging workflow | Missing | Create as composed prompt |
| **safe-refactor** | refactor.md | Partial | Add as orchestrated workflow |
| **careful-delete** | New | Missing | Add for destructive operations |
| **fan-out** | New | Missing | Add for parallel subtasks |
| **pipeline** | Phase structure | Good | Already phase-based |

---

## Detailed Integration Plan

### 1. Phase 1 (Triage) Enhancements

**Add from rubber-duck:**
```markdown
## Scope Clarification

Before proceeding, verify understanding:

1. **What are we building?** → [Clear description]
2. **What's the definition of done?** → [Verifiable criteria]
3. **What's OUT of scope?** → [Explicit exclusions]

If any ambiguity exists, ask clarifying questions NOW.
Do not proceed with vague scope.
```

**Add from sanity-check:**
```markdown
## Assumption Validation

List assumptions about this task:

| Assumption | Verification | Status |
|------------|--------------|--------|
| [The function X exists] | grep/read | Verified / Wrong |
| [The error is caused by Y] | logs/reproduce | Verified / Wrong |

**STOP if key assumptions are wrong.** Reassess before proceeding.
```

### 2. Phase 2 (Plan) Enhancements

**Add from pre-mortem:**
```markdown
## Pre-Mortem: If this fails in 2 weeks, why?

Generate 3-5 failure scenarios:

| # | Scenario | Likelihood | Impact | Mitigation |
|---|----------|------------|--------|------------|
| 1 | [Specific failure] | HIGH/MED/LOW | [What breaks] | [Prevention] |
| 2 | [Specific failure] | HIGH/MED/LOW | [What breaks] | [Prevention] |

**Reorder plan to address HIGH risks first.**
```

**Add from eta:**
```markdown
## Time Estimate

| Phase | Estimate | Confidence |
|-------|----------|------------|
| Recon & setup | ~X min | HIGH/MED/LOW |
| Implementation | ~Y min | HIGH/MED/LOW |
| Testing | ~Z min | HIGH/MED/LOW |
| Verification | ~W min | HIGH/MED/LOW |

**Total:** ~[range] minutes
**Checkpoint at:** [Step N / halfway point]

Tasks >30 min need explicit checkpoints.
```

### 3. Phase 3 (Implement) Enhancements

**Add from stay-in-lane:**
```markdown
## Scope Check (after each file change)

| Original Ask | What I Just Did | In Scope? |
|--------------|-----------------|-----------|
| [Quote from task] | [Description] | YES/NO |

If NO: **Revert.** Document why this was out of scope.
Resist: "while I'm here", "I should also", "best practices say"
```

**Add from trace-it:**
```markdown
## Before Modifying Shared Code

If changing: utils, types, configs, shared components

1. **Find all callers:** `grep -r "import.*from.*[file]"`
2. **List affected files:** [count]
3. **Check for breaking changes:** [yes/no]

Do NOT modify shared code without tracing impact first.
```

**Add retry limit from base.md (strengthen):**
```markdown
## Approach Tracking

| Approach | Attempts | Result |
|----------|----------|--------|
| [Approach 1] | 2 | Failed: [reason] |
| [Approach 2] | 1 | In progress |

**HARD LIMIT: 3 attempts per approach.**

After 3 failures:
1. STOP
2. Document what didn't work and why
3. Try fundamentally different approach OR escalate

Never retry the same thing expecting different results.
```

### 4. Phase 6 (Review) Enhancements

**Add from loose-ends:**
```markdown
## Loose Ends Sweep

Before declaring complete:

### Code Hygiene
- [ ] No unused imports
- [ ] No console.log/print statements
- [ ] No commented-out code
- [ ] No debugger statements

### TODOs Created
- [ ] All TODOs addressed or explicitly deferred
- [ ] New TODOs have issue references

### Tests
- [ ] New code has tests
- [ ] Existing tests still pass
- [ ] Edge cases considered

### References
- [ ] No broken imports
- [ ] No stale comments

Quick scan:
```bash
git diff --name-only | xargs grep -n "TODO\|FIXME\|console.log"
```
```

### 5. Phase 7 (Verify) Enhancements

**Add from prove-it:**
```markdown
## Evidence of Completion

| Criterion | Claim | Proof |
|-----------|-------|-------|
| [Acceptance criterion] | [What we claim] | [Command + output / File reference / Test result] |

**Verification Commands Run:**
- `[command]` → `[actual output]`

**No criterion marked complete without concrete evidence.**

STOP if you're about to say "done" without running the code.
"Looks right" ≠ "Is right"
```

**Add from retrospective:**
```markdown
## Retrospective

### Failed Approaches (document FIRST)
| Approach | Why It Failed | Time Spent |
|----------|---------------|------------|
| [Approach] | [Specific reason] | [Estimate] |

### What Worked
**Final approach:** [Summary]
**Key insight:** [The "aha" moment]

### Learnings
- **Would do differently:** [What to change next time]
- **Surprised by:** [Unexpected findings]
- **Reusable pattern:** [Anything worth extracting]
```

### 6. New: Breadcrumbs System

**Add to task structure:**
```markdown
## Breadcrumbs (for future sessions)

### Discoveries
- [Important finding]: [Location/evidence]

### Dead Ends
- [Approach]: [Why it failed] - Don't try again

### Context
- [Why we made decision X]: [Reasoning]

### Next Session
- [What's left to do]
- [What to watch out for]
```

---

## New Prompts to Create

### prompts/library/scope-clarification.md
Extract rubber-duck patterns for reuse across phases.

### prompts/library/pre-mortem.md  
Extract pre-mortem methodology as standalone library prompt.

### prompts/library/verification.md
Extract prove-it patterns for verification with evidence.

### prompts/library/retrospective.md
Extract retrospective template for post-task learning.

### prompts/library/assumption-validation.md
Extract sanity-check patterns for validating assumptions.

---

## Elixir Pattern for Doyaken

The "elixir" concept (composed workflows) maps well to Doyaken's phase system. Consider adding:

### prompts/workflows/debug-to-fix.md
Orchestrates: rubber-duck → investigate → fix → prove-it

### prompts/workflows/safe-refactor.md
Orchestrates: pre-mortem → trace-it → implement → prove-it

### prompts/workflows/battle-plan.md
Orchestrates: rubber-duck → pre-mortem → eta → you-sure

These can be invoked via `dk skill` for complex tasks that need the full ritual.

---

## Implementation Priority

### Priority 1: Core Workflow Enhancement
1. **Pre-mortem** → Phase 2 (high impact)
2. **Prove-it** → Phase 7 (prevents false completions)
3. **Stay-in-lane** → Phase 3 (prevents scope creep)
4. **Retry limits** → Phase 3 (prevents infinite loops)

### Priority 2: Context & Learning
5. **Retrospective** → Phase 7 (enables learning)
6. **Breadcrumbs** → Task structure (session continuity)
7. **Sanity-check** → Phase 1 (prevents assumption cascades)

### Priority 3: Polish
8. **Loose-ends** → Phase 6 (cleanup checklist)
9. **ETA** → Phase 2 (time estimation)
10. **Trace-it** → Phase 3 (impact analysis)

---

## Key Philosophical Takeaways

From the Skill Potions documentation:

1. **"Failed Attempts" tables get read more than any other section.** Capture failures first.

2. **Skills should be born from real pain.** The theoretical ones are weaker than battle-tested ones.

3. **Verification converts prediction into observation.** "Looks right" vs "works right".

4. **Every correction becomes a permanent lesson.** The system gets smarter through use.

5. **Don't tell AI what to do, give it success criteria.** Declarative > imperative.

6. **Scope creep is Claude's helpful instincts gone wrong.** Force explicit scope checks.

7. **Assumptions cascade into completely wrong solutions.** Validate before building.

---

## Files to Create/Modify

```
prompts/library/
├── scope-clarification.md    # NEW: from rubber-duck
├── pre-mortem.md             # NEW: structured risk assessment
├── verification.md           # NEW: prove-it patterns
├── retrospective.md          # NEW: learning capture
├── assumption-validation.md  # NEW: sanity-check
└── base.md                   # MODIFY: add retry limits, scope check

prompts/phases/
├── 1-triage.md     # MODIFY: add scope clarification, assumption validation
├── 2-plan.md       # MODIFY: add pre-mortem, ETA
├── 3-implement.md  # MODIFY: add scope check, retry limits, trace-it
├── 6-review.md     # MODIFY: add loose-ends checklist
└── 7-verify.md     # MODIFY: add prove-it, retrospective

prompts/workflows/  # NEW directory
├── debug-to-fix.md
├── safe-refactor.md
└── battle-plan.md
```
