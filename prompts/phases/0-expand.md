# Phase 0: EXPAND

You are expanding a brief prompt into a full specification.

## Methodology

{{include:library/planning.md}}

## Phase Instructions

1. **Classify** the intent (BUILD/FIX/IMPROVE/REVIEW)
2. **Understand** the request - what's the smallest change that solves the problem?
3. **Analyze** the codebase - find related files, patterns, existing tests
4. **Write user stories** - For non-trivial tasks, write structured user stories:
   `As a <role>, I want <feature> so that <benefit>`
   Number them US-1, US-2, etc. For trivial tasks, skip user stories and write acceptance criteria directly.
5. **Write acceptance criteria** - Map each AC to its user story where applicable:
   `- [ ] AC-1 (US-1): [Specific testable criterion]`
6. **Write acceptance scenarios** - For each user story, write Given/When/Then scenarios with IDs:
   ```
   SC-1 (AC-1): Given <precondition>, When <action>, Then <expected result>
   ```
7. **Define success metrics** - Measurable outcomes with pass/fail thresholds:
   - **Functional**: Core behavior (e.g., "Endpoint returns 200 with valid payload")
   - **Quality**: Code standards (e.g., "All tests pass", "No lint errors")
   - **Regression**: Existing behavior preserved (e.g., "Existing tests still pass")
8. **Set scope boundaries** - Explicit in-scope and out-of-scope lists. Out-of-scope items should have exclusion reasons: `- [item] -- [why excluded]`
9. **Mark unknowns** - Tag unclear items with `[NEEDS CLARIFICATION]`
10. **Recommend priority** - Based on intent classification and urgency signals

**Scaling guidance**: Match spec depth to task complexity. A typo fix needs only acceptance criteria and success metrics. A new feature needs full user stories, scenarios, and scope boundaries.

## Output

Produce a specification with these sections:

- **Context**: Intent (BUILD/FIX/IMPROVE/REVIEW), explanation of what and why
- **Acceptance Criteria**: Specific testable criteria (AC-1, AC-2, etc.)
- **User Stories**: For non-trivial tasks (or "N/A — see Acceptance Criteria")
- **Acceptance Scenarios**: Given/When/Then for each user story
- **Success Metrics**: Functional, Quality, Regression thresholds
- **Scope**: In-scope list, out-of-scope list with exclusion reasons
- **Dependencies**: Any blockers or prerequisites
- **Notes**: Assumptions, edge cases, risks with mitigations

## Rules

- Do NOT write code - only produce the specification
- Be specific - vague specs lead to vague implementations
- Keep scope focused - note related work as out-of-scope
