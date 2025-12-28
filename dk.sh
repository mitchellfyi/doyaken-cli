# shellcheck shell=bash disable=SC2296
# ^ dk.sh is zsh-only; SC2296 suppresses zsh parameter expansion syntax warnings.
# Doyaken — Shell functions (zsh only)
#
# Source this in ~/.zshrc:
#   source $DOYAKEN_DIR/dk.sh
#
# Requires zsh — uses zsh-specific syntax (e.g., ${(j: :)@} for array joining).
# Hook scripts (hooks/*.sh) use #!/usr/bin/env bash. Library files (lib/*.sh)
# use bash/zsh-compatible syntax and are sourced by both dk.sh and hook scripts.
#
# Provides:
#   doyaken <command>       Manage Doyaken installation
#   dk <number>             Start/resume a phased lifecycle for a ticket
#   dk "description"        Start/resume a phased lifecycle for a task
#   dk --resume             Resume the most recent session
#   dk --from-pr <N>        Resume session linked to a PR
#   dkrm <number|name|--all>  Remove a worktree
#   dkls                   List worktrees
#   dkclean                Clean stale worktrees + gone branches
#   dkloop <prompt>         Run a prompt until fully implemented

DOYAKEN_DIR="${DOYAKEN_DIR:-$HOME/work/doyaken}"
source "$DOYAKEN_DIR/lib/common.sh"

# ─── doyaken CLI ─────────────────────────────────────────────────────────
# unalias/unfunction before each function definition so this file can be
# re-sourced (e.g. via `doyaken reload`) without "already defined" errors.

unalias doyaken 2>/dev/null; unfunction doyaken 2>/dev/null
doyaken() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    install)   bash "$DOYAKEN_DIR/bin/install.sh" "$@" ;;
    uninstall) bash "$DOYAKEN_DIR/bin/uninstall.sh" "$@" ;;
    init)      bash "$DOYAKEN_DIR/bin/init.sh" "$@" ;;
    config)    bash "$DOYAKEN_DIR/bin/config.sh" "$@" ;;
    uninit)    bash "$DOYAKEN_DIR/bin/uninit.sh" "$@" ;;
    reload)
      source "$DOYAKEN_DIR/dk.sh"
      echo "Reloaded Doyaken shell functions."
      ;;
    status)    bash "$DOYAKEN_DIR/bin/status.sh" "$@" ;;
    help|--help|-h)
      echo "Doyaken — workflow automation for Claude Code"
      echo ""
      echo "Commands:"
      echo "  dk install          Global install (skills, agents, hooks, zshrc)"
      echo "  dk uninstall        Global uninstall"
      echo "  dk init             Bootstrap current repo for Doyaken"
      echo "  dk config           Configure integrations (ticket tracker, Figma, etc.)"
      echo "  dk uninit           Remove Doyaken from current repo"
      echo "  dk reload           Reload shell functions after editing dk.sh"
      echo "  dk status           Show installation status"
      echo ""
      echo "Worktree commands:"
      echo "  dk <number>            Start/resume phased lifecycle for a ticket"
      echo "  dk \"<description>\"     Start/resume phased lifecycle for a task"
      echo "  dk --resume            Resume the most recent session"
      echo "  dk --from-pr <N>      Resume session linked to a PR"
      echo "  dkrm <number|name>    Remove a worktree"
      echo "  dkrm --all            Remove all worktrees"
      echo "  dkls                  List worktrees"
      echo "  dkclean               Clean stale worktrees + gone branches"
      echo ""
      echo "Prompt loop:"
      echo "  dkloop <prompt>          Run a prompt until fully implemented"
      echo ""
      echo "Lifecycle phases (run automatically by dk):"
      echo "  1. Plan            Gather context, draft plan, get approval"
      echo "  2. Implement       Work through tasks with TDD + self-review"
      echo "  3. Verify & Commit Format, lint, typecheck, test, then commit + push"
      echo "  4. PR              Generate PR description, get approval"
      echo "  5. Complete        Monitor CI/reviews, close ticket"
      ;;
    *)
      echo "Unknown command: $cmd"
      echo "Run 'dk help' for usage."
      return 1
      ;;
  esac
}

# ─── Phase configuration ────────────────────────────────────────────────────

# Default Claude flags for all dk-launched sessions:
#   --chrome           Enable browser automation tools (MCP)
#   --model opus       Use Opus for autonomous multi-phase work
#   --permission-mode bypassPermissions  No interactive prompts (autonomous)
#   --effort max       Maximum reasoning effort for complex tasks
DK_CLAUDE_FLAGS=(--chrome --model opus --permission-mode bypassPermissions --effort max)

# Phase 1 uses plan mode — enforced read-only until user approves via ExitPlanMode.
# All other phases use bypassPermissions (from DK_CLAUDE_FLAGS).
DK_PLAN_FLAGS=(--chrome --model opus --permission-mode plan --effort max)

# Phase definitions (1-indexed, index 0 is unused placeholder)
DK_PHASE_NAMES=("" "Plan" "Implement" "Verify & Commit" "PR" "Complete")

DK_PHASE_PROMISES=("" \
  "PHASE_1_COMPLETE" \
  "PHASE_2_COMPLETE" \
  "PHASE_3_COMPLETE" \
  "PHASE_4_COMPLETE" \
  "DOYAKEN_TICKET_COMPLETE" \
)

