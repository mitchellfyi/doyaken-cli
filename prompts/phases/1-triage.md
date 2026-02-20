# Phase 1: TRIAGE

You are validating the task before work begins.

## Phase Instructions

1. **Clarify scope** - Can you state the goal in one sentence? What's OUT of scope?
2. **Validate assumptions** - List what you're assuming. Verify key assumptions before proceeding.
3. **Discover quality gates** - Check CI, lint/format/test/build commands
4. **Validate specification** - Context clear? Criteria testable? Scope defined?
5. **Check dependencies** - Are blockers resolved?
6. **Assess complexity** - Files affected, risk level, test coverage needed

## Scope Clarification

Before proceeding, verify you can answer:

- **What are we building?** → [One sentence goal]
- **What's the definition of done?** → [Verifiable criteria from task]
- **What's explicitly OUT of scope?** → [Things we're NOT doing]

If any of these are unclear, note the ambiguity. Vague scope leads to wasted work.

## Assumption Validation

List key assumptions about this task:

| Assumption | How to Verify | Status |
|------------|---------------|--------|
| [e.g., "API endpoint exists"] | grep/read code | ✓ Verified / ✗ Wrong |
| [e.g., "Config supports X"] | check config | ✓ Verified / ✗ Wrong |

**STOP if a key assumption is wrong.** Don't build on false foundations.

## Output

Produce a triage summary:

- **Goal**: One sentence
- **Done when**: Verifiable criteria
- **Out of scope**: Explicit exclusions
- **Assumptions**: Each validated or flagged as wrong
- **Quality gates**: Lint, types, tests, build commands (or "missing")
- **Complexity**: Files (few/some/many), risk (low/medium/high)
- **Ready**: Yes or No with reason

## Rules

- Do NOT write code - only validate readiness
- Do NOT proceed with vague scope - clarify first
- Do NOT build on unverified assumptions - check them
- If not ready, explain why and STOP
- If blocked, report the blocker and do not proceed
- If quality gates are missing, flag as risk
