#!/usr/bin/env bash
# shellcheck disable=SC2088,SC1091
# dex install — one-time global setup
# SC2088 suppressed: tilde in display strings is intentionally literal (e.g., "~/.claude/skills").
set -euo pipefail

if [[ -z "${DEX_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  DEX_DIR="$(dirname "$SCRIPT_DIR")"
  export DEX_DIR
fi
source "$DEX_DIR/lib/common.sh"
CLAUDE_DIR="$HOME/.claude"
ZSHRC="$HOME/.zshrc"

echo "Dex — Global Install"
echo ""

# Ensure ~/.claude directory exists (Claude Code normally creates it, but we
# need it before creating symlinks)
mkdir -p "$CLAUDE_DIR"

# 1. Symlink skills
if [[ -L "$CLAUDE_DIR/skills" ]]; then
  current=$(readlink "$CLAUDE_DIR/skills")
  if [[ "$current" == "$DEX_DIR/skills" ]]; then
    dx_ok "~/.claude/skills → $DEX_DIR/skills"
  else
    dx_error "~/.claude/skills points to $current; remove it or choose a clean install target"
    exit 1
  fi
elif [[ -d "$CLAUDE_DIR/skills" ]]; then
  if ! dx_install_claude_skill_links "$CLAUDE_DIR/skills"; then
    dx_warn "Continuing install after incomplete Claude skill link setup"
  fi
else
  if ln -s "$DEX_DIR/skills" "$CLAUDE_DIR/skills"; then
    dx_done "Symlinked ~/.claude/skills → $DEX_DIR/skills"
  else
    dx_error "Failed to symlink ~/.claude/skills"
  fi
fi

# 2. Install conservative Claude/Codex tooling.
if ! dx_bootstrap_agent_tooling "" "install"; then
  dx_warn "Continuing install without complete Claude/Codex tooling bootstrap"
fi

# 3. Source dx.sh in ~/.zshrc
if grep -qE 'dex(-cli)?/dx\.sh|DEX_DIR.*/dx\.sh' "$ZSHRC" 2>/dev/null; then
  dx_ok "dx.sh already sourced in ~/.zshrc"
else
  {
    echo ""
    echo "# Dex"
    echo "export DEX_DIR=\"$DEX_DIR\""
    echo "source \"\$DEX_DIR/dx.sh\""
  } >> "$ZSHRC"
  dx_done "Added DEX_DIR export and source to ~/.zshrc"
fi

# 4. Make scripts executable
chmod +x "$DEX_DIR/hooks/"*.sh "$DEX_DIR/hooks/"*.py "$DEX_DIR/bin/"*.sh 2>/dev/null
dx_done "Made scripts executable"

echo ""
echo "Install complete. Run: source ~/.zshrc"
echo ""
echo "Next: cd to a repo and run 'dx init' to bootstrap it."
