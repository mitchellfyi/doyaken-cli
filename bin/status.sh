#!/usr/bin/env bash
# doyaken status — show installation status
set -euo pipefail

source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
CLAUDE_DIR="$HOME/.claude"

echo "Doyaken — Status"
echo ""

# Global installation
echo "Global:"
if [[ -L "$CLAUDE_DIR/skills" ]]; then
  target=$(readlink "$CLAUDE_DIR/skills")
  if [[ "$target" == "$DOYAKEN_DIR/skills" ]]; then
    # Count only directories (each skill is a dir containing SKILL.md), not .DS_Store etc.
    count=$(find "$CLAUDE_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    echo "  Skills:    $count skills symlinked"
  else
    echo "  Skills:    WRONG TARGET ($target)"
  fi
else
  echo "  Skills:    NOT INSTALLED"
fi

if [[ -L "$CLAUDE_DIR/agents" ]]; then
  target=$(readlink "$CLAUDE_DIR/agents")
  if [[ "$target" == "$DOYAKEN_DIR/agents" ]]; then
    # Count only .md files (agent definitions), not .DS_Store or other artifacts
    count=$(find "$CLAUDE_DIR/agents" -mindepth 1 -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    echo "  Agents:    $count agent(s) symlinked"
  else
    echo "  Agents:    WRONG TARGET ($target)"
  fi
else
  echo "  Agents:    NOT INSTALLED"
fi

if grep -q 'doyaken/hooks' "$CLAUDE_DIR/settings.json" 2>/dev/null; then
  echo "  Hooks:     installed in ~/.claude/settings.json"
else
  echo "  Hooks:     NOT INSTALLED"
fi

if grep -q 'doyaken/dk.sh' "$HOME/.zshrc" 2>/dev/null; then
  echo "  Shell:     sourced in ~/.zshrc"
else
  echo "  Shell:     NOT INSTALLED"
fi

# Current project
echo ""
echo "Project:"
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$repo_root" ]]; then
  echo "  Not in a git repository"
else
  repo_name=$(basename "$repo_root")
  echo "  Repo:      $repo_name ($repo_root)"

  if [[ -f "$repo_root/.doyaken/doyaken.md" ]]; then
    echo "  Init:      yes (.doyaken/doyaken.md exists)"
  else
    echo "  Init:      no — run 'dk init'"
  fi

  worktrees_dir="$repo_root/.doyaken/worktrees"
  if [[ -d "$worktrees_dir" ]]; then
    count=$(find "$worktrees_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    echo "  Worktrees: $count active"
  else
    echo "  Worktrees: none"
  fi
fi

# Changes available immediately?
echo ""
echo "Live updates:"
echo "  Skills, hooks, rules, prompts → changes take effect immediately"
echo "  Shell functions (dk.sh)       → run 'dk reload' to apply"
