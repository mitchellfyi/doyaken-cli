# Task: @ File References and Context Management

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-010-context-file-management`                      |
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

Aider pioneered the `/add` and `/drop` pattern for managing which files are in the AI's context. Claude Code, Codex, Gemini, and OpenCode all support `@` file references for injecting file content into messages. This is critical for interactive mode — users need to tell the agent which files to focus on.

## Objective

Implement file context management: `@` references for inline file injection, `/add` and `/drop` for persistent context, and a context window indicator.

## Requirements

### @ File References
1. Typing `@` triggers file path completion (fuzzy search)
2. `@path/to/file.ts` in a message injects file content into the agent prompt
3. `@path/to/dir/` injects directory listing
4. Support glob patterns: `@src/**/*.test.ts`
5. Tab completion after `@` with fuzzy file search

### /add and /drop Commands
1. `/add <file>` — add file to persistent context (included in every message)
2. `/drop <file>` — remove file from persistent context
3. `/files` — list files currently in context with token estimates
4. `/context` — show total context size (files + conversation)
5. Persistent context files listed in session metadata

### ! Shell Command Integration
1. `!<command>` — execute shell command, include output in context
2. `!git log --oneline -5` — show git log and add to conversation
3. Shell output truncated at configurable limit (default 500 lines)

### Context Window Indicator
1. Show approximate context usage in status bar: `Context: 45K/128K tokens`
2. Warn when approaching limit (>80%)
3. Suggest `/compact` when context is high

### /compact Command
1. `/compact` — summarize conversation history to reduce context size
2. Use agent to generate summary, replace older messages
3. Keep recent N messages (configurable, default 10) plus summary
4. Show before/after token counts

## Technical Notes

- File content injection: read file, wrap in code fence with filename, prepend to message
- Token estimation: rough heuristic (1 token ≈ 4 chars for English, 3 chars for code)
- Fuzzy file search: use `find` + `fzf` (if available) or simple glob matching
- Context files stored in session: `context_files: [path1, path2, ...]`
- Compaction: send conversation to agent with "summarize this conversation" prompt

## Success Criteria

- [ ] `@file.ts` injects file content into message
- [ ] Tab completion works for file paths after `@`
- [ ] `/add` and `/drop` manage persistent context
- [ ] `/files` shows context files with sizes
- [ ] `!command` executes and includes output
- [ ] Context usage shown in status bar
- [ ] `/compact` reduces context size with summary
