#!/usr/bin/env bash
#
# skills.sh - Skills management for doyaken
#
# Skills are markdown prompts with YAML frontmatter that declare
# their tool requirements and can be run standalone or hooked into phases.
#

set -euo pipefail

# Skills search paths (project first, then global)
# Includes both root skills and vendor skills
get_skill_paths() {
  local paths=()

  # Project-specific skills (root)
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken/skills" ]; then
    paths+=("$DOYAKEN_PROJECT/.doyaken/skills")
  fi

  # Project-specific vendor skills
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken/skills/vendors" ]; then
    for vendor_dir in "$DOYAKEN_PROJECT/.doyaken/skills/vendors"/*/; do
      [ -d "$vendor_dir" ] && paths+=("$vendor_dir")
    done
  fi

  # Global skills (root)
  if [ -d "$DOYAKEN_HOME/skills" ]; then
    paths+=("$DOYAKEN_HOME/skills")
  fi

  # Global vendor skills
  if [ -d "$DOYAKEN_HOME/skills/vendors" ]; then
    for vendor_dir in "$DOYAKEN_HOME/skills/vendors"/*/; do
      [ -d "$vendor_dir" ] && paths+=("$vendor_dir")
    done
  fi

  # Only print if array has elements (avoids unbound variable error with set -u)
  [ ${#paths[@]} -gt 0 ] && printf '%s\n' "${paths[@]}"
}

# Get vendor name from skill path
# Returns empty if not a vendor skill
get_vendor_from_path() {
  local path="$1"
  if [[ "$path" == */vendors/*/* ]]; then
    # Extract vendor name from path like .../vendors/vercel/skill.md
    local vendor
    vendor=$(echo "$path" | sed 's|.*/vendors/\([^/]*\)/.*|\1|')
    echo "$vendor"
  fi
}

# Find skill file by name
# Supports both simple names (security-audit) and vendor-namespaced (vercel:deploy)
# Returns the full path to the skill file, or empty if not found
find_skill() {
  local name="$1"
  local vendor=""
  local skill_name="$name"

  # Check for vendor:skill format
  if [[ "$name" == *:* ]]; then
    vendor="${name%%:*}"
    skill_name="${name#*:}"
  fi

  # If vendor specified, search vendor directories first
  if [ -n "$vendor" ]; then
    # Project vendor skills
    if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -f "$DOYAKEN_PROJECT/.doyaken/skills/vendors/$vendor/${skill_name}.md" ]; then
      echo "$DOYAKEN_PROJECT/.doyaken/skills/vendors/$vendor/${skill_name}.md"
      return 0
    fi

    # Global vendor skills
    if [ -f "$DOYAKEN_HOME/skills/vendors/$vendor/${skill_name}.md" ]; then
      echo "$DOYAKEN_HOME/skills/vendors/$vendor/${skill_name}.md"
      return 0
    fi

    return 1
  fi

  # No vendor specified - search all paths
  while IFS= read -r dir; do
    if [ -f "$dir/${name}.md" ]; then
      echo "$dir/${name}.md"
      return 0
    fi
  done < <(get_skill_paths)

  return 1
}

# Parse skill frontmatter (YAML between --- markers)
# Usage: parse_skill_frontmatter <skill_file>
parse_skill_frontmatter() {
  local skill_file="$1"

  # Extract YAML between first two --- markers
  awk '
    /^---$/ {
      if (started) { exit }
      started = 1
      next
    }
    started { print }
  ' "$skill_file"
}

# Get skill body (everything after frontmatter)
# Usage: get_skill_body <skill_file>
get_skill_body() {
  local skill_file="$1"

  # Everything after the second ---
  awk '
    /^---$/ { count++; next }
    count >= 2 { print }
  ' "$skill_file"
}

# Get a specific field from skill frontmatter
# Usage: get_skill_field <skill_file> <field>
get_skill_field() {
  local skill_file="$1"
  local field="$2"

  parse_skill_frontmatter "$skill_file" | grep "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//"
}

# Get skill name
get_skill_name() {
  local skill_file="$1"
  get_skill_field "$skill_file" "name"
}

# Get skill description
get_skill_description() {
  local skill_file="$1"
  get_skill_field "$skill_file" "description"
}

# Get skill requirements (MCP servers needed)
# Returns one requirement per line
get_skill_requires() {
  local skill_file="$1"

  parse_skill_frontmatter "$skill_file" | awk '
    /^requires:/ { in_requires = 1; next }
    /^[a-z]/ && in_requires { exit }
    in_requires && /^[[:space:]]*-/ {
      gsub(/^[[:space:]]*-[[:space:]]*/, "")
      print
    }
  '
}

# Get skill arguments definition
# Returns JSON-like structure for each arg
get_skill_args() {
  local skill_file="$1"

  parse_skill_frontmatter "$skill_file" | awk '
    /^args:/ { in_args = 1; next }
    /^[a-z]/ && !/^[[:space:]]/ && in_args { exit }
    in_args && /^[[:space:]]*-[[:space:]]*name:/ {
      if (arg_name) print arg_name "|" arg_desc "|" arg_default "|" arg_required
      gsub(/^[[:space:]]*-[[:space:]]*name:[[:space:]]*/, "")
      arg_name = $0
      arg_desc = ""
      arg_default = ""
      arg_required = "false"
    }
    in_args && /^[[:space:]]*description:/ {
      gsub(/^[[:space:]]*description:[[:space:]]*/, "")
      arg_desc = $0
    }
    in_args && /^[[:space:]]*default:/ {
      gsub(/^[[:space:]]*default:[[:space:]]*/, "")
      gsub(/"/, "")
      arg_default = $0
    }
    in_args && /^[[:space:]]*required:/ {
      gsub(/^[[:space:]]*required:[[:space:]]*/, "")
      arg_required = $0
    }
    END {
      if (arg_name) print arg_name "|" arg_desc "|" arg_default "|" arg_required
    }
  '
}

# List all available skills
# Output format: name|description|location|vendor
# Vendor skills are displayed with vendor:skill format
list_skills() {
  local shown=()

  while IFS= read -r dir; do
    [ -d "$dir" ] || continue

    for skill_file in "$dir"/*.md; do
      [ -f "$skill_file" ] || continue

      # Skip README files
      [[ "$(basename "$skill_file")" == "README.md" ]] && continue

      local base_name
      base_name=$(basename "$skill_file" .md)

      # Determine if this is a vendor skill
      local vendor
      vendor=$(get_vendor_from_path "$skill_file")

      # Build display name (vendor:skill or just skill)
      local display_name="$base_name"
      if [ -n "$vendor" ]; then
        display_name="${vendor}:${base_name}"
      fi

      # Skip if we've already shown this skill (project overrides global)
      local already_shown=false
      for s in "${shown[@]:-}"; do
        [ "$s" = "$display_name" ] && already_shown=true && break
      done
      [ "$already_shown" = true ] && continue

      shown+=("$display_name")

      local desc
      desc=$(get_skill_description "$skill_file")
      [ -z "$desc" ] && desc="No description"

      local location="global"
      [[ "$dir" == *"/.doyaken/skills"* ]] && [[ "$dir" != "$DOYAKEN_HOME"* ]] && location="project"

      # Add vendor info to output
      echo "${display_name}|${desc}|${location}|${vendor:-builtin}"
    done
  done < <(get_skill_paths)
}

# List vendor skills only
# Output format: name|description|location|vendor
list_vendor_skills() {
  list_skills | grep -v '|builtin$' || true
}

# List skills by vendor
# Usage: list_skills_by_vendor <vendor>
list_skills_by_vendor() {
  local vendor="$1"
  list_skills | grep "|${vendor}$" || true
}

# Show skill info
# Usage: skill_info <name>
skill_info() {
  local name="$1"
  local skill_file

  skill_file=$(find_skill "$name") || {
    echo "Skill not found: $name" >&2
    return 1
  }

  local desc
  desc=$(get_skill_description "$skill_file")

  echo "Skill: $name"
  echo "Description: ${desc:-No description}"
  echo "Location: $skill_file"
  echo ""

  echo "Requirements:"
  local requires
  requires=$(get_skill_requires "$skill_file")
  if [ -n "$requires" ]; then
    echo "$requires" | while read -r req; do
      echo "  - $req (MCP server)"
    done
  else
    echo "  (none)"
  fi
  echo ""

  echo "Arguments:"
  local args
  args=$(get_skill_args "$skill_file")
  if [ -n "$args" ]; then
    echo "$args" | while IFS='|' read -r arg_name arg_desc arg_default arg_required; do
      local default_str=""
      [ -n "$arg_default" ] && default_str=" (default: $arg_default)"
      local required_str=""
      [ "$arg_required" = "true" ] && required_str=" [required]"
      echo "  --${arg_name}: ${arg_desc}${default_str}${required_str}"
    done
  else
    echo "  (none)"
  fi
}

# Parse skill arguments from command line
# Usage: parse_skill_cli_args <skill_file> "$@"
# Sets SKILL_ARG_<name> variables
parse_skill_cli_args() {
  local skill_file="$1"
  shift

  # Get defined args with defaults
  local args
  args=$(get_skill_args "$skill_file")

  # Set defaults first
  if [ -n "$args" ]; then
    while IFS='|' read -r arg_name arg_desc arg_default arg_required; do
      local var_name="SKILL_ARG_${arg_name}"
      var_name="${var_name//-/_}"
      var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')

      if [ -n "$arg_default" ]; then
        export "$var_name=$arg_default"
      else
        export "$var_name="
      fi
    done <<< "$args"
  fi

  # Parse CLI arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --*=*)
        local arg="${1#--}"
        local key="${arg%%=*}"
        local value="${arg#*=}"
        local var_name="SKILL_ARG_${key}"
        var_name="${var_name//-/_}"
        var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
        export "$var_name=$value"
        ;;
      --*)
        local key="${1#--}"
        shift
        local value="${1:-}"
        local var_name="SKILL_ARG_${key}"
        var_name="${var_name//-/_}"
        var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
        export "$var_name=$value"
        ;;
      *)
        # Positional arg - skip for now
        ;;
    esac
    shift
  done

  # Check required args
  if [ -n "$args" ]; then
    while IFS='|' read -r arg_name arg_desc arg_default arg_required; do
      if [ "$arg_required" = "true" ]; then
        local var_name="SKILL_ARG_${arg_name}"
        var_name="${var_name//-/_}"
        var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
        local value="${!var_name:-}"
        if [ -z "$value" ]; then
          echo "Error: Required argument --${arg_name} not provided" >&2
          return 1
        fi
      fi
    done <<< "$args"
  fi
}

# Substitute variables in skill prompt
# Replaces {{VAR}} with environment variable values
substitute_skill_vars() {
  local content="$1"

  # Standard variables
  content="${content//\{\{DOYAKEN_PROJECT\}\}/${DOYAKEN_PROJECT:-}}"
  content="${content//\{\{DOYAKEN_HOME\}\}/${DOYAKEN_HOME:-}}"
  content="${content//\{\{TIMESTAMP\}\}/$(date '+%Y-%m-%d %H:%M')}"

  # Git variables
  local git_remote=""
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.git" ]; then
    git_remote=$(git -C "$DOYAKEN_PROJECT" remote get-url origin 2>/dev/null || echo "")
  fi
  content="${content//\{\{GIT_REMOTE\}\}/$git_remote}"

  # Skill argument variables (ARGS.name)
  # Find all SKILL_ARG_* environment variables
  while IFS='=' read -r var_name var_value; do
    if [[ "$var_name" == SKILL_ARG_* ]]; then
      local arg_name="${var_name#SKILL_ARG_}"
      arg_name=$(echo "$arg_name" | tr '[:upper:]' '[:lower:]')
      arg_name="${arg_name//_/-}"
      content="${content//\{\{ARGS.$arg_name\}\}/$var_value}"
      # Also support uppercase
      local arg_name_upper
      arg_name_upper=$(echo "$arg_name" | tr '[:lower:]' '[:upper:]')
      content="${content//\{\{ARGS.$arg_name_upper\}\}/$var_value}"
    fi
  done < <(env | grep '^SKILL_ARG_')

  echo "$content"
}

# Check if required MCP servers are available
# Usage: check_skill_requirements <skill_file>
check_skill_requirements() {
  local skill_file="$1"
  local requires
  requires=$(get_skill_requires "$skill_file")

  [ -z "$requires" ] && return 0

  local missing=()
  while read -r req; do
    # Check if MCP server is configured
    # For now, just check if integration is enabled in manifest
    if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -f "$DOYAKEN_PROJECT/.doyaken/manifest.yaml" ]; then
      local enabled
      enabled=$(yq -e ".integrations.${req}.enabled // false" "$DOYAKEN_PROJECT/.doyaken/manifest.yaml" 2>/dev/null || echo "false")
      if [ "$enabled" != "true" ]; then
        missing+=("$req")
      fi
    else
      missing+=("$req")
    fi
  done <<< "$requires"

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing required integrations: ${missing[*]}" >&2
    echo "Enable them in .doyaken/manifest.yaml:" >&2
    for m in "${missing[@]}"; do
      echo "  integrations:" >&2
      echo "    $m:" >&2
      echo "      enabled: true" >&2
    done
    return 1
  fi

  return 0
}

# Run a skill
# Usage: run_skill <name> [args...]
run_skill() {
  local name="$1"
  shift

  local skill_file
  skill_file=$(find_skill "$name") || {
    echo "Skill not found: $name" >&2
    echo "Run 'doyaken skills' to see available skills" >&2
    return 1
  }

  echo "Running skill: $name"

  # Check requirements
  check_skill_requirements "$skill_file" || return 1

  # Parse arguments
  parse_skill_cli_args "$skill_file" "$@" || return 1

  # Build prompt
  local body
  body=$(get_skill_body "$skill_file")
  local prompt
  prompt=$(substitute_skill_vars "$body")

  # Include base prompt if available
  local base_prompt=""
  if [ -f "$DOYAKEN_HOME/prompts/library/base.md" ]; then
    base_prompt=$(cat "$DOYAKEN_HOME/prompts/library/base.md")
    prompt="$base_prompt

---

$prompt"
  fi

  # Run through agent
  # Source agents.sh if not already loaded
  if ! type agent_command &>/dev/null; then
    source "$DOYAKEN_HOME/lib/agents.sh"
  fi

  local agent="${DOYAKEN_AGENT:-claude}"
  local model="${DOYAKEN_MODEL:-}"

  echo "Using agent: $agent${model:+ ($model)}"
  echo ""

  # Build and run agent command
  local cmd
  cmd=$(agent_command "$agent")

  local args=()
  local tmp_args

  # Add autonomous mode args
  read -r -a tmp_args <<< "$(agent_autonomous_args "$agent")"
  args+=("${tmp_args[@]}")

  # Add model args if specified
  if [ -n "$model" ]; then
    read -r -a tmp_args <<< "$(agent_model_args "$agent" "$model")"
    args+=("${tmp_args[@]}")
  fi

  # For interactive skill runs (tty), don't use --print so output streams live
  # For non-interactive runs (piped/scripted), use --print for captured output
  if [ -t 1 ]; then
    # Interactive terminal - let agent run with live output (no --print)
    # Just add output format for text
    if [ "$agent" = "claude" ]; then
      args+=("--output-format" "text")
    fi
  else
    # Non-interactive - use verbose args which include --print
    local verbose_args
    verbose_args=$(agent_verbose_args "$agent")
    if [ -n "$verbose_args" ]; then
      read -r -a tmp_args <<< "$verbose_args"
      args+=("${tmp_args[@]}")
    fi
  fi

  # Add prompt
  local prompt_flag
  prompt_flag=$(agent_prompt_args "$agent" "$prompt")
  if [ -n "$prompt_flag" ]; then
    args+=("$prompt_flag" "$prompt")
  else
    # Agents that take prompt as positional arg
    args+=("$prompt")
  fi

  # Execute
  if [ "${AGENT_DRY_RUN:-0}" = "1" ]; then
    # Show command without full prompt (which can be very long)
    local display_args=()
    for arg in "${args[@]}"; do
      if [ "${#arg}" -gt 100 ]; then
        display_args+=("[prompt: ${#arg} chars]")
      else
        display_args+=("$arg")
      fi
    done
    echo "[DRY RUN] Would execute: $cmd ${display_args[*]}"
    return 0
  fi

  $cmd "${args[@]}"
}
