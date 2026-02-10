#!/usr/bin/env bash
#
# approval.sh - Human-in-the-loop approval system for doyaken
#
# Provides configurable approval gates between phases.
# Autonomy levels: full-auto, supervised, plan-only
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_APPROVAL_LOADED:-}" ]] && return 0
_DOYAKEN_APPROVAL_LOADED=1

# ============================================================================
# Autonomy Levels
# ============================================================================

# Levels: full-auto (default), supervised, plan-only
DOYAKEN_APPROVAL="${DOYAKEN_APPROVAL:-full-auto}"

# ============================================================================
# Approval Gate
# ============================================================================

# Check if approval is needed after a phase
# Usage: approval_gate <phase_name> <task_id>
# Returns: 0 = continue, 1 = abort, 2 = skip next phase
approval_gate() {
  local phase_name="$1"
  local task_id="${2:-}"

  case "$DOYAKEN_APPROVAL" in
    full-auto)
      # No approval needed
      return 0
      ;;
    plan-only)
      # Stop after plan phase
      if [ "$phase_name" = "plan" ]; then
        _approval_prompt_plan_only "$task_id"
        return $?
      fi
      return 0
      ;;
    supervised)
      _approval_prompt_supervised "$phase_name" "$task_id"
      return $?
      ;;
    *)
      # Unknown level — treat as full-auto
      return 0
      ;;
  esac
}

# ============================================================================
# Supervised Mode Prompt
# ============================================================================

_approval_prompt_supervised() {
  local phase_name="$1"
  local task_id="${2:-}"

  echo ""
  echo -e "${BOLD}Phase completed: ${GREEN}$phase_name${NC}"

  # Show git diff stat if available
  local project="${DOYAKEN_PROJECT:-$(pwd)}"
  if [ -d "$project/.git" ]; then
    local changes
    changes=$(git -C "$project" diff --stat HEAD 2>/dev/null)
    if [ -n "$changes" ]; then
      echo -e "${DIM}Changes:${NC}"
      echo "$changes"
    fi
  fi

  echo ""
  echo "  [Y] Continue to next phase"
  echo "  [n] Pause (return to prompt)"
  echo "  [s] Skip next phase"
  echo "  [a] Abort task execution"
  echo ""

  local choice
  local timeout="${DOYAKEN_AUTO_TIMEOUT:-60}"

  if [ "$timeout" -gt 0 ]; then
    echo -e "  ${YELLOW}(auto-continue in ${timeout}s)${NC}"
    printf "Continue? [Y/n/s/a]: "
    if ! read -r -t "$timeout" choice 2>/dev/null; then
      echo ""
      echo -e "${DIM}Auto-continuing...${NC}"
      choice="y"
    fi
  else
    printf "Continue? [Y/n/s/a]: "
    read -r choice
  fi

  case "${choice:-y}" in
    y|Y|"")
      return 0
      ;;
    n|N)
      echo -e "${YELLOW}Paused${NC} — use /run to continue"
      return 1
      ;;
    s|S)
      echo -e "${YELLOW}Skipping${NC} next phase"
      return 2
      ;;
    a|A)
      echo -e "${RED}Aborting${NC} task execution"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

# ============================================================================
# Plan-Only Mode Prompt
# ============================================================================

_approval_prompt_plan_only() {
  local task_id="${1:-}"

  echo ""
  echo -e "${BOLD}Plan phase completed${NC}"
  echo -e "${DIM}Review the plan above. The agent will not proceed until you approve.${NC}"
  echo ""
  echo "  [Y] Approve plan and continue implementation"
  echo "  [n] Reject plan (return to prompt)"
  echo "  [a] Abort task execution"
  echo ""

  local choice
  printf "Approve plan? [Y/n/a]: "
  read -r choice

  case "${choice:-y}" in
    y|Y|"")
      echo -e "${GREEN}Plan approved${NC} — continuing to implementation"
      return 0
      ;;
    n|N)
      echo -e "${YELLOW}Plan rejected${NC} — use /run to regenerate"
      return 1
      ;;
    a|A)
      echo -e "${RED}Aborting${NC}"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

# ============================================================================
# Approval Configuration
# ============================================================================

# Set the approval level
# Usage: set_approval_level "supervised"
set_approval_level() {
  local level="$1"

  case "$level" in
    full-auto|supervised|plan-only)
      export DOYAKEN_APPROVAL="$level"
      return 0
      ;;
    *)
      echo "Unknown approval level: $level"
      echo "Valid levels: full-auto, supervised, plan-only"
      return 1
      ;;
  esac
}

# Get current approval level
get_approval_level() {
  echo "${DOYAKEN_APPROVAL:-full-auto}"
}

# Check if a specific phase should be skipped due to approval
# Used after approval_gate returns 2 (skip)
APPROVAL_SKIP_NEXT=0

# Reset skip flag
approval_reset_skip() {
  APPROVAL_SKIP_NEXT=0
}
