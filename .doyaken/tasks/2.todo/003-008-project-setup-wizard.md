# Task: Project Setup Wizard for Multi-Agent Readiness

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-008-project-setup-wizard`                         |
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

Doyaken's vision is to be a universal tool that helps people set up their projects for AI agent usage. Currently `dk init` creates a basic `.doyaken/` structure, but it doesn't optimize the project for AI agent workflows. Competitors like Claude Code have `/init` that generates agent instruction files, Gemini has `/init` for GEMINI.md, and spec-kit has constitution files.

## Objective

Enhance `dk init` into an interactive project setup wizard that analyzes the existing project and generates optimal configuration for AI agent usage, regardless of which AI agent will be used.

## Requirements

### Project Analysis
1. Detect tech stack (language, framework, build tool, test runner)
2. Detect existing AI agent configs (CLAUDE.md, .cursorrules, AGENTS.md, GEMINI.md, .github/copilot-instructions.md)
3. Detect quality tools (linter, formatter, type checker)
4. Detect CI/CD configuration
5. Detect package manager and dependencies

### Generated Files
1. **AGENTS.md**: Universal AI agent instructions (works with any agent)
   - Project overview and architecture
   - Code conventions and patterns
   - Testing methodology
   - How to run quality checks
   - Important files and directories
2. **Agent-specific symlinks/copies**:
   - CLAUDE.md → AGENTS.md (or custom Claude instructions)
   - .cursorrules → extracted rules
   - GEMINI.md → Gemini-formatted version
   - .github/copilot-instructions.md → Copilot format
3. **.doyaken/manifest.yaml**: Populated with detected config
4. **Quality gates**: Auto-detect and configure lint/test/build commands

### Interactive Mode
1. When running `dk init` interactively:
   - Show detected tech stack, ask to confirm/correct
   - Ask which AI agents they'll use (multi-select)
   - Ask about workflow preferences (autonomous vs supervised)
   - Ask about quality gate preferences
2. Non-interactive mode with `dk init --auto` for CI/automation

### Project Health Check
1. `dk doctor` should check for:
   - Missing agent instruction files
   - Outdated config
   - Missing quality gates
   - Undetected tech stack components
2. Suggest fixes for each issue found

### Multi-Agent Config Sync
1. When AGENTS.md is updated, offer to sync to agent-specific files
2. `/sync-agents` command to manually sync

## Technical Notes

- Tech stack detection: check for package.json, Cargo.toml, go.mod, requirements.txt, etc.
- Use existing `lib/project.sh` detection logic as starting point
- Generated AGENTS.md should be project-specific, not generic boilerplate
- Keep generated files editable — don't overwrite user customizations on re-run

## Success Criteria

- [ ] `dk init` detects tech stack, framework, test runner
- [ ] Generates AGENTS.md with project-specific instructions
- [ ] Generates agent-specific config files for selected agents
- [ ] `dk doctor` reports missing or outdated configurations
- [ ] Non-interactive `dk init --auto` works for CI
- [ ] Existing user customizations preserved on re-init
