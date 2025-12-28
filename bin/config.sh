#!/usr/bin/env bash
# doyaken config — configure integrations for the current project
# Asks which integrations to use and writes the config to .doyaken/doyaken.md.
# Called by `doyaken init` after codebase analysis, and standalone via `doyaken config`.
set -euo pipefail

source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"

repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$repo_root" ]]; then
  echo "ERROR: Not in a git repository."
  exit 1
fi

doyaken_md="$repo_root/.doyaken/doyaken.md"
if [[ ! -f "$doyaken_md" ]]; then
  echo "ERROR: .doyaken/doyaken.md not found. Run 'dk init' first."
  exit 1
fi

# Clean up temp files on exit (normal or interrupt). The awk section below
# writes to a .integrations.tmp file that must not be left behind.
trap 'rm -f "${doyaken_md}.integrations.tmp" "${doyaken_md}.tmp" 2>/dev/null' EXIT

echo "Configuring integrations..."
echo ""

# ── Ticket tracker ───────────────────────────────────────────────────────

echo "Ticket tracker:"
echo "  [1] Linear (MCP)"
echo "  [2] GitHub Issues (gh CLI)"
echo "  [3] None"

# Default to GitHub Issues if gh is available, otherwise None
default_tracker=3
if command -v gh &>/dev/null; then
  default_tracker=2
fi

while true; do
  printf "Choice [%s]: " "$default_tracker"
  read -r tracker_choice
  tracker_choice="${tracker_choice:-$default_tracker}"
  case "$tracker_choice" in
    1) TRACKER_TOOL="Linear MCP"; TRACKER_STATUS="enabled"; break ;;
    2) TRACKER_TOOL="GitHub Issues (\`gh\`)"; TRACKER_STATUS="enabled"; break ;;
    3) TRACKER_TOOL="none"; TRACKER_STATUS="not configured"; break ;;
    *) echo "Invalid choice. Enter 1, 2, or 3." ;;
  esac
done

# ── Optional integrations ────────────────────────────────────────────────

ask_yn() {
  local prompt="$1"
  local default="${2:-n}"
  local suffix="[y/N]"
  [[ "$default" == "y" ]] && suffix="[Y/n]"
  printf "%s %s: " "$prompt" "$suffix"
  read -r answer
  answer="${answer:-$default}"
  [[ "${answer:0:1}" == "y" || "${answer:0:1}" == "Y" ]]
}

FIGMA_STATUS="not configured"
SENTRY_STATUS="not configured"
VERCEL_STATUS="not configured"
GRAFANA_STATUS="not configured"

echo ""
ask_yn "Figma (design context)?" "n" && FIGMA_STATUS="enabled"
ask_yn "Sentry (error monitoring)?" "n" && SENTRY_STATUS="enabled"
ask_yn "Vercel (deployments)?" "n" && VERCEL_STATUS="enabled"
ask_yn "Grafana (observability)?" "n" && GRAFANA_STATUS="enabled"

# ── Write to doyaken.md ──────────────────────────────────────────────────

INTEGRATIONS="## Integrations

| Integration | Tool | Status |
|-------------|------|--------|
| Ticket tracker | ${TRACKER_TOOL} | ${TRACKER_STATUS} |
| Design | Figma MCP | ${FIGMA_STATUS} |
| Error monitoring | Sentry MCP | ${SENTRY_STATUS} |
| Deployments | Vercel MCP | ${VERCEL_STATUS} |
| Observability | Grafana MCP | ${GRAFANA_STATUS} |

When an integration is \"not configured\", skip any workflow steps that reference it.
For ticket tracking: use the enabled tracker for all status updates, context gathering, and ticket lifecycle management."

# Write integrations content to a temp file (avoids BSD awk multiline -v bug)
INTEGRATIONS_TMP="${doyaken_md}.integrations.tmp"
printf '%s\n' "$INTEGRATIONS" > "$INTEGRATIONS_TMP"

# Replace existing Integrations section, or append before ## Workflow (or at end)
if grep -q '^## Integrations' "$doyaken_md" 2>/dev/null; then
  # Remove from ## Integrations to the next ## heading (or EOF), insert replacement.
  # Pass the temp file path via env var to avoid awk program string injection.
  _DKTMP="$INTEGRATIONS_TMP" awk '
    /^## Integrations/ { skip=1; while ((getline line < ENVIRON["_DKTMP"]) > 0) print line; next }
    skip && /^## / { skip=0 }
    !skip { print }
  ' "$doyaken_md" > "${doyaken_md}.tmp" && mv "${doyaken_md}.tmp" "$doyaken_md"
elif grep -q '^## Workflow' "$doyaken_md" 2>/dev/null; then
  # Insert before ## Workflow
  _DKTMP="$INTEGRATIONS_TMP" awk '
    /^## Workflow/ { while ((getline line < ENVIRON["_DKTMP"]) > 0) print line; print "" }
    { print }
  ' "$doyaken_md" > "${doyaken_md}.tmp" && mv "${doyaken_md}.tmp" "$doyaken_md"
else
  # Append to end
  printf '\n%s\n' "$INTEGRATIONS" >> "$doyaken_md"
fi
rm -f "$INTEGRATIONS_TMP"

echo ""
echo "Integrations configured:"
echo "  Ticket tracker: ${TRACKER_TOOL} (${TRACKER_STATUS})"
[[ "$FIGMA_STATUS" == "enabled" ]] && echo "  Figma: enabled"
[[ "$SENTRY_STATUS" == "enabled" ]] && echo "  Sentry: enabled"
[[ "$VERCEL_STATUS" == "enabled" ]] && echo "  Vercel: enabled"
[[ "$GRAFANA_STATUS" == "enabled" ]] && echo "  Grafana: enabled"
echo ""
echo "To reconfigure later, run: dk config"
