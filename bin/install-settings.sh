#!/usr/bin/env bash
# shellcheck disable=SC2088,SC1091
# Install or refresh Doyaken's Claude Code settings entries.
set -euo pipefail

source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"

QUIET=0
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
  esac
done

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
INSTALL_STATE_FILE="$CLAUDE_DIR/.doyaken-install-state.json"
mkdir -p "$CLAUDE_DIR"

say_done() {
  [[ $QUIET -eq 1 ]] || dk_done "$1"
}

say_info() {
  [[ $QUIET -eq 1 ]] || dk_info "$1"
}

say_error() {
  [[ $QUIET -eq 1 ]] || dk_error "$1"
}

managed_worktree_dirs_json="[]"

__dk_managed_dirs_from_template() {
  if command -v jq >/dev/null 2>&1; then
    jq -c '(.worktree.symlinkDirectories // []) | if type == "array" then . else [] end' "$DOYAKEN_DIR/settings.json"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$DOYAKEN_DIR/settings.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    settings = json.load(f)
dirs = settings.get("worktree", {}).get("symlinkDirectories", [])
print(json.dumps(dirs if isinstance(dirs, list) else [], separators=(",", ":")))
PY
  else
    printf '%s\n' '["node_modules",".venv","vendor","target",".next",".nuxt"]'
  fi
}

