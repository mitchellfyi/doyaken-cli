#!/usr/bin/env bash
# shellcheck disable=SC2088,SC1091
# Install or refresh Dex's Claude Code settings entries.
set -euo pipefail

source "${DEX_DIR:-$HOME/work/dex}/lib/common.sh"

QUIET=0
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
  esac
done

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
INSTALL_STATE_FILE="$CLAUDE_DIR/.dex-install-state.json"
mkdir -p "$CLAUDE_DIR"

say_done() {
  [[ $QUIET -eq 1 ]] || dx_done "$1"
}

say_info() {
  [[ $QUIET -eq 1 ]] || dx_info "$1"
}

say_error() {
  [[ $QUIET -eq 1 ]] || dx_error "$1"
}

managed_worktree_dirs_json="[]"

__dx_managed_dirs_from_template() {
  if command -v jq >/dev/null 2>&1; then
    jq -c '(.worktree.symlinkDirectories // []) | if type == "array" then . else [] end' "$DEX_DIR/settings.json"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$DEX_DIR/settings.json" <<'PY'
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

__dx_managed_dirs_added_by_merge() {
  local existing_settings="$1"
  local template_settings="$2"

  jq -s -c --arg dir "$DEX_DIR" --arg home "$HOME" '
    . as $docs |
    def array_or_empty: if type == "array" then . else [] end;
    def arrays_equal($left; $right):
      (($left | sort) == ($right | sort));
    def contains_all($haystack; $needles):
      all($needles[]; . as $dir | ($haystack | index($dir)));
    def is_dex_cmd:
      type == "string" and (
        contains($dir + "/hooks/")
        or contains($home + "/work/dex/hooks/")
        or contains("$HOME/work/dex/hooks/")
        or contains("$DEX_DIR/hooks/")
        or (contains("export DEX_DIR=") and contains("/hooks/"))
        or test("(^|[[:space:]\\\"])[^[:space:]\\\"]*/dex(-cli)?/hooks/(load-ticket-context\\.sh|user-prompt-submit\\.sh|guard-handler\\.py|post-commit-guard\\.sh|phase-loop\\.sh|stop-sound\\.sh|pre-compact\\.sh|session-end\\.sh)([[:space:]\\\"]|$)")
      );
    def existing_has_dex_hooks:
      [($docs[0].hooks // {}) | to_entries[]? | .value[]? | .hooks[]? | .command | select(is_dex_cmd)] | length > 0;
    def existing_dirs: (($docs[0].worktree.symlinkDirectories // []) | array_or_empty);
    def template_dirs: (($docs[1].worktree.symlinkDirectories // []) | array_or_empty);
    if existing_has_dex_hooks and (
         arrays_equal(existing_dirs; template_dirs)
         or contains_all(existing_dirs; template_dirs)
       ) then
      template_dirs
    else
      [template_dirs[] | . as $dir | select((existing_dirs | index($dir)) | not)]
    end
  ' "$existing_settings" <(printf '%s\n' "$template_settings")
}

__dx_record_managed_worktree_dirs() {
  local dirs_json="$1"
  local tmpfile

  tmpfile="${INSTALL_STATE_FILE}.tmp.$$"
  if ! command -v jq >/dev/null 2>&1; then
    if printf '{"worktree":{"managedSymlinkDirectories":%s}}\n' "$dirs_json" > "$tmpfile" && mv "$tmpfile" "$INSTALL_STATE_FILE"; then
      return 0
    fi
    rm -f "$tmpfile" 2>/dev/null || true
    say_error "Failed to record Dex-managed worktree settings"
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
  say_error "Failed to record Dex-managed worktree settings"
  return 1
}

settings_template=$(<"$DEX_DIR/settings.json")

# Substitute the default install path with the actual DEX_DIR, handling arbitrary
# path characters (quotes, backslashes, etc.) that would corrupt a raw bash
# string replacement embedded in JSON.
if command -v python3 >/dev/null 2>&1; then
  local_settings=$(python3 - "$DEX_DIR/settings.json" "$DEX_DIR" <<'PY'
import json, sys

def _replace(obj, old, new):
    if isinstance(obj, str):
        return obj.replace(old, new)
    if isinstance(obj, list):
        return [_replace(item, old, new) for item in obj]
    if isinstance(obj, dict):
        return {k: _replace(v, old, new) for k, v in obj.items()}
    return obj

with open(sys.argv[1], encoding='utf-8') as fh:
    data = json.load(fh)
print(json.dumps(_replace(data, '$HOME/work/dex', sys.argv[2]), indent=2))
PY
  ) || { say_error "Failed to customise settings template via python3"; exit 1; }
elif command -v jq >/dev/null 2>&1; then
  # jq ≥1.6: walk + gsub; dollar sign must be escaped as \$ in the regex.
  local_settings=$(jq \
    --arg new "$DEX_DIR" \
    'walk(if type == "string" then gsub("\\$HOME/work/dex"; $new) else . end)' \
    "$DEX_DIR/settings.json" 2>/dev/null) \
    || { say_error "Failed to customise settings template via jq"; exit 1; }
else
  # Last-resort fallback — safe for typical paths that contain no JSON-special chars.
  local_settings=${settings_template//\$HOME\/work\/dex/$DEX_DIR}
fi

if [[ -f "$SETTINGS_FILE" ]]; then
  if command -v jq >/dev/null 2>&1; then
    if ! managed_worktree_dirs_json=$(__dx_managed_dirs_added_by_merge "$SETTINGS_FILE" "$local_settings"); then
      say_error "Failed to inspect existing worktree settings"
      exit 1
    fi

    if merged=$(jq -s --arg dir "$DEX_DIR" --arg home "$HOME" '
      def append_unique($base; $add):
        reduce (($add // [])[]) as $item (($base // []); if index($item) then . else . + [$item] end);
      def merge_worktree($existing; $template):
        (($existing.worktree // {}) * ($template.worktree // {}))
        | if (($existing.worktree.symlinkDirectories // null) != null or ($template.worktree.symlinkDirectories // null) != null) then
            .symlinkDirectories = append_unique($existing.worktree.symlinkDirectories; $template.worktree.symlinkDirectories)
          else
            .
          end;
      def is_dex_cmd:
        type == "string" and (
          contains($dir + "/hooks/")
          or contains($home + "/work/dex/hooks/")
          or contains("$HOME/work/dex/hooks/")
          or contains("$DEX_DIR/hooks/")
          or (contains("export DEX_DIR=") and contains("/hooks/"))
          or test("(^|[[:space:]\\\"])[^[:space:]\\\"]*/dex(-cli)?/hooks/(load-ticket-context\\.sh|user-prompt-submit\\.sh|guard-handler\\.py|post-commit-guard\\.sh|phase-loop\\.sh|stop-sound\\.sh|pre-compact\\.sh|session-end\\.sh)([[:space:]\\\"]|$)")
        );
      .[0] + {hooks: (reduce (.[1].hooks | to_entries[]) as $e (
        (.[0].hooks // {});
        .[$e.key] = (
          [
            (.[$e.key] // [])[]
            | .hooks = ([.hooks[]? | select((.command | is_dex_cmd) | not)])
            | select((.hooks // []) | length > 0)
          ]
          + $e.value
        )
      ))} + {worktree: merge_worktree(.[0]; .[1])}
    ' "$SETTINGS_FILE" <(printf '%s\n' "$local_settings")) && [[ -n "$merged" ]]; then
      tmpfile="${SETTINGS_FILE}.tmp.$$"
      if printf '%s\n' "$merged" > "$tmpfile" && mv "$tmpfile" "$SETTINGS_FILE"; then
        __dx_record_managed_worktree_dirs "$managed_worktree_dirs_json" || exit 1
        say_done "Merged hooks and worktree settings into ~/.claude/settings.json"
      else
        rm -f "$tmpfile" 2>/dev/null || true
        say_error "Failed to merge settings — settings.json left unchanged"
        exit 1
      fi
    else
      say_error "Failed to merge settings — settings.json left unchanged"
      [[ $QUIET -eq 1 ]] || printf '        Add settings manually from %s/settings.json\n' "$DEX_DIR"
      exit 1
    fi
  else
    say_error "jq is required to merge Dex hooks into existing ~/.claude/settings.json"
    say_info "Add these settings to ~/.claude/settings.json manually:"
    if [[ $QUIET -ne 1 ]]; then
      printf '\n%s\n\n' "$local_settings"
    fi
    exit 1
  fi
else
  tmpfile="${SETTINGS_FILE}.tmp.$$"
  if printf '%s\n' "$local_settings" > "$tmpfile" && mv "$tmpfile" "$SETTINGS_FILE"; then
    managed_worktree_dirs_json=$(__dx_managed_dirs_from_template)
    __dx_record_managed_worktree_dirs "$managed_worktree_dirs_json" || exit 1
    say_done "Created ~/.claude/settings.json with hooks and worktree settings"
  else
    rm -f "$tmpfile" 2>/dev/null || true
    say_error "Failed to copy settings.json"
    exit 1
  fi
fi
