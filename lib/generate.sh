#!/usr/bin/env bash
#
# generate.sh - Cross-tool config generation with managed content markers
#
# Generates config files (eslint, prettier, tsconfig, etc.) with managed
# sections that can be updated without clobbering user customizations.
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_GENERATE_LOADED:-}" ]] && return 0
_DOYAKEN_GENERATE_LOADED=1

# Generate or update a config file from a template
# Managed section is delimited by markers; user content outside markers is preserved.
#
# Usage: generate_config "template_file" "target_file" ["hash"|"html"|"slash"]
generate_config() {
  local template="$1"
  local target="$2"
  local comment_style="${3:-hash}"

  local begin_marker end_marker
  case "$comment_style" in
    html)
      begin_marker="<!-- DOYAKEN:BEGIN -->"
      end_marker="<!-- DOYAKEN:END -->"
      ;;
    slash)
      begin_marker="// DOYAKEN:BEGIN"
      end_marker="// DOYAKEN:END"
      ;;
    *)
      begin_marker="# DOYAKEN:BEGIN"
      end_marker="# DOYAKEN:END"
      ;;
  esac

  if [ ! -f "$template" ]; then
    echo "Template not found: $template" >&2
    return 1
  fi

  local template_content
  template_content=$(cat "$template")
  local managed_block="${begin_marker}
${template_content}
${end_marker}"

  if [ -f "$target" ]; then
    # Target exists — check for existing markers
    if grep -qF "$begin_marker" "$target" 2>/dev/null; then
      # Replace managed section only (keep user content before/after)
      local tmp_file
      tmp_file=$(mktemp "${target}.XXXXXX")

      awk -v begin="$begin_marker" -v end="$end_marker" -v block="$managed_block" '
        $0 == begin { skip=1; print block; next }
        $0 == end   { skip=0; next }
        !skip       { print }
      ' "$target" > "$tmp_file"

      mv "$tmp_file" "$target"
      echo "Updated managed section in: $target"
    else
      # No markers — append managed section
      {
        echo ""
        echo "$managed_block"
      } >> "$target"
      echo "Appended managed section to: $target"
    fi
  else
    # Target doesn't exist — create with markers
    mkdir -p "$(dirname "$target")"
    echo "$managed_block" > "$target"
    echo "Created: $target"
  fi
}

# Detect if the managed section has drifted from the template
# Usage: detect_drift "target_file" "template_file" ["comment_style"]
# Returns: 0 if in sync, 1 if drifted or missing
detect_drift() {
  local target="$1"
  local template="$2"
  local comment_style="${3:-hash}"

  local begin_marker
  case "$comment_style" in
    html)  begin_marker="<!-- DOYAKEN:BEGIN -->" ;;
    slash) begin_marker="// DOYAKEN:BEGIN" ;;
    *)     begin_marker="# DOYAKEN:BEGIN" ;;
  esac

  local end_marker
  case "$comment_style" in
    html)  end_marker="<!-- DOYAKEN:END -->" ;;
    slash) end_marker="// DOYAKEN:END" ;;
    *)     end_marker="# DOYAKEN:END" ;;
  esac

  [ -f "$target" ] || return 1
  [ -f "$template" ] || return 1

  # Extract managed section from target
  local current_managed
  current_managed=$(awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { skip=1; next }
    $0 == end   { skip=0; next }
    skip        { print }
  ' "$target")

  local template_content
  template_content=$(cat "$template")

  if [ "$current_managed" = "$template_content" ]; then
    return 0
  fi
  return 1
}

# Generate all configs defined in the manifest
# Reads generate.configs[] from .doyaken/manifest.yaml
generate_all() {
  local manifest="${DOYAKEN_PROJECT:-.}/.doyaken/manifest.yaml"

  if [ ! -f "$manifest" ]; then
    echo "No manifest found"
    return 1
  fi

  if ! command -v yq &>/dev/null; then
    echo "yq required for generate" >&2
    return 1
  fi

  local configs
  configs=$(yq -r '.generate.configs[]? // empty' "$manifest" 2>/dev/null)

  if [ -z "$configs" ]; then
    echo "No generate.configs defined in manifest"
    echo ""
    echo "Add to .doyaken/manifest.yaml:"
    echo "  generate:"
    echo "    configs:"
    echo "      - template: config/generators/eslint.yaml"
    echo "        target: .eslintrc.js"
    echo "        style: slash"
    return 0
  fi

  local count=0
  local drift_count=0
  local config_count
  config_count=$(yq '.generate.configs | length' "$manifest" 2>/dev/null)

  local i
  for (( i=0; i < config_count; i++ )); do
    local tmpl target style
    tmpl=$(yq -r ".generate.configs[$i].template" "$manifest")
    target=$(yq -r ".generate.configs[$i].target" "$manifest")
    style=$(yq -r ".generate.configs[$i].style // \"hash\"" "$manifest")

    # Resolve template path relative to project
    local template_path="$tmpl"
    if [ ! -f "$template_path" ]; then
      template_path="${DOYAKEN_PROJECT:-.}/$tmpl"
    fi
    if [ ! -f "$template_path" ]; then
      template_path="${DOYAKEN_HOME}/config/generators/$tmpl"
    fi

    local target_path="${DOYAKEN_PROJECT:-.}/$target"

    if [ -f "$template_path" ]; then
      generate_config "$template_path" "$target_path" "$style"
      count=$((count + 1))

      if ! detect_drift "$target_path" "$template_path" "$style"; then
        drift_count=$((drift_count + 1))
      fi
    else
      echo "Template not found: $tmpl (tried $template_path)"
    fi
  done

  echo ""
  echo "Generated $count config(s)"
  [ "$drift_count" -gt 0 ] && echo "Warning: $drift_count file(s) have drifted from templates"
}
