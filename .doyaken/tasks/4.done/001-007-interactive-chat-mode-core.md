# Task: Add Interactive Chat/REPL Mode to Doyaken

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `001-007-interactive-chat-mode-core`                   |
| Status      | `done`                                                 |
| Priority    | `001` Critical                                         |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   | `2026-02-10 12:00`                                     |
| Blocked By  |                                                        |
| Blocks      | 002-007, 002-008, 002-009, 002-010, 002-011            |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-10 01:46` |

---

## Context

Doyaken currently runs as a batch-mode executor: pick task → run 8 phases → exit. Every major competitor (Claude Code, OpenCode, Codex, Gemini CLI, Aider) has interactive chat/REPL modes. This is the single most important feature gap.

## Objective

Add an interactive REPL mode (`dk chat` or `doyaken --interactive`) that allows users to have a conversation with the AI agent while it works. The user should be able to:
- Send messages to the agent mid-execution
- See streaming agent output in real-time
- Issue commands (slash commands) to control execution
- Exit cleanly with Ctrl+C or `/quit`

## Requirements

### Core REPL Loop
1. Add `dk chat` command that enters interactive mode
2. Implement a readline-based input loop (use `rlwrap` or bash `read -e` with history)
3. Support input history (up/down arrows) persisted to `~/.doyaken/history`
4. Show a prompt indicator showing current state: `doyaken> ` (idle), `doyaken [task-id]> ` (working)
5. Route input to either slash-command handler or agent message handler

### Agent Integration
1. When user sends a message, construct a prompt and pipe to the configured AI agent
2. Stream agent output to terminal in real-time (like current progress mode)
3. Support mid-message cancellation with Ctrl+C (kill current agent, return to prompt)
4. Maintain conversation context between messages (append to conversation log)

### Architecture
1. New file: `lib/interactive.sh` — the REPL loop and input handling
2. New file: `lib/commands.sh` — slash command registry and dispatch
3. Modify `lib/cli.sh` to add `chat` subcommand
4. Conversation log stored in `.doyaken/sessions/<session-id>/messages.jsonl`
5. Must coexist with existing batch mode (don't break `dk run`)

### Minimum Slash Commands (for this task)
- `/help` — show available commands
- `/quit` or `/exit` — exit interactive mode
- `/clear` — clear screen
- `/status` — show current task status

## Technical Notes

- Consider using `rlwrap` for readline support if available, falling back to `read -e`
- Agent communication should use the same `run_phase_once` pipeline but with a "chat" pseudo-phase
- The REPL must handle signals properly (Ctrl+C cancels current operation, doesn't exit)
- Keep it simple: bash REPL first, rich TUI later (separate task)

## Success Criteria

- [x] `dk chat` enters interactive mode with prompt
- [x] User can type messages and get AI responses
- [x] `/help`, `/quit`, `/clear`, `/status` work
- [x] Ctrl+C cancels current agent operation without exiting
- [x] Input history persists between sessions
- [x] Existing batch mode (`dk run`) unchanged

## Research Reference

See `.doyaken/research/interactive-mode-competitor-analysis.md`
