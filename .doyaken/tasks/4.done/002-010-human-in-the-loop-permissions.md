# Task: Human-in-the-Loop Permission & Approval System

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-010-human-in-the-loop-permissions`                |
| Status      | `done`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-06 15:30`                                     |
| Started     | `2026-02-10`                                           |
| Completed   | `2026-02-10`                                           |
| Blocked By  | 001-007                                                |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken currently runs fully autonomously with no human approval checkpoints. This is fine for trusted workflows but risky for new users or sensitive operations. Every competitor (Claude Code, OpenCode, Codex) implements tiered permission models. Adding optional approval gates would increase trust and safety.

## Objective

Implement a configurable approval system that can pause execution for human review at specified points, with configurable autonomy levels.

## Requirements

### Autonomy Levels
1. **Full Auto** (default, current behavior): No approvals needed, runs all phases autonomously
2. **Supervised**: Pause between phases for human review/approval
3. **Interactive**: Pause before each file write and shell command for approval
4. **Plan Only**: Run EXPAND/TRIAGE/PLAN phases only, show plan, wait for approval before IMPLEMENT

Configure via:
- CLI flag: `--approval <level>` or shorthand `--supervised`, `--plan-only`
- Manifest: `approval: supervised`
- Interactive command: `/approval <level>`

### Phase Gates
1. In supervised mode, after each phase completes:
   - Show phase summary (what was done, files changed, tests results)
   - Prompt: "Continue to next phase? [Y/n/skip/abort]"
   - Y = continue, n = pause (return to chat), skip = skip next phase, abort = stop execution
2. In plan-only mode:
   - Run through PLAN phase
   - Show complete plan to user
   - Wait for explicit "go" command before continuing

### Operation Approval (Interactive Level)
1. Before file writes: show diff, ask approval
2. Before shell commands: show command, ask approval
3. Options: "allow once", "allow all from this phase", "deny"
4. Pattern-based auto-approval: e.g., allow all `*.test.ts` writes

### Review Points
1. After PLAN phase: "Here's the implementation plan. Proceed?"
2. After IMPLEMENT phase: "Here are the changes. Run tests?"
3. After TEST phase: "Tests passed/failed. Continue to review?"
4. After REVIEW phase: "Review complete. Any changes before verify?"

### Configuration
```yaml
# .doyaken/manifest.yaml
approval: full-auto    # full-auto | supervised | interactive | plan-only
approval_gates:        # custom gates (only in supervised mode)
  - after: plan
    action: pause      # pause | confirm | skip
  - after: implement
    action: confirm
```

## Technical Notes

- Hook into existing `run_all_phases` loop — add approval check between phases
- In batch mode, approval prompts use `read_with_timeout` (existing function with auto-timeout)
- In interactive mode, approval returns to REPL prompt
- Store approval preferences per session (don't re-ask for same patterns)

## Success Criteria

- [ ] `--supervised` flag pauses between phases for approval
- [ ] `--plan-only` stops after PLAN phase
- [ ] Phase summaries shown at each gate
- [ ] User can skip, continue, or abort at each gate
- [ ] Default behavior (full-auto) unchanged
- [ ] Approval preferences configurable in manifest
