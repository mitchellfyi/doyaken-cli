# Task: Enhanced Spec Generation in EXPAND Phase (Spec-Kit Inspired)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-007-enhanced-spec-generation`                     |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

GitHub's spec-kit uses a structured specification format (user stories, acceptance criteria, success metrics) that improves AI agent output quality by 25%. Doyaken's EXPAND phase already generates expanded task descriptions, but they lack the structured format that helps agents produce better code. We should adopt the best parts of spec-kit's approach while avoiding its heavyweight "reinvented waterfall" problems.

## Objective

Enhance the EXPAND phase prompt to generate structured specifications with user stories, acceptance criteria, and measurable success criteria — without requiring a separate spec-driven workflow.

## Requirements

### Enhanced Task Spec Format
After EXPAND phase, the task file should contain:

```markdown
## Specification

### User Stories
- **US-1** [P1]: As a <role>, I want <feature> so that <benefit>
  - GIVEN <context> WHEN <action> THEN <result>
  - GIVEN <context> WHEN <action> THEN <result>

### Acceptance Criteria
- [ ] AC-1: <measurable criterion>
- [ ] AC-2: <measurable criterion>

### Success Metrics
- SM-1: <quantifiable metric> (e.g., "Tests pass with >80% coverage")

### Scope
- **In scope**: <what this task covers>
- **Out of scope**: <what this task does NOT cover>

### Dependencies
- <dependency on other tasks or systems>
```

### EXPAND Phase Prompt Update
1. Update `.doyaken/prompts/phases/0-expand.md` to instruct agent to:
   - Generate user stories from the brief task description
   - Write Given/When/Then acceptance scenarios
   - Define measurable success criteria
   - Identify scope boundaries
   - Mark unclear items with `[NEEDS CLARIFICATION]`
2. Include template/examples in the prompt

### Task Template Update
1. Update `dk tasks new` to include spec section placeholders
2. When creating tasks interactively, prompt for basic user story

### TRIAGE Phase Integration
1. TRIAGE phase should validate spec completeness
2. Flag missing acceptance criteria or vague success metrics
3. Check for `[NEEDS CLARIFICATION]` markers

### Brownfield Support
1. For tasks on existing codebases, EXPAND should:
   - Reference existing architecture/patterns
   - Check for related existing code
   - Note integration points

## Technical Notes

- This is primarily a prompt engineering task — updating phase prompts
- Task file format is markdown, so the spec section is just new markdown sections
- Don't require spec completion for small tasks (bug fixes, typos)
- Add a `--quick` flag to skip spec generation for trivial tasks

## Success Criteria

- [ ] EXPAND phase generates structured user stories with acceptance criteria
- [ ] Given/When/Then format used for acceptance scenarios
- [ ] Success metrics are measurable
- [ ] TRIAGE phase validates spec completeness
- [ ] Small tasks can skip detailed spec with `--quick`
- [ ] Spec section visible in task file after EXPAND
