# Task: Hooks & Lifecycle Events System

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `004-007-hooks-lifecycle-events`                       |
| Status      | `todo`                                                 |
| Priority    | `004` Low                                              |
| Created     | `2026-02-06 15:30`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | 001-007                                                |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Claude Code and Gemini CLI both have hooks systems that run user-defined scripts at lifecycle events (before/after tool use, phase transitions, etc.). Doyaken has a basic hooks.sh but limited lifecycle event support. A proper hooks system would allow users to customize behavior without modifying core code.

## Objective

Implement a comprehensive hooks system that fires at key lifecycle events and allows users to run custom scripts.

## Requirements

### Lifecycle Events

| Event | Fires When |
|-------|-----------|
| `pre-phase` | Before each phase starts |
| `post-phase` | After each phase completes |
| `pre-task` | Before task execution begins |
| `post-task` | After task execution completes |
| `pre-agent` | Before agent invocation |
| `post-agent` | After agent response received |
| `on-error` | When a phase or agent fails |
| `on-interrupt` | When Ctrl+C is pressed |
| `on-checkpoint` | When a checkpoint is created |
| `on-approval` | When user approves/denies in supervised mode |

### Hook Configuration
```yaml
# .doyaken/manifest.yaml
hooks:
  pre-phase:
    - command: "./scripts/lint-check.sh"
      phases: [implement, test]  # only run for these phases
  post-task:
    - command: "notify-send 'Task complete'"
  on-error:
    - command: "./scripts/collect-diagnostics.sh"
```

### Hook Script Interface
1. Hooks receive context as environment variables:
   - `DOYAKEN_PHASE` — current phase name
   - `DOYAKEN_TASK_ID` — current task ID
   - `DOYAKEN_EVENT` — event name
   - `DOYAKEN_EXIT_CODE` — exit code (for post-* events)
   - `DOYAKEN_SESSION_ID` — current session ID
2. Hook exit codes:
   - 0 = success, continue
   - 1 = warning (log but continue)
   - 2 = block (abort the operation)
3. Hook stdout captured and logged
4. Hook timeout: configurable, default 30s

### Built-in Hooks
1. Quality gate hook: run lint/test/build after implement phase
2. Notification hook: desktop notification on completion
3. Git hook: auto-commit after successful phases

## Technical Notes

- Build on existing `lib/hooks.sh`
- Hooks run synchronously (block execution until complete)
- Use `timeout` for hook execution to prevent hangs
- Hook scripts must be executable (`chmod +x`)
- Pass context via env vars (not stdin) for simplicity

## Success Criteria

- [ ] Hooks fire at all listed lifecycle events
- [ ] Hook configuration works from manifest.yaml
- [ ] Hooks receive correct context via environment variables
- [ ] Exit code 2 blocks the operation
- [ ] Hook timeout prevents hanging
- [ ] Built-in quality gate hook works
