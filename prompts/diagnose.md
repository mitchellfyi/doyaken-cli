# Diagnose (Debugging & Troubleshooting)

You are diagnosing a problem in the codebase.

## Mindset

- **Scientific method** - Observe, hypothesize, test, conclude
- **Bisect, don't guess** - Narrow down systematically
- **Verify fixes** - Confirm the root cause, not just symptoms
- **Document findings** - Your investigation helps future debugging

## 1) Understand the Symptom

Before diving into code, clearly articulate:

- **What's happening?** (actual behaviour)
- **What should happen?** (expected behaviour)
- **When does it happen?** (always, sometimes, specific conditions)
- **When did it start?** (recent change, always broken, regression)

## 2) Gather Evidence

Collect information before forming hypotheses:

```
Error messages:
- [exact error text]

Stack traces:
- [relevant stack trace]

Logs:
- [relevant log entries]

Steps to reproduce:
1. [step 1]
2. [step 2]
3. [observe symptom]

Environment:
- [relevant env details]
```

## 3) Form Hypotheses

Based on evidence, list possible causes:

| # | Hypothesis | Likelihood | How to test |
|---|------------|------------|-------------|
| 1 | [possible cause] | high/med/low | [test method] |
| 2 | [possible cause] | high/med/low | [test method] |

Start with the most likely hypothesis.

## 4) Test Hypotheses (Bisect)

Test systematically, don't guess:

**For regressions:**
```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# ... follow prompts
```

**For logic errors:**
- Add strategic logging/breakpoints
- Trace execution path
- Check assumptions at each step

**For data issues:**
- Inspect actual data at each stage
- Compare expected vs actual values
- Check for edge cases (null, empty, boundary)

## 5) Identify Root Cause

Once you've narrowed down:

- **What** is the actual bug? (specific line/logic)
- **Why** does it cause the symptom?
- **When** was it introduced? (if regression)
- **How widespread** is the impact?

## 6) Fix and Verify

1. Make the minimal fix for the root cause
2. Write a regression test that fails before fix, passes after
3. Verify the original symptom is resolved
4. Check for side effects

## 7) Document Findings

```
### Diagnosis Summary

Symptom:
- [what was observed]

Root cause:
- [what was actually wrong]

Fix:
- [what was changed]

Regression test:
- [test added to prevent recurrence]

Lessons:
- [what can prevent similar issues]
```

## Common Debugging Patterns

### "Works on my machine"
- Check environment differences (versions, config, data)
- Check for hardcoded paths or assumptions
- Check for race conditions or timing issues

### Intermittent failures
- Look for race conditions
- Check for shared mutable state
- Look for external dependencies (network, time, random)

### Silent failures
- Check error handling (are exceptions swallowed?)
- Check for early returns without logging
- Add defensive logging at key points

### Performance issues
- Profile before optimizing
- Look for N+1 queries, expensive loops
- Check for blocking I/O on hot paths

## Rules

- Don't guess - verify each hypothesis
- Fix root causes, not symptoms
- Always add a regression test
- Document the investigation for future reference
- If stuck after 3 attempts, step back and reassess
