# Task: Plan Mode — Read-Only Exploration and Planning

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-009-plan-mode`                                    |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | 001-007, 002-007                                       |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Claude Code, OpenCode, and Codex all have "plan mode" — a read-only exploration mode where the agent analyzes code and generates an implementation plan without making changes. This is the safest way to start a task and gives users confidence before committing to changes.

## Objective

Add a plan mode to doyaken that runs EXPAND + TRIAGE + PLAN phases in read-only mode, generates a structured plan, and waits for user approval before proceeding to implementation.

## Requirements

### Plan Mode Entry
1. `/plan` slash command in interactive mode
2. `dk plan` CLI command
3. `dk run --plan-only` flag
4. Toggle with `/plan` (enter) and `/build` (exit) in interactive mode

### Read-Only Constraints
1. In plan mode, agent's system prompt includes: "You are in PLAN mode. Do NOT modify any files, run any destructive commands, or make any changes. Only read, analyze, and plan."
2. Agent allowed to: read files, search code, run read-only commands (git log, grep, etc.)
3. Agent NOT allowed to: write files, run tests, install packages, commit

### Plan Output
1. Generate a structured plan file: `.doyaken/plans/<task-id>-plan.md`
2. Plan format:
   ```markdown
   # Implementation Plan: <task title>

   ## Analysis
   - Current state of the codebase
   - Relevant files and patterns

   ## Approach
   - High-level strategy
   - Alternative approaches considered

   ## Changes Required
   1. File: `path/to/file.ts`
      - What: <description of change>
      - Why: <rationale>
   2. ...

   ## Test Strategy
   - What tests to add/modify
   - Edge cases to cover

   ## Risks
   - <potential issues>
   - <mitigation strategies>

   ## Estimated Complexity
   - Files to modify: N
   - New files: N
   - Estimated difficulty: Low/Medium/High
   ```

### Plan Review
1. Show plan to user in terminal with formatting
2. User can: approve (continue to implement), modify (edit plan), reject (discard)
3. Approved plan becomes context for IMPLEMENT phase

### Integration with Existing Phases
1. Plan mode = EXPAND + TRIAGE + PLAN phases
2. Build mode = IMPLEMENT + TEST + DOCS + REVIEW + VERIFY phases
3. `dk run` = all 8 phases (plan + build)

## Technical Notes

- Reuse existing phase infrastructure — plan mode just runs first 3 phases
- Add read-only flag to agent invocation that prepends constraint to system prompt
- Plan file stored alongside task file for reference
- Consider: plan mode could use a cheaper/faster model (e.g., Haiku for planning)

## Success Criteria

- [ ] `/plan` generates structured plan without modifying files
- [ ] Plan output is well-formatted with file changes, rationale, risks
- [ ] User can approve/reject plan before implementation
- [ ] Approved plan feeds into IMPLEMENT phase as context
- [ ] Read-only constraint enforced in agent prompt
- [ ] `dk plan` works from CLI without interactive mode
