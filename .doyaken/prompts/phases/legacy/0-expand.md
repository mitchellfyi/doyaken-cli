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
5. **Write acceptance criteria** - Map each AC to its user story:
   `- [ ] AC-1 (US-1): [Specific testable criterion]`
   For trivial tasks without user stories, omit the `(US-N)` mapping.
6. **Write acceptance scenarios** - For each user story, write Given/When/Then scenarios with IDs:
   ```
   SC-1 (AC-1): Given <precondition>, When <action>, Then <expected result>
   SC-2 (AC-1): Given <alternate precondition>, When <action>, Then <expected result>
   ```
7. **Define success metrics** - Organize into mandatory categories:
   - **Functional**: Core behavior works (e.g., "Endpoint returns 200 with valid payload")
   - **Quality**: Code quality standards met (e.g., "All tests pass", "No lint errors", "No type errors")
   - **Regression**: Existing behavior unchanged (e.g., "Existing API tests still pass")
   - **Performance** (if relevant): Measurable thresholds (e.g., "Response time < 200ms for N=1000")
   Every metric must have a pass/fail threshold. No vague outcomes.
8. **Set scope boundaries** - Explicit in-scope and out-of-scope lists. Every out-of-scope item must have an exclusion reason: `- [item] -- [why excluded]`
9. **Identify key files** - List the 3-5 most relevant existing files with patterns to follow. This bridges to the PLAN phase.
10. **Mark unknowns** - Tag unclear items with `[NEEDS CLARIFICATION]: [question] -- [why it matters]`
11. **Recommend priority** - Based on intent classification and urgency signals:
   - 001 (Critical): Security vulnerabilities, data loss, production outages
   - 002 (High): Bugs affecting users, blocking dependencies, urgent fixes
   - 003 (Medium): Feature work, improvements, moderate bugs
   - 004 (Low): Nice-to-haves, minor polish, documentation-only

**Scaling guidance** - Match spec depth to task complexity:
- **Trivial** (typo, config change): AC list + success metrics only. No user stories, no scenarios.
- **Small** (single-file bug fix, simple addition): ACs + success metrics + scope. User stories optional.
- **Medium** (multi-file feature, refactoring): Full spec — user stories, ACs with traceability, scenarios, all metric categories, key files.
- **Large** (new subsystem, cross-cutting change): Full spec + explicit clarifications section + dependency analysis + risk assessment.

**Anti-vagueness rules** - The following terms are BANNED in acceptance criteria and success metrics unless accompanied by a measurable threshold:
"works correctly", "is fast", "is clean", "handles properly", "is robust", "is secure", "performs well", "is user-friendly", "is reliable", "scales well"
Replace with specific, testable conditions.

## Output

Update the task file with these sections:

```markdown
## Context

**Intent**: BUILD / FIX / IMPROVE / REVIEW

[Clear explanation of what and why]

---

## Acceptance Criteria

- [ ] AC-1 (US-1): [Specific testable criterion]
- [ ] AC-N (US-N): Tests written and passing
- [ ] AC-N: Quality gates pass (lint, format, type-check, build)
- [ ] AC-N: Changes committed with task reference

---

## Specification

### User Stories

- **US-1**: As a [role], I want [feature] so that [benefit]
- **US-2**: ...

(For trivial tasks: "N/A — see Acceptance Criteria above")

### Acceptance Scenarios

**US-1:**
- SC-1 (AC-1): Given [precondition], When [action], Then [expected result]
- SC-2 (AC-1): Given [alternate case], When [action], Then [expected result]

**US-2:**
- SC-N (AC-N): Given ..., When ..., Then ...

(For trivial tasks: "N/A")

### Success Metrics

**Functional:**
- [ ] [Specific behavior with pass/fail threshold]

**Quality:**
- [ ] All tests pass (0 failures)
- [ ] No lint errors (shellcheck/eslint exit 0)

**Regression:**
- [ ] Existing test suite passes (0 new failures)

**Performance:** (if relevant)
- [ ] [Metric with threshold, e.g., "Response time < 200ms at p95"]

### Key Files

| File | Relevance | Pattern to Follow |
|------|-----------|-------------------|
| `path/to/file` | [why relevant] | [pattern/convention to match] |

(3-5 most relevant files — bridges to PLAN phase)

### Scope

**In Scope:**
- [what will be done]

**Out of Scope:**
- [item] -- [why excluded]

### Dependencies

- [dependencies, or "None"]

### Clarifications

- [NEEDS CLARIFICATION]: [question] -- [why it matters]

(If none: "No clarifications needed")

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
- Stories: [N user stories]
- Scenarios: [N acceptance scenarios]
- Clarifications: [N items, or "none"]
- Key files: [files to modify]
- Complexity: [trivial/small/medium/large]
- Recommended priority: [001-004] [label] - [reason]
```

## Rules

- Do NOT write code - only update the task file
- Be specific - vague specs lead to vague implementations
- Keep scope focused - create follow-up tasks for related work
- Scale spec depth to task complexity - don't over-specify trivial work
- Mark anything unclear with `[NEEDS CLARIFICATION]: [question] -- [why it matters]`
- Every AC must be testable — if you can't describe how to verify it, rewrite it
- Every out-of-scope item must explain why it's excluded

{{VERIFICATION_CONTEXT}}

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
