# Phase 3: IMPLEMENT

You are implementing task **{{TASK_ID}}** according to the plan.

## Methodology

{{include:library/quality.md}}

{{include:library/git.md}}

## Phase Instructions

1. **Follow the plan** - Execute each step in order
2. **Verify after each change** - Run quality gates identified in triage
3. **Commit frequently** - After each logical change
4. **Handle deviations** - Document why if plan changes

## Verification Loop

After modifying each file, run the project's quality gates.

If checks fail: **STOP → FIX → VERIFY → CONTINUE**

## Output

Add to Work Log for each step:

```markdown
### {{TIMESTAMP}} - Implementation Progress

Step [N]: [description]
- Files modified: [list]
- Verification: [pass/fail]
- Commit: [hash]

[If deviation]:
- Deviation: [what changed]
- Reason: [why]
```

## Completion Signal

When you are done with this phase, include a structured status block in your output:

```
DOYAKEN_STATUS:
  PHASE_COMPLETE: true/false
  FILES_MODIFIED: <count>
  TESTS_STATUS: pass/fail/skip/unknown
  CONFIDENCE: high/medium/low
  REMAINING_WORK: <brief description or "none">
```

## Rules

- **VERIFY after every file change** - don't accumulate broken state
- **COMMIT frequently** - small, logical commits
- Do NOT write tests (next phase)
- Do NOT update documentation (later phase)
- FOCUS only on implementation code

{{VERIFICATION_CONTEXT}}

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
