# Phase 0: EXPAND

You are expanding task **{{TASK_ID}}** from a brief prompt into a full specification.

## Methodology

{{include:library/planning.md}}

## Phase Instructions

1. **Classify** the intent (BUILD/FIX/IMPROVE/REVIEW)
2. **Understand** the request - what's the smallest change that solves the problem?
3. **Analyze** the codebase - find related files, patterns, existing tests
4. **Write user stories** - For non-trivial tasks, write structured user stories:
   `As a <role>, I want <feature> so that <benefit>`
   Number them US-1, US-2, etc. For trivial tasks (typo fixes, small bug fixes), skip user stories and write acceptance criteria directly.
5. **Write acceptance scenarios** - For each user story, write Given/When/Then scenarios:
   ```
   Given <precondition>
   When <action>
   Then <expected result>
   ```
6. **Define success metrics** - Measurable outcomes (e.g., "Tests pass", "No regressions", "Lint clean", "Response time < 200ms")
7. **Set scope boundaries** - Explicit in-scope and out-of-scope lists
8. **Mark unknowns** - Tag unclear items with `[NEEDS CLARIFICATION]`
9. **Recommend priority** - Based on intent classification and urgency signals:
   - 001 (Critical): Security vulnerabilities, data loss, production outages
   - 002 (High): Bugs affecting users, blocking dependencies, urgent fixes
   - 003 (Medium): Feature work, improvements, moderate bugs
   - 004 (Low): Nice-to-haves, minor polish, documentation-only

**Scaling guidance**: Match spec depth to task complexity. A typo fix needs only acceptance criteria and success metrics. A new feature needs full user stories, scenarios, and scope boundaries.

## Output

Update the task file with these sections:

```markdown
## Context

**Intent**: BUILD / FIX / IMPROVE / REVIEW

[Clear explanation of what and why]

---

## Acceptance Criteria

- [ ] AC-1: [Specific testable criterion]
- [ ] AC-N: Tests written and passing
- [ ] AC-N: Quality gates pass
- [ ] AC-N: Changes committed with task reference

---

## Specification

### User Stories

- **US-1**: As a [role], I want [feature] so that [benefit]
- **US-2**: ...

(For trivial tasks: "N/A — see Acceptance Criteria above")

### Acceptance Scenarios

**US-1:**
- Given [precondition], When [action], Then [expected result]

**US-2:**
- Given ..., When ..., Then ...

### Success Metrics

- [ ] [Measurable outcome, e.g., "All tests pass", "No lint errors"]

### Scope

**In Scope:**
- [what will be done]

**Out of Scope:**
- [what won't be done]

### Dependencies

- [dependencies, or "None"]

---

## Notes

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
- Recommended priority: [001-004] [label] - [reason]
```

## Rules

- Do NOT write code - only update the task file
- Be specific - vague specs lead to vague implementations
- Keep scope focused - create follow-up tasks for related work
- Scale spec depth to task complexity - don't over-specify trivial work
- Mark anything unclear with `[NEEDS CLARIFICATION]`

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
