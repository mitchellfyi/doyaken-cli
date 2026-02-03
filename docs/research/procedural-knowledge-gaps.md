# Research: Procedural Knowledge Gaps in AI Task Execution

**Source:** ["Your AI Has Infinite Knowledge and Zero Habits"](https://medium.com/@elliotJL/your-ai-has-infinite-knowledge-and-zero-habits-heres-the-fix-e279215d478d) by Elliot JL  
**Reference Implementation:** [Claude Skill Potions](https://github.com/ElliotJLT/Claude-Skill-Potions)  
**Date:** 2026-02-03

---

## Core Insight

The article draws on Gilbert Ryle's epistemological distinction:

| Type | Definition | AI Example |
|------|------------|------------|
| **Knowing That** (Declarative) | Facts, information, propositions | "You should assess risks before starting" |
| **Knowing How** (Procedural) | Ability to do things automatically | *Actually assessing risks every time* |

**The Gap:** LLMs have massive declarative knowledge but no procedural layer—no ingrained habits, no automatic workflows, no "muscle memory."

---

## Documented Failure Modes

### 1. No Risk Assessment
- AI jumps straight to implementation
- Discovers problems mid-way, patches reactively
- Expert behavior: imagine failure first, then prevent it

### 2. Overconfidence Without Calibration
- States "the function returns X" with identical confidence whether certain or guessing
- Users can't tell what to verify

### 3. Hallucination Without Verification
- References files, functions, code that don't exist
- Looks correct, fails when executed

### 4. Infinite Loops on Failed Approaches
- Fails at something, retries exact same approach 5+ times
- Never tries different strategy, never escalates
- Burns time without progress

### 5. No Definition of Done
- Perfectionism loops: "We could also add...", "It would be better if..."
- No clear declaration that something is shippable
- Endless refinement

### 6. Context Rot Over Long Sessions
- Instructions from earlier get forgotten
- Original goal drifts
- Quality degrades even within context limit

### 7. Imposes Preferences Instead of Matching Patterns
- Suggests modern patterns in legacy codebases
- Introduces new libraries when existing ones are used
- Refactors while fixing bugs (scope creep)

---

## Skills as Production Rules

Skills encode **if-then patterns** that execute automatically:

```
TRIGGER (the "if")     → When condition X is detected
PROCEDURE (the "then") → Execute steps 1, 2, 3
CONSTRAINTS           → NEVER do Y, ALWAYS do Z
```

### Key Skills from Claude Skill Potions

| Skill | Purpose | Maps to Failure Mode |
|-------|---------|---------------------|
| **pre-mortem** | Imagine failure before starting, assess risks | #1 No risk assessment |
| **prove-it** | Verify outcome before declaring complete | #3 Hallucination, #5 No definition of done |
| **rubber-duck** | Force scope clarification through questions | Vague requirements |
| **stay-in-lane** | Verify changes match what was asked | #7 Scope creep |
| **sanity-check** | Validate assumptions before building on them | Assumption cascades |
| **breadcrumbs** | Leave notes for future sessions | #6 Context rot |
| **you-sure** | Pause before destructive actions | Safety |
| **retrospective** | Document what worked/failed after completion | Compound learning |
| **learn-from-this** | Draft new skill from failures | Compound learning |

### Orchestration (Elixirs)

Complex workflows chain multiple skills:

**battle-plan** = rubber-duck → pre-mortem → eta → you-sure

No coding until plan is approved.

---

## Gap Analysis: Current Doyaken CLI

### What's Already Good ✅

| Current Feature | Article Alignment |
|-----------------|-------------------|
| Phase structure (triage → plan → implement → test → verify) | Enforces workflow |
| Quality gates in triage | Prevents skipping verification |
| Plan phase with risk section | Addresses #1 partially |
| Work log requirement | Breadcrumbs for continuity |
| "VERIFY after every file change" | Addresses #3 partially |
| "Don't thrash - step back after 3 tries" | Addresses #4 |

### Gaps to Address ⚠️

| Gap | Issue | Proposed Fix |
|-----|-------|--------------|
| **Pre-mortem is weak** | Risk assessment in Phase 2 is optional/light | Make pre-mortem mandatory with structured output |
| **No prove-it enforcement** | Tasks can be "done" without proof | Require concrete evidence for each criterion |
| **No rubber-duck phase** | Triage validates but doesn't clarify | Add scope clarification before planning |
| **No stay-in-lane check** | Scope creep happens during implementation | Add mid-implementation scope verification |
| **No assumption validation** | Builds on wrong assumptions | Add sanity-check prompts at key points |
| **No failure capture** | Lessons aren't systematically captured | Add retrospective to verify phase |
| **No retry limit enforcement** | "3 tries" is stated but not enforced | Make it a hard gate |
| **No confidence calibration** | Agent doesn't indicate certainty level | Add confidence markers to outputs |

---

## Proposed Improvements

### 1. Enhanced Pre-Mortem (Phase 2)

Add mandatory pre-mortem structure:

```markdown
### Pre-Mortem: It's 3 days from now and this task failed. Why?

**Likely Failure Modes:**
1. [Scenario]: [Likelihood: H/M/L] [Impact: H/M/L]
   - Mitigation: [specific action]
   - Early warning: [what to watch for]

**Unknowns that could derail:**
- [ ] [Unknown]: [How to resolve before proceeding]

**Dependencies that could break:**
- [ ] [Dependency]: [Fallback if unavailable]
```

### 2. Prove-It Verification (Phase 7)

Strengthen verification:

```markdown
### Evidence of Completion

| Criterion | Claim | Proof |
|-----------|-------|-------|
| [criterion] | [what we claim] | [command run + output OR file reference OR test result] |

**Verification Commands Run:**
- `[command]` → [result]

**No criterion marked complete without concrete evidence.**
```

### 3. Scope Guard (Phase 3)

Add mid-implementation check:

```markdown
### Scope Check (after each major change)

Original ask: [quote from task]
What I just did: [description]
Still in scope? [YES/NO]

If NO: Revert and document why this was out of scope.
```

### 4. Retry Limit Enforcement

```markdown
### Approach Tracking

| Approach | Attempts | Result |
|----------|----------|--------|
| [approach 1] | 2 | Failed: [reason] |
| [approach 2] | 1 | In progress |

**HARD LIMIT: 3 attempts per approach.**
After 3 failures with same approach:
1. STOP
2. Document what didn't work
3. Try fundamentally different approach OR escalate
```

### 5. Retrospective (Add to Phase 7)

```markdown
### Retrospective

**What worked well:**
- [thing that went smoothly]

**What was harder than expected:**
- [surprise difficulty]

**Failed approaches (for future reference):**
- [approach]: [why it didn't work]

**If doing this again:**
- [lesson learned]
```

### 6. Confidence Markers

When stating facts, use confidence markers:

```
VERIFIED: [thing I confirmed by running/reading]
INFERRED: [thing I deduced from context]
ASSUMED: [thing I believe but haven't verified]
```

---

## Implementation Priority

1. **Pre-mortem enhancement** (Phase 2) - High impact, addresses root cause
2. **Prove-it with evidence** (Phase 7) - Prevents false completions
3. **Retry limit enforcement** (Phase 3) - Prevents wasted cycles
4. **Scope guard** (Phase 3) - Prevents drift
5. **Retrospective** (Phase 7) - Enables compound learning
6. **Confidence markers** (All phases) - Builds trust

---

## References

- [Gilbert Ryle - The Concept of Mind](https://www.goodreads.com/book/show/695125.The_Concept_of_Mind)
- [Claude Skill Potions](https://github.com/ElliotJLT/Claude-Skill-Potions)
- [Andrej Karpathy's notes on coding with LLMs](https://twitter.com/kaborymk)
- [obra/superpowers](https://github.com/obra/superpowers) - TDD for skill development
