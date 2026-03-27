#!/usr/bin/env bash
# shellcheck disable=SC2088
# doyaken uninstall — remove global installation
# SC2088 suppressed: tilde in display strings is intentionally literal (e.g., "~/.claude/skills").
set -euo pipefail

source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
ZSHRC="$HOME/.zshrc"

echo "Doyaken — Global Uninstall"
echo ""

# 0. If inside an initialized repo, uninit it first
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -n "$repo_root" ]] && [[ -d "$repo_root/.doyaken" ]]; then
  bash "$DOYAKEN_DIR/bin/uninit.sh"
  echo ""
fi

# 1. Remove skills symlink (only if it points to Doyaken)
if [[ -L "$CLAUDE_DIR/skills" ]]; then
  target=$(readlink "$CLAUDE_DIR/skills")
  if [[ "$target" == "$DOYAKEN_DIR/skills" ]]; then
    rm "$CLAUDE_DIR/skills"
    dk_done "Removed ~/.claude/skills symlink"
  else
    dk_skip "~/.claude/skills points to $target (not Doyaken)"
  fi
else
  dk_skip "~/.claude/skills is not a symlink"
fi

# 2. Remove agents symlink (only if it points to Doyaken)
if [[ -L "$CLAUDE_DIR/agents" ]]; then
  target=$(readlink "$CLAUDE_DIR/agents")
  if [[ "$target" == "$DOYAKEN_DIR/agents" ]]; then
    rm "$CLAUDE_DIR/agents"
    dk_done "Removed ~/.claude/agents symlink"
  else
    dk_skip "~/.claude/agents points to $target (not Doyaken)"
  fi
else
  dk_skip "~/.claude/agents is not a symlink"
fi

# 3. Remove Doyaken hooks from settings (preserve non-Doyaken hooks)
if [[ -f "$SETTINGS_FILE" ]] && grep -q 'doyaken/hooks' "$SETTINGS_FILE" 2>/dev/null; then
  if command -v jq &>/dev/null; then
    # Check if ALL hooks are Doyaken hooks (common case)
    all_doyaken=$(jq -r '[.hooks // {} | to_entries[].value[].hooks[].command] | all(test("doyaken"))' "$SETTINGS_FILE" 2>/dev/null)
    if [[ "$all_doyaken" == "true" ]]; then
      jq 'del(.hooks)' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      dk_done "Removed hooks from ~/.claude/settings.json"
    else
      dk_warn "Mixed hooks detected — Doyaken hooks alongside other hooks."
      echo "       Manually remove entries containing 'doyaken/hooks' from ~/.claude/settings.json"
    fi
  else
    dk_info "Manually remove hooks containing 'doyaken/hooks' from ~/.claude/settings.json"
  fi
else
  dk_skip "No Doyaken hooks in settings"
fi

# 4. Remove source line and Doyaken comment from zshrc
if grep -q 'doyaken/dk.sh' "$ZSHRC" 2>/dev/null; then
  # -x matches entire line; removes "# Doyaken" or "# Doyaken — ..." exact lines.
  # Also removes the DOYAKEN_DIR export and source lines.
  # || true: grep -v exits 1 when no lines survive filtering (valid when .zshrc
  # contained only Doyaken lines); without this, set -e + pipefail aborts the script.
  grep -vxE '# Doyaken( —.*)?' "$ZSHRC" | grep -vE '^export DOYAKEN_DIR=' | grep -v 'doyaken/dk\.sh' > "${ZSHRC}.tmp" || true
  mv "${ZSHRC}.tmp" "$ZSHRC"
  dk_done "Removed Doyaken lines from ~/.zshrc"
else
  dk_skip "No Doyaken source line in ~/.zshrc"
fi

echo ""
echo "Uninstall complete. Run: source ~/.zshrc"
echo ""
echo "Note: $DOYAKEN_DIR was NOT deleted. Remove it manually if you want."
