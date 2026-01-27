---
description: Apply diagnose methodology
---

# Diagnose (Debugging & Troubleshooting)

You are diagnosing a problem in the codebase.

## Debugging Methodology

{{include:library/debugging.md}}

## Output Format

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

## Rules

- Don't guess - verify each hypothesis
- Fix root causes, not symptoms
- Always add a regression test
- Document the investigation for future reference
- If stuck after 3 attempts, step back and reassess

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
