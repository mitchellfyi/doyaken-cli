#!/usr/bin/env bash
# shellcheck disable=SC2088,SC1091
# doyaken uninstall — remove global installation
# SC2088 suppressed: tilde in display strings is intentionally literal (e.g., "~/.claude/skills").
set -euo pipefail

source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
INSTALL_STATE_FILE="$CLAUDE_DIR/.doyaken-install-state.json"
ZSHRC="$HOME/.zshrc"
LEGACY_MANAGED_WORKTREE_DIRS_JSON=""

__dk_settings_have_doyaken_hooks() {
  [[ -f "$SETTINGS_FILE" ]] || return 1
  if command -v jq &>/dev/null; then
    jq -e --arg dir "$DOYAKEN_DIR" --arg home "$HOME" '
      def is_doyaken_cmd:
        type == "string" and (
          contains($dir + "/hooks/")
          or contains($home + "/work/doyaken/hooks/")
          or contains("$HOME/work/doyaken/hooks/")
          or contains("$DOYAKEN_DIR/hooks/")
          or (contains("export DOYAKEN_DIR=") and contains("/hooks/"))
          or test("(^|[[:space:]\\\"])[^[:space:]\\\"]*/doyaken(-cli)?/hooks/(load-ticket-context\\.sh|user-prompt-submit\\.sh|guard-handler\\.py|post-commit-guard\\.sh|phase-loop\\.sh|stop-sound\\.sh|pre-compact\\.sh|session-end\\.sh)([[:space:]\\\"]|$)")
        );
      [(.hooks // {}) | to_entries[] | .value[]? | .hooks[]? | .command | select(is_doyaken_cmd)] | length > 0
    ' "$SETTINGS_FILE" >/dev/null 2>&1
    return $?
  fi
  grep -Fq "$DOYAKEN_DIR/hooks/" "$SETTINGS_FILE" 2>/dev/null && return 0
  grep -Fq "$HOME/work/doyaken/hooks/" "$SETTINGS_FILE" 2>/dev/null && return 0
  grep -Fq "\$HOME/work/doyaken/hooks/" "$SETTINGS_FILE" 2>/dev/null && return 0
  grep -Fq "\$DOYAKEN_DIR/hooks/" "$SETTINGS_FILE" 2>/dev/null && return 0
  grep -Eq 'export DOYAKEN_DIR=.*hooks/|/doyaken(-cli)?/hooks/(load-ticket-context\.sh|user-prompt-submit\.sh|guard-handler\.py|post-commit-guard\.sh|phase-loop\.sh|stop-sound\.sh|pre-compact\.sh|session-end\.sh)' "$SETTINGS_FILE" 2>/dev/null
}

__dk_settings_have_doyaken_worktree_settings() {
  [[ -f "$SETTINGS_FILE" ]] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  if [[ -f "$INSTALL_STATE_FILE" ]]; then
    jq -e '
      (.worktree.managedSymlinkDirectories // []) | type == "array" and length > 0
    ' "$INSTALL_STATE_FILE" >/dev/null 2>&1
    return $?
  fi
  [[ -n "$LEGACY_MANAGED_WORKTREE_DIRS_JSON" ]]
}

__dk_managed_worktree_dirs_json() {
  command -v jq >/dev/null 2>&1 || return 1
  if [[ -f "$INSTALL_STATE_FILE" ]]; then
    jq -c '(.worktree.managedSymlinkDirectories // []) | if type == "array" then . else [] end' "$INSTALL_STATE_FILE"
  else
    printf '%s\n' "$LEGACY_MANAGED_WORKTREE_DIRS_JSON"
  fi
}

__dk_legacy_managed_worktree_dirs_json() {
  [[ -f "$SETTINGS_FILE" ]] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  jq -e --arg dir "$DOYAKEN_DIR" --arg home "$HOME" --slurpfile template "$DOYAKEN_DIR/settings.json" '
    def is_doyaken_cmd:
      type == "string" and (
        contains($dir + "/hooks/")
        or contains($home + "/work/doyaken/hooks/")
        or contains("$HOME/work/doyaken/hooks/")
        or contains("$DOYAKEN_DIR/hooks/")
        or (contains("export DOYAKEN_DIR=") and contains("/hooks/"))
        or test("(^|[[:space:]\\\"])[^[:space:]\\\"]*/doyaken(-cli)?/hooks/(load-ticket-context\\.sh|user-prompt-submit\\.sh|guard-handler\\.py|post-commit-guard\\.sh|phase-loop\\.sh|stop-sound\\.sh|pre-compact\\.sh|session-end\\.sh)([[:space:]\\\"]|$)")
      );
    def has_doyaken_hooks:
      [(.hooks // {}) | to_entries[]? | .value[]? | .hooks[]? | .command | select(is_doyaken_cmd)] | length > 0;
    def arrays_equal($left; $right):
      (($left | sort) == ($right | sort));
    def contains_all($haystack; $needles):
      all($needles[]; . as $dir | ($haystack | index($dir)));
    def current_dirs: ((.worktree.symlinkDirectories // []) | if type == "array" then . else [] end);
    def template_dirs: (($template[0].worktree.symlinkDirectories // []) | if type == "array" then . else [] end);
    if has_doyaken_hooks and (arrays_equal(current_dirs; template_dirs) or contains_all(current_dirs; template_dirs)) then
      template_dirs
    else
      empty
    end
  ' "$SETTINGS_FILE" 2>/dev/null
}

echo "Doyaken — Global Uninstall"
echo ""

if LEGACY_MANAGED_WORKTREE_DIRS_JSON=$(__dk_legacy_managed_worktree_dirs_json); then
  :
else
  LEGACY_MANAGED_WORKTREE_DIRS_JSON=""
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

# 3. Remove Codex skill links
if ! dk_uninstall_codex_skills; then
  dk_warn "Continuing uninstall after incomplete Codex skill cleanup"
fi

# 4. Remove Doyaken hooks from settings (preserve non-Doyaken hooks)
if __dk_settings_have_doyaken_hooks; then
  if command -v jq &>/dev/null; then
    if jq --arg dir "$DOYAKEN_DIR" --arg home "$HOME" '
      def is_doyaken_cmd:
        type == "string" and (
          contains($dir + "/hooks/")
          or contains($home + "/work/doyaken/hooks/")
          or contains("$HOME/work/doyaken/hooks/")
          or contains("$DOYAKEN_DIR/hooks/")
          or (contains("export DOYAKEN_DIR=") and contains("/hooks/"))
          or test("(^|[[:space:]\\\"])[^[:space:]\\\"]*/doyaken(-cli)?/hooks/(load-ticket-context\\.sh|user-prompt-submit\\.sh|guard-handler\\.py|post-commit-guard\\.sh|phase-loop\\.sh|stop-sound\\.sh|pre-compact\\.sh|session-end\\.sh)([[:space:]\\\"]|$)")
        );
      .hooks |= (
        (. // {})
        | with_entries(
            .value |= map(
              .hooks = ([.hooks[]? | select((.command | is_doyaken_cmd) | not)])
              | select((.hooks // []) | length > 0)
            )
          )
        | with_entries(select((.value // []) | length > 0))
      )
      | if ((.hooks // {}) | length) == 0 then del(.hooks) else . end
    ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"; then
      mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      dk_done "Removed hooks from ~/.claude/settings.json"
    else
      rm -f "${SETTINGS_FILE}.tmp"
      dk_error "Failed to remove Doyaken hooks from ~/.claude/settings.json"
    fi
  else
    dk_info "Manually remove hooks containing '$DOYAKEN_DIR/hooks/' or '\$DOYAKEN_DIR/hooks/' from ~/.claude/settings.json"
  fi
else
  dk_skip "No Doyaken hooks in settings"
fi

# 5. Remove Doyaken-managed worktree settings while preserving user entries
if __dk_settings_have_doyaken_worktree_settings; then
  managed_dirs_json=$(__dk_managed_worktree_dirs_json)
  if jq --argjson managed_dirs "$managed_dirs_json" '
    .worktree.symlinkDirectories = [(.worktree.symlinkDirectories // [])[] | . as $dir | select(($managed_dirs | index($dir)) | not)]
    | if ((.worktree.symlinkDirectories // []) | length) == 0 then del(.worktree.symlinkDirectories) else . end
    | if ((.worktree // {}) | length) == 0 then del(.worktree) else . end
  ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"; then
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    rm -f "$INSTALL_STATE_FILE"
    dk_done "Removed worktree settings from ~/.claude/settings.json"
  else
    rm -f "${SETTINGS_FILE}.tmp"
    dk_error "Failed to remove Doyaken worktree settings from ~/.claude/settings.json"
  fi
else
  dk_skip "No Doyaken-managed worktree settings in settings"
fi
rm -f "$INSTALL_STATE_FILE" 2>/dev/null || true

# 6. Remove source line and Doyaken comment from zshrc
if grep -qE 'doyaken/dk\.sh|DOYAKEN_DIR.*/dk\.sh' "$ZSHRC" 2>/dev/null; then
  # -x matches entire line; removes "# Doyaken" or "# Doyaken — ..." exact lines.
  # Also removes the DOYAKEN_DIR export and source lines.
  # || true: grep -v exits 1 when no lines survive filtering (valid when .zshrc
  # contained only Doyaken lines); without this, set -e + pipefail aborts the script.
  grep -vxE '# Doyaken( —.*)?' "$ZSHRC" | grep -vE '^export DOYAKEN_DIR=' | grep -vE 'doyaken.*dk\.sh|DOYAKEN_DIR.*/dk\.sh' > "${ZSHRC}.tmp" || true
  mv "${ZSHRC}.tmp" "$ZSHRC"
  dk_done "Removed Doyaken lines from ~/.zshrc"
else
  dk_skip "No Doyaken source line in ~/.zshrc"
fi

echo ""
echo "Uninstall complete. Run: source ~/.zshrc"
echo ""
echo "Note: $DOYAKEN_DIR was NOT deleted. Remove it manually if you want."
