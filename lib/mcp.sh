#!/usr/bin/env bash
#
# mcp.sh - MCP (Model Context Protocol) configuration management
#
# Generates MCP configs for different AI agents based on enabled integrations.
#

set -euo pipefail

# MCP server definitions directory
MCP_SERVERS_DIR="${DOYAKEN_HOME}/config/mcp/servers"

# Mask sensitive tokens for logging
# Keeps first 4 chars for identification, replaces rest with ***
# Usage: mask_token "ghp_abc123..."
mask_token() {
  local token="$1"
  local min_visible=4
  if [ ${#token} -le $min_visible ]; then
    echo "***"
  else
    echo "${token:0:$min_visible}***"
  fi
}

# Load MCP server definition
# Usage: load_mcp_server <server_name>
# Returns YAML content
load_mcp_server() {
  local name="$1"
  local server_file="$MCP_SERVERS_DIR/${name}.yaml"

  if [ -f "$server_file" ]; then
    cat "$server_file"
  else
    echo "" >&2
    return 1
  fi
}

# Get enabled integrations from manifest
# Returns one integration name per line
get_enabled_integrations() {
  local manifest="${DOYAKEN_PROJECT:-.}/.doyaken/manifest.yaml"

  [ -f "$manifest" ] || return 0

  yq -e '.integrations | to_entries | .[] | select(.value.enabled == true) | .key' "$manifest" 2>/dev/null || true
}

# Generate Claude MCP config (.mcp.json format)
# Usage: generate_claude_mcp_config [output_file]
generate_claude_mcp_config() {
  local output="${1:-}"
  local config='{"mcpServers":{'
  local first=true

  while IFS= read -r integration; do
    [ -z "$integration" ] && continue

    local server_file="$MCP_SERVERS_DIR/${integration}.yaml"
    [ -f "$server_file" ] || continue

    # Validate integration (skip if strict mode blocks it)
    local strict_mode=""
    [ "${DOYAKEN_MCP_STRICT:-}" = "1" ] && strict_mode="strict"
    if ! mcp_validate_integration "$integration" "$strict_mode"; then
      continue
    fi

    local name command args_json env_json

    name=$(yq -r '.name // ""' "$server_file")
    command=$(yq -r '.command // ""' "$server_file")

    # Convert args array to JSON
    args_json=$(yq -o=json '.args // []' "$server_file")

    # Convert env object to JSON with variable expansion
    env_json=$(yq -o=json '.env // {}' "$server_file" | expand_env_vars)

    [ -z "$command" ] && continue

    [ "$first" = false ] && config+=','
    first=false

    config+="\"${name}\":{\"command\":\"${command}\",\"args\":${args_json},\"env\":${env_json}}"

  done < <(get_enabled_integrations)

  config+='}}'

  if [ -n "$output" ]; then
    echo "$config" | jq '.' > "$output"
    echo "Generated: $output"
  else
    echo "$config" | jq '.'
  fi
}

# Generate Codex MCP config (TOML format)
# Usage: generate_codex_mcp_config [output_file]
generate_codex_mcp_config() {
  local output="${1:-}"
  local config=""

  while IFS= read -r integration; do
    [ -z "$integration" ] && continue

    local server_file="$MCP_SERVERS_DIR/${integration}.yaml"
    [ -f "$server_file" ] || continue

    # Validate integration (skip if strict mode blocks it)
    local strict_mode=""
    [ "${DOYAKEN_MCP_STRICT:-}" = "1" ] && strict_mode="strict"
    if ! mcp_validate_integration "$integration" "$strict_mode"; then
      continue
    fi

    local name command args env_keys

    name=$(yq -r '.name // ""' "$server_file")
    command=$(yq -r '.command // ""' "$server_file")

    [ -z "$command" ] && continue

    config+="[mcp_servers.${name}]"$'\n'

    # Build command array
    local cmd_array="[\"$command\""
    while IFS= read -r arg; do
      [ -n "$arg" ] && cmd_array+=", \"$arg\""
    done < <(yq -r '.args[]? // empty' "$server_file")
    cmd_array+="]"
    config+="command = $cmd_array"$'\n'

    # Add env vars
    while IFS= read -r env_line; do
      [ -z "$env_line" ] && continue
      local key="${env_line%%:*}"
      local value="${env_line#*: }"
      value=$(expand_env_var "$value")
      config+="env.${key} = \"${value}\""$'\n'
    done < <(yq -r '.env | to_entries | .[] | "\(.key): \(.value)"' "$server_file" 2>/dev/null || true)

    config+=$'\n'

  done < <(get_enabled_integrations)

  if [ -n "$output" ]; then
    echo "$config" > "$output"
    echo "Generated: $output"
  else
    echo "$config"
  fi
}

# Generate Gemini MCP config (settings.json format)
# Usage: generate_gemini_mcp_config [output_file]
generate_gemini_mcp_config() {
  local output="${1:-}"
  local config='{"mcpServers":{'
  local first=true

  while IFS= read -r integration; do
    [ -z "$integration" ] && continue

    local server_file="$MCP_SERVERS_DIR/${integration}.yaml"
    [ -f "$server_file" ] || continue

    # Validate integration (skip if strict mode blocks it)
    local strict_mode=""
    [ "${DOYAKEN_MCP_STRICT:-}" = "1" ] && strict_mode="strict"
    if ! mcp_validate_integration "$integration" "$strict_mode"; then
      continue
    fi

    local name command args_json env_json

    name=$(yq -r '.name // ""' "$server_file")
    command=$(yq -r '.command // ""' "$server_file")

    # Convert args array to JSON
    args_json=$(yq -o=json '.args // []' "$server_file")

    # Convert env object to JSON
    env_json=$(yq -o=json '.env // {}' "$server_file" | expand_env_vars)

    [ -z "$command" ] && continue

    [ "$first" = false ] && config+=','
    first=false

    config+="\"${name}\":{\"command\":\"${command}\",\"args\":${args_json},\"env\":${env_json}}"

  done < <(get_enabled_integrations)

  config+='}}'

  if [ -n "$output" ]; then
    echo "$config" | jq '.' > "$output"
    echo "Generated: $output"
  else
    echo "$config" | jq '.'
  fi
}

# Expand environment variables in a string
# ${VAR} or ${VAR:-default} syntax
expand_env_var() {
  local value="$1"

  # Match ${VAR} or ${VAR:-default}
  if [[ "$value" =~ ^\$\{([A-Z_][A-Z0-9_]*)(:-(.*))?\}$ ]]; then
    local var_name="${BASH_REMATCH[1]}"
    local default_value="${BASH_REMATCH[3]:-}"
    local actual_value="${!var_name:-$default_value}"
    echo "$actual_value"
  else
    echo "$value"
  fi
}

# Expand env vars in JSON
expand_env_vars() {
  local json
  json=$(cat)

  # Simple expansion - replace ${VAR} patterns
  while [[ "$json" =~ \$\{([A-Z_][A-Z0-9_]*)(:-(.*))?\} ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local var_name="${BASH_REMATCH[1]}"
    local default_value="${BASH_REMATCH[3]:-}"
    local actual_value="${!var_name:-$default_value}"

    # Escape for JSON
    actual_value="${actual_value//\\/\\\\}"
    actual_value="${actual_value//\"/\\\"}"

    json="${json//$full_match/$actual_value}"
  done

  echo "$json"
}

# Validate if an MCP package is in the allowlist
# Returns:
#   0 = official (matches pattern or trusted list)
#   1 = unofficial (not in allowlist) - warn only
#
# Usage: mcp_validate_package "@modelcontextprotocol/server-github"
mcp_validate_package() {
  local package="$1"
  local allowlist_file="${DOYAKEN_HOME}/config/mcp/allowed-packages.yaml"

  # If allowlist file missing, treat all as unofficial (warn only)
  [ -f "$allowlist_file" ] || return 1

  # Check glob patterns (scoped packages)
  local pattern
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    # Convert glob to regex: @foo/* -> ^@foo/
    local regex="${pattern%\*}"
    regex="^${regex//\//\\/}"
    if [[ "$package" =~ $regex ]]; then
      return 0
    fi
  done < <(yq -r '.patterns[]?' "$allowlist_file" 2>/dev/null)

  # Check exact match in trusted list
  local trusted
  while IFS= read -r trusted; do
    [ -z "$trusted" ] && continue
    [ "$package" = "$trusted" ] && return 0
  done < <(yq -r '.trusted[]?' "$allowlist_file" 2>/dev/null)

  return 1
}

# Validate required env vars for an MCP integration
# Returns:
#   0 = all required env vars are set
#   1 = one or more env vars missing
#
# Sets MCP_MISSING_VARS with list of missing vars (for error reporting)
#
# Usage: mcp_validate_env_vars "github"
mcp_validate_env_vars() {
  local integration="$1"
  local server_file="$MCP_SERVERS_DIR/${integration}.yaml"

  MCP_MISSING_VARS=""
  [ -f "$server_file" ] || return 1

  local missing=()
  while IFS= read -r env_line; do
    [ -z "$env_line" ] && continue
    local value="${env_line#*: }"

    # Check if it's a variable reference without default
    if [[ "$value" =~ ^\$\{([A-Z_][A-Z0-9_]*)\}$ ]]; then
      local var_name="${BASH_REMATCH[1]}"
      if [ -z "${!var_name:-}" ]; then
        missing+=("$var_name")
      fi
    fi
    # ${VAR:-default} syntax has a default, so skip those
  done < <(yq -r '.env | to_entries | .[] | "\(.key): \(.value)"' "$server_file" 2>/dev/null || true)

  if [ ${#missing[@]} -gt 0 ]; then
    MCP_MISSING_VARS="${missing[*]}"
    return 1
  fi
  return 0
}

# Validate an MCP integration (package + env vars)
# Returns:
#   0 = valid (or non-strict mode with warnings)
#   1 = invalid (strict mode blocks unofficial or missing vars)
#
# Usage: mcp_validate_integration "github" [strict]
mcp_validate_integration() {
  local integration="$1"
  local strict="${2:-}"
  local server_file="$MCP_SERVERS_DIR/${integration}.yaml"

  [ -f "$server_file" ] || return 1

  local package
  package=$(yq -r '.args[] | select(test("^@|^[a-z]"))' "$server_file" 2>/dev/null | head -1)

  # Validate package
  if [ -n "$package" ]; then
    if ! mcp_validate_package "$package"; then
      if [ "$strict" = "strict" ]; then
        echo "[BLOCK] $integration: Unofficial package '$package' blocked in strict mode" >&2
        return 1
      else
        echo "[WARN] $integration: Unofficial package '$(mask_token "$package")'" >&2
      fi
    fi
  fi

  # Validate env vars
  if ! mcp_validate_env_vars "$integration"; then
    if [ "$strict" = "strict" ]; then
      echo "[BLOCK] $integration: Missing required env vars: $MCP_MISSING_VARS" >&2
      return 1
    else
      echo "[WARN] $integration: Missing env vars: $MCP_MISSING_VARS" >&2
    fi
  fi

  return 0
}

# Check if conditions for a server are met
# Usage: mcp_check_conditions "server_file"
# Returns: 0 if all conditions met, 1 if not
mcp_check_conditions() {
  local server_file="$1"

  # Check required commands exist
  local cmds
  cmds=$(yq -r '.conditions.commands[]? // empty' "$server_file" 2>/dev/null)
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    if ! command -v "$cmd" &>/dev/null; then
      return 1
    fi
  done <<< "$cmds"

  # Check required env vars are set
  local envs
  envs=$(yq -r '.conditions.env[]? // empty' "$server_file" 2>/dev/null)
  while IFS= read -r var; do
    [ -z "$var" ] && continue
    if [ -z "${!var:-}" ]; then
      return 1
    fi
  done <<< "$envs"

  return 0
}

# Show setup instructions for an MCP server
# Usage: mcp_setup "server_name"
mcp_setup() {
  local name="$1"
  local server_file="$MCP_SERVERS_DIR/${name}.yaml"

  if [ ! -f "$server_file" ]; then
    echo "Unknown server: $name" >&2
    echo "Available servers:" >&2
    for f in "$MCP_SERVERS_DIR"/*.yaml; do
      [ -f "$f" ] && echo "  - $(basename "$f" .yaml)" >&2
    done
    return 1
  fi

  local desc install docs notes
  desc=$(yq -r '.description // "No description"' "$server_file" 2>/dev/null)
  install=$(yq -r '.setup.install // empty' "$server_file" 2>/dev/null)
  docs=$(yq -r '.setup.docs // empty' "$server_file" 2>/dev/null)
  notes=$(yq -r '.setup.notes // empty' "$server_file" 2>/dev/null)

  echo ""
  echo -e "${BOLD:-}Setup: $name${NC:-}"
  echo "  $desc"
  echo ""
  [ -n "$install" ] && echo "  Install:  $install"
  [ -n "$docs" ]    && echo "  Docs:     $docs"
  [ -n "$notes" ]   && echo "  Notes:    $notes"

  # Check current conditions
  echo ""
  if mcp_check_conditions "$server_file"; then
    echo -e "  Status: ${GREEN:-}Ready${NC:-} (all conditions met)"
  else
    echo -e "  Status: ${RED:-}Not ready${NC:-}"
    local cmds envs
    cmds=$(yq -r '.conditions.commands[]? // empty' "$server_file" 2>/dev/null)
    while IFS= read -r cmd; do
      [ -z "$cmd" ] && continue
      if command -v "$cmd" &>/dev/null; then
        echo -e "    ${GREEN:-}[ok]${NC:-} command: $cmd"
      else
        echo -e "    ${RED:-}[!!]${NC:-} command: $cmd (not found)"
      fi
    done <<< "$cmds"
    envs=$(yq -r '.conditions.env[]? // empty' "$server_file" 2>/dev/null)
    while IFS= read -r var; do
      [ -z "$var" ] && continue
      if [ -n "${!var:-}" ]; then
        echo -e "    ${GREEN:-}[ok]${NC:-} env: $var"
      else
        echo -e "    ${RED:-}[!!]${NC:-} env: $var (not set)"
      fi
    done <<< "$envs"
  fi
  echo ""
}

# Generate MCP config for specified agent
# Usage: mcp_configure [--agent <agent>]
mcp_configure() {
  local agent="${DOYAKEN_AGENT:-claude}"

  while [ $# -gt 0 ]; do
    case "$1" in
      --agent)
        shift
        agent="$1"
        ;;
    esac
    shift
  done

  local project_dir="${DOYAKEN_PROJECT:-.}"
  local mcp_dir="$project_dir/.doyaken/mcp"

  # Create mcp directory
  mkdir -p "$mcp_dir"

  case "$agent" in
    claude)
      generate_claude_mcp_config "$mcp_dir/.mcp.json"
      echo ""
      echo "To use with Claude Code, either:"
      echo "  1. Copy to project root: cp $mcp_dir/.mcp.json $project_dir/.mcp.json"
      echo "  2. Or merge with ~/.claude.json"
      ;;
    codex)
      generate_codex_mcp_config "$mcp_dir/codex-mcp.toml"
      echo ""
      echo "Merge this config into ~/.codex/config.toml"
      ;;
    gemini)
      generate_gemini_mcp_config "$mcp_dir/gemini-mcp.json"
      echo ""
      echo "Merge mcpServers into ~/.gemini/settings.json"
      ;;
    *)
      echo "Unknown agent: $agent" >&2
      echo "Supported agents: claude, codex, gemini" >&2
      return 1
      ;;
  esac

  # Add mcp directory to gitignore if not already
  local gitignore="$project_dir/.gitignore"
  if [ -f "$gitignore" ]; then
    if ! grep -q "^\.doyaken/mcp/" "$gitignore" 2>/dev/null; then
      echo ".doyaken/mcp/" >> "$gitignore"
      echo "Added .doyaken/mcp/ to .gitignore"
    fi
  fi
}

# Show MCP status
mcp_status() {
  echo "MCP Integration Status"
  echo "======================"
  echo ""

  local project_dir="${DOYAKEN_PROJECT:-.}"
  local manifest="$project_dir/.doyaken/manifest.yaml"

  if [ ! -f "$manifest" ]; then
    echo "No manifest found. Run 'doyaken init' first."
    return 1
  fi

  echo "Enabled integrations:"
  local enabled
  enabled=$(get_enabled_integrations)
  if [ -n "$enabled" ]; then
    while IFS= read -r integration; do
      local server_file="$MCP_SERVERS_DIR/${integration}.yaml"
      if [ -f "$server_file" ]; then
        local desc
        desc=$(yq -r '.description // "No description"' "$server_file")
        echo "  [x] $integration - $desc"
      else
        echo "  [!] $integration - No MCP server definition found"
      fi
    done <<< "$enabled"
  else
    echo "  (none)"
  fi

  echo ""
  echo "Available integrations:"
  for server_file in "$MCP_SERVERS_DIR"/*.yaml; do
    [ -f "$server_file" ] || continue
    local name
    name=$(basename "$server_file" .yaml)

    # Check if enabled
    local is_enabled=false
    if [ -n "$enabled" ]; then
      while IFS= read -r e; do
        [ "$e" = "$name" ] && is_enabled=true && break
      done <<< "$enabled"
    fi

    if [ "$is_enabled" = false ]; then
      local desc
      if command -v yq &>/dev/null; then
        desc=$(yq -r '.description // "No description"' "$server_file")
      else
        # Fallback: extract description using grep
        desc=$(grep -m1 "^description:" "$server_file" 2>/dev/null | sed 's/^description:[[:space:]]*//' | tr -d '"' || echo "No description")
      fi
      echo "  [ ] $name - $desc"
    fi
  done

  echo ""
  echo "Generated configs:"
  local mcp_dir="$project_dir/.doyaken/mcp"
  if [ -d "$mcp_dir" ]; then
    for f in "$mcp_dir"/*; do
      [ -f "$f" ] && echo "  - $f"
    done
  else
    echo "  (none - run 'doyaken mcp configure')"
  fi

  echo ""
  echo "To enable an integration, edit $manifest:"
  echo "  integrations:"
  echo "    github:"
  echo "      enabled: true"
}

# Check MCP server availability
mcp_doctor() {
  echo "MCP Health Check"
  echo "================"
  echo ""

  local all_ok=true

  # Check yq is available
  if command -v yq &>/dev/null; then
    echo "[ok] yq is installed"
  else
    echo "[!!] yq is not installed (required for YAML parsing)"
    all_ok=false
  fi

  # Check jq is available
  if command -v jq &>/dev/null; then
    echo "[ok] jq is installed"
  else
    echo "[!!] jq is not installed (required for JSON formatting)"
    all_ok=false
  fi

  # Check npx is available (for MCP servers)
  if command -v npx &>/dev/null; then
    echo "[ok] npx is installed"
  else
    echo "[!!] npx is not installed (required for most MCP servers)"
    all_ok=false
  fi

  echo ""

  # Check enabled integrations have required env vars and valid packages
  local enabled
  enabled=$(get_enabled_integrations)
  if [ -n "$enabled" ]; then
    echo "Checking enabled integrations:"
    while IFS= read -r integration; do
      local server_file="$MCP_SERVERS_DIR/${integration}.yaml"
      [ -f "$server_file" ] || continue

      local has_issues=false

      # Check package allowlist
      local package
      package=$(yq -r '.args[] | select(test("^@|^[a-z]"))' "$server_file" 2>/dev/null | head -1)
      if [ -n "$package" ] && ! mcp_validate_package "$package"; then
        echo "  [!!] $integration: Unofficial package '$package'"
        has_issues=true
      fi

      # Check conditions
      if ! mcp_check_conditions "$server_file"; then
        echo "  [!!] $integration: Conditions not met"
        local setup_install
        setup_install=$(yq -r '.setup.install // empty' "$server_file" 2>/dev/null)
        [ -n "$setup_install" ] && echo "       Setup: $setup_install"
        has_issues=true
        all_ok=false
      fi

      # Check required env vars using the validation function
      if ! mcp_validate_env_vars "$integration"; then
        echo "  [!!] $integration: Missing env vars: $MCP_MISSING_VARS"
        has_issues=true
        all_ok=false
      fi

      if [ "$has_issues" = false ]; then
        echo "  [ok] $integration"
      fi

    done <<< "$enabled"
  else
    echo "No integrations enabled."
  fi

  echo ""
  if [ "$all_ok" = true ]; then
    echo "All checks passed!"
    return 0
  else
    echo "Some issues found. Fix them before using MCP tools."
    echo "Run 'dk mcp setup <name>' for setup instructions."
    return 1
  fi
}
