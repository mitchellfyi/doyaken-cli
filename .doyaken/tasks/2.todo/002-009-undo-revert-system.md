# Task: Undo/Revert System with Git Integration

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-009-undo-revert-system`                           |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | 001-007, 002-007                                       |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

When an AI agent makes unwanted changes, users currently have no way to revert within doyaken. They must manually use git commands. Every major competitor (Claude Code, OpenCode, Codex, Aider, Cline) provides undo/revert functionality. This is a critical safety feature for interactive mode.

## Objective

Implement undo/revert commands that allow users to roll back agent changes at various granularities: last change, last phase, or to a specific checkpoint.

## Requirements

### Checkpoint System
1. Before each phase execution, create a git checkpoint (lightweight tag or stash)
2. Checkpoints stored as: `doyaken/checkpoint/<session-id>/<phase>/<timestamp>`
3. Track checkpoint metadata in session (what changed, which phase, file list)
4. Cleanup old checkpoints (configurable retention, default 50 per session)

### Commands

| Command | Description |
|---------|-------------|
| `/undo` | Revert last agent change (git reset to pre-change state) |
| `/redo` | Re-apply last undone change |
| `/revert <phase>` | Revert all changes from a specific phase |
| `/checkpoint` | Show checkpoint history |
| `/checkpoint save [tag]` | Create manual checkpoint |
| `/restore <id>` | Restore to a specific checkpoint |
| `/diff` | Show what the agent changed since last checkpoint |

### Undo Behavior
1. `/undo` reverts the last agent message's file changes
2. Conversation history preserved (message marked as "reverted")
3. Agent informed: "The user reverted your last changes. The files are now back to their previous state."
4. Support multiple undo levels (undo stack)

### Redo Behavior
1. `/redo` re-applies the last undone change
2. Uses git reflog or stashed patches
3. Only available immediately after `/undo` (cleared on new agent action)

### Safety
1. Never force-push or modify remote branches
2. Warn if there are uncommitted changes that would be lost
3. `/undo` should show a diff preview before applying (with confirmation for large changes)
4. Handle the case where user has made manual changes between checkpoints

## Technical Notes

- Implementation: `git stash create` for lightweight checkpoints (no ref needed)
- Store stash refs in session metadata
- For undo: `git checkout -- <files>` for file-level revert, or `git stash pop` for full revert
- Redo stack: save patches before undo, re-apply on redo
- Must handle untracked files (new files created by agent)

## Success Criteria

- [ ] `/undo` reverts last agent file changes
- [ ] `/redo` re-applies undone changes
- [ ] Checkpoints created automatically before each phase
- [ ] `/checkpoint` shows history with timestamps and descriptions
- [ ] `/diff` shows changes since last checkpoint
- [ ] Conversation context updated to reflect undo
- [ ] No data loss — user warned before destructive operations
