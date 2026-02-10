# Task: API Rate Limiting with Hourly Quotas

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-013-rate-limiting`                                |
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

Doyaken currently has no proactive rate limiting. It only reacts to rate limit errors after they happen (via `fallback_to_sonnet()` which detects 429/overloaded patterns in logs). This means the agent slams into API limits, gets degraded to a weaker model, and wastes time on failed requests. Ralph implements proactive rate limiting with hourly quotas and countdown waiting, preventing limit hits entirely.

## Objective

Add proactive API rate limiting that tracks agent invocations per hour and pauses execution when approaching the quota, rather than waiting for 429 errors.

## Requirements

### Quota Tracking
1. Track the number of agent CLI invocations (one per phase per iteration) within a rolling 1-hour window
2. Store invocation timestamps in `$STATE_DIR/rate_limit.log` (one timestamp per line)
3. On each invocation, prune entries older than 1 hour, count remaining, check against quota
4. Use atomic writes for the log file

### Quota Enforcement
1. Before each agent invocation in `run_phase_once()`, check the rate limiter
2. If at or over quota: display a countdown timer showing when the next slot opens, then wait
3. The countdown should show: calls used/quota, time until next slot, and which phase is waiting
4. Waiting should be interruptible by Ctrl+C (use `sleep N & wait $!` pattern)

### Configuration
Add to `config/global.yaml`:
- `rate_limit.calls_per_hour: 80` — default hourly quota (conservative, below most API limits)
- `rate_limit.enabled: true` — master toggle
- `rate_limit.warning_threshold: 0.8` — warn when 80% of quota consumed

Support override via manifest and ENV vars (`DOYAKEN_RATE_LIMIT_CALLS_PER_HOUR`, etc.).

### User Feedback
- At 80% quota: log a warning showing remaining calls
- At quota: log clearly that rate limiting has kicked in, show countdown
- After cooldown: log when execution resumes
- In dry-run mode: show what the rate limiter would do without blocking

### Integration with Existing Fallback
- Rate limiter runs *before* agent invocation (proactive)
- Model fallback runs *after* a failed invocation (reactive)
- Both systems should coexist — rate limiter reduces the need for fallback, but fallback still catches unexpected 429s

## Technical Notes

- New file: `lib/rate_limiter.sh`
- Source from core.sh
- Timestamp format: epoch seconds (via `date +%s`) for easy arithmetic
- Pruning: `awk -v cutoff="$(( $(date +%s) - 3600 ))" '$1 > cutoff'` or equivalent
- The countdown display should overwrite the same line (use `\r` or tput) for a clean UX
- Cross-platform: use `date +%s` which works on both macOS and Linux

## Success Criteria

- [ ] Agent invocations tracked per rolling hour in STATE_DIR
- [ ] Execution pauses with countdown when quota reached
- [ ] Countdown is interruptible with Ctrl+C
- [ ] Warning logged at configurable threshold (default 80%)
- [ ] Configurable via global.yaml / manifest / ENV
- [ ] Coexists with existing model fallback mechanism
- [ ] Stale entries pruned automatically
- [ ] Unit tests in `test/unit/rate_limiter.bats`

## Inspiration

Ralph's rate limiter in `ralph_loop.sh` — tracks calls per hour with countdown timer and hourly reset.
