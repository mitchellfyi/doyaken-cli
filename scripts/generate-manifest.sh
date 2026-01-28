#!/usr/bin/env bash
#
# Generate manifest.json for doyaken installation/upgrade
#
# This script creates a manifest of all files with:
# - SHA256 checksums
# - File categories (overwrite, preserve, template)
# - List of obsolete files from previous versions
#
# Run this before each release to update the manifest.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST_FILE="$ROOT_DIR/manifest.json"

# Get version from package.json
VERSION=$(grep '"version"' "$ROOT_DIR/package.json" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Generating manifest.json for version $VERSION..."

# Compute checksum
compute_checksum() {
  local file="$1"
  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | cut -d' ' -f1
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | cut -d' ' -f1
  else
    openssl dgst -sha256 "$file" | awk '{print $NF}'
  fi
}

# Determine category based on path
get_category() {
  local path="$1"
  case "$path" in
    config/*)           echo "preserve" ;;
    templates/*)        echo "template" ;;
    lib/*)              echo "overwrite" ;;
    bin/*)              echo "overwrite" ;;
    prompts/*)          echo "overwrite" ;;
    skills/*)           echo "overwrite" ;;
    hooks/*)            echo "overwrite" ;;
    scripts/*)          echo "overwrite" ;;
    *)                  echo "overwrite" ;;
  esac
}

# Start JSON
cat > "$MANIFEST_FILE" << EOF
{
  "version": "$VERSION",
  "generated": "$TIMESTAMP",
  "files": {
EOF

# Track if we need comma
first=true

# Process directories in order
process_dir() {
  local dir="$1"
  local base="$ROOT_DIR/$dir"

  [ -d "$base" ] || return 0

  find "$base" -type f \( -name "*.sh" -o -name "*.md" -o -name "*.yaml" -o -name "*.json" -o -name "*.mdc" -o -name "doyaken" \) | sort | while read -r file; do
    local rel_path="${file#$ROOT_DIR/}"
    local checksum
    checksum=$(compute_checksum "$file")
    local category
    category=$(get_category "$rel_path")
    local size
    size=$(wc -c < "$file" | tr -d ' ')

    if [ "$first" = "true" ]; then
      first=false
    else
      echo ","
    fi

    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "%s",\n' "$category"
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done
}

# Process each directory
{
  # lib (shell scripts)
  for file in "$ROOT_DIR"/lib/*.sh; do
    [ -f "$file" ] || continue
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    category=$(get_category "$rel_path")
    size=$(wc -c < "$file" | tr -d ' ')

    if [ "$first" = "true" ]; then
      first=false
    else
      echo ","
    fi

    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "%s",\n' "$category"
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

  # bin
  for file in "$ROOT_DIR"/bin/*; do
    [ -f "$file" ] || continue
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    size=$(wc -c < "$file" | tr -d ' ')

    echo ","
    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "overwrite",\n'
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

  # config
  find "$ROOT_DIR/config" -type f -name "*.yaml" 2>/dev/null | sort | while read -r file; do
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    size=$(wc -c < "$file" | tr -d ' ')

    echo ","
    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "preserve",\n'
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

  # prompts
  find "$ROOT_DIR/prompts" -type f -name "*.md" 2>/dev/null | sort | while read -r file; do
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    size=$(wc -c < "$file" | tr -d ' ')

    echo ","
    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "overwrite",\n'
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

  # skills
  find "$ROOT_DIR/skills" -type f -name "*.md" 2>/dev/null | sort | while read -r file; do
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    size=$(wc -c < "$file" | tr -d ' ')

    echo ","
    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "overwrite",\n'
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

  # hooks
  find "$ROOT_DIR/hooks" -type f -name "*.sh" 2>/dev/null | sort | while read -r file; do
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    size=$(wc -c < "$file" | tr -d ' ')

    echo ","
    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "overwrite",\n'
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

  # scripts (only specific ones to install)
  for script in sync-agent-files.sh generate-commands.sh setup-hooks.sh; do
    file="$ROOT_DIR/scripts/$script"
    [ -f "$file" ] || continue
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    size=$(wc -c < "$file" | tr -d ' ')

    echo ","
    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "overwrite",\n'
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

  # templates
  find "$ROOT_DIR/templates" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.json" -o -name "*.mdc" -o -name ".cursorrules" -o -name ".opencode.json" \) 2>/dev/null | sort | while read -r file; do
    rel_path="${file#$ROOT_DIR/}"
    checksum=$(compute_checksum "$file")
    size=$(wc -c < "$file" | tr -d ' ')

    echo ","
    printf '    "%s": {\n' "$rel_path"
    printf '      "category": "template",\n'
    printf '      "sha256": "%s",\n' "$checksum"
    printf '      "size": %d\n' "$size"
    printf '    }'
  done

} >> "$MANIFEST_FILE"

# End files object and add obsolete list
cat >> "$MANIFEST_FILE" << 'EOF'

  },
  "obsolete": [
  ]
}
EOF

# Count files
file_count=$(grep -c '"category":' "$MANIFEST_FILE" || echo "0")
echo "Generated manifest with $file_count files"
echo "Output: $MANIFEST_FILE"
