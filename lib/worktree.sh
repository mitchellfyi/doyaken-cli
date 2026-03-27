# shellcheck shell=bash
# Doyaken shared library — worktree helpers
#
# Bash/zsh-compatible utilities for worktree management and state cleanup.
# Used by dk.sh (dkrm, dkls, dkclean, __dk_show_header) and bin/uninit.sh.
# Depends on: DK_STATE_DIR (from lib/common.sh)

# dk_wt_branch <wt_dir> [fallback]
# Get the current branch of a worktree. Returns empty or fallback for
# detached HEAD or query failure.
dk_wt_branch() {
  local wt_dir="$1"
  local fallback="${2:-}"
  local branch
  branch=$(git -C "$wt_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
    echo "$fallback"
  else
    echo "$branch"
  fi
}

# dk_wt_remove <wt_dir>
# Force-remove a worktree. Tries git worktree remove first, falls back to rm -rf.
dk_wt_remove() {
  git worktree remove "$1" --force 2>/dev/null || rm -rf "$1"
}

# dk_cleanup_last_session <wt_name>
# Remove the last-session pointer if it references the given worktree name.
dk_cleanup_last_session() {
  local wt_name="$1"
  local last_session_file="$DK_STATE_DIR/last-session"
  [[ -f "$last_session_file" ]] || return 0
  local last_info
  last_info=$(cat "$last_session_file" 2>/dev/null) || return 0
  if [[ "${last_info%%:*}" == "$wt_name" ]]; then
    rm -f "$last_session_file"
  fi
}

# dk_claude_project_dir <absolute_path>
# Returns the ~/.claude/projects/ directory name for a given path.
# Claude Code encodes project paths by replacing / and . with -.
dk_claude_project_dir() {
  echo "$HOME/.claude/projects/$(echo "$1" | tr '/.' '--')"
}

# dk_link_claude_to_worktree <repo_root> <wt_dir>
# Create symlinks so the worktree shares .claude/ config and MCP auth
# with the main repo. Idempotent and non-fatal.
dk_link_claude_to_worktree() {
  local repo_root="$1" wt_dir="$2"

  # 1. Symlink .claude/ (settings.local.json, agent-memory)
  if [[ -d "$repo_root/.claude" ]] && [[ ! -e "$wt_dir/.claude" ]]; then
    if ln -s "$repo_root/.claude" "$wt_dir/.claude" 2>/dev/null; then
      dk_info "Linked .claude/ from main repo"
    else
      dk_warn "Failed to symlink .claude/ into worktree"
    fi
  fi

  # 2. Symlink ~/.claude/projects/ so worktree shares MCP OAuth tokens
  local repo_proj wt_proj
  repo_proj=$(dk_claude_project_dir "$repo_root")
  wt_proj=$(dk_claude_project_dir "$wt_dir")
  if [[ -d "$repo_proj" ]] && [[ ! -e "$wt_proj" ]]; then
    if ln -s "$repo_proj" "$wt_proj" 2>/dev/null; then
      dk_info "Linked Claude project data for MCP auth"
    else
      dk_warn "Failed to symlink Claude project data"
    fi
  fi
}

# dk_unlink_claude_from_worktree <wt_dir>
# Remove the ~/.claude/projects/ symlink for a worktree.
# Only removes symlinks, never real directories.
# The .claude/ symlink inside the worktree is removed by dk_wt_remove.
dk_unlink_claude_from_worktree() {
  local wt_dir="$1"
  local wt_proj
  wt_proj=$(dk_claude_project_dir "$wt_dir")
  if [[ -L "$wt_proj" ]]; then
    rm -f "$wt_proj"
  fi
}

# dk_cleanup_stale_files <dir> <extensions> <max_age_days>
# Find and delete files matching "*.ext" older than max_age_days.
# extensions is space-separated (e.g., "state complete active").
# Prints the count of deleted files to stdout.
dk_cleanup_stale_files() {
  local dir="$1"
  local extensions="$2"
  local max_age="$3"
  [[ -d "$dir" ]] || { echo "0"; return 0; }
  [[ -n "$extensions" ]] || { echo "0"; return 0; }

  local find_args=()
  local first=1
  local ext
  for ext in $extensions; do
    if [[ $first -eq 1 ]]; then
      find_args+=(-name "*.${ext}")
      first=0
    else
      find_args+=(-o -name "*.${ext}")
    fi
  done

  # Single find pass: count deleted files via -print + -delete
  local count
  count=$(find "$dir" \( "${find_args[@]}" \) -mtime +"$max_age" -delete -print 2>/dev/null | wc -l | tr -d ' ')
  echo "${count:-0}"
}
