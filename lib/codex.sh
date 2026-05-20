# shellcheck shell=bash
# Dex helpers for Codex CLI integration.

dx_codex_skills_dir() {
  printf '%s\n' "${CODEX_HOME:-$HOME/.codex}/skills"
}

dx_count_dex_skills() {
  local count=0
  local skill_dir
  for skill_dir in "$DEX_DIR"/skills/*; do
    [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue
    count=$((count + 1))
  done
  printf '%s\n' "$count"
}

dx_codex_skill_link_repairable() {
  local current="$1" skill_name="$2"
  case "$current" in
    */dex*/skills/"$skill_name"|*/dex*/skills/"$skill_name"/) return 0 ;;
    *) return 1 ;;
  esac
}

dx_remove_legacy_codex_skill_links() {
  local codex_dir="$1"
  [[ -d "$codex_dir" ]] || return 0

  local removed=0
  local target current skill_name
  while IFS= read -r target; do
    [[ -L "$target" ]] || continue
    skill_name=$(basename "$target")
    current=$(readlink "$target")
    case "$skill_name:$current" in
      dk*:*/doyaken*/skills/*|doyaken:*/doyaken*/skills/*)
        if rm "$target"; then
          removed=$((removed + 1))
        fi
        ;;
    esac
  done < <(find "$codex_dir" -mindepth 1 -maxdepth 1 -type l 2>/dev/null)

  if [[ $removed -gt 0 ]]; then
    dx_done "Removed ${removed} legacy Doyaken Codex skill link(s)"
  fi
}

dx_install_codex_skills() {
  local codex_dir
  codex_dir=$(dx_codex_skills_dir)
  if ! mkdir -p "$codex_dir"; then
    dx_warn "Could not create ${codex_dir}; skipping Codex skill links"
    return 1
  fi

  dx_remove_legacy_codex_skill_links "$codex_dir"

  local installed=0
  local expected=0
  local failed=0
  local repaired=0
  local skipped=0
  local skill_dir skill_name target current
  for skill_dir in "$DEX_DIR"/skills/*; do
    [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue
    expected=$((expected + 1))
    skill_name=$(basename "$skill_dir")
    target="$codex_dir/$skill_name"

    if [[ -L "$target" ]]; then
      current=$(readlink "$target")
      if [[ "$current" == "$skill_dir" ]]; then
        installed=$((installed + 1))
      elif dx_codex_skill_link_repairable "$current" "$skill_name"; then
        if rm "$target" && ln -s "$skill_dir" "$target"; then
          installed=$((installed + 1))
          repaired=$((repaired + 1))
        else
          failed=$((failed + 1))
        fi
      else
        dx_warn "${codex_dir}/${skill_name} is a symlink to ${current} — leaving it unchanged"
        skipped=$((skipped + 1))
      fi
    elif [[ -e "$target" ]]; then
      dx_warn "${codex_dir}/${skill_name} exists and is not a symlink — leaving it unchanged"
      skipped=$((skipped + 1))
    else
      if ln -s "$skill_dir" "$target"; then
        installed=$((installed + 1))
      else
        failed=$((failed + 1))
      fi
    fi
  done

  if [[ $failed -gt 0 || $skipped -gt 0 || $installed -ne $expected ]]; then
    dx_warn "Installed ${installed}/${expected} Codex skill link(s); repaired ${repaired}; skipped ${skipped}; failed ${failed}"
    return 1
  else
    dx_done "Installed ${installed}/${expected} Dex skill link(s) for Codex CLI"
  fi
}

dx_count_codex_dex_skills() {
  local codex_dir
  codex_dir=$(dx_codex_skills_dir)
  [[ -d "$codex_dir" ]] || {
    printf '%s\n' "0"
    return 0
  }

  local count=0
  local skill_dir skill_name target current
  for skill_dir in "$DEX_DIR"/skills/*; do
    [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue
    skill_name=$(basename "$skill_dir")
    target="$codex_dir/$skill_name"
    if [[ -L "$target" ]]; then
      current=$(readlink "$target")
      [[ "$current" == "$skill_dir" ]] && count=$((count + 1))
    fi
  done
  printf '%s\n' "$count"
}

dx_codex_dex_skills_complete() {
  local expected installed
  expected=$(dx_count_dex_skills)
  installed=$(dx_count_codex_dex_skills)
  [[ "$expected" -gt 0 && "$installed" -eq "$expected" ]]
}

dx_uninstall_codex_skills() {
  local codex_dir
  codex_dir=$(dx_codex_skills_dir)
  [[ -d "$codex_dir" ]] || {
    dx_skip "${codex_dir} does not exist"
    return 0
  }

  local removed=0
  local failed=0
  local target current skill_name
  while IFS= read -r target; do
    current=$(readlink "$target")
    skill_name=$(basename "$target")
    if [[ "$current" == "$DEX_DIR"/skills/* ]] || dx_codex_skill_link_repairable "$current" "$skill_name"; then
      if [[ -e "$current" ]] && [[ ! -d "$current" ]]; then
        continue
      fi
        if rm "$target"; then
          removed=$((removed + 1))
        else
          dx_warn "Could not remove ${target}"
          failed=$((failed + 1))
        fi
    fi
  done < <(find "$codex_dir" -mindepth 1 -maxdepth 1 -type l 2>/dev/null)

  if [[ $failed -gt 0 ]]; then
    dx_warn "Removed ${removed} Dex Codex skill link(s); failed ${failed}"
    return 1
  elif [[ $removed -gt 0 ]]; then
    dx_done "Removed ${removed} Dex Codex skill link(s)"
  else
    dx_skip "No Dex Codex skill links found"
  fi
}
