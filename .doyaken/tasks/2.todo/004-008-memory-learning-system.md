# Task: Cross-Session Memory & Learning System

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `004-008-memory-learning-system`                       |
| Status      | `todo`                                                 |
| Priority    | `004` Low                                              |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | 002-008                                                |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

GitHub Copilot's memory system (repository-scoped, citation-based, self-healing) shows a 7% improvement in task completion. Claude Code has auto-memory with MEMORY.md. OpenCode has a skills system for institutional knowledge. Doyaken should build on its existing prompts library to create a project-specific memory system.

## Objective

Implement a project-scoped memory system that accumulates knowledge across sessions — patterns discovered, conventions learned, common errors, architecture decisions — and feeds this context to the agent automatically.

## Requirements

### Memory Storage
1. Store in `.doyaken/memory/MEMORY.md` (primary, always loaded)
2. Topic files: `.doyaken/memory/<topic>.md` for detailed notes
3. Memory file loaded into agent system prompt for every invocation

### Memory Accumulation
1. After each completed task, prompt agent: "What did you learn about this codebase that would help future tasks?"
2. Agent writes insights to memory (patterns, conventions, gotchas)
3. Insights include code references (file:line) for verification

### Memory Curation
1. `/memory` — show current memory contents
2. `/memory add <note>` — manually add a memory note
3. `/memory forget <topic>` — remove outdated memory
4. Memory auto-curated: when MEMORY.md exceeds 200 lines, agent summarizes
5. Periodic verification: check cited code references still exist

### Categories
- **Architecture**: Project structure, key abstractions, data flow
- **Conventions**: Naming, formatting, patterns in use
- **Gotchas**: Common errors, tricky behaviors, known issues
- **Dependencies**: Key libraries, versions, compatibility notes
- **Testing**: Test patterns, fixtures, common assertions

### Integration
1. EXPAND phase loads memory to inform spec generation
2. PLAN phase loads memory for architecture-aware planning
3. IMPLEMENT phase loads memory for convention-following
4. REVIEW phase loads memory to check convention compliance

## Technical Notes

- Keep MEMORY.md under 200 lines (concise, curated)
- Use topic files for details, link from MEMORY.md
- Memory is project-scoped (in .doyaken/), not global
- Similar to Claude Code's auto-memory pattern
- Don't overwrite user edits — append and let user curate

## Success Criteria

- [ ] MEMORY.md auto-populated after task completion
- [ ] Memory loaded into agent context for every invocation
- [ ] `/memory` commands work for viewing and editing
- [ ] Memory auto-curated when exceeding size limit
- [ ] Code references included and periodically verified
