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
# need it before creating symlinks in steps 1-2)
mkdir -p "$CLAUDE_DIR"

# 1. Symlink skills
if [[ -L "$CLAUDE_DIR/skills" ]]; then
  current=$(readlink "$CLAUDE_DIR/skills")
	  if [[ "$current" == "$DEX_DIR/skills" ]]; then
	    dx_ok "~/.claude/skills → $DEX_DIR/skills"
	  else
	    rm "$CLAUDE_DIR/skills"
	    if ln -s "$DEX_DIR/skills" "$CLAUDE_DIR/skills"; then
	      dx_done "Updated ~/.claude/skills → $DEX_DIR/skills (was: $current)"
	    else
	      dx_error "Failed to symlink ~/.claude/skills"
	    fi
	  fi
elif [[ -d "$CLAUDE_DIR/skills" ]]; then
  if ! dx_install_claude_skill_links "$CLAUDE_DIR/skills"; then
    dx_warn "Continuing install after incomplete Claude skill link repair"
  fi
else
  if ln -s "$DEX_DIR/skills" "$CLAUDE_DIR/skills"; then
    dx_done "Symlinked ~/.claude/skills → $DEX_DIR/skills"
  else
    dx_error "Failed to symlink ~/.claude/skills"
  fi
fi

# 2. Symlink agents
if [[ -L "$CLAUDE_DIR/agents" ]]; then
  current=$(readlink "$CLAUDE_DIR/agents")
	  if [[ "$current" == "$DEX_DIR/agents" ]]; then
	    dx_ok "~/.claude/agents → $DEX_DIR/agents"
	  else
	    rm "$CLAUDE_DIR/agents"
	    if ln -s "$DEX_DIR/agents" "$CLAUDE_DIR/agents"; then
	      dx_done "Updated ~/.claude/agents → $DEX_DIR/agents (was: $current)"
	    else
	      dx_error "Failed to symlink ~/.claude/agents"
	    fi
	  fi
elif [[ -d "$CLAUDE_DIR/agents" ]]; then
  dx_warn "~/.claude/agents exists as a directory — back up and re-run:"
  echo "       mv ~/.claude/agents ~/.claude/agents.bak && dx install"
else
  if ln -s "$DEX_DIR/agents" "$CLAUDE_DIR/agents"; then
    dx_done "Symlinked ~/.claude/agents → $DEX_DIR/agents"
  else
    dx_error "Failed to symlink ~/.claude/agents"
  fi
fi

# 3. Install or repair conservative Claude/Codex tooling.
if ! dx_bootstrap_agent_tooling "" "repair"; then
  dx_warn "Continuing install without complete Claude/Codex tooling bootstrap"
fi

# 4. Source dx.sh in ~/.zshrc
if grep -qE 'dex(-cli)?/dx\.sh|DEX_DIR.*/dx\.sh' "$ZSHRC" 2>/dev/null; then
  # Ensure DEX_DIR export exists (upgrade path: older installs lack it)
  if ! grep -qE '^export DEX_DIR=' "$ZSHRC" 2>/dev/null; then
    # Insert the export line before the existing source line.
    # Uses awk instead of sed -i to avoid BSD/GNU sed portability issues.
    _DXDIR="$DEX_DIR" awk '
      /dex(-cli)?\/dx\.sh|DEX_DIR.*\/dx\.sh/ && !inserted { print "export DEX_DIR=\"" ENVIRON["_DXDIR"] "\""; inserted=1 }
      { print }
    ' "$ZSHRC" > "${ZSHRC}.tmp" && mv "${ZSHRC}.tmp" "$ZSHRC"
    dx_done "Added DEX_DIR export to ~/.zshrc (upgrade)"
  else
    dx_ok "dx.sh already sourced in ~/.zshrc"
  fi
else
  # Check for old Dex or pre-rename source lines.
  if grep -qE 'dex.*dx\.sh|DEX_DIR.*/dx\.sh|doyaken.*dk\.sh|DOYAKEN_DIR.*/dk\.sh' "$ZSHRC" 2>/dev/null; then
    dx_info "Found old Dex/Doyaken shell source line — replacing..."
    # grep -v exits 1 when no lines survive filtering, which is valid when
    # .zshrc only contained old Dex/Doyaken lines.
    grep -vE 'dex.*dx\.sh|DEX_DIR.*/dx\.sh|export DEX_DIR=|doyaken.*dk\.sh|DOYAKEN_DIR.*/dk\.sh|export DOYAKEN_DIR=' "$ZSHRC" > "${ZSHRC}.tmp" || true
    mv "${ZSHRC}.tmp" "$ZSHRC"
  fi
  {
    echo ""
    echo "# Dex"
    echo "export DEX_DIR=\"$DEX_DIR\""
    echo "source \"\$DEX_DIR/dx.sh\""
  } >> "$ZSHRC"
  dx_done "Added DEX_DIR export and source to ~/.zshrc"
fi

# 5. Make scripts executable
chmod +x "$DEX_DIR/hooks/"*.sh "$DEX_DIR/hooks/"*.py "$DEX_DIR/bin/"*.sh 2>/dev/null
dx_done "Made scripts executable"

echo ""
echo "Install complete. Run: source ~/.zshrc"
echo ""
echo "Next: cd to a repo and run 'dx init' to bootstrap it."
