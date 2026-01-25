# Phase 0: EXPAND (Task Specification)

You are expanding task {{TASK_ID}} from a brief prompt into a full specification.

## 1) Classify the Intent

Determine what type of work this is:

| Intent | Description | Signals |
|--------|-------------|---------|
| **BUILD** | New feature or capability | "add", "create", "implement", "new" |
| **FIX** | Bug fix or error resolution | "fix", "broken", "error", "doesn't work" |
| **IMPROVE** | Enhance existing functionality | "improve", "optimize", "refactor", "better" |
| **REVIEW** | Audit, analyze, or document | "review", "audit", "check", "document" |

This classification guides how thorough the specification needs to be.

## 2) Understand the Request

- Read the task's current description/prompt
- Identify what the user is actually asking for (not what you think they need)
- Determine the scope - what's the smallest change that solves the problem?
- Check if this overlaps with or depends on other tasks

## 3) Analyze the Codebase

Before specifying what to build, understand what exists:

- Find ALL files related to this task's domain
- Understand current architecture and patterns
- Check existing tests - what's covered, what's missing?
- Identify what exists vs what needs to be built
- Note any conventions or patterns to follow

## 4) Define Acceptance Criteria

Write specific, testable criteria. Each criterion should be:

- **Verifiable** - Can objectively check if it's done
- **Atomic** - One thing per criterion
- **Necessary** - Actually required for the task (no gold-plating)

Bad: "Works correctly" / "Handles errors properly"
Good: "Returns 404 when user not found" / "Logs error message with request ID"

## 5) Identify Edge Cases and Risks

Consider what could go wrong:

- What happens with empty/null/invalid input?
- What if external services fail?
- Are there race conditions or concurrency concerns?
- What existing functionality might break?

## 6) Set Scope Boundaries

Prevent scope creep by being explicit:

- **In scope**: What WILL be done
- **Out of scope**: What WON'T be done (even if related)
- **Assumptions**: What we're taking for granted

## Output

Update the task file with expanded specification:

```markdown
## Context

**Intent**: BUILD / FIX / IMPROVE / REVIEW

[Clear explanation of what needs to be done and why]

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

**Edge Cases:**
- [edge case 1 and how it should be handled]

**Risks:**
- [potential risk and mitigation]
```

Also update the Work Log:

```markdown
### {{TIMESTAMP}} - Task Expanded

- Intent: [BUILD/FIX/IMPROVE/REVIEW]
- Original prompt: [brief prompt]
- Scope: [summary of what will be done]
- Key files: [main files to modify]
- Complexity: [low/medium/high]
- Risks: [key risks identified]
```

## Rules

- Do NOT write any code in this phase
- Do NOT modify any source files
- ONLY update the task file with expanded specification
- Be specific and concrete - vague specs lead to vague implementations
- If the prompt is unclear, make reasonable assumptions and document them
- Keep scope focused - create follow-up tasks for related work
- Prefer the smallest change that solves the problem

Task file: {{TASK_FILE}}
