#!/usr/bin/env bash
#
# security.sh - Secret scanning for doyaken
#
# Scans files and diffs for accidentally committed secrets
# (API keys, tokens, private keys, passwords).
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_SECURITY_LOADED:-}" ]] && return 0
_DOYAKEN_SECURITY_LOADED=1

# Secret detection patterns (extended grep regex)
# Each entry: "pattern_name|regex"
SECRET_PATTERNS=(
  "AWS Access Key|AKIA[0-9A-Z]{16}"
  "AWS Secret Key|aws_secret_access_key\s*=\s*['\"][^'\"]{20,}['\"]"
  "GitHub Token|ghp_[a-zA-Z0-9]{36}"
  "GitHub OAuth|gho_[a-zA-Z0-9]{36}"
  "GitHub App Token|ghu_[a-zA-Z0-9]{36}"
  "GitLab Token|glpat-[a-zA-Z0-9_-]{20,}"
  "OpenAI API Key|sk-[a-zA-Z0-9]{48}"
  "Anthropic API Key|sk-ant-[a-zA-Z0-9_-]{40,}"
  "Slack Token|xox[bpsa]-[a-zA-Z0-9-]{10,}"
  "Private Key|-----BEGIN\s*(RSA|DSA|EC|OPENSSH|PGP)\s*PRIVATE\s*KEY-----"
  "Password Assignment|password\s*[:=]\s*['\"][^'\"]{4,}['\"]"
  "Generic Secret|secret\s*[:=]\s*['\"][^'\"]{8,}['\"]"
  "Heroku API Key|[hH][eE][rR][oO][kK][uU].*[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}"
)

# Scan a file or directory for secrets
# Usage: scan_for_secrets "file_or_dir"
# Returns: matched lines on stdout, exit code 0 if secrets found, 1 if clean
scan_for_secrets() {
  local target="$1"
  local found=0

  local entry
  for entry in "${SECRET_PATTERNS[@]}"; do
    local name="${entry%%|*}"
    local pattern="${entry#*|}"

    local matches
    matches=$(grep -rnE "$pattern" "$target" 2>/dev/null | head -5) || true
    if [ -n "$matches" ]; then
      echo "  [$name]"
      echo "$matches" | while IFS= read -r line; do
        echo "    $line"
      done
      found=1
    fi
  done

  return $((1 - found))
}

# Scan git staged files for secrets
# Usage: scan_staged_files
# Returns: 0 if secrets found (with output), 1 if clean
scan_staged_files() {
  local staged_files
  staged_files=$(git diff --cached --name-only 2>/dev/null) || return 1

  [ -z "$staged_files" ] && return 1

  local found=0
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ -f "$file" ] || continue

    # Skip binary files
    file -b --mime-type "$file" 2>/dev/null | grep -q "^text/" || continue

    local result
    if result=$(scan_for_secrets "$file" 2>/dev/null); then
      if [ "$found" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW:-}Potential secrets detected in staged files:${NC:-}"
      fi
      echo ""
      echo "  File: $file"
      echo "$result"
      found=1
    fi
  done <<< "$staged_files"

  return $((1 - found))
}

# Scan diff text for secret patterns
# Usage: check_secrets_in_diff "diff_text"
# Returns: 0 if secrets found, 1 if clean
check_secrets_in_diff() {
  local diff_text="$1"
  local found=0

  # Only scan added lines (lines starting with +, excluding +++ headers)
  local added_lines
  added_lines=$(echo "$diff_text" | grep '^+[^+]' | sed 's/^+//' || true)

  [ -z "$added_lines" ] && return 1

  local entry
  for entry in "${SECRET_PATTERNS[@]}"; do
    local name="${entry%%|*}"
    local pattern="${entry#*|}"

    local matches
    matches=$(echo "$added_lines" | grep -nE "$pattern" 2>/dev/null | head -3) || true
    if [ -n "$matches" ]; then
      echo "  [$name] found in diff"
      echo "$matches" | while IFS= read -r line; do
        echo "    $line"
      done
      found=1
    fi
  done

  return $((1 - found))
}
