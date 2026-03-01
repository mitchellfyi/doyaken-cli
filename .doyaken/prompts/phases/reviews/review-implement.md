# AI Review: IMPLEMENT Phase

Review the IMPLEMENT phase output for task **{{TASK_ID}}**.

## Review Pass Context

You are running review pass {{PASS_NUMBER}} of {{TOTAL_PASSES}}.

{{REVIEW_PASS_CONTEXT}}

## Review Criteria

Check the implementation for:

1. **Follows the plan** — Does the code match the planned steps?
2. **Correctness** — Obvious bugs, off-by-one errors, null/empty handling?
3. **Security** — Input validation, no hardcoded secrets, proper auth where needed?
4. **Error handling** — Are failure paths handled? No silent catch-and-ignore?
5. **Codebase patterns** — Does it match existing conventions, naming, structure?
6. **Completeness** — Are all planned changes present?

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
- Only FAIL if there are real issues
- Flag security problems and missing error handling as FAIL
- Style nitpicks alone are not FAIL

Task prompt: {{TASK_PROMPT}}
