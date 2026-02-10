#!/usr/bin/env bash
#
# sessions.sh - Session lifecycle management for doyaken
#
# Provides save, resume, fork, list, export, and delete for chat sessions.
# Sessions are stored in .doyaken/sessions/<id>/ with:
#   meta.yaml    — session metadata
#   messages.jsonl — conversation log
#   context.md   — accumulated context for resume
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_SESSIONS_LOADED:-}" ]] && return 0
_DOYAKEN_SESSIONS_LOADED=1

# ============================================================================
# Session Directory Resolution
# ============================================================================

# Get the sessions root directory
_sessions_root() {
  if [ -n "${DOYAKEN_DIR:-}" ] && [ -d "$DOYAKEN_DIR" ]; then
    echo "$DOYAKEN_DIR/sessions"
  elif [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken" ]; then
    echo "$DOYAKEN_PROJECT/.doyaken/sessions"
  else
    echo "${DOYAKEN_HOME:-$HOME/.doyaken}/sessions"
  fi
}

# ============================================================================
# Session Metadata
# ============================================================================

# Save session metadata to meta.yaml
# Usage: session_save_meta <session_dir> <session_id> <status> [tag]
session_save_meta() {
  local session_dir="$1"
  local session_id="$2"
  local status="$3"
  local tag="${4:-}"

  local meta_file="$session_dir/meta.yaml"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Read existing created time or use now
  local created="$now"
  if [ -f "$meta_file" ]; then
    local existing_created
    existing_created=$(grep '^created:' "$meta_file" 2>/dev/null | sed 's/^created:[[:space:]]*//' | tr -d '"' || echo "")
    [ -n "$existing_created" ] && created="$existing_created"
  fi

  # Count messages
  local msg_count=0
  if [ -f "$session_dir/messages.jsonl" ]; then
    msg_count=$(wc -l < "$session_dir/messages.jsonl" | tr -d ' ')
  fi

  cat > "$meta_file" << EOF
id: "$session_id"
created: "$created"
updated: "$now"
status: "$status"
tag: "${tag}"
agent: "${DOYAKEN_AGENT:-claude}"
model: "${DOYAKEN_MODEL:-}"
task: "${CHAT_CURRENT_TASK:-}"
messages: $msg_count
project: "$(basename "${DOYAKEN_PROJECT:-unknown}")"
EOF
}

# Read a field from session meta.yaml
# Usage: session_read_meta <session_dir> <field>
session_read_meta() {
  local session_dir="$1"
  local field="$2"
  local meta_file="$session_dir/meta.yaml"

  if [ ! -f "$meta_file" ]; then
    return 1
  fi

  grep "^${field}:" "$meta_file" 2>/dev/null | sed "s/^${field}:[[:space:]]*//" | tr -d '"'
}

# ============================================================================
# Session Save / Resume
# ============================================================================

# Save the current session
# Usage: session_save [tag]
session_save() {
  local tag="${1:-}"

  if [ -z "${CHAT_SESSION_ID:-}" ] || [ -z "${CHAT_SESSION_DIR:-}" ]; then
    echo "No active session"
    return 1
  fi

  mkdir -p "$CHAT_SESSION_DIR"
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved" "$tag"

  # Save context summary if messages exist
  if [ -f "$CHAT_MESSAGES_FILE" ]; then
    _generate_context_summary "$CHAT_SESSION_DIR"
  fi

  return 0
}

# Generate a simple context.md from messages
_generate_context_summary() {
  local session_dir="$1"
  local context_file="$session_dir/context.md"
  local messages_file="$session_dir/messages.jsonl"

  [ ! -f "$messages_file" ] && return 0

  local msg_count
  msg_count=$(wc -l < "$messages_file" | tr -d ' ')

  {
    echo "# Session Context"
    echo ""
    echo "Messages: $msg_count"
    echo "Agent: ${DOYAKEN_AGENT:-claude}"
    [ -n "${CHAT_CURRENT_TASK:-}" ] && echo "Task: $CHAT_CURRENT_TASK"
    echo "Updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo ""
    echo "## Recent Messages"
    echo ""
    # Include last few user messages as context
    grep '"role":"user"' "$messages_file" 2>/dev/null | tail -5 | while IFS= read -r line; do
      local content
      content=$(echo "$line" | sed 's/.*"content":"\([^"]*\)".*/\1/' | head -c 200)
      echo "- $content"
    done
  } > "$context_file"
}

# Resume a session by ID
# Usage: session_resume [session_id]
# If no ID given, resumes the most recent saved session
session_resume() {
  local target_id="${1:-}"
  local sessions_root
  sessions_root=$(_sessions_root)

  if [ ! -d "$sessions_root" ]; then
    echo "No sessions found"
    return 1
  fi

  local target_dir=""

  if [ -n "$target_id" ]; then
    # Find session by ID (exact or partial match)
    for dir in "$sessions_root"/*/; do
      [ -d "$dir" ] || continue
      local dir_name
      dir_name=$(basename "$dir")
      if [ "$dir_name" = "$target_id" ] || [[ "$dir_name" == *"$target_id"* ]]; then
        target_dir="$dir"
        break
      fi
    done
  else
    # Find most recent session with status "saved"
    local latest_time=""
    for dir in "$sessions_root"/*/; do
      [ -d "$dir" ] || continue
      [ -f "$dir/meta.yaml" ] || continue
      local status
      status=$(session_read_meta "$dir" "status")
      [ "$status" != "saved" ] && [ "$status" != "interrupted" ] && continue
      local updated
      updated=$(session_read_meta "$dir" "updated")
      if [ -z "$latest_time" ] || [[ "$updated" > "$latest_time" ]]; then
        latest_time="$updated"
        target_dir="$dir"
      fi
    done
  fi

  if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
    echo "Session not found${target_id:+: $target_id}"
    return 1
  fi

  # Load session state
  CHAT_SESSION_ID=$(session_read_meta "$target_dir" "id")
  CHAT_SESSION_DIR="$target_dir"
  CHAT_MESSAGES_FILE="$target_dir/messages.jsonl"
  CHAT_CURRENT_TASK=$(session_read_meta "$target_dir" "task")

  # Update status
  session_save_meta "$target_dir" "$CHAT_SESSION_ID" "active"

  return 0
}

# Get resume context for the agent
session_get_resume_context() {
  if [ -z "${CHAT_SESSION_DIR:-}" ]; then
    return 1
  fi

  local context_file="$CHAT_SESSION_DIR/context.md"
  if [ -f "$context_file" ]; then
    cat "$context_file"
  fi
}

# ============================================================================
# Session Fork
# ============================================================================

# Fork a session into a new independent session
# Usage: session_fork [source_id]
session_fork() {
  local source_id="${1:-$CHAT_SESSION_ID}"
  local sessions_root
  sessions_root=$(_sessions_root)

  # Find source session
  local source_dir=""
  for dir in "$sessions_root"/*/; do
    [ -d "$dir" ] || continue
    local dir_name
    dir_name=$(basename "$dir")
    if [ "$dir_name" = "$source_id" ] || [[ "$dir_name" == *"$source_id"* ]]; then
      source_dir="$dir"
      break
    fi
  done

  if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
    echo "Source session not found: $source_id"
    return 1
  fi

  # Create new session with unique ID
  local new_id
  new_id="$(date '+%Y%m%d-%H%M%S')-$$-$RANDOM"
  local new_dir="$sessions_root/$new_id"
  mkdir -p "$new_dir"
  chmod 700 "$new_dir"

  # Copy messages and context
  [ -f "$source_dir/messages.jsonl" ] && cp "$source_dir/messages.jsonl" "$new_dir/"
  [ -f "$source_dir/context.md" ] && cp "$source_dir/context.md" "$new_dir/"

  # Write new metadata
  CHAT_SESSION_ID="$new_id"
  CHAT_SESSION_DIR="$new_dir"
  CHAT_MESSAGES_FILE="$new_dir/messages.jsonl"

  # Preserve task from source
  local source_task
  source_task=$(session_read_meta "$source_dir" "task")
  CHAT_CURRENT_TASK="${source_task:-$CHAT_CURRENT_TASK}"

  session_save_meta "$new_dir" "$new_id" "active"

  echo "$new_id"
}

# ============================================================================
# Session List / Export / Delete
# ============================================================================

# List all sessions
# Usage: session_list [limit]
session_list() {
  local limit="${1:-10}"
  local sessions_root
  sessions_root=$(_sessions_root)

  if [ ! -d "$sessions_root" ]; then
    echo "No sessions found"
    return 0
  fi

  local count=0
  # Sort by directory name (which contains timestamp) in reverse
  for dir in $(find "$sessions_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r); do
    [ -f "$dir/meta.yaml" ] || continue
    (( count >= limit )) && break

    local id status updated task tag msgs
    id=$(session_read_meta "$dir" "id")
    status=$(session_read_meta "$dir" "status")
    updated=$(session_read_meta "$dir" "updated")
    task=$(session_read_meta "$dir" "task")
    tag=$(session_read_meta "$dir" "tag")
    msgs=$(session_read_meta "$dir" "messages")

    # Format status with color
    local status_color
    case "$status" in
      active)      status_color="${GREEN}active${NC}" ;;
      saved)       status_color="${CYAN}saved${NC}" ;;
      interrupted) status_color="${YELLOW}interrupted${NC}" ;;
      *)           status_color="${DIM}$status${NC}" ;;
    esac

    # Truncate updated to just date+time
    local short_date
    short_date=$(echo "$updated" | sed 's/T/ /; s/Z//' | cut -c1-16)

    printf "  %-24s %b  %-4s msgs  %s" "$id" "$status_color" "$msgs" "$short_date"
    [ -n "$task" ] && printf "  ${DIM}%s${NC}" "$task"
    [ -n "$tag" ] && printf "  ${CYAN}[%s]${NC}" "$tag"
    echo ""

    count=$((count + 1))
  done

  if [ "$count" -eq 0 ]; then
    echo "No sessions found"
  fi
}

# Export a session as markdown
# Usage: session_export [session_id]
session_export() {
  local target_id="${1:-$CHAT_SESSION_ID}"
  local sessions_root
  sessions_root=$(_sessions_root)

  local target_dir=""
  for dir in "$sessions_root"/*/; do
    [ -d "$dir" ] || continue
    local dir_name
    dir_name=$(basename "$dir")
    if [ "$dir_name" = "$target_id" ] || [[ "$dir_name" == *"$target_id"* ]]; then
      target_dir="$dir"
      break
    fi
  done

  if [ -z "$target_dir" ]; then
    echo "Session not found: $target_id"
    return 1
  fi

  # Build markdown
  local id agent task
  id=$(session_read_meta "$target_dir" "id")
  agent=$(session_read_meta "$target_dir" "agent")
  task=$(session_read_meta "$target_dir" "task")

  echo "# Session: $id"
  echo ""
  echo "Agent: $agent"
  [ -n "$task" ] && echo "Task: $task"
  echo ""
  echo "---"
  echo ""

  # Format messages
  if [ -f "$target_dir/messages.jsonl" ]; then
    while IFS= read -r line; do
      local role content
      role=$(echo "$line" | sed 's/.*"role":"\([^"]*\)".*/\1/')
      content=$(echo "$line" | sed 's/.*"content":"\([^"]*\)".*/\1/')
      if [ "$role" = "user" ]; then
        echo "## User"
        echo ""
        echo "$content"
        echo ""
      else
        echo "## Assistant"
        echo ""
        echo "$content"
        echo ""
      fi
    done < "$target_dir/messages.jsonl"
  fi
}

# Delete a session
# Usage: session_delete <session_id>
session_delete() {
  local target_id="$1"
  local sessions_root
  sessions_root=$(_sessions_root)

  if [ -z "$target_id" ]; then
    echo "Session ID required"
    return 1
  fi

  local target_dir=""
  for dir in "$sessions_root"/*/; do
    [ -d "$dir" ] || continue
    local dir_name
    dir_name=$(basename "$dir")
    if [ "$dir_name" = "$target_id" ] || [[ "$dir_name" == *"$target_id"* ]]; then
      target_dir="$dir"
      break
    fi
  done

  if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
    echo "Session not found: $target_id"
    return 1
  fi

  # Don't delete active session
  if [ "$target_id" = "${CHAT_SESSION_ID:-}" ]; then
    echo "Cannot delete active session"
    return 1
  fi

  rm -rf "$target_dir"
  return 0
}
