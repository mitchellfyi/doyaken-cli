---
description: Apply debugging methodology
---

# Debugging Methodology

## Mindset

- **Reproduce first** - Can't fix what you can't see
- **One change at a time** - Otherwise you won't know what worked
- **Trust nothing** - Verify assumptions with evidence
- **Simplify** - Reduce to minimal reproducing case

## The Scientific Method

1. **Observe** - What exactly is happening?
2. **Hypothesize** - What could cause this?
3. **Predict** - If hypothesis is true, what else should we see?
4. **Test** - Check the prediction
5. **Conclude** - Was hypothesis correct? Repeat if not.

## Step 1: Reproduce the Bug

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

## Step 2: Gather Evidence

Collect all available information:

### Error Messages
- Full stack trace
- Error codes
- Any logged context

### Environment
- What version of the code?
- What OS/browser/runtime?
- What data was involved?
- What happened just before?

### Timeline
- When did it start happening?
- What changed around that time?
- Does it happen at specific times?

## Step 3: Form Hypotheses

Common bug categories to consider:

| Category | Look For |
|----------|----------|
| **Input** | Invalid data, edge cases, encoding |
| **State** | Race conditions, stale cache, wrong order |
| **Environment** | Config differences, missing deps, permissions |
| **Integration** | API changes, network issues, timeouts |
| **Logic** | Off-by-one, wrong operator, missing case |
| **Resources** | Memory leaks, connection exhaustion, disk full |

### Prioritize Hypotheses
- Most likely based on evidence
- Easiest to test/eliminate
- Most recently changed code

## Step 4: Isolate the Problem

### Binary Search
If unsure where the bug is:
1. Find a known good state (older commit, simpler input)
2. Find the bad state
3. Bisect to find exact point of failure

```bash
git bisect start
git bisect bad HEAD
git bisect good v1.0.0
# Git will guide you through testing commits
```

### Simplify the Case
- Remove components until bug disappears
- Add back until it reappears
- Minimal reproduction is valuable

### Add Logging
Strategic logging points:
- Function entry/exit
- Before/after state changes
- Decision points (if/else branches)
- External calls (API, DB)

## Step 5: Fix and Verify

### The Fix
- Fix the root cause, not the symptom
- Understand WHY the bug happened
- Consider if similar bugs exist elsewhere

### Verification
- [ ] Bug no longer reproduces
- [ ] No new bugs introduced (run all tests)
- [ ] Edge cases handled
- [ ] Fix makes sense (review your own code)

### Prevention
- Add a test that would have caught this
- Consider if tooling could prevent similar bugs
- Document if it was a subtle issue

## Common Debugging Techniques

### Print Debugging
Simple but effective:
- Add logging at suspicious locations
- Include relevant variable values
- Use markers to identify output (e.g., ">>> checkpoint 1")

Clean up after! Never commit debug logs.

### Debugger
Step through code execution:
- Set breakpoints at suspicious locations
- Inspect variable values
- Step into/over/out of functions
- Watch expressions

### Rubber Duck Debugging
Explain the problem out loud:
- Forces you to articulate assumptions
- Often reveals the issue mid-explanation
- Works with any patient listener (or duck)

### Diff Against Working State
```bash
git diff HEAD~5  # What changed recently?
git log --oneline -10  # What commits might be relevant?
```

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **Random changes** | Wastes time, obscures root cause | Systematic hypothesis testing |
| **Blame others first** | Delays finding real cause | Assume your code until proven otherwise |
| **Fix symptoms** | Bug will return | Find and fix root cause |
| **Debug in production** | Risky, stressful | Reproduce locally first |
| **No test after fix** | Bug may recur | Add regression test |

## When You're Stuck

- Take a break (seriously, it helps)
- Explain it to someone else
- Sleep on it
- Question your assumptions
- Read the documentation again
- Search for similar issues (GitHub, Stack Overflow)
- Ask for help with clear problem statement

## Debugging Checklist

- [ ] Can reproduce the bug consistently
- [ ] Collected all relevant evidence
- [ ] Formed specific hypotheses
- [ ] Tested hypotheses systematically
- [ ] Found root cause (not just symptom)
- [ ] Fix verified to resolve issue
- [ ] No regressions introduced
- [ ] Test added to prevent recurrence

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
