# Task: Agent Session Continuity Across Phases

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-011-session-continuity`                           |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-10 12:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken currently invokes the agent as a fresh process for every phase — each of the 8 phases starts a new `claude` CLI session with no memory of previous phases. This means the agent loses context between PLAN → IMPLEMENT → TEST → REVIEW. The agent must re-read files and re-discover context each time, wasting tokens and time. Ralph preserves Claude Code session IDs across loop iterations with a 24-hour expiry, allowing the agent to maintain conversation context.

Doyaken already has basic session tracking (`save_session`/`load_session` in core.sh:1750) but it only tracks iteration metadata — it doesn't pass session IDs to the agent CLI to enable context continuity.

## Objective

Pass agent session IDs between phases so the agent maintains conversation context across the 8-phase pipeline within a single task, and optionally across iterations of the same task.

## Requirements

### Intra-Task Session Continuity
1. After the first phase (SPEC), capture the agent's session ID from its output
2. For subsequent phases (PLAN through COMMIT), pass `--resume <session-id>` to the `claude` CLI
3. This keeps the agent's conversation context alive — it remembers what it planned when implementing
4. If session resume fails (expired, invalid), fall back to fresh session and log a warning

### Session ID Capture
For Claude CLI with `--output-format stream-json`:
- Parse the `session_id` field from the JSON stream output
- Store in `$RUN_LOG_DIR/session_id` (one file per task run)

For other agents:
- Check if the agent supports session resumption (codex, gemini, etc.)
- If not, skip gracefully — session continuity is opt-in per agent

### Session Expiry
1. Track session creation timestamp alongside the ID
2. Default expiry: 4 hours (configurable) — sessions older than this start fresh
3. On expiry: log that session expired, start new one

### Configuration
Add to `config/global.yaml`:
- `session.continuity: true` — enable/disable session passing between phases
- `session.expiry_hours: 4` — session expiry time
- `session.cross_iteration: false` — whether to reuse sessions across task iterations (default off, can cause context pollution)

Support override via manifest, ENV vars, and `--no-resume` CLI flag (which already exists).

### Inter-Iteration Continuity (Optional)
When `session.cross_iteration: true`:
- After completing all phases for a task, preserve the session ID
- On the next iteration (next task), offer the agent the previous session for context
- This is risky (context pollution between unrelated tasks) so default OFF

## Technical Notes

- Modify `run_phase_once()` to accept and pass session ID
- Modify `run_all_phases()` to thread session ID through the phase loop
- Claude CLI: `--resume <session-id>` resumes a conversation
- Parse session_id from stream-json: look for `"session_id"` field in result message
- Existing `AGENT_NO_RESUME` / `--no-resume` flag should disable this feature
- Update `save_session()` / `load_session()` to include the agent's session ID (not just doyaken's internal session tracking)

## Success Criteria

- [ ] Agent session ID captured from first phase output
- [ ] Subsequent phases pass `--resume <id>` to maintain context
- [ ] Graceful fallback when resume fails (start fresh session)
- [ ] Session expiry after configurable timeout (default 4h)
- [ ] `--no-resume` flag disables session continuity
- [ ] Configurable via global.yaml / manifest / ENV
- [ ] Works for Claude agent; graceful no-op for agents without session support
- [ ] Unit tests in `test/unit/session_continuity.bats`

## Inspiration

Ralph's session continuity in `ralph_loop.sh` — preserves Claude Code session IDs across loop iterations with 24-hour expiry and `--resume` flag passing.
