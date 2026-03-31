#!/usr/bin/env bash
# Stop hook — Phase audit loop for quality-gated autonomous execution.
#
# Flow:
#   1. Claude tries to stop → this hook runs
#   2. Check .complete file → if found, allow stop (exit 0)
#   3. Check iteration count → if max reached, allow stop (exit 0)
#   4. Otherwise: inject audit prompt into stderr, block stop (exit 2)
#   5. Claude reads the audit prompt, reviews its work, and either:
#      a. Finds issues → fixes them → tries to stop → back to step 1
#      b. Finds nothing → writes .complete file → tries to stop → step 2 allows it
#
# Completion detection:
#   .complete signal file — written by phase audit prompts (Phases 1-4)
#   or the /dkcomplete skill (Phase 5). This file is the ONLY mechanism the
#   hook checks; the promise string (e.g., PHASE_1_COMPLETE) is not parsed.
#
# Activated by:
#   - DOYAKEN_LOOP_ACTIVE=1 in environment (set by dk/dkloop wrappers)
#   - .active signal file in DK_LOOP_DIR (created by /dkloop skill for in-session use)
# Deactivated by: .complete file or max iterations
#
# See: docs/autonomous-mode.md for full architecture documentation
set -euo pipefail

source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
mkdir -p "$DK_LOOP_DIR"

SESSION_ID="${DOYAKEN_SESSION_ID:-$(dk_session_id)}"

# Check activation: env var OR .active file (for in-session /dkloop skill)
ACTIVE_FILE=$(dk_active_file "$SESSION_ID")
LOOP_ACTIVE="${DOYAKEN_LOOP_ACTIVE:-0}"
if [[ "$LOOP_ACTIVE" != "1" ]] && [[ ! -f "$ACTIVE_FILE" ]]; then
  exit 0
fi

# If activated via .active file (in-session /dkloop), default to prompt-loop
# mode. The .active file is a touch file — it doesn't carry data. Phase/promise
# env vars can still override these defaults if set before the session.
if [[ -f "$ACTIVE_FILE" ]]; then
  DOYAKEN_LOOP_PHASE="${DOYAKEN_LOOP_PHASE:-prompt-loop}"
  DOYAKEN_LOOP_PROMISE="${DOYAKEN_LOOP_PROMISE:-PROMPT_COMPLETE}"
fi

STATE_FILE=$(dk_loop_file "$SESSION_ID")
# 30 iterations is tuned for medium-sized features; reduce for simple bugs (10-15).
# Each iteration = one audit cycle, so 30 is a safety net, not an expected count.
MAX_ITERATIONS="${DOYAKEN_LOOP_MAX_ITERATIONS:-30}"
COMPLETION_PROMISE="${DOYAKEN_LOOP_PROMISE:-DOYAKEN_TICKET_COMPLETE}"

# Completion detection: The .complete file is the sole automated mechanism.
# Phase audit prompts (1-plan.md through prompt-loop.md) instruct Claude to:
#   1. Create this file via `touch "$(dk_complete_file "$(dk_session_id)")"`
#   2. Output the promise string (e.g., PHASE_1_COMPLETE) for human readability
# Only the file triggers this check — the promise string is not parsed.
# See: docs/autonomous-mode.md § Completion Signals
COMPLETE_FILE=$(dk_complete_file "$SESSION_ID")
if [[ -f "$COMPLETE_FILE" ]]; then
  echo "Completion signal file found. Phase complete."
  rm -f "$STATE_FILE" "$COMPLETE_FILE" "$ACTIVE_FILE"
  exit 0
fi

# Read current iteration count and timestamp.
# State file format: "iteration:epoch" (new) or bare "iteration" (legacy).
ITERATION=0
LAST_EPOCH=0
STALL_COUNT=0
if [[ -f "$STATE_FILE" ]]; then
  RAW=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
  if [[ "$RAW" =~ ^([0-9]+):([0-9]+):?([0-9]*)$ ]]; then
    # New format: iteration:epoch or iteration:epoch:stall_count
    ITERATION="${BASH_REMATCH[1]}"
    LAST_EPOCH="${BASH_REMATCH[2]}"
    STALL_COUNT="${BASH_REMATCH[3]:-0}"
  elif [[ "$RAW" =~ ^[0-9]+$ ]]; then
    # Legacy format: bare iteration count
    ITERATION=$RAW
  fi