DK_PHASE_MESSAGES=("" \
  "You are in plan mode. Run /dkplan — gather context, explore the codebase, and create your implementation plan. When the plan is ready, use ExitPlanMode to present it for approval." \
  "The plan is approved. Run /dkimplement — work through all tasks with TDD. Run /dkreview when done. When all tasks pass review, output PHASE_2_COMPLETE and stop." \
  "Run /dkverify — format, lint, typecheck, test. Fix any failures. When all green, run /dkcommit. When pushed, output PHASE_3_COMPLETE and stop." \
  "Run /dkpr. Generate the PR description, present it for my review. When I approve, mark ready and output PHASE_4_COMPLETE and stop." \
  "Set up monitoring with /loop 2m /dkwatchci and /loop 5m /dkwatchreviews. When all checks green and reviews approved, run /dkcomplete. Output DOYAKEN_TICKET_COMPLETE and stop." \
)

# Audit prompt file basenames (must match prompts/phase-audits/ filenames)
DK_PHASE_AUDIT_FILES=("" "1-plan" "2-implement" "3-verify" "4-pr" "5-complete")

# ─── Internal helpers ───────────────────────────────────────────────────────

# dk_default_branch is provided by lib/git.sh (sourced via lib/common.sh)

# __dk_is_ticket <string>
# Returns 0 if the string looks like a ticket reference (bare number, prefixed
# like ENG-999, ticket-999). Returns 1 otherwise (freeform task description).
# Used by __dk_setup_worktree and dkrm to consistently classify user input.
__dk_is_ticket() {
  [[ "$1" =~ ^[[:space:]]*[a-zA-Z]*-?[0-9]+[[:space:]]*$ ]]
}

# __dk_setup_worktree <raw_input>
# Sets: _dk_wt_name, _dk_wt_dir, _dk_is_task, _dk_repo_root, _dk_default_branch
# Returns 0 if worktree exists or was created, 1 on error.
# See: docs/autonomous-mode.md for the full lifecycle that follows worktree creation.
__dk_setup_worktree() {
  local raw_input="$1"

  _dk_repo_root=$(dk_repo_root) || return 1

  _dk_is_task=0
  if __dk_is_ticket "$raw_input"; then
    local num="${raw_input//[^0-9]/}"  # strip everything except digits
    _dk_wt_name="ticket-${num}"
  else
    local slug
    slug=$(dk_slugify "$raw_input")
    if [[ -z "$slug" ]]; then
      echo "ERROR: Could not create a valid name from '$raw_input'"
      return 1
    fi
    _dk_wt_name="task-${slug}"
    _dk_is_task=1
  fi

  _dk_wt_dir="${_dk_repo_root}/.doyaken/worktrees/${_dk_wt_name}"

  _dk_default_branch=$(dk_default_branch)

  # If worktree exists, we're done
  if [[ -d "$_dk_wt_dir" ]]; then
    return 0
  fi

  # Require doyaken init
  if [[ ! -d "${_dk_repo_root}/.doyaken" ]]; then
    echo "ERROR: This repo hasn't been initialised for Doyaken."
    echo "Run: dk init"
    return 1
  fi

  # Create worktree
  echo "Creating worktree ${_dk_wt_name}..."
  git fetch origin "$_dk_default_branch" --quiet 2>/dev/null || true
  mkdir -p "${_dk_repo_root}/.doyaken/worktrees"

  if ! git worktree add "$_dk_wt_dir" -b "worktree-${_dk_wt_name}" "origin/${_dk_default_branch}" 2>&1; then
    echo "ERROR: Failed to create worktree."
    return 1
  fi

  # Save raw prompt for task worktrees (picked up by SessionStart hook)
  if [[ $_dk_is_task -eq 1 ]]; then
    printf '%s\n' "$raw_input" > "$_dk_wt_dir/.doyaken-prompt"
  fi

  return 0
}

# dk_session_id is provided by lib/session.sh (sourced via lib/common.sh)

# __dk_build_system_context <wt_name> <step> <session_id> <wt_dir>
# Write a system prompt context file that persists across conversation compaction.
# Returns the file path on stdout. The file is passed to --append-system-prompt-file
# so Claude always knows which phase it is in, even after compaction.
__dk_build_system_context() {
  local wt_name="$1" step="$2" session_id="$3" wt_dir="$4"
  local ctx_file
  ctx_file=$(dk_context_file "$session_id")
  mkdir -p "$(dirname "$ctx_file")"

  local complete_file
  complete_file=$(dk_complete_file "$session_id")

  cat > "$ctx_file" <<EOF
You are Doyaken, running Phase ${step} (${DK_PHASE_NAMES[$step]}) for ${wt_name}.
Worktree: ${wt_dir}

Completion protocol:
1. Write the signal file: use Bash to run: touch "${complete_file}"
2. Output the promise string: ${DK_PHASE_PROMISES[$step]}

If you lose context after compaction, re-read the phase audit prompt at:
  ${DOYAKEN_DIR}/prompts/phase-audits/${DK_PHASE_AUDIT_FILES[$step]}.md
EOF
  echo "$ctx_file"
}

