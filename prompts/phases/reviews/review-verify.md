# AI Review: VERIFY Phase

Review the VERIFY phase output for task **{{TASK_ID}}**.

## Review Pass Context

You are running review pass {{PASS_NUMBER}} of {{TOTAL_PASSES}}.

{{REVIEW_PASS_CONTEXT}}

## Review Criteria

Check the verification for:

1. **Evidence** — Is every AC proven with concrete evidence (command output, test result)?
2. **Quality gates** — Are all gates reported as passing?
3. **Loose ends** — Any TODOs, FIXMEs, console.log, debugger left?
4. **CI** — Is CI status reported and passing?
5. **Ship-ready** — Any remaining blockers? Is this truly ready to merge?

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
- Missing evidence for any AC is a FAIL
- Claims without proof are a FAIL

Task prompt: {{TASK_PROMPT}}
