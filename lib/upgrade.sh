#!/usr/bin/env bash
#
# doyaken Upgrade Library
#
# Provides idempotent install/upgrade logic with:
# - Version comparison
# - File manifest tracking
# - Checksum-based modification detection
# - Backup and rollback support
# - Dry-run previews
#
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"
UPGRADE_BACKUP_COUNT="${UPGRADE_BACKUP_COUNT:-5}"

# Source centralized logging
_UPGRADE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$_UPGRADE_SCRIPT_DIR/logging.sh" ]]; then
  source "$_UPGRADE_SCRIPT_DIR/logging.sh"
  set_log_prefix "upgrade"
else
  # Fallback if logging.sh not available (during install)
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
fi

# Source project utilities
if [[ -f "$_UPGRADE_SCRIPT_DIR/project.sh" ]]; then
  source "$_UPGRADE_SCRIPT_DIR/project.sh"
fi

# ============================================================================
# Logging (aliases for upgrade module)
# ============================================================================

_log_info() { echo -e "${BLUE}[upgrade]${NC} $1"; }
_log_success() { echo -e "${GREEN}[upgrade]${NC} $1"; }
_log_warn() { echo -e "${YELLOW}[upgrade]${NC} $1"; }
_log_error() { echo -e "${RED}[upgrade]${NC} $1" >&2; }

# ============================================================================
# Utility Functions
# ============================================================================

# Compute SHA256 checksum of a file
# Usage: upgrade_compute_checksum "file"
upgrade_compute_checksum() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo ""
    return 1
  fi

  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | cut -d' ' -f1
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | cut -d' ' -f1
  else
    # Fallback to openssl
    openssl dgst -sha256 "$file" | awk '{print $NF}'
  fi
}

# Compare semantic versions
# Returns: 0 if v1 > v2, 1 if v1 == v2, 2 if v1 < v2
upgrade_compare_versions() {
  local v1="$1"
  local v2="$2"

  # Remove 'v' prefix if present
  v1="${v1#v}"
  v2="${v2#v}"

  if [ "$v1" = "$v2" ]; then
    return 1
  fi

  # Use sort -V for version comparison
  local higher
  higher=$(printf '%s\n%s\n' "$v1" "$v2" | sort -V | tail -n1)

  if [ "$higher" = "$v1" ]; then
    return 0  # v1 is newer
  else
    return 2  # v2 is newer (v1 is older)
  fi
}

