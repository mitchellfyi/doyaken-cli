#!/usr/bin/env bash
#
# audit.sh - Audit logging for doyaken
#
# Appends timestamped JSON-line events to an audit log.
# Useful for tracking phase execution, gate results, and session history.
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_AUDIT_LOADED:-}" ]] && return 0
_DOYAKEN_AUDIT_LOADED=1

# Audit log location (project-level)
AUDIT_LOG="${DOYAKEN_PROJECT:-.}/.doyaken/audit.log"

# Write a JSON-line event to the audit log
# Usage: audit_log "event_name" "details"
audit_log() {
  local event="$1"
  local details="${2:-}"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local log_dir
  log_dir=$(dirname "$AUDIT_LOG")
  [ -d "$log_dir" ] || mkdir -p "$log_dir"

  # Escape quotes in details for valid JSON
  details="${details//\\/\\\\}"
  details="${details//\"/\\\"}"
  details="${details//$'\n'/\\n}"

  echo "{\"ts\":\"$ts\",\"event\":\"$event\",\"details\":\"$details\"}" >> "$AUDIT_LOG"
}

# Log session start
# Usage: audit_init "session_id"
audit_init() {
  local session_id="$1"
  audit_log "session_start" "session=$session_id agent=${DOYAKEN_AGENT:-claude} model=${DOYAKEN_MODEL:-}"
}

# Log phase completion
# Usage: audit_phase "phase_name" "pass|fail" "duration_seconds"
audit_phase() {
  local phase="$1"
  local status="$2"
  local duration="${3:-0}"
  audit_log "phase_complete" "phase=$phase status=$status duration_s=$duration"
}

# Log verification gate result
# Usage: audit_gate "gate_name" "pass|fail"
audit_gate() {
  local gate="$1"
  local result="$2"
  audit_log "gate_result" "gate=$gate result=$result"
}

# Pretty-print recent audit entries
# Usage: audit_show [--last N]
audit_show() {
  local limit=20

  while [ $# -gt 0 ]; do
    case "$1" in
      --last)
        shift
        limit="${1:-20}"
        ;;
    esac
    shift
  done

  if [ ! -f "$AUDIT_LOG" ]; then
    echo "No audit log found at: $AUDIT_LOG"
    return 0
  fi

  echo ""
  echo -e "${BOLD:-}Audit Log${NC:-} (last $limit entries)"
  echo "==========="
  echo ""

  tail -n "$limit" "$AUDIT_LOG" | while IFS= read -r line; do
    if command -v jq &>/dev/null; then
      local ts event details
      ts=$(echo "$line" | jq -r '.ts // ""' 2>/dev/null)
      event=$(echo "$line" | jq -r '.event // ""' 2>/dev/null)
      details=$(echo "$line" | jq -r '.details // ""' 2>/dev/null)
      printf "  %s  %-20s  %s\n" "${ts:-?}" "${event:-?}" "${details:-}"
    else
      echo "  $line"
    fi
  done
  echo ""
}