# __dk_run_phases <wt_name> <wt_dir> <default_branch> <start_step> <state_file> <times_file> <resume_hint>
#
# Phase loop state machine: runs phases start_step through 5 sequentially.
# Each phase launches a Claude Code session with:
#   - A phase-specific message (DK_PHASE_MESSAGES) that tells Claude which skills to run
#   - An audit loop (DOYAKEN_LOOP_* env vars) that prevents premature exit
#   - Session naming (-n) so --resume can reconnect across phase boundaries
#
# Phase transitions:
#   Phase N completes (exit 0) → state_file written with N+1 → loop continues
#   Phase N interrupted (exit != 0) → state_file written with N → function returns
#   All 5 phases complete → state_file written with 6 (sentinel for "done")
#
# The .complete signal file (managed by phase-loop.sh) is the bridge between
# Claude's intent to stop and the wrapper's phase advancement. See docs/autonomous-mode.md.
#
# Returns non-zero if user interrupts or an error occurs.
__dk_run_phases() {
  local wt_name="$1" wt_dir="$2" default_branch="$3" step="$4"
  local state_file="$5" times_file="$6" resume_hint="$7"

  # Ensure Claude Code CLI is installed — all phases depend on it
  if ! command -v claude &>/dev/null; then
    echo "ERROR: Claude Code CLI not found in PATH."
    echo "Install it from https://docs.anthropic.com/en/docs/claude-code then try again."
    return 1
  fi

  # Ensure state directory exists (needed for resume path and fresh start)
  mkdir -p "$DK_STATE_DIR"

  while [[ $step -le 5 ]]; do
    __dk_show_header "$wt_name" "$step" "$wt_dir" "$default_branch"

    local claude_args=()
    if [[ $step -eq 1 ]]; then
      # Phase 1: plan mode — enforced read-only until user approves via ExitPlanMode.
      # No stop hook: plan mode's built-in approval is the quality gate.
      claude_args=("${DK_PLAN_FLAGS[@]}" -n "$wt_name")
      # Resume only if re-entering Phase 1 (prior session exists)
      if [[ -f "$times_file" ]]; then
        claude_args+=(--resume)
      fi
    else
      # Phases 2-5: autonomous with stop hook audit loop
      claude_args=("${DK_CLAUDE_FLAGS[@]}" -n "$wt_name")
      claude_args+=(--resume)

      # System prompt context file — survives conversation compaction so Claude
      # always knows which phase it is in and how to signal completion.
      local session_id
      session_id=$(dk_session_id "$wt_name")
      local ctx_file
      ctx_file=$(__dk_build_system_context "$wt_name" "$step" "$session_id" "$wt_dir")
      claude_args+=(--append-system-prompt-file "$ctx_file")

      # Live status line — shows phase, audit iteration, and elapsed time in TUI
      claude_args+=(--settings "{\"statusLine\":{\"type\":\"command\",\"command\":\"bash '${DOYAKEN_DIR}/bin/status-line.sh'\"}}")

      # Fork session at major phase boundaries to free context budget.
      # Phase 3 (Verify) and Phase 5 (Complete) benefit from a fresh context
      # window rather than inheriting a nearly-full window from implementation.
      # The system prompt file ensures essential context survives the fork.
      if [[ $step -eq 3 ]] || [[ $step -eq 5 ]]; then
        claude_args+=(--fork-session)
      fi
    fi

    # Record phase start time
    echo "${step}:$(date +%s)" >> "$times_file"

    if [[ $step -eq 1 ]]; then
      # Phase 1: plan mode — no audit loop. ExitPlanMode handles approval.
      (cd "$wt_dir" && \
        DOYAKEN_DIR="$DOYAKEN_DIR" \
        claude "${claude_args[@]}" "${DK_PHASE_MESSAGES[$step]}")
    else
      # Phases 2-5: audit loop active.
      # Load phase-specific audit prompt from file
      local audit_prompt=""
      local audit_file="$DOYAKEN_DIR/prompts/phase-audits/${DK_PHASE_AUDIT_FILES[$step]}.md"
      [[ -f "$audit_file" ]] && audit_prompt=$(cat "$audit_file")

      # The Stop hook (phase-loop.sh) uses these env vars to block premature stops:
      #   DOYAKEN_LOOP_ACTIVE=1   — enables the audit loop
      #   DOYAKEN_LOOP_PROMISE    — completion string for this phase
      #   DOYAKEN_LOOP_PROMPT     — audit prompt injected when Claude tries to stop
      #   DOYAKEN_LOOP_PHASE      — phase number (fallback for prompt file lookup)
      # Claude exits 0 when the .complete file is written (loop allows stop) or
      # max iterations reached. Non-zero means user interrupt or error.
      # See: docs/autonomous-mode.md for the full architecture.
      # Runs in a subshell so `cd` doesn't affect the parent shell. Environment
      # variables are set inline (not exported) to scope them to this invocation.
      (cd "$wt_dir" && \
        DOYAKEN_LOOP_ACTIVE=1 \
        DOYAKEN_LOOP_PROMISE="${DK_PHASE_PROMISES[$step]}" \
        DOYAKEN_LOOP_PROMPT="$audit_prompt" \
        DOYAKEN_LOOP_PHASE="$step" \
        DOYAKEN_DIR="$DOYAKEN_DIR" \
        claude "${claude_args[@]}" "${DK_PHASE_MESSAGES[$step]}")
    fi

    local exit_code=$?

    # Non-zero exit = user interrupted (Ctrl+C) or error — save state for resume
    if [[ $exit_code -ne 0 ]]; then
      echo "$step" > "$state_file"
      echo ""
      echo "Paused at Phase ${step}: ${DK_PHASE_NAMES[$step]}"
      echo "Resume with: ${resume_hint}"
      return $exit_code
    fi

    # Advance to next phase
    step=$((step + 1))
    echo "$step" > "$state_file"
  done

  # All phases complete — write step=6 so re-running `dk <ticket>` or
  # `dk --resume` detects completion instead of restarting from Phase 1.
  # State files are cleaned up by dkrm / dkclean when the worktree is removed.
  echo "6" > "$state_file"
  __dk_show_header "$wt_name" 6 "$wt_dir" "$default_branch"
  echo "All phases complete! Run dkrm ${wt_name} to clean up."
}

