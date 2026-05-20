# shellcheck shell=bash
# Dex shared library — common constants and bootstrap
#
# Source this from any script:
#   source "$DEX_DIR/lib/common.sh"
#
# Provides: DEX_DIR, DX_STATE_DIR, DX_LOOP_DIR, DX_ARTIFACT_DIR, dx_repo_root()
# Also sources: lib/git.sh, lib/session.sh, lib/output.sh, lib/worktree.sh,
# lib/provider.sh, lib/codex.sh, lib/ui-capture.sh, lib/agent-tools.sh,
# and lib/maintenance.sh

if [[ -z "${DEX_DIR:-}" ]]; then
  # Auto-detect from this file's location (lib/common.sh → repo root).
  # BASH_SOURCE works in bash; $0 works in zsh when sourced.
  _dx_self="${BASH_SOURCE[0]:-$0}"
  DEX_DIR="$(cd "$(dirname "$_dx_self")/.." && pwd)"
  export DEX_DIR
  unset _dx_self
fi
# shellcheck disable=SC2034  # exported by sourcing; used by dx.sh and sibling libs
DX_STATE_DIR="${DX_STATE_DIR:-$HOME/.claude/.dex-phases}"
# shellcheck disable=SC2034  # exported by sourcing; used by dx.sh and sibling libs
DX_LOOP_DIR="${DX_LOOP_DIR:-$HOME/.claude/.dex-loops}"
# shellcheck disable=SC2034  # exported by sourcing; used by UI capture helpers
DX_ARTIFACT_DIR="${DX_ARTIFACT_DIR:-$HOME/.claude/.dex-artifacts}"

# dx_repo_root — print the *main* repo toplevel or return 1
# If cwd is inside a dex worktree (.dex/worktrees/<name>/...),
# returns the main repo root, not the worktree root. This prevents dx
# from creating nested worktrees when the user's shell is cd'd into one.
dx_repo_root() {
  local root
  if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
    root=""
  fi
  if [[ -z "$root" ]]; then
    echo "ERROR: Not in a git repository." >&2
    return 1
  fi
  # Escape worktree paths — strip /.dex/worktrees/<name> suffix
  if [[ "$root" == *"/.dex/worktrees/"* ]]; then
    root="${root%%/.dex/worktrees/*}"
  fi
  echo "$root"
}

# Source sibling libraries
# shellcheck disable=SC1091
source "$DEX_DIR/lib/git.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/session.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/output.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/worktree.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/provider.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/codex.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/ui-capture.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/agent-tools.sh"
# shellcheck disable=SC1091
source "$DEX_DIR/lib/maintenance.sh"
