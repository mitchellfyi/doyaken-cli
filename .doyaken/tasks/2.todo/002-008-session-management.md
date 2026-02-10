# Task: Session Management — Save, Resume, Fork

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-008-session-management`                           |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | 001-007                                                |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken currently has basic session tracking (session files in data dir) but no way to resume a conversation or fork an existing session. Every competitor (Claude Code, OpenCode, Codex, Gemini) supports full session lifecycle management. This is critical for multi-day tasks and iterative development.

## Objective

Implement session persistence so users can pause work, resume later, fork sessions for exploration, and list/manage their session history.

## Requirements

### Session Storage
1. Sessions stored in `.doyaken/sessions/<session-id>/`
2. Each session contains:
   - `meta.yaml` — session metadata (id, created, updated, task_id, status, title, model, agent)
   - `messages.jsonl` — conversation history (role, content, timestamp, phase)
   - `context.md` — accumulated context/summary for the agent
   - `checkpoints/` — git refs or snapshots at key points
3. Session IDs: `YYYYMMDD-HHMMSS-<short-hash>` format

### Commands

| Command | Description |
|---------|-------------|
| `/sessions` | List recent sessions with task, status, date |
| `/session save [tag]` | Save current session with optional tag |
| `/session resume [id]` | Resume a session (latest if no id) |
| `/session fork [id]` | Fork session into new branch |
| `/session export [id]` | Export session as markdown |
| `/session delete [id]` | Delete a session |

### Resume Behavior
1. On resume, load `context.md` as system context for the agent
2. Show user a summary of where they left off
3. Agent receives: "You are resuming a previous session. Here's what was done: [context]"
4. Task state preserved (which phase was last completed)

### Auto-Save
1. Session auto-saves after each agent response
2. Save on clean exit (`/quit`)
3. Save on interrupt (Ctrl+C) with "interrupted" status
4. Auto-compaction: when messages.jsonl exceeds threshold, summarize older messages into context.md

### CLI Integration
1. `dk chat --resume` — resume last session
2. `dk chat --resume <id>` — resume specific session
3. `dk sessions` — list sessions (works outside interactive mode)
4. Enhance existing session tracking in core.sh to be compatible

## Technical Notes

- Build on existing `save_session`/`load_session` functions in core.sh
- JSONL format for messages (one JSON object per line) — easy to append, parse
- Context compaction: summarize with agent, store summary, truncate old messages
- Git checkpoint: `git stash create` or lightweight tag at session save points

## Success Criteria

- [ ] Sessions persist between `dk chat` invocations
- [ ] `/session resume` loads previous conversation context
- [ ] `/session fork` creates independent branch
- [ ] Auto-save on exit/interrupt
- [ ] `dk sessions` shows session list from non-interactive mode
- [ ] Session includes task state (current phase, completed phases)