# __dk_format_elapsed <seconds>
# Format seconds as "Xm Ys"
__dk_format_elapsed() {
  local secs=$1
  if [[ $secs -lt 60 ]]; then
    echo "${secs}s"
  else
    echo "$((secs / 60))m $((secs % 60))s"
  fi
}

# __dk_show_header <wt_name> <current_step> <wt_dir> [default_branch]
# Display lifecycle progress between phases
__dk_show_header() {
  local wt_name="$1" step="$2" wt_dir="$3" default_branch="${4:-main}"
  local session_id times_file
  session_id=$(dk_session_id "$wt_name")
  times_file=$(dk_times_file "$session_id")

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  DOYAKEN — ${wt_name}"
  echo ""

  # Phase progress line
  local progress="  "
  local i
  for i in 1 2 3 4 5; do
    if [[ $i -lt $step ]]; then
      progress+="✓ ${DK_PHASE_NAMES[$i]}"
    elif [[ $i -eq $step ]]; then
      progress+="→ ${DK_PHASE_NAMES[$i]}"
    else
      progress+="○ ${DK_PHASE_NAMES[$i]}"
    fi
    [[ $i -lt 5 ]] && progress+="  "
  done
  echo "$progress"
  echo ""

  # Metadata (only if worktree exists and has commits).
  # Parses "X files changed" from `git diff --stat` summary line; falls back to "0"
  # if the diff is empty (no changes yet) or the base branch is unreachable.
  if [[ -d "$wt_dir" ]]; then
    local files_changed commits_count
    files_changed=$(git -C "$wt_dir" diff --stat "origin/${default_branch}" 2>/dev/null | tail -1 | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo "0")
    commits_count=$(git -C "$wt_dir" log --oneline "origin/${default_branch}..HEAD" 2>/dev/null | wc -l | tr -d ' ')

    local actual_branch
    actual_branch=$(dk_wt_branch "$wt_dir" "worktree-${wt_name}")
    local meta="  Branch: ${actual_branch}"
    [[ "$files_changed" != "0" ]] && meta+=" | ${files_changed} files changed"
    [[ "$commits_count" != "0" ]] && meta+=" | ${commits_count} commits"
    echo "$meta"
  fi

  # Timing info
  if [[ -f "$times_file" ]] && [[ $step -gt 1 ]]; then
    local prev_step=$((step - 1))
    local prev_start total_start now phase_elapsed total_elapsed
    now=$(date +%s)

    # Previous phase elapsed
    prev_start=$(grep "^${prev_step}:" "$times_file" 2>/dev/null | tail -1 | cut -d: -f2)
    total_start=$(head -1 "$times_file" 2>/dev/null | cut -d: -f2)

    local timing=""
    if [[ -n "$prev_start" ]]; then
      phase_elapsed=$((now - prev_start))
      timing+="  Phase ${prev_step} took $(__dk_format_elapsed $phase_elapsed)"
    fi
    if [[ -n "$total_start" ]]; then
      total_elapsed=$((now - total_start))
      timing+=" | Total: $(__dk_format_elapsed $total_elapsed)"
    fi
    [[ -n "$timing" ]] && echo "$timing"
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ─── dk — phased lifecycle wrapper ──────────────────────────────────────────

unalias dk 2>/dev/null; unfunction dk 2>/dev/null
dk() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: dk <NUMBER>        (e.g. dk 999, dk ENG-999)"
    echo "       dk \"<description>\" (e.g. dk \"fix login bug\")"
    echo "       dk --resume        Resume the most recent session"
    echo "       dk --from-pr <N>   Resume session linked to a PR"
    echo ""
    echo "       dk init|config|install|uninstall|uninit|status|reload|help"
    return 1
  fi

  # Route management subcommands to doyaken
  case "$1" in
    init|config|install|uninstall|uninit|status|reload|help|--help|-h)
      doyaken "$@"
      return $?
      ;;
  esac

  # Resume mode — find most recent session and continue from tracked phase
  if [[ "$1" == "--resume" ]]; then
    local last_session_file="$DK_STATE_DIR/last-session"
    if [[ ! -f "$last_session_file" ]]; then
      echo "ERROR: No previous session found."
      echo "Start a new session with: dk <number>"
      return 1
    fi
    # last-session file format: "wt_name:wt_dir" (e.g., "ticket-999:/path/to/worktree")
    local last_info
    last_info=$(cat "$last_session_file" 2>/dev/null)
    local last_wt_name="${last_info%%:*}"  # everything before first colon
    local last_wt_dir="${last_info#*:}"    # everything after first colon
    if [[ ! -d "$last_wt_dir" ]]; then
      echo "ERROR: Worktree ${last_wt_name} no longer exists."
      rm -f "$last_session_file"
      return 1
    fi

    # Validate worktree git state
    if ! git -C "$last_wt_dir" rev-parse --git-dir &>/dev/null; then
      echo "ERROR: Worktree ${last_wt_name} has corrupted git state."
      echo "Run dkrm ${last_wt_name} and start fresh."
      return 1
    fi

    # Reconstruct raw_input for resume message
    local raw_input="$last_wt_name"
    _dk_wt_name="$last_wt_name"
    _dk_wt_dir="$last_wt_dir"
    _dk_default_branch=$(dk_default_branch "$last_wt_dir")

    # Fall through to the phase loop below
    local session_id state_file times_file
    session_id=$(dk_session_id "$_dk_wt_name")
    state_file=$(dk_state_file "$session_id")
    times_file=$(dk_times_file "$session_id")
    local step=1
    [[ -f "$state_file" ]] && step=$(cat "$state_file" 2>/dev/null)
    [[ "$step" =~ ^[1-6]$ ]] || step=1

    if [[ $step -gt 5 ]]; then
      echo "All phases already complete for ${_dk_wt_name}."
      echo "Run dkrm ${_dk_wt_name} to clean up, or reset with:"
      echo "  rm $state_file"
      return 0
    fi

    echo "Resuming ${_dk_wt_name} from Phase ${step}: ${DK_PHASE_NAMES[$step]}..."

    __dk_run_phases "$_dk_wt_name" "$_dk_wt_dir" "$_dk_default_branch" "$step" "$state_file" "$times_file" "dk --resume"
    return $?
  fi

  # PR-linked mode — resume a session associated with a GitHub PR
  if [[ "$1" == "--from-pr" ]]; then
    if [[ -z "${2:-}" ]]; then
      echo "Usage: dk --from-pr <PR_NUMBER|URL>"
      return 1
    fi
    claude "${DK_CLAUDE_FLAGS[@]}" --from-pr "$2"
    return $?
  fi

  # Normal mode — setup worktree and run phased lifecycle
  local raw_input="${(j: :)@}"  # zsh: join all args with spaces

  if ! __dk_setup_worktree "$raw_input"; then
    return 1
  fi

  mkdir -p "$DK_STATE_DIR"

  local session_id state_file times_file
  session_id=$(dk_session_id "$_dk_wt_name")
  state_file=$(dk_state_file "$session_id")
  times_file=$(dk_times_file "$session_id")

  # Save as last session for --resume
  echo "${_dk_wt_name}:${_dk_wt_dir}" > "$DK_STATE_DIR/last-session"

  # Read current phase (default: 1)
  local step=1
  if [[ -f "$state_file" ]]; then
    step=$(cat "$state_file" 2>/dev/null)
    [[ "$step" =~ ^[1-6]$ ]] || step=1
  fi

  if [[ $step -gt 5 ]]; then
    echo "All phases already complete for ${_dk_wt_name}."
    echo "Run dkrm ${raw_input} to clean up, or reset with:"
    echo "  rm $state_file"
    return 0
  fi

  if [[ $step -gt 1 ]]; then
    echo "Resuming ${_dk_wt_name} from Phase ${step}: ${DK_PHASE_NAMES[$step]}..."
  fi

  # ── Phase loop ──
  __dk_run_phases "$_dk_wt_name" "$_dk_wt_dir" "$_dk_default_branch" "$step" "$state_file" "$times_file" "dk ${raw_input}"
}

