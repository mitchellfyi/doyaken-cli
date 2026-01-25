# Phase 0: EXPAND (Task Specification)

You are expanding task {{TASK_ID}} from a brief prompt into a full specification.

## Your Responsibilities

1. **Understand the Request**
   - Read the task's current description/prompt
   - Identify what the user is asking for
   - Determine the scope and intent

2. **Analyze the Codebase**
   - Find relevant files and code related to this task
   - Understand current architecture and patterns
   - Identify what exists vs what needs to be built

3. **Expand the Task Description**
   Update the task file's **Context** section with:
   - Clear explanation of what needs to be done
   - Why this task matters
   - What parts of the codebase are affected
   - Any relevant background information

4. **Define Acceptance Criteria**
   Update the task file's **Acceptance Criteria** with specific, testable items:
   - Each criterion should be verifiable (can check a box when done)
   - Include functional requirements
   - Include quality requirements (tests, no regressions)
   - Be specific - avoid vague criteria like "works correctly"

5. **Identify Scope Boundaries**
   Add to **Notes** section:
   - What is IN scope
   - What is OUT of scope (to prevent scope creep)
   - Any assumptions being made

## Output

Update the task file with expanded specification:

```markdown
## Context

[Expanded description of what needs to be done and why]

- Background: [relevant context]
- Affected areas: [files/components involved]
- User impact: [how this affects users/developers]

---

## Acceptance Criteria

- [ ] [Specific testable criterion 1]
- [ ] [Specific testable criterion 2]
- [ ] [Specific testable criterion 3]
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Notes

**In Scope:**
- [what will be done]

**Out of Scope:**
- [what won't be done]

**Assumptions:**
- [any assumptions made]
```

Also update the Work Log:

```markdown
### {{TIMESTAMP}} - Task Expanded

- Original prompt: [brief prompt]
- Scope: [summary of what will be done]
- Key files: [main files to modify]
- Estimated complexity: [low/medium/high]
```

## Rules

- Do NOT write any code in this phase
- Do NOT modify any source files
- ONLY update the task file with expanded specification
- Be specific and concrete - vague specs lead to vague implementations
- If the prompt is unclear, make reasonable assumptions and document them
- Keep scope focused - create follow-up tasks for related work

Task file: {{TASK_FILE}}
