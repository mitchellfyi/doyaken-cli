#!/usr/bin/env bash
# dk log — Pretty-print structured phase execution logs.
#
# Usage:
#   dk log                  Show logs for all recent sessions
#   dk log <session_id>     Show log for a specific session
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

format_duration() {
  local secs=$1
  if [[ $secs -lt 60 ]]; then
    echo "${secs}s"
  elif [[ $secs -lt 3600 ]]; then
    echo "$((secs / 60))m $((secs % 60))s"
  else
    echo "$((secs / 3600))h $(( (secs % 3600) / 60 ))m"
  fi
}

format_status() {
  case "$1" in
    advance)  echo "advance" ;;
    timeout)  echo "TIMEOUT" ;;
    interrupt) echo "interrupt" ;;
    crash)    echo "CRASH" ;;
    max-iter) echo "MAX-ITER" ;;
    *)        echo "$1" ;;
  esac
}

main() {
  local session_filter="${1:-}"

  if [[ ! -d "$DK_STATE_DIR" ]]; then
    echo "No phase logs found."
    return 0
  fi

  local found=0

  for log_file in "$DK_STATE_DIR"/*.log; do
    [[ -f "$log_file" ]] || continue

    # Extract session_id from filename
    local local_sid
    local_sid=$(basename "$log_file" .log)

    # Filter if specified
    if [[ -n "$session_filter" ]] && [[ "$local_sid" != *"$session_filter"* ]]; then
      continue
    fi

    found=1
    echo ""
    echo "Session: $local_sid"
    echo "─────────────────────────────────────────────────────────"
    printf "  %-5s  %-18s  %-10s  %-10s  %s\n" "Phase" "Name" "Duration" "Iters" "Status"
    printf "  %-5s  %-18s  %-10s  %-10s  %s\n" "─────" "──────────────────" "──────────" "──────" "──────"

    # Skip header line, read data rows
    tail -n +2 "$log_file" | while IFS=$'\t' read -r sid phase phase_name start end dur iters status exit_code; do
      [[ -z "$phase" ]] && continue
      local formatted_dur formatted_status
      formatted_dur=$(format_duration "$dur")
      formatted_status=$(format_status "$status")
      printf "  %-5s  %-18s  %-10s  %-10s  %s\n" "$phase" "$phase_name" "$formatted_dur" "$iters" "$formatted_status"
    done

    # Total duration
    local first_start last_end
    first_start=$(tail -n +2 "$log_file" | head -1 | cut -f4)
    last_end=$(tail -1 "$log_file" | cut -f5)
    if [[ -n "$first_start" ]] && [[ -n "$last_end" ]] && [[ "$first_start" =~ ^[0-9]+$ ]] && [[ "$last_end" =~ ^[0-9]+$ ]]; then
      local total=$((last_end - first_start))
      echo ""
      echo "  Total: $(format_duration $total)"
    fi
    echo ""
  done

  if [[ $found -eq 0 ]]; then
    if [[ -n "$session_filter" ]]; then
      echo "No logs found matching '$session_filter'."
    else
      echo "No phase logs found."
    fi
  fi
}

main "$@"
