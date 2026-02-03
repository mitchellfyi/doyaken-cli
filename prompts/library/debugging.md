# Debugging Methodology

## Mindset

- **Clarify before solving** - Understand the problem before proposing fixes
- **Reproduce first** - Can't fix what you can't see
- **One change at a time** - Otherwise you won't know what worked
- **Trust nothing** - Verify assumptions with evidence
- **Prove the fix** - Run the code, don't assume it works

## The Debug Cycle

**CLARIFY → INVESTIGATE → FIX → VERIFY**

Don't skip steps. The #1 debugging mistake is jumping to fixes before understanding the problem.

## Step 1: Clarify the Problem

Before investigating, make sure you understand:

1. **What should happen?** (Expected behavior)
2. **What actually happens?** (Observed behavior)
3. **What was already tried?** (Eliminate paths)

**State the problem in one sentence:**
> "When I [action], I expect [expected], but instead [actual]."

Write this down. If you can't state it clearly, you don't understand it yet.

## Step 2: Reproduce the Bug

Before anything else, confirm you can trigger the bug:

- [ ] Can reproduce consistently?
- [ ] What are the exact steps?
- [ ] What inputs trigger it?
- [ ] Does it happen in all environments?

**If you can't reproduce it:**
- Check logs for the original occurrence
- Look for race conditions (timing-dependent)
- Try different data combinations
- Check for environment-specific factors

## Step 3: Investigate (Don't Guess)

### Verify Assumptions

List what you're assuming about the code:

| Assumption | How to Verify | Status |
|------------|---------------|--------|
| [e.g., "Function X does Y"] | Read the function | ✓/✗ |
| [e.g., "Config is set to Z"] | Check config | ✓/✗ |

**STOP if assumptions are wrong.** Reassess before continuing.

### Gather Evidence

- Full stack trace, not just the message
- What version of code? What environment?
- What changed recently? (`git log --oneline -10`)
- What happened just before the error?

### Common Bug Categories

| Category | Look For |
|----------|----------|
| **Input** | Invalid data, edge cases, encoding |
| **State** | Race conditions, stale cache, wrong order |
| **Environment** | Config differences, missing deps, permissions |
| **Integration** | API changes, network issues, timeouts |
| **Logic** | Off-by-one, wrong operator, missing case |
| **Resources** | Memory leaks, connection exhaustion, disk full |

### State the Root Cause

Before fixing, write:
> "The bug happens because [specific cause]."
> "I know this because [evidence]."

If you can't write these sentences, you haven't found the root cause yet.

## Step 4: Fix (Minimal and Focused)

- Fix the root cause, not the symptom
- Smallest change that solves the problem
- Don't refactor while fixing bugs (separate concerns)
- Consider if similar bugs exist elsewhere

**Before writing code, state:**
1. What you're changing
2. Why this fixes the root cause
3. Risk of this change breaking something else

## Step 5: Verify (Prove It Works)

Don't say "fixed" until you've verified:

- [ ] Original bug no longer reproduces
- [ ] Tested the exact scenario from Step 1
- [ ] No new bugs introduced (run all tests)
- [ ] Edge cases handled

**Show evidence:**
```
Verified:
- Ran [command] → [result]
- Tested [scenario] → [expected behavior]
- Tests pass: [output]
```

"Looks fixed" ≠ "Is fixed"

## Step 6: Prevent Recurrence

- Add a test that would have caught this
- Document if it was a subtle issue
- Consider if tooling could prevent similar bugs

## Debugging Techniques

### Binary Search
```bash
git bisect start
git bisect bad HEAD
git bisect good v1.0.0
# Git guides you to the breaking commit
```

### Strategic Logging
- Function entry/exit
- Before/after state changes
- Decision points (if/else branches)
- External calls (API, DB)

Clean up after - never commit debug logs.

### Rubber Duck Debugging
Explain the problem out loud. Forces you to articulate assumptions.

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **Jumping to fixes** | Solving wrong problem | Clarify first |
| **Random changes** | Wastes time, obscures cause | Systematic testing |
| **Assuming it works** | Bug returns | Verify with evidence |
| **Fix symptoms** | Root cause remains | Find actual cause |
| **Debug in production** | Risky, stressful | Reproduce locally |

## When Stuck

1. Take a break (genuinely helps)
2. Explain it to someone (or a duck)
3. Question your assumptions - are they verified?
4. Check what changed recently
5. Search for similar issues
6. Ask for help with clear problem statement

After 3 failed attempts at the same approach: **try something different**.

## Debugging Output Template

```markdown
## Debug: [Brief description]

### Problem
When I [action], I expect [expected], but instead [actual].

### Investigation
Assumptions verified:
- [assumption] → [verified/wrong]

Root cause: [specific cause]
Evidence: [how you know]

### Fix
Changed: [what]
Why: [addresses root cause]

### Verification
- [x] Original bug fixed: [evidence]
- [x] Tests pass: [output]
- [x] No regressions: [how checked]
```
