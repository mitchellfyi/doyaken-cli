#!/usr/bin/env bash
# shellcheck disable=SC1091
# Temporary legacy migration helper for Doyaken -> Dex project metadata.
set -euo pipefail

source "${DEX_DIR:-$HOME/work/dex}/lib/common.sh"

usage() {
  cat <<'USAGE'
Usage: dx rename [--dry-run]

Migrate legacy Doyaken project metadata in the current git repository:
  .doyaken/ -> .dex/
  .doyaken/doyaken.md -> .dex/dex.md

The command rewrites legacy Doyaken/dk references only inside .dex/.

Options:
  --dry-run   Show what would change without writing files
  -h, --help  Show this help
USAGE
}

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      dx_error "Unknown rename option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  repo_root=""
fi
if [[ -z "$repo_root" ]]; then
  dx_error "Not in a git repository."
  exit 1
fi

legacy_dir="$repo_root/.doyaken"
metadata_dir="$repo_root/.dex"

echo "Dex — Rename: $(basename "$repo_root")"
echo ""

if [[ ! -d "$legacy_dir" && ! -d "$metadata_dir" ]]; then
  dx_skip "No .doyaken/ or .dex/ metadata directory found."
  exit 0
fi

if [[ -d "$legacy_dir" && -e "$metadata_dir" ]]; then
  dx_error "Both .doyaken/ and .dex/ exist; refusing to merge automatically."
  dx_info "Move or remove one directory, then run 'dx rename' again."
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  if [[ -d "$legacy_dir" ]]; then
    dx_info "Would move .doyaken/ to .dex/"
  else
    dx_info "Would rewrite legacy references in existing .dex/"
  fi
  if [[ -f "$legacy_dir/doyaken.md" || -f "$metadata_dir/doyaken.md" ]]; then
    dx_info "Would rename doyaken.md to dex.md"
  fi
  exit 0
fi

if [[ -d "$legacy_dir" ]]; then
  mv "$legacy_dir" "$metadata_dir"
  dx_done "Moved .doyaken/ to .dex/"
fi

if [[ -f "$metadata_dir/doyaken.md" && ! -e "$metadata_dir/dex.md" ]]; then
  mv "$metadata_dir/doyaken.md" "$metadata_dir/dex.md"
  dx_done "Renamed .dex/doyaken.md to .dex/dex.md"
fi

if [[ -f "$metadata_dir/AGENTS.md" ]] && grep -qF '@doyaken.md' "$metadata_dir/AGENTS.md" 2>/dev/null; then
  tmp_file="${metadata_dir}/AGENTS.md.tmp.$$"
  sed 's/@doyaken\.md/@dex.md/g' "$metadata_dir/AGENTS.md" > "$tmp_file" && mv "$tmp_file" "$metadata_dir/AGENTS.md"
fi

if ! command -v python3 >/dev/null 2>&1; then
  dx_warn "python3 not found; metadata directory was moved but legacy text was not rewritten."
  exit 0
fi

changed_count=$(python3 - "$metadata_dir" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
literal_replacements = [
    ("mitchellfyi/doyaken-cli", "mitchellfyi/dex"),
    ("doyaken-cli", "dex"),
    ("https://doyaken.ai", "https://dexcode.ai"),
    ("doyaken.ai", "dexcode.ai"),
    ("DKSync", "DXSync"),
    ("DOYAKEN", "DEX"),
    ("Doyaken", "Dex"),
    ("doyaken", "dex"),
    ("DK_", "DX_"),
    ("__dk_", "__dx_"),
    ("dk_", "dx_"),
    ("$HOME/work/doyaken", "$HOME/work/dex"),
    ("/work/doyaken", "/work/dex"),
]
regex_replacements = [
    (re.compile(r"\bdk([A-Za-z0-9]+)"), r"dx\1"),
    (re.compile(r"\bdk-"), "dx-"),
    (re.compile(r"\bdk\b"), "dx"),
    (re.compile(r"\bDK\b"), "DX"),
]
changed = 0

for path in root.rglob("*"):
    if not path.is_file():
        continue
    try:
        original = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    updated = original
    for old, new in literal_replacements:
        updated = updated.replace(old, new)
    for pattern, repl in regex_replacements:
        updated = pattern.sub(repl, updated)
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        changed += 1

print(changed)
PY
)

dx_done "Rewrote legacy references in .dex/ (${changed_count:-0} file(s))"