# ─── dkloop — prompt loop (run until done) ─────────────────────────────────

unalias dkloop 2>/dev/null; unfunction dkloop 2>/dev/null
dkloop() {
  local prompt=""
  if [[ $# -eq 0 ]]; then
    # No prompt given — load the default codebase improvement prompt
    local default_prompt_file="$DOYAKEN_DIR/prompts/default-loop.md"
    if [[ ! -f "$default_prompt_file" ]]; then
      echo "ERROR: Default prompt not found at $default_prompt_file"
      return 1
    fi
    prompt=$(cat "$default_prompt_file")
    dk_info "No prompt given — using default: review, improve, and harden the codebase"
  else
    prompt="${(j: :)@}"
  fi

  if ! command -v claude &>/dev/null; then
    echo "ERROR: Claude Code CLI not found in PATH."
    echo "Install it from https://docs.anthropic.com/en/docs/claude-code then try again."
    return 1
  fi

  # Validate we're in a git repo (needed for session ID derivation)
  local repo_root
  repo_root=$(dk_repo_root) || return 1

  # Derive a unique session ID so concurrent dkloops on the same branch don't collide
  mkdir -p "$DK_LOOP_DIR"
  local session_id
  session_id=$(dk_unique_session_id)

  # Remove any loop files that happen to share this unique session ID (harmless
  # no-op in practice since each dkloop gets a fresh ID via dk_unique_session_id).
  rm -f "$(dk_loop_file "$session_id")" "$(dk_complete_file "$session_id")" "$(dk_active_file "$session_id")"

  # Persist the original prompt so the Stop hook can re-inject it on each audit
  # iteration. Context compaction may lose the initial message after several rounds.
  local prompt_file
  prompt_file="$(dk_prompt_file "$session_id")"
  printf '%s\n' "$prompt" > "$prompt_file"

  # Show header
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  local prompt_slug
  prompt_slug=$(dk_slugify "${prompt:0:40}")
  local session_name=""
  [[ -n "$prompt_slug" ]] && session_name="dkloop-${prompt_slug}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  DOYAKEN — dkloop (prompt loop)"
  echo ""
  echo "  Branch: ${branch}"
  echo "  Prompt: ${prompt:0:72}$([ ${#prompt} -gt 72 ] && echo '...')"
  echo "  Phase:  Plan → Implement"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # ── Session 1: Plan ──
  # Plan mode enforces read-only until the user approves via ExitPlanMode.
  # No stop hook — plan mode's built-in approval is the quality gate.
  local plan_args=("${DK_PLAN_FLAGS[@]}")
  [[ -n "$session_name" ]] && plan_args+=(-n "$session_name")
  plan_args+=(--append-system-prompt "You are in a dkloop planning session. Your original task prompt is saved at ${prompt_file}. Re-read it with the Read tool if you lose track of the task.")

  dk_info "Phase: Plan (read-only until approved)"
  DOYAKEN_SESSION_ID="$session_id" \
  DOYAKEN_DIR="$DOYAKEN_DIR" \
  claude "${plan_args[@]}" "You are in plan mode. Run /dkplan for the following task:

${prompt}

Gather context, explore the codebase, and create your implementation plan. When the plan is ready, use ExitPlanMode to present it for approval."

  local plan_exit=$?
  if [[ $plan_exit -ne 0 ]]; then
    rm -f "$(dk_loop_file "$session_id")" \
          "$(dk_complete_file "$session_id")" \
          "$(dk_active_file "$session_id")" \
          "$(dk_prompt_file "$session_id")" 2>/dev/null
    echo ""
    dk_info "dkloop interrupted during planning (exit code: $plan_exit)."
    return $plan_exit
  fi

  # ── Session 2: Implement ──
  # Autonomous mode with stop hook audit loop. Resumes the plan session.
  local impl_args=("${DK_CLAUDE_FLAGS[@]}" --resume)
  [[ -n "$session_name" ]] && impl_args+=(-n "$session_name")
  impl_args+=(--append-system-prompt "You are in a dkloop session. Your original task prompt is saved at ${prompt_file}. Re-read it with the Read tool before any audit step, or when you lose track of what you are working on.")

  dk_info "Phase: Implement (autonomous)"
  DOYAKEN_SESSION_ID="$session_id" \
  DOYAKEN_LOOP_ACTIVE=1 \
  DOYAKEN_LOOP_PROMISE="PROMPT_COMPLETE" \
  DOYAKEN_LOOP_PHASE="prompt-loop" \
  DOYAKEN_DIR="$DOYAKEN_DIR" \
  claude "${impl_args[@]}" "The plan is approved. Implement it now. Work through all tasks, following TDD where the project has tests. The stop hook audit will guide you through quality verification and final review when you are done."

  local exit_code=$?

  # Clean up state files
  rm -f "$(dk_loop_file "$session_id")" \
        "$(dk_complete_file "$session_id")" \
        "$(dk_active_file "$session_id")" \
        "$(dk_prompt_file "$session_id")" 2>/dev/null

  if [[ $exit_code -eq 0 ]]; then
    echo ""
    dk_done "dkloop complete."
  else
    echo ""
    dk_info "dkloop interrupted (exit code: $exit_code)."
  fi

  return $exit_code
}

# ─── dkrm — remove worktrees ──────────────────────────────────────────────

unalias dkrm 2>/dev/null; unfunction dkrm 2>/dev/null
dkrm() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: dkrm <NUMBER>     (e.g. dkrm 999)"
    echo "       dkrm <name>       (e.g. dkrm task-fix-login)"
    echo "       dkrm --all        Remove all worktrees"
    return 1
  fi

  # Find repo root — git rev-parse may fail if cwd was deleted, so fall back
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$repo_root" ]]; then
    local cwd
    cwd="$(pwd 2>/dev/null || echo "")"
    if [[ "$cwd" == *"/.doyaken/worktrees/"* ]]; then
      repo_root="${cwd%%/.doyaken/worktrees/*}"
    fi
  fi
  if [[ -z "$repo_root" ]]; then
    echo "ERROR: Could not determine repo root. cd to the repo and try again."
    return 1
  fi

  local worktrees_dir="${repo_root}/.doyaken/worktrees"

  # Move to repo root first in case we're inside a worktree being removed.
  # Must succeed — subsequent git operations depend on being in the right directory.
  # Note: this intentionally does not restore the original cwd — if the user was
  # inside a worktree that got deleted, returning there would fail.
  cd "$repo_root" || return 1

  if [[ "$1" == "--all" ]]; then
    local found=0
    local renamed_branches=()
    local session_ids=()

    if [[ -d "$worktrees_dir" ]]; then
      for wt_dir in "$worktrees_dir"/*/; do
        [[ -d "$wt_dir" ]] || continue
        found=1
        local wt_name
        wt_name="$(basename "$wt_dir")"
        session_ids+=("worktree-${wt_name}")

        # The SessionStart hook may rename the worktree branch (e.g. from
        # worktree-ticket-999 to feat/ENG-999-description) to follow project
        # conventions. Track these renamed branches so we can delete them below
        # — they won't match the 'worktree-*' glob pattern.
        local actual_branch
        actual_branch=$(dk_wt_branch "$wt_dir")
        if [[ -n "$actual_branch" && "$actual_branch" != "worktree-${wt_name}" ]]; then
          renamed_branches+=("$actual_branch")
        fi

        echo "Removing ${wt_name}..."
        dk_wt_remove "$wt_dir"
      done
    fi

    local branch
    while IFS= read -r branch; do
      [[ -z "$branch" ]] && continue
      found=1
      echo "Deleting branch ${branch}..."
      git branch -D "$branch" 2>/dev/null || true
    done < <(git branch --list 'worktree-ticket-*' 'worktree-task-*' 2>/dev/null | sed 's/^[* ]*//')

    # Delete renamed branches that wouldn't match the worktree-* pattern
    for branch in "${renamed_branches[@]}"; do
      echo "Deleting renamed branch ${branch}..."
      git branch -D "$branch" 2>/dev/null || true
      found=1
    done

    git worktree prune 2>/dev/null

    # Clean up last-session pointer (all worktrees gone, nothing to resume)
    rm -f "$DK_STATE_DIR/last-session" 2>/dev/null

    # Clean up state files for THIS repo's worktrees only (not cross-repo globs)
    local sid
    for sid in "${session_ids[@]}"; do
      dk_cleanup_session "$sid"
    done

    if [[ $found -eq 0 ]]; then
      echo "No worktrees or branches found."
    else
      echo "All worktrees removed."
    fi
    return 0
  fi

  local raw_input="${(j: :)@}"  # zsh: join all args with spaces

  local wt_name
  if __dk_is_ticket "$raw_input"; then
    local num="${raw_input//[^0-9]/}"  # strip everything except digits
    wt_name="ticket-${num}"
  else
    # For freeform names, try multiple matches so the user can pass:
    #   "task-fix-login"  → exact dir name from dkls output
    #   "fix login"       → slugified to "fix-login", then prefixed with "task-"
    #   "fix-login"       → same after slugify
    local slug
    slug=$(dk_slugify "$raw_input")
    if [[ -z "$slug" ]]; then
      echo "ERROR: Could not create a valid name from '$raw_input'"
      return 1
    fi
    if [[ -d "${worktrees_dir}/${slug}" ]]; then
      wt_name="$slug"
    elif [[ -d "${worktrees_dir}/task-${slug}" ]]; then
      wt_name="task-${slug}"
    else
      echo "ERROR: No worktree found matching '${raw_input}'."
      echo "Run dkls to see available worktrees."
      return 1
    fi
  fi

  local wt_dir="${worktrees_dir}/${wt_name}"
  local branch_name="worktree-${wt_name}"

  # Detect actual branch name (may have been renamed by ticket instructions)
  local actual_branch=""
  [[ -d "$wt_dir" ]] && actual_branch=$(dk_wt_branch "$wt_dir")

  local has_dir=0 has_branch=0
  [[ -d "$wt_dir" ]] && has_dir=1
  git show-ref --verify --quiet "refs/heads/${branch_name}" 2>/dev/null && has_branch=1

  # Also check for the actual branch if it differs from the expected name
  local has_actual_branch=0
  if [[ -n "$actual_branch" && "$actual_branch" != "$branch_name" ]]; then
    git show-ref --verify --quiet "refs/heads/${actual_branch}" 2>/dev/null && has_actual_branch=1
  fi

  if [[ $has_dir -eq 0 ]] && [[ $has_branch -eq 0 ]] && [[ $has_actual_branch -eq 0 ]]; then
    echo "ERROR: No worktree or branch found for '${wt_name}'."
    return 1
  fi

  echo "Removing ${wt_name}..."

  [[ $has_dir -eq 1 ]] && dk_wt_remove "$wt_dir"

  if [[ $has_branch -eq 1 ]]; then
    echo "  Deleting branch ${branch_name}..."
    git branch -D "$branch_name" 2>/dev/null || true
  fi

  if [[ $has_actual_branch -eq 1 ]]; then
    echo "  Deleting renamed branch ${actual_branch}..."
    git branch -D "$actual_branch" 2>/dev/null || true
  fi

  # Clean up state files and last-session pointer
  local session_id
  session_id=$(dk_session_id "$wt_name")
  dk_cleanup_session "$session_id"
  dk_cleanup_last_session "$wt_name"

  git worktree prune 2>/dev/null
  echo "Done."
}

# ─── dkls — list worktrees ────────────────────────────────────────────────

unalias dkls 2>/dev/null; unfunction dkls 2>/dev/null
dkls() {
  local repo_root
  repo_root=$(dk_repo_root) || return 1

  local worktrees_dir="${repo_root}/.doyaken/worktrees"
  if [[ ! -d "$worktrees_dir" ]]; then
    echo "No worktrees."
    return 0
  fi

  local count=0
  for wt_dir in "$worktrees_dir"/*/; do
    [[ -d "$wt_dir" ]] || continue
    count=$((count + 1))
    local wt_name
    wt_name="$(basename "$wt_dir")"
    local wt_status=""

    # Check git state is valid before querying status/branch
    if ! git -C "$wt_dir" rev-parse --git-dir &>/dev/null; then
      wt_status=" [corrupted git state]"
      echo "  ${wt_name}  (?)${wt_status}"
      continue
    fi

    if git -C "$wt_dir" status --porcelain 2>/dev/null | head -1 | grep -q .; then
      wt_status="${wt_status} [changes]"
    fi

    local branch
    branch=$(dk_wt_branch "$wt_dir" "?")

    # Show phase status
    local session_id
    session_id=$(dk_session_id "$wt_name")
    local phase_file
    phase_file=$(dk_state_file "$session_id")
    if [[ -f "$phase_file" ]]; then
      local phase_num
      phase_num=$(cat "$phase_file" 2>/dev/null)
      if [[ "$phase_num" =~ ^[1-5]$ ]]; then
        wt_status="${wt_status} [phase ${phase_num}/5: ${DK_PHASE_NAMES[$phase_num]}]"
      elif [[ "$phase_num" =~ ^[0-9]+$ ]] && [[ "$phase_num" -gt 5 ]]; then
        wt_status="${wt_status} [complete]"
      fi
    fi

    [[ -z "$wt_status" ]] && wt_status=" [idle]"
    echo "  ${wt_name}  (${branch})${wt_status}"
  done

  if [[ $count -eq 0 ]]; then
    echo "No worktrees."
  fi
}

# ─── dkclean — prune stale worktrees + gone branches ─────────────────────────

unalias dkclean 2>/dev/null; unfunction dkclean 2>/dev/null
dkclean() {
  local repo_root
  repo_root=$(dk_repo_root) || return 1

  # cd to repo root so bare git commands (fetch, branch -D, branch --list) operate
  # on the correct repository. Note: this intentionally does not restore the original
  # cwd — if the user was inside a removed worktree, returning there would fail.
  cd "$repo_root" || return 1
  local cleaned=0

  # 1. Prune stale worktrees (no uncommitted changes)
  local worktrees_dir="${repo_root}/.doyaken/worktrees"
  if [[ -d "$worktrees_dir" ]]; then
    for wt_dir in "$worktrees_dir"/*/; do
      [[ -d "$wt_dir" ]] || continue
      local wt_name
      wt_name="$(basename "$wt_dir")"

      # Skip worktrees with active phase state (still in a lifecycle)
      local session_id phase_file
      session_id=$(dk_session_id "$wt_name")
      phase_file=$(dk_state_file "$session_id")
      if [[ -f "$phase_file" ]]; then
        local phase_val
        phase_val=$(cat "$phase_file" 2>/dev/null)
        if [[ "$phase_val" =~ ^[1-5]$ ]]; then
          echo "  Skipping ${wt_name} (active phase ${phase_val}/5: ${DK_PHASE_NAMES[$phase_val]})"
          continue
        fi
      fi

      # Skip worktrees with uncommitted changes
      if git -C "$wt_dir" status --porcelain 2>/dev/null | head -1 | grep -q .; then
        echo "  Skipping ${wt_name} (has uncommitted changes)"
        continue
      fi

      # Skip worktrees with unpushed commits
      local wt_branch
      wt_branch=$(dk_wt_branch "$wt_dir")
      if [[ -n "$wt_branch" ]]; then
        if ! git -C "$wt_dir" rev-parse "origin/${wt_branch}" &>/dev/null; then
          echo "  Skipping ${wt_name} (branch not pushed to remote)"
          continue
        fi
        if git -C "$wt_dir" log --oneline "origin/${wt_branch}..HEAD" 2>/dev/null | head -1 | grep -q .; then
          echo "  Skipping ${wt_name} (has unpushed commits)"
          continue
        fi
      fi

      echo "  Removing stale worktree: ${wt_name}"
      dk_wt_remove "$wt_dir"

      # Delete the branch (wt_branch captured above; handles renamed branches too)
      [[ -n "$wt_branch" ]] && git branch -D "$wt_branch" 2>/dev/null || true

      # Clean up state files and last-session pointer
      dk_cleanup_session "$session_id"
      dk_cleanup_last_session "$wt_name"

      cleaned=$((cleaned + 1))
    done
  fi

  # 2. Prune branches whose remote tracking branch is gone
  git fetch --prune 2>/dev/null || true

  local branch
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    # Don't delete branches with active worktrees
    local has_worktree=0
    if [[ -d "$worktrees_dir" ]]; then
      for wt_dir in "$worktrees_dir"/*/; do
        [[ -d "$wt_dir" ]] || continue
        local wt_branch
        wt_branch=$(dk_wt_branch "$wt_dir")
        if [[ "$wt_branch" == "$branch" ]]; then
          has_worktree=1
          break
        fi
      done
    fi

    if [[ $has_worktree -eq 1 ]]; then
      echo "  Skipping branch ${branch} (has active worktree)"
      continue
    fi

    echo "  Deleting gone branch: ${branch}"
    git branch -D "$branch" 2>/dev/null || true
    cleaned=$((cleaned + 1))
  done < <(git branch -vv 2>/dev/null | grep ': gone]' | sed 's/^[* ]*//' | awk '{print $1}')

  # 3. Prune worktree branches that have no worktree directory
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    local ticket_name="${branch#worktree-}"
    if [[ ! -d "$worktrees_dir/$ticket_name" ]]; then
      echo "  Deleting orphan branch: ${branch}"
      git branch -D "$branch" 2>/dev/null || true
      cleaned=$((cleaned + 1))
    fi
  done < <(git branch --list 'worktree-ticket-*' 'worktree-task-*' 2>/dev/null | sed 's/^[* ]*//')

  git worktree prune 2>/dev/null

  # 4. Clean up old loop state files (older than 7 days).
  # 7 days gives enough time to resume interrupted sessions while preventing
  # indefinite accumulation. Most tickets complete within a day or two.
  local old_files
  old_files=$(dk_cleanup_stale_files "$DK_LOOP_DIR" "state complete active prompt" 7)
  if [[ "$old_files" -gt 0 ]]; then
    echo "  Cleaned ${old_files} old loop state file(s)"
    cleaned=$((cleaned + old_files))
  fi

  # 5. Clean up old phase state files (older than 7 days)
  local old_phase_files
  old_phase_files=$(dk_cleanup_stale_files "$DK_STATE_DIR" "phase times system-context" 7)
  if [[ "$old_phase_files" -gt 0 ]]; then
    echo "  Cleaned ${old_phase_files} old phase state file(s)"
    cleaned=$((cleaned + old_phase_files))
  fi

  if [[ $cleaned -eq 0 ]]; then
    echo "Nothing to clean."
  else
    echo "Cleaned ${cleaned} item(s)."
  fi
}
