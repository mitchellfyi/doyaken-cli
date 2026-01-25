#!/usr/bin/env bash
#
# skills.sh - Skills management for doyaken
#
# Skills are markdown prompts with YAML frontmatter that declare
# their tool requirements and can be run standalone or hooked into phases.
#

set -euo pipefail

# Skills search paths (project first, then global)
get_skill_paths() {
  local paths=()

  # Project-specific skills
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken/skills" ]; then
    paths+=("$DOYAKEN_PROJECT/.doyaken/skills")
  fi

  # Global skills (shipped with doyaken)
  if [ -d "$DOYAKEN_HOME/skills" ]; then
    paths+=("$DOYAKEN_HOME/skills")
  fi

  printf '%s\n' "${paths[@]}"
}

# Find skill file by name
# Returns the full path to the skill file, or empty if not found
find_skill() {
  local name="$1"

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
# Output format: name|description|location
list_skills() {
  local shown=()

  while IFS= read -r dir; do
    [ -d "$dir" ] || continue

    for skill_file in "$dir"/*.md; do
      [ -f "$skill_file" ] || continue

      local name
      name=$(basename "$skill_file" .md)

      # Skip if we've already shown this skill (project overrides global)
      local already_shown=false
      for s in "${shown[@]:-}"; do
        [ "$s" = "$name" ] && already_shown=true && break
      done
      [ "$already_shown" = true ] && continue

      shown+=("$name")

      local desc
      desc=$(get_skill_description "$skill_file")
      [ -z "$desc" ] && desc="No description"

      local location="global"
      [[ "$dir" == *"/.doyaken/skills" ]] && location="project"

      echo "${name}|${desc}|${location}"
    done
  done < <(get_skill_paths)
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
      content="${content//\{\{ARGS.${arg_name^^}\}\}/$var_value}"
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
  read -r -a tmp_args <<< "$(agent_autonomous_args "$agent")"
  args+=("${tmp_args[@]}")
  if [ -n "$model" ]; then
    read -r -a tmp_args <<< "$(agent_model_args "$agent" "$model")"
    args+=("${tmp_args[@]}")
  fi
  read -r -a tmp_args <<< "$(agent_prompt_args "$agent" "$prompt")"
  args+=("${tmp_args[@]}")

  # Execute
  if [ "${AGENT_DRY_RUN:-0}" = "1" ]; then
    echo "[DRY RUN] Would execute: $cmd ${args[*]}"
    return 0
  fi

  $cmd "${args[@]}"
}
