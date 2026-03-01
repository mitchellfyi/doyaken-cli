# AI Review: PLAN Phase

Review the PLAN phase output for task **{{TASK_ID}}**.

## Review Pass Context

You are running review pass {{PASS_NUMBER}} of {{TOTAL_PASSES}}.

{{REVIEW_PASS_CONTEXT}}

## Review Criteria

Check the plan for:

1. **Acceptance criteria** — Are they specific and testable? No vague terms?
2. **Scope** — Is it clearly bounded? In-scope and out-of-scope defined?
3. **Implementation steps** — Are they concrete, ordered, and verifiable?
4. **Gap analysis** — Is it complete for each criterion?
5. **Quality gates** — Were they discovered and listed in the QUALITY_GATES block? Format must be exact: `lint:cmd`, `format:cmd`, `test:cmd`, `build:cmd` (one per line, empty if none)

## Output Format

End your review with exactly one of:

```
REVIEW_RESULT: PASS
```

or

```
REVIEW_RESULT: FAIL

[Specific issues found, one per line. Be concrete.]
```

## Rules

- Be thorough but focused
- Only FAIL if there are real issues that would cause problems in later phases
- Missing or malformed QUALITY_GATES block is a FAIL
- Vague acceptance criteria are a FAIL

Task prompt: {{TASK_PROMPT}}