fi
ITERATION=$((ITERATION + 1))
NOW_EPOCH=$(date +%s)

# Stall detection — if the time between consecutive iterations exceeds the
# threshold, the loop may be stuck on a fundamentally broken problem.
# Inspired by autoresearch's NaN/exploding-loss early termination.
STALL_TIMEOUT="${DOYAKEN_LOOP_STALL_TIMEOUT:-300}"  # default: 5 minutes
STALL_ESCALATE_AFTER="${DOYAKEN_LOOP_STALL_ESCALATE:-3}"  # escalate after N stalls
IS_STALLED=0
if [[ $LAST_EPOCH -gt 0 ]] && [[ $STALL_TIMEOUT -gt 0 ]]; then
  ELAPSED=$((NOW_EPOCH - LAST_EPOCH))
  if [[ $ELAPSED -gt $STALL_TIMEOUT ]]; then
    STALL_COUNT=$((STALL_COUNT + 1))
    IS_STALLED=1
  else
    STALL_COUNT=0
  fi
fi

# Semantic stuck detection — check if review findings are repeating across
# iterations. Claude writes a findings hash after each review cycle (see
# prompts/phase-audits/2-implement.md). If the same hash appears 3+ consecutive
# times, the loop is semantically stuck on the same issues.
FINDINGS_FILE=$(dk_findings_file "$SESSION_ID")
SEMANTIC_STUCK=0
if [[ -f "$FINDINGS_FILE" ]]; then
  LAST_HASH=$(tail -1 "$FINDINGS_FILE" 2>/dev/null || echo "")
  if [[ -n "$LAST_HASH" ]]; then
    # Count consecutive identical hashes from the end of the file
    REPEAT_COUNT=0
    while IFS= read -r line; do
      if [[ "$line" == "$LAST_HASH" ]]; then
        REPEAT_COUNT=$((REPEAT_COUNT + 1))
      else
        break
      fi
    done < <(tac "$FINDINGS_FILE" 2>/dev/null)
    if [[ $REPEAT_COUNT -ge 3 ]]; then
      SEMANTIC_STUCK=1
    fi
  fi
fi

# Check max iterations.
# Leave STATE_FILE intact (unlike the .complete path) so the wrapper can
# distinguish max-iter (exit 0 + state file present) from advance (exit 0 +
# state file removed by .complete cleanup). The wrapper is responsible for
# cleaning up the state file after reading the iteration count.
if [[ $ITERATION -gt $MAX_ITERATIONS ]]; then
  echo "Phase audit loop reached max iterations ($MAX_ITERATIONS). Allowing stop."
  rm -f "$ACTIVE_FILE"
  exit 0
fi

# Save iteration count with timestamp atomically: write to a PID-suffixed temp
# file, then mv. mv is atomic on POSIX filesystems, so a crash mid-write won't
# corrupt the state file (we'd lose at most the temp file, and default to 0 on
# next read).
TEMP_FILE="${STATE_FILE}.tmp.$$"
if ! echo "${ITERATION}:${NOW_EPOCH}:${STALL_COUNT}" > "$TEMP_FILE" || ! mv "$TEMP_FILE" "$STATE_FILE"; then
  echo "WARNING: Failed to save loop state. Allowing stop."
  rm -f "$TEMP_FILE"
  exit 0
fi

# Resolve the audit prompt — injected into stderr so Claude sees it on its next turn.
# Three sources, checked in priority order:
#   1. DOYAKEN_LOOP_PROMPT env var — set by dk.sh wrapper per-phase (preloaded from file)
#   2. Phase audit file from prompts/phase-audits/<name>.md — looked up via DOYAKEN_LOOP_PHASE
#      (used by in-session activations like /dkloop where the env var isn't set)
#   3. Generic fallback — hardcoded prompt below, used when neither source is available
AUDIT_PROMPT="${DOYAKEN_LOOP_PROMPT:-}"