# Get file category from manifest
# Usage: upgrade_get_category "manifest.json" "lib/cli.sh"
upgrade_get_category() {
  local manifest="$1"
  local file_path="$2"

  if [ ! -f "$manifest" ]; then
    echo "overwrite"
    return
  fi

  if command -v jq &>/dev/null; then
    local category
    category=$(jq -r ".files[\"$file_path\"].category // \"overwrite\"" "$manifest" 2>/dev/null)
    echo "${category:-overwrite}"
  else
    # Fallback: assume overwrite for lib/, preserve for config/
    case "$file_path" in
      config/*) echo "preserve" ;;
      templates/*) echo "template" ;;
      *) echo "overwrite" ;;
    esac
  fi
}

# ============================================================================
# Manifest Functions
# ============================================================================

# Load installed manifest
# Returns JSON on stdout, empty if not found
upgrade_load_manifest() {
  local target_dir="${1:-$DOYAKEN_HOME}"
  local manifest="$target_dir/manifest.json"

  if [ -f "$manifest" ]; then
    cat "$manifest"
  else
    echo "{}"
  fi
}

# Get version from VERSION file or manifest
upgrade_get_version() {
  local target_dir="${1:-$DOYAKEN_HOME}"

  # Try VERSION file first (most explicit)
  if [ -f "$target_dir/VERSION" ]; then
    cat "$target_dir/VERSION"
    return
  fi

  # Fall back to manifest.json
  if [ -f "$target_dir/manifest.json" ] && command -v jq &>/dev/null; then
    local version
    version=$(jq -r '.version // ""' "$target_dir/manifest.json" 2>/dev/null)
    if [ -n "$version" ]; then
      echo "$version"
      return
    fi
  fi

  echo ""
}

# ============================================================================
# Check Functions
# ============================================================================

# Check if upgrade is available
# Returns: 0 = upgrade available, 1 = up to date, 2 = downgrade
upgrade_check() {
  local source_dir="$1"
  local target_dir="${2:-$DOYAKEN_HOME}"

  local source_version target_version
  source_version=$(upgrade_get_version "$source_dir")
  target_version=$(upgrade_get_version "$target_dir")

  if [ -z "$target_version" ]; then
    # Fresh install
    _log_info "Fresh installation detected"
    return 0
  fi

  if [ -z "$source_version" ]; then
    _log_error "Cannot determine source version"
    return 1
  fi

  _log_info "Installed: $target_version"
  _log_info "Available: $source_version"

  upgrade_compare_versions "$source_version" "$target_version"
  local result=$?

  case $result in
    0)
      _log_info "Upgrade available: $target_version → $source_version"
      return 0
      ;;
    1)
      _log_info "Already up to date"
      return 1
      ;;
    2)
      _log_warn "Downgrade detected: $target_version → $source_version"
      return 2
      ;;
  esac
}

# Verify installation integrity
# Returns: 0 = valid, 1 = corrupted
upgrade_verify() {
  local target_dir="${1:-$DOYAKEN_HOME}"
  local manifest="$target_dir/manifest.json"
  local errors=0

  _log_info "Verifying installation..."

  # Check essential directories
  for dir in lib bin; do
    if [ ! -d "$target_dir/$dir" ]; then
      _log_error "Missing directory: $dir/"
      ((++errors))
    fi
  done

  # Check essential files
  for file in lib/cli.sh lib/core.sh bin/doyaken; do
    if [ ! -f "$target_dir/$file" ]; then
      _log_error "Missing file: $file"
      ((++errors))
    fi
  done

  # If manifest exists, verify critical lib files exist
  if [ -f "$manifest" ] && command -v jq &>/dev/null; then
    local files
    # Only verify lib/ and bin/ files - these are critical for operation
    # Skip README.md and other documentation files
    files=$(jq -r '.files | to_entries[] | select(.value.category == "overwrite") | .key | select(startswith("lib/") or startswith("bin/"))' "$manifest" 2>/dev/null)

    while IFS= read -r file; do
      [ -z "$file" ] && continue
      if [ ! -f "$target_dir/$file" ]; then
        _log_warn "Missing: $file"
        ((++errors))
      fi
    done <<< "$files"
  fi

  if [ "$errors" -gt 0 ]; then
    _log_error "Installation verification failed: $errors error(s)"
    return 1
  fi

  _log_success "Installation verified"
  return 0
}

# ============================================================================
# Backup Functions
# ============================================================================

# Create backup before upgrade
upgrade_create_backup() {
  local target_dir="${1:-$DOYAKEN_HOME}"
  local backup_base="$target_dir/backups"
  local timestamp
  timestamp=$(date '+%Y-%m-%dT%H-%M-%S')
  local backup_dir="$backup_base/$timestamp"

  _log_info "Creating backup: $backup_dir"

  mkdir -p "$backup_dir"
  chmod 700 "$backup_dir"

  # Backup VERSION and manifest
  [ -f "$target_dir/VERSION" ] && /bin/cp -f "$target_dir/VERSION" "$backup_dir/"
  [ -f "$target_dir/manifest.json" ] && /bin/cp -f "$target_dir/manifest.json" "$backup_dir/"

  # Backup config files (user data)
  if [ -d "$target_dir/config" ]; then
    mkdir -p "$backup_dir/config"
    chmod 700 "$backup_dir/config"
    /bin/cp -rf "$target_dir/config"/* "$backup_dir/config/" 2>/dev/null || true
  fi

  # Clean old backups (keep last N)
  local backup_count
  backup_count=$(find "$backup_base" -maxdepth 1 -type d -name "20*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$backup_count" -gt "$UPGRADE_BACKUP_COUNT" ]; then
    local to_delete=$((backup_count - UPGRADE_BACKUP_COUNT))
    find "$backup_base" -maxdepth 1 -type d -name "20*" | sort | head -n "$to_delete" | while read -r old_backup; do
      _log_info "Removing old backup: $(basename "$old_backup")"
      rm -rf "$old_backup"
    done
  fi

  echo "$backup_dir"
}

# Rollback to previous version
upgrade_rollback() {
  local target_dir="${1:-$DOYAKEN_HOME}"
  local backup_dir="${2:-}"
  local backup_base="$target_dir/backups"

  # Find latest backup if not specified
  if [ -z "$backup_dir" ]; then
    backup_dir=$(find "$backup_base" -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -n1)
  fi

  if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
    _log_error "No backup found to rollback"
    return 1
  fi

  _log_info "Rolling back from: $(basename "$backup_dir")"

  # Restore VERSION and manifest
  [ -f "$backup_dir/VERSION" ] && /bin/cp -f "$backup_dir/VERSION" "$target_dir/"
  [ -f "$backup_dir/manifest.json" ] && /bin/cp -f "$backup_dir/manifest.json" "$target_dir/"

  # Restore config files
  if [ -d "$backup_dir/config" ]; then
    /bin/cp -rf "$backup_dir/config"/* "$target_dir/config/" 2>/dev/null || true
  fi

  _log_success "Rollback complete"
  return 0
}

# List available backups
upgrade_list_backups() {
  local target_dir="${1:-$DOYAKEN_HOME}"
  local backup_base="$target_dir/backups"

  if [ ! -d "$backup_base" ]; then
    _log_info "No backups found"
    return
  fi

  echo ""
  echo "Available backups:"
  echo ""

  find "$backup_base" -maxdepth 1 -type d -name "20*" | sort -r | while read -r backup; do
    local name
    name=$(basename "$backup")
    local version=""
    [ -f "$backup/VERSION" ] && version=$(cat "$backup/VERSION")
    printf "  %s  %s\n" "$name" "${version:+(v$version)}"
  done

  echo ""
}

# ============================================================================
# Preview Functions
# ============================================================================

# Show what would change
upgrade_preview() {
  local source_dir="$1"
  local target_dir="${2:-$DOYAKEN_HOME}"
  local source_manifest="$source_dir/manifest.json"
  local target_manifest="$target_dir/manifest.json"

  echo ""
  echo -e "${BOLD}Upgrade Preview${NC}"
  echo "================"
  echo ""

  local source_version target_version
  source_version=$(upgrade_get_version "$source_dir")
  target_version=$(upgrade_get_version "$target_dir")

  echo "Version: ${target_version:-new} → $source_version"
  echo ""

  local added=0 updated=0 removed=0 preserved=0

  if [ -f "$source_manifest" ] && command -v jq &>/dev/null; then
    # Get files from source manifest
    local source_files
    source_files=$(jq -r '.files | keys[]' "$source_manifest" 2>/dev/null)

    echo "Changes:"
    echo ""

    while IFS= read -r file; do
      [ -z "$file" ] && continue
      local category
      category=$(jq -r ".files[\"$file\"].category // \"overwrite\"" "$source_manifest" 2>/dev/null)

      if [ ! -f "$target_dir/$file" ]; then
        echo -e "  ${GREEN}+ $file${NC}"
        ((++added))
      elif [ "$category" = "overwrite" ]; then
        # Check if file changed
        local source_sum target_sum
        source_sum=$(jq -r ".files[\"$file\"].sha256 // \"\"" "$source_manifest" 2>/dev/null)
        target_sum=$(upgrade_compute_checksum "$target_dir/$file")

        if [ "$source_sum" != "$target_sum" ]; then
          echo -e "  ${CYAN}~ $file${NC}"
          ((++updated))
        fi
      elif [ "$category" = "preserve" ]; then
        ((++preserved))
      fi
    done <<< "$source_files"

    # Check obsolete list (only these files will actually be removed)
    # Protected paths are never removed: projects/, tasks/, backups/, logs/, state/, locks/, config/
    local obsolete_files
    obsolete_files=$(jq -r '.obsolete[]? // empty' "$source_manifest" 2>/dev/null)
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      # Skip protected paths in preview too
      case "$file" in
        projects/*|tasks/*|backups/*|logs/*|state/*|locks/*|config/*) continue ;;
      esac
      if [ -f "$target_dir/$file" ]; then
        echo -e "  ${RED}- $file${NC} (obsolete)"
        ((++removed))
      fi
    done <<< "$obsolete_files"
  else
    echo "  (manifest not available, will copy all files)"
  fi

  echo ""
  echo "Summary:"
  echo "  Added:     $added"
  echo "  Updated:   $updated"
  echo "  Removed:   $removed"
  echo "  Preserved: $preserved"
  echo ""
}

# ============================================================================
# Apply Functions
# ============================================================================

# Copy a single file with directory creation
_copy_file() {
  local src="$1"
  local dst="$2"

  local dst_dir
  dst_dir=$(dirname "$dst")
  mkdir -p "$dst_dir"

  # Resolve to absolute paths to detect same-file scenario
  local abs_src abs_dst
  abs_src=$(cd "$(dirname "$src")" && pwd)/$(basename "$src")
  abs_dst=$(cd "$(dirname "$dst")" 2>/dev/null && pwd)/$(basename "$dst") 2>/dev/null || abs_dst="$dst"

  # Skip if source and destination are the same file
  if [ "$abs_src" = "$abs_dst" ]; then
    return 0
  fi

  # Use /bin/cp to avoid aliases (cp -i), force overwrite
  /bin/cp -f "$src" "$dst"
}

# Apply upgrade
# Returns: 0 = success, 1 = failure
upgrade_apply() {
  local source_dir="$1"
  local target_dir="${2:-$DOYAKEN_HOME}"
  local force="${3:-false}"
  local dry_run="${4:-false}"

  local source_manifest="$source_dir/manifest.json"
  local target_manifest="$target_dir/manifest.json"
  local progress_file="$target_dir/.upgrade-in-progress"

  # Check for interrupted upgrade
  if [ -f "$progress_file" ]; then
    _log_warn "Previous upgrade was interrupted"
    if [ "$force" != "true" ]; then
      _log_info "Run with --force to continue, or --rollback to restore"
      return 1
    fi
    _log_info "Continuing with --force"
  fi

  # Check version
  local check_result=0
  upgrade_check "$source_dir" "$target_dir" || check_result=$?

  case $check_result in
    1)
      if [ "$force" != "true" ]; then
        _log_info "Use --force to reinstall"
        return 0
      fi
      ;;
    2)
      if [ "$force" != "true" ]; then
        _log_error "Downgrade requires --force flag"
        return 1
      fi
      _log_warn "Proceeding with downgrade (--force)"
      ;;
  esac

  # Preview changes
  upgrade_preview "$source_dir" "$target_dir"

  if [ "$dry_run" = "true" ]; then
    _log_info "Dry run complete (no changes made)"
    return 0
  fi

  # Create backup (if not fresh install)
  local backup_dir=""
  if [ -d "$target_dir" ] && [ -f "$target_dir/VERSION" ]; then
    backup_dir=$(upgrade_create_backup "$target_dir")
  fi

  # Mark upgrade in progress
  mkdir -p "$target_dir"
  touch "$progress_file"

  _log_info "Applying upgrade..."

  # Create directories
  for dir in lib bin config prompts skills templates hooks scripts projects backups; do
    mkdir -p "$target_dir/$dir"
  done

  local errors=0

  if [ -f "$source_manifest" ] && command -v jq &>/dev/null; then
    # Use manifest for smart upgrade
    local files
    files=$(jq -r '.files | to_entries[] | "\(.key)|\(.value.category)"' "$source_manifest" 2>/dev/null)

    while IFS='|' read -r file category; do
      [ -z "$file" ] && continue

      local src="$source_dir/$file"
      local dst="$target_dir/$file"

      if [ ! -f "$src" ]; then
        continue
      fi

      case "$category" in
        overwrite)
          if ! _copy_file "$src" "$dst"; then
            _log_error "Failed to copy: $file"
            ((++errors))
          fi
          ;;
        preserve)
          if [ ! -f "$dst" ]; then
            if ! _copy_file "$src" "$dst"; then
              _log_error "Failed to copy: $file"
              ((++errors))
            fi
          fi
          ;;
        template)
          if [ ! -f "$dst" ]; then
            if ! _copy_file "$src" "$dst"; then
              _log_error "Failed to copy: $file"
              ((++errors))
            fi
          else
            # Check if template has newer version
            local src_sum dst_sum manifest_sum
            src_sum=$(upgrade_compute_checksum "$src")
            dst_sum=$(upgrade_compute_checksum "$dst")
            manifest_sum=$(jq -r ".files[\"$file\"].sha256 // \"\"" "$target_manifest" 2>/dev/null)

            if [ "$src_sum" != "$dst_sum" ] && [ "$dst_sum" != "$manifest_sum" ]; then
              # User modified and source changed - save as .new
              _copy_file "$src" "${dst}.new"
              _log_warn "Template updated: $file (saved as ${file}.new)"
            elif [ "$src_sum" != "$dst_sum" ]; then
              # Source changed, user didn't modify
              _copy_file "$src" "$dst"
            fi
          fi
          ;;
      esac
    done <<< "$files"

    # Remove obsolete files (ONLY those explicitly listed in manifest)
    # NEVER delete user data: projects/, tasks/, backups/, logs/, state/, locks/
    local obsolete_files
    obsolete_files=$(jq -r '.obsolete[]? // empty' "$source_manifest" 2>/dev/null)
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      # Safety check: never remove user data directories
      case "$file" in
        projects/*|tasks/*|backups/*|logs/*|state/*|locks/*|config/*)
          _log_warn "Skipping protected path: $file"
          continue
          ;;
      esac
      if [ -f "$target_dir/$file" ]; then
        _log_info "Removing obsolete: $file"
        rm -f "$target_dir/$file"
      fi
    done <<< "$obsolete_files"

  else
    # Fallback: copy all files without manifest
    _log_warn "No manifest found, copying all files"
    _log_info "Source: $source_dir"
    _log_info "Target: $target_dir"

    # Copy directories
    for dir in lib bin prompts skills hooks scripts; do
      if [ -d "$source_dir/$dir" ]; then
        # Check if source has files
        local file_count
        file_count=$(count_files "$source_dir/$dir")
        if [ "$file_count" -gt 0 ]; then
          if ! /bin/cp -rf "$source_dir/$dir"/* "$target_dir/$dir/" 2>&1; then
            _log_error "Failed to copy $dir/ directory"
            ((++errors))
          fi
        fi
      fi
    done

    # Verify critical files were copied
    if [ ! -f "$target_dir/bin/doyaken" ]; then
      _log_error "Critical file bin/doyaken not copied"
      # Try direct copy as fallback
      if [ -f "$source_dir/bin/doyaken" ]; then
        _log_info "Attempting direct copy of bin/doyaken..."
        if /bin/cp -f "$source_dir/bin/doyaken" "$target_dir/bin/doyaken"; then
          chmod +x "$target_dir/bin/doyaken"
          _log_success "Direct copy succeeded"
        else
          ((++errors))
        fi
      else
        _log_error "Source bin/doyaken not found at $source_dir/bin/doyaken"
        ((++errors))
      fi
    fi

    # Copy config (preserve mode)
    if [ -d "$source_dir/config" ]; then
      find "$source_dir/config" -type f | while read -r src; do
        local rel="${src#$source_dir/}"
        local dst="$target_dir/$rel"
        if [ ! -f "$dst" ]; then
          _copy_file "$src" "$dst"
        fi
      done
    fi

    # Copy templates (preserve mode)
    if [ -d "$source_dir/templates" ]; then
      find "$source_dir/templates" -type f | while read -r src; do
        local rel="${src#$source_dir/}"
        local dst="$target_dir/$rel"
        if [ ! -f "$dst" ]; then
          _copy_file "$src" "$dst"
        fi
      done
    fi
  fi

  # Update VERSION file
  local source_version
  source_version=$(upgrade_get_version "$source_dir")
  if [ -n "$source_version" ]; then
    echo "$source_version" > "$target_dir/VERSION"
  fi

  # Copy manifest
  if [ -f "$source_manifest" ]; then
    /bin/cp -f "$source_manifest" "$target_dir/manifest.json"
  fi

  # Set permissions
  chmod +x "$target_dir/bin/doyaken" 2>/dev/null || true
  chmod +x "$target_dir/lib"/*.sh 2>/dev/null || true
  chmod +x "$target_dir/scripts"/*.sh 2>/dev/null || true
  chmod +x "$target_dir/hooks"/*.sh 2>/dev/null || true

  # Remove progress marker
  rm -f "$progress_file"

  if [ "$errors" -gt 0 ]; then
    _log_error "Upgrade completed with $errors error(s)"
    if [ -n "$backup_dir" ]; then
      _log_info "Backup available at: $backup_dir"
    fi
    return 1
  fi

  # Verify installation
  if ! upgrade_verify "$target_dir"; then
    _log_error "Verification failed after upgrade"
    if [ -n "$backup_dir" ]; then
      _log_info "Rolling back..."
      upgrade_rollback "$target_dir" "$backup_dir"
    fi
    return 1
  fi

  _log_success "Upgrade complete: $(upgrade_get_version "$target_dir")"
  return 0
}

# ============================================================================
# Main Entry Point (for direct execution)
# ============================================================================

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] && [[ -n "${0:-}" ]]; then
  echo "This is a library file. Source it from another script:"
  echo "  source lib/upgrade.sh"
  exit 1
fi
