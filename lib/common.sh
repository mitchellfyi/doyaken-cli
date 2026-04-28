# shellcheck shell=bash
# Doyaken shared library — common constants and bootstrap
#
# Source this from any script:
#   source "$DOYAKEN_DIR/lib/common.sh"
#
# Provides: DOYAKEN_DIR, DK_STATE_DIR, DK_LOOP_DIR, dk_repo_root()
# Also sources: lib/git.sh, lib/session.sh, lib/output.sh, lib/worktree.sh

if [[ -z "${DOYAKEN_DIR:-}" ]]; then
  # Auto-detect from this file's location (lib/common.sh → repo root).
  # BASH_SOURCE works in bash; $0 works in zsh when sourced.
  _dk_self="${BASH_SOURCE[0]:-$0}"
  DOYAKEN_DIR="$(cd "$(dirname "$_dk_self")/.." && pwd)"
  export DOYAKEN_DIR
  unset _dk_self
fi
DK_STATE_DIR="$HOME/.claude/.doyaken-phases"
DK_LOOP_DIR="$HOME/.claude/.doyaken-loops"

# dk_repo_root — print the *main* repo toplevel or return 1
# If cwd is inside a doyaken worktree (.doyaken/worktrees/<name>/...),
# returns the main repo root, not the worktree root. This prevents dk
# from creating nested worktrees when the user's shell is cd'd into one.
dk_repo_root() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$root" ]]; then
    echo "ERROR: Not in a git repository." >&2
    return 1
  fi
  # Escape worktree paths — strip /.doyaken/worktrees/<name> suffix
  if [[ "$root" == *"/.doyaken/worktrees/"* ]]; then
    root="${root%%/.doyaken/worktrees/*}"
  fi
  echo "$root"
}

# Source sibling libraries
source "$DOYAKEN_DIR/lib/git.sh"
source "$DOYAKEN_DIR/lib/session.sh"
source "$DOYAKEN_DIR/lib/output.sh"
source "$DOYAKEN_DIR/lib/worktree.sh"
