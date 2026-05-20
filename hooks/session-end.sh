#!/usr/bin/env bash
# SessionEnd hook — records session end time and cleans up ephemeral state files.
# Runs when a Claude Code session ends (cleanly or otherwise).
set -euo pipefail

source "${DEX_DIR:-$HOME/work/dex}/lib/common.sh"

SESSION_ID="${DEX_SESSION_ID:-$(dx_session_id)}"

# Record end time in the times file (complements phase start times written by dx.sh)
TIMES_FILE=$(dx_times_file "$SESSION_ID")
CTX_FILE=$(dx_context_file "$SESSION_ID")

if [[ -f "$TIMES_FILE" || -f "$CTX_FILE" || -f "$(dx_state_file "$SESSION_ID")" || -f "$(dx_active_file "$SESSION_ID")" || -f "$(dx_loop_config_file "$SESSION_ID")" || -f "$(dx_handoff_mode_file "$SESSION_ID")" ]]; then
  dx_record_session_branch "$SESSION_ID" "$(pwd)" 2>/dev/null || true
fi

if [[ -f "$TIMES_FILE" ]]; then
  echo "end:$(date +%s)" >> "$TIMES_FILE"
fi

# Clean up the system context file — it's regenerated at each phase start
rm -f "$CTX_FILE" 2>/dev/null || true