if [[ -z "$AUDIT_PROMPT" ]]; then
  LOOP_PHASE="${DOYAKEN_LOOP_PHASE:-}"
  # Map phase number to audit file basename (must match actual filenames)
  AUDIT_FILENAME=""
  case "$LOOP_PHASE" in
    1) AUDIT_FILENAME="1-plan" ;;
    2) AUDIT_FILENAME="2-implement" ;;
    3) AUDIT_FILENAME="3-verify" ;;
    4) AUDIT_FILENAME="4-pr" ;;
    5) AUDIT_FILENAME="5-complete" ;;
    prompt-loop) AUDIT_FILENAME="prompt-loop" ;;
  esac
  AUDIT_FILE="$DOYAKEN_DIR/prompts/phase-audits/${AUDIT_FILENAME}.md"
  if [[ -n "$AUDIT_FILENAME" ]] && [[ -f "$AUDIT_FILE" ]]; then
    AUDIT_PROMPT=$(cat "$AUDIT_FILE")
  fi
fi

if [[ -z "$AUDIT_PROMPT" ]]; then
  AUDIT_PROMPT="You are not done yet. Review your work critically before stopping:

1. Is the current phase fully complete?
2. Are there any issues, improvements, or optimizations remaining?
3. Have you verified the quality of your output?

If everything is done, output: $COMPLETION_PROMISE
If something needs work, fix it and try again."
fi

echo "" >&2
if [[ "${DOYAKEN_LOOP_PHASE:-}" == "prompt-loop" ]]; then
  echo "--- Prompt Loop: iteration $ITERATION/$MAX_ITERATIONS ---" >&2
else
  echo "--- Phase Audit: iteration $ITERATION/$MAX_ITERATIONS ---" >&2
fi
echo "" >&2

# Re-inject the original prompt so Claude doesn't lose it after context compaction.
# The prompt file is written by dkloop in dk.sh before launching Claude.
PROMPT_FILE=$(dk_prompt_file "$SESSION_ID")
if [[ -f "$PROMPT_FILE" ]]; then
  printf '%s\n' "## Original Task Prompt" >&2
  printf '%s\n' "" >&2
  cat "$PROMPT_FILE" >&2
  printf '%s\n' "" >&2
  printf '%s\n' "---" >&2
  printf '%s\n' "" >&2
fi

# If stalled beyond the escalation threshold, inject an escalation prompt instead
# of (or in addition to) the normal audit prompt.
if [[ $IS_STALLED -eq 1 ]] && [[ $STALL_COUNT -ge $STALL_ESCALATE_AFTER ]]; then
  printf '%s\n' "## STUCK LOOP DETECTED (stalled $STALL_COUNT times)" >&2
  printf '%s\n' "" >&2
  printf '%s\n' "You appear to be stuck in a loop. The last $STALL_COUNT iterations each took longer than ${STALL_TIMEOUT}s without making progress." >&2
  printf '%s\n' "" >&2
  printf '%s\n' "MANDATORY: Read prompts/failure-recovery.md and run the failure analysis." >&2
  printf '%s\n' "You MUST choose a different recovery strategy. Do NOT retry the same approach." >&2
  printf '%s\n' "" >&2
fi

if [[ $SEMANTIC_STUCK -eq 1 ]]; then
  printf '%s\n' "## STUCK LOOP DETECTED (same findings recurring)" >&2
  printf '%s\n' "" >&2
  printf '%s\n' "The last 3+ review cycles found the SAME issues. You are going in circles." >&2
  printf '%s\n' "" >&2
  printf '%s\n' "MANDATORY: Read prompts/failure-recovery.md and run the failure analysis." >&2
  printf '%s\n' "You MUST choose a different strategy. Options:" >&2
  printf '%s\n' "  - CHANGE_APPROACH: Try a fundamentally different implementation" >&2
  printf '%s\n' "  - ACCEPT_WITH_DEBT: Accept non-critical findings and track as debt" >&2
  printf '%s\n' "  - SPLIT_TASK: Reduce scope to what you can complete cleanly" >&2
  printf '%s\n' "  - ESCALATE: Signal completion and let the user take over" >&2
  printf '%s\n' "" >&2
fi

printf '%s\n' "$AUDIT_PROMPT" >&2
echo "" >&2

# Exit 2 to block the Stop action
exit 2