__dk_managed_dirs_added_by_merge() {
  local existing_settings="$1"
  local template_settings="$2"

  jq -s -c --arg dir "$DOYAKEN_DIR" --arg home "$HOME" '
    . as $docs |
    def array_or_empty: if type == "array" then . else [] end;
    def arrays_equal($left; $right):
      (($left | sort) == ($right | sort));
    def contains_all($haystack; $needles):
      all($needles[]; . as $dir | ($haystack | index($dir)));
    def is_doyaken_cmd:
      type == "string" and (
        contains($dir + "/hooks/")
        or contains($home + "/work/doyaken/hooks/")
        or contains("$HOME/work/doyaken/hooks/")
        or contains("$DOYAKEN_DIR/hooks/")
        or (contains("export DOYAKEN_DIR=") and contains("/hooks/"))
        or test("(^|[[:space:]\\\"])[^[:space:]\\\"]*/doyaken(-cli)?/hooks/(load-ticket-context\\.sh|user-prompt-submit\\.sh|guard-handler\\.py|post-commit-guard\\.sh|phase-loop\\.sh|stop-sound\\.sh|pre-compact\\.sh|session-end\\.sh)([[:space:]\\\"]|$)")
      );
    def existing_has_doyaken_hooks:
      [($docs[0].hooks // {}) | to_entries[]? | .value[]? | .hooks[]? | .command | select(is_doyaken_cmd)] | length > 0;
    def existing_dirs: (($docs[0].worktree.symlinkDirectories // []) | array_or_empty);
    def template_dirs: (($docs[1].worktree.symlinkDirectories // []) | array_or_empty);
    if existing_has_doyaken_hooks and (
         arrays_equal(existing_dirs; template_dirs)
         or contains_all(existing_dirs; template_dirs)
       ) then
      template_dirs
    else
      [template_dirs[] | . as $dir | select((existing_dirs | index($dir)) | not)]
    end
  ' "$existing_settings" <(printf '%s\n' "$template_settings")
}

__dk_record_managed_worktree_dirs() {
  local dirs_json="$1"
  local tmpfile

  tmpfile="${INSTALL_STATE_FILE}.tmp.$$"
  if ! command -v jq >/dev/null 2>&1; then
    if printf '{"worktree":{"managedSymlinkDirectories":%s}}\n' "$dirs_json" > "$tmpfile" && mv "$tmpfile" "$INSTALL_STATE_FILE"; then
      return 0
    fi
    rm -f "$tmpfile" 2>/dev/null || true
    say_error "Failed to record Doyaken-managed worktree settings"
    return 1
  fi

  jq -e 'type == "array"' <<<"$dirs_json" >/dev/null 2>&1 || return 0

  if [[ -f "$INSTALL_STATE_FILE" ]]; then
    jq --argjson dirs "$dirs_json" '
      def append_unique($base; $add):
        reduce (($add // [])[]) as $item (($base // []); if index($item) then . else . + [$item] end);
      .worktree.managedSymlinkDirectories = append_unique(.worktree.managedSymlinkDirectories; $dirs)
    ' "$INSTALL_STATE_FILE" > "$tmpfile"
  else
    printf '{}\n' | jq --argjson dirs "$dirs_json" '
      def append_unique($base; $add):
        reduce (($add // [])[]) as $item (($base // []); if index($item) then . else . + [$item] end);
      .worktree.managedSymlinkDirectories = append_unique(.worktree.managedSymlinkDirectories; $dirs)
    ' > "$tmpfile"
  fi

  if [[ -s "$tmpfile" ]] && mv "$tmpfile" "$INSTALL_STATE_FILE"; then
    return 0
  fi

  rm -f "$tmpfile" 2>/dev/null || true
  say_error "Failed to record Doyaken-managed worktree settings"
  return 1
}

settings_template=$(<"$DOYAKEN_DIR/settings.json")
local_settings=${settings_template//\$HOME\/work\/doyaken/$DOYAKEN_DIR}

if [[ -f "$SETTINGS_FILE" ]]; then
  if command -v jq >/dev/null 2>&1; then
    if ! managed_worktree_dirs_json=$(__dk_managed_dirs_added_by_merge "$SETTINGS_FILE" "$local_settings"); then
      say_error "Failed to inspect existing worktree settings"
      exit 1
    fi

    if merged=$(jq -s --arg dir "$DOYAKEN_DIR" --arg home "$HOME" '
      def append_unique($base; $add):
        reduce (($add // [])[]) as $item (($base // []); if index($item) then . else . + [$item] end);
      def merge_worktree($existing; $template):
        (($existing.worktree // {}) * ($template.worktree // {}))
        | if (($existing.worktree.symlinkDirectories // null) != null or ($template.worktree.symlinkDirectories // null) != null) then
            .symlinkDirectories = append_unique($existing.worktree.symlinkDirectories; $template.worktree.symlinkDirectories)
          else
            .
          end;
      def is_doyaken_cmd:
        type == "string" and (
          contains($dir + "/hooks/")
          or contains($home + "/work/doyaken/hooks/")
          or contains("$HOME/work/doyaken/hooks/")
          or contains("$DOYAKEN_DIR/hooks/")
          or (contains("export DOYAKEN_DIR=") and contains("/hooks/"))
          or test("(^|[[:space:]\\\"])[^[:space:]\\\"]*/doyaken(-cli)?/hooks/(load-ticket-context\\.sh|user-prompt-submit\\.sh|guard-handler\\.py|post-commit-guard\\.sh|phase-loop\\.sh|stop-sound\\.sh|pre-compact\\.sh|session-end\\.sh)([[:space:]\\\"]|$)")
        );
      .[0] + {hooks: (reduce (.[1].hooks | to_entries[]) as $e (
        (.[0].hooks // {});
        .[$e.key] = (
          [
            (.[$e.key] // [])[]
            | .hooks = ([.hooks[]? | select((.command | is_doyaken_cmd) | not)])
            | select((.hooks // []) | length > 0)
          ]
          + $e.value
        )
      ))} + {worktree: merge_worktree(.[0]; .[1])}
    ' "$SETTINGS_FILE" <(printf '%s\n' "$local_settings")) && [[ -n "$merged" ]]; then
      tmpfile="${SETTINGS_FILE}.tmp.$$"
      if printf '%s\n' "$merged" > "$tmpfile" && mv "$tmpfile" "$SETTINGS_FILE"; then
        __dk_record_managed_worktree_dirs "$managed_worktree_dirs_json" || exit 1
        say_done "Merged hooks and worktree settings into ~/.claude/settings.json"
      else
        rm -f "$tmpfile" 2>/dev/null || true
        say_error "Failed to merge settings — settings.json left unchanged"
        exit 1
      fi
    else
      say_error "Failed to merge settings — settings.json left unchanged"
      [[ $QUIET -eq 1 ]] || printf '        Add settings manually from %s/settings.json\n' "$DOYAKEN_DIR"
      exit 1
    fi
  else
    say_error "jq is required to merge Doyaken hooks into existing ~/.claude/settings.json"
    say_info "Add these settings to ~/.claude/settings.json manually:"
    if [[ $QUIET -ne 1 ]]; then
      printf '\n%s\n\n' "$local_settings"
    fi
    exit 1
  fi
else
  tmpfile="${SETTINGS_FILE}.tmp.$$"
  if printf '%s\n' "$local_settings" > "$tmpfile" && mv "$tmpfile" "$SETTINGS_FILE"; then
    managed_worktree_dirs_json=$(__dk_managed_dirs_from_template)
    __dk_record_managed_worktree_dirs "$managed_worktree_dirs_json" || exit 1
    say_done "Created ~/.claude/settings.json with hooks and worktree settings"
  else
    rm -f "$tmpfile" 2>/dev/null || true
    say_error "Failed to copy settings.json"
    exit 1
  fi
fi
