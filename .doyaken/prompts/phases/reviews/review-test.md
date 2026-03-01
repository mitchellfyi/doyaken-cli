# AI Review: TEST Phase

Review the TEST phase output for task **{{TASK_ID}}**.

## Review Pass Context

You are running review pass {{PASS_NUMBER}} of {{TOTAL_PASSES}}.

{{REVIEW_PASS_CONTEXT}}

## Review Criteria

Check the tests and docs for:

1. **Test coverage** — Do tests cover the acceptance criteria? Edge cases?
2. **Test quality** — Can tests actually fail? No trivial assertions? Error paths tested?
3. **Flaky patterns** — Timing-dependent, order-dependent, or non-deterministic tests?
4. **Documentation** — Do docs match the implementation? API docs accurate?
5. **Completeness** — All new public functions have tests? Docs updated where needed?

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
- Tests that can't catch bugs are a FAIL
- Outdated docs are a FAIL

Task prompt: {{TASK_PROMPT}}
