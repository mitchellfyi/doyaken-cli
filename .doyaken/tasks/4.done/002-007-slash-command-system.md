# Task: Extensible Slash Command System

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-007-slash-command-system`                          |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | 001-007                                                |
| Blocks      | 002-008, 002-009                                       |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Every major AI CLI tool (Claude Code, OpenCode, Codex, Gemini, Aider) uses slash commands as the primary user interaction pattern. Doyaken needs an extensible slash command system that integrates with the interactive REPL.

## Objective

Build a slash command registry and dispatch system. Commands should be discoverable, extensible, and support tab-completion.

## Requirements

### Command Registry
1. Commands registered in `lib/commands.sh` with a simple pattern:
   ```bash
   register_command "name" "description" "handler_function"
   ```
2. Handler functions receive remaining args: `cmd_help() { ... }`
3. Support fuzzy matching for partial commands (`/he` → `/help`)
4. Show error with suggestions for ambiguous matches

### Built-in Commands (Phase 1)

| Command | Description |
|---------|-------------|
| `/help` | List all commands with descriptions |
| `/quit` `/exit` | Exit interactive mode |
| `/clear` | Clear terminal screen |
| `/status` | Show task board summary |
| `/tasks` | List tasks (todo/doing/done counts) |
| `/task <id>` | Show task details |
| `/pick <id>` | Pick up a specific task |
| `/run` | Run all phases on current task |
| `/phase <name>` | Run a specific phase (expand, plan, implement, etc.) |
| `/skip <phase>` | Skip a phase |
| `/model [name]` | Show or change current AI model |
| `/agent [name]` | Show or change current AI agent |
| `/config <key> [value]` | Show or set config value |
| `/log` | Show recent log entries |
| `/diff` | Show git diff of changes |

### Extensibility
1. Skills (`.doyaken/skills/*.md`) auto-registered as slash commands
2. Project-level custom commands via `.doyaken/commands/` directory
3. Each command file exports: name, description, handler

### Tab Completion
1. When user types `/` + Tab, show available commands
2. Command-specific completion for arguments (e.g., `/task` + Tab shows task IDs)

## Technical Notes

- Pattern: declare -A COMMANDS; COMMANDS[name]="handler:description"
- For bash 3.x compat, may need parallel arrays instead of associative
- Tab completion via `complete` builtin or readline hooks
- Commands should output to stdout, errors to stderr

## Success Criteria

- [ ] All listed commands functional
- [ ] `/help` shows formatted command list
- [ ] Partial matching works (`/he` → `/help`)
- [ ] Skills auto-register as commands
- [ ] Tab completion works for command names
