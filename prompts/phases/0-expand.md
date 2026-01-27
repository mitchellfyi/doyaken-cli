# Phase 0: EXPAND

You are expanding task **{{TASK_ID}}** from a brief prompt into a full specification.

## Methodology

{{include:library/planning.md}}

## Phase Instructions

1. **Classify** the intent (BUILD/FIX/IMPROVE/REVIEW)
2. **Understand** the request - what's the smallest change that solves the problem?
3. **Analyze** the codebase - find related files, patterns, existing tests
4. **Define** acceptance criteria - specific, testable, no vague language
5. **Identify** edge cases and risks
6. **Set** scope boundaries (in/out of scope)

## Output

Update the task file's Context, Acceptance Criteria, and Notes sections:

```markdown
## Context

**Intent**: BUILD / FIX / IMPROVE / REVIEW

[Clear explanation of what and why]

---

## Acceptance Criteria

- [ ] [Specific testable criterion]
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Notes

**In Scope:** [what will be done]
**Out of Scope:** [what won't be done]
**Assumptions:** [any assumptions]
**Edge Cases:** [cases and handling]
**Risks:** [risks and mitigation]
```

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Task Expanded

- Intent: [BUILD/FIX/IMPROVE/REVIEW]
- Scope: [summary]
- Key files: [files to modify]
- Complexity: [low/medium/high]
```

## Rules

- Do NOT write code - only update the task file
- Be specific - vague specs lead to vague implementations
- Keep scope focused - create follow-up tasks for related work

Task file: {{TASK_FILE}}
