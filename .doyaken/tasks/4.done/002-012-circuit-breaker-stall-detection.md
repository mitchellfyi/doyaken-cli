# Task: Circuit Breaker with 3-State Stall Detection

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-012-circuit-breaker-stall-detection`              |
| Status      | `done`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-10 12:00`                                     |
| Started     | `2026-02-10`                                           |
| Completed   | `2026-02-10`                                           |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken currently has a rudimentary "circuit breaker" in `run_with_retry()` (core.sh:2222) — if `CONSECUTIVE_FAILURES` hits 3, it sleeps for 30 seconds and continues. This is a blunt instrument. Ralph implements a proper 3-state circuit breaker (CLOSED → HALF_OPEN → OPEN) with multiple stagnation signals that prevents infinite loops and wasted API calls when the agent is stuck.

## Objective

Replace the existing naive failure counter with a proper circuit breaker state machine that detects multiple forms of stagnation and halts execution intelligently.

## Requirements

### State Machine
1. **CLOSED** (normal) — agent is making progress, all phases run normally
2. **HALF_OPEN** (caution) — 2 consecutive no-progress iterations detected, allow one more attempt
3. **OPEN** (halted) — threshold breached, stop execution and wait for cooldown or user intervention

### Stagnation Signals
Detect these signals by analyzing phase logs after each iteration:
1. **No file changes** — `git diff --stat` shows nothing modified after a full phase cycle
2. **Repeated errors** — same error pattern appears N times in consecutive logs
3. **Output decline** — agent output shrinks significantly (< 30% of average) suggesting it's looping
4. **Repeated phase failures** — same phase fails consecutively across iterations

### Configuration
Add to `config/global.yaml` under a new `circuit_breaker:` section:
- `no_progress_threshold: 3` — consecutive no-progress iterations before OPEN
- `same_error_threshold: 5` — repeated identical errors before OPEN
- `output_decline_percent: 70` — output drops below 70% of rolling average
- `cooldown_minutes: 5` — wait time when OPEN before auto-transitioning to HALF_OPEN
- `enabled: true` — master toggle

Support override via manifest and ENV vars following existing config priority chain.

### State Persistence
- Store circuit breaker state in `$STATE_DIR/circuit_breaker.json` (or plain text)
- Track: current state, consecutive no-progress count, last error hash, rolling output sizes, transition timestamps
- Use atomic write pattern (temp+mv) consistent with existing lock file pattern

### Integration Points
- Hook into `run_with_retry()` or `run_agent_iteration()` — check state before each iteration
- After each iteration, analyze results and update state
- When OPEN: log clear message explaining why, suggest user action, respect cooldown timer
- On progress detected: transition back to CLOSED and reset counters

## Technical Notes

- Extract into `lib/circuit_breaker.sh` to keep core.sh manageable
- Source it from core.sh like other lib files
- Use `git diff --stat` for file change detection (already available in the codebase)
- Error deduplication: hash the last N lines of error output with `md5` or `cksum`
- Keep it simple — plain text state file is fine, no need for jq dependency

## Success Criteria

- [ ] 3-state circuit breaker (CLOSED/HALF_OPEN/OPEN) implemented
- [ ] Detects no-file-change stagnation
- [ ] Detects repeated error patterns
- [ ] Detects output decline
- [ ] Configurable thresholds via global.yaml / manifest / ENV
- [ ] State persisted across iterations in STATE_DIR
- [ ] Cooldown timer with auto-transition OPEN → HALF_OPEN
- [ ] Clear user-facing log messages when circuit opens
- [ ] Existing `CONSECUTIVE_FAILURES` logic in run_with_retry replaced
- [ ] Unit tests in `test/unit/circuit_breaker.bats`

## Inspiration

Ralph's `lib/circuit_breaker.sh` — 3-state machine with configurable thresholds, cooldown, and history tracking.
