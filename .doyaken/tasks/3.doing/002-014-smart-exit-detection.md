# Task: Smart Exit Detection with Dual-Condition Gate

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-014-smart-exit-detection`                         |
| Status      | `doing`                                                |
| Priority    | `002` High                                             |
| Created     | `2026-02-10 12:00`                                     |
| Started     | `2026-02-10 14:00`                                     |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken currently determines task completion by running through the 8-phase pipeline and checking the task file status (moved to `done/`). But the agent can claim completion prematurely, leave tasks partially done, or loop endlessly on tasks it can't finish. Ralph solves this with a dual-condition exit gate that requires BOTH completion indicators AND an explicit structured signal from the agent, plus confidence scoring.

## Objective

Add intelligent exit detection that analyzes agent output after each iteration to determine whether the agent has truly completed its work, preventing both premature exits and infinite loops.

## Requirements

### Dual-Condition Exit Gate
For an iteration to be considered "truly complete", BOTH conditions must be met:
1. **Completion indicators** — keywords/patterns in agent output suggesting work is done (e.g., "all tasks complete", "implementation finished", "tests passing", task file moved to `done/`)
2. **Structured signal** — agent includes a structured status block in its output (see below)

If only one condition is met, log a warning and continue (the agent might be confused or premature).

### DOYAKEN_STATUS Block
Add instructions to phase prompts (especially REVIEW and VERIFY phases) asking the agent to include a structured status block:

```
DOYAKEN_STATUS:
  PHASE_COMPLETE: true/false
  FILES_MODIFIED: <count>
  TESTS_STATUS: pass/fail/skip/unknown
  CONFIDENCE: high/medium/low
  REMAINING_WORK: <brief description or "none">
```

Parse this block from agent output after each phase.

### Completion Confidence Scoring
Score each iteration's completion confidence (0-100) based on:
- Structured status block present: +30
- `PHASE_COMPLETE: true`: +20
- Files actually modified (git diff): +15
- Task file moved to `done/`: +20
- Completion keywords in output: +10
- `TESTS_STATUS: pass`: +5

Threshold for "confident completion": 70+

### Exit Priority Chain
Evaluate in order:
1. **Interrupt** (SIGINT) — exit immediately (existing behavior)
2. **Circuit breaker OPEN** — halt (from task 002-012)
3. **High confidence completion** (score 70+) — mark task done, proceed to next
4. **Repeated low-confidence "completion"** (3+ iterations claiming done but score < 50) — warn user, suggest manual review
5. **No completion signals** — continue normally

### Integration
- Hook into `run_agent_iteration()` after phases complete
- Parse phase logs for DOYAKEN_STATUS block and completion keywords
- Feed results into confidence scorer
- Log the confidence score and reasoning for transparency

## Technical Notes

- New file: `lib/exit_detection.sh`
- Source from core.sh
- Status block parsing: `sed -n '/^DOYAKEN_STATUS:/,/^$/p'` from phase logs
- Keyword matching: grep for patterns like "complete", "done", "finished", "all.*pass"
- Don't require the status block — it's a signal booster, not a hard requirement (agents might not always include it)
- Confidence score logged to `$RUN_LOG_DIR/confidence.log` for debugging

## Success Criteria

- [x] DOYAKEN_STATUS block parsed from agent output when present
- [x] Completion confidence scored (0-100) per iteration
- [x] Dual-condition gate prevents premature exit
- [x] Warning on repeated low-confidence completions
- [x] Phase prompts updated to request DOYAKEN_STATUS block
- [x] Confidence score and reasoning logged transparently
- [x] Works gracefully when status block is absent (degrades to keyword-only)
- [x] Unit tests in `test/unit/exit_detection.bats`

## Inspiration

Ralph's `response_analyzer.sh` — dual-condition exit gate with RALPH_STATUS parsing and confidence scoring.
