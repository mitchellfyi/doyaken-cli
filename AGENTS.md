# AGENTS.md

Instructions for AI coding agents working on the Doyaken codebase.

## What Is Doyaken

Doyaken is a standalone workflow automation framework for Claude Code. It provides autonomous ticket lifecycle management — from planning through PR merge — using worktree isolation, quality-gated phase execution, and codebase-agnostic skill discovery. It works with any repo after a one-time global install.

## Tech Stack

- **Shell (primary):** All CLI logic, hooks, and library code
  - `dk.sh` — **zsh-only** (sourced in `~/.zshrc`, uses zsh syntax like `${(j: :)@}`)
  - `hooks/*.sh` — **bash** (`#!/usr/bin/env bash`)
  - `lib/*.sh` — **bash/zsh-compatible** (sourced by both dk.sh and hooks)
- **Python 3 (stdlib only):** `hooks/guard-handler.py` — guard evaluation, no external dependencies
- **Markdown + YAML frontmatter:** Skills, agents, guards, prompts, rules

## Directory Structure

```
agents/              Sub-agents (symlinked to ~/.claude/agents/)
bin/                 CLI scripts (install, init, config, status, etc.)
docs/                Extended documentation (guards, autonomous mode)
hooks/               Claude Code hooks + guard handler
  guards/            Built-in guard rules (markdown with YAML frontmatter)
lib/                 Shared shell libraries (common, git, session, output, worktree)
prompts/             Prompt templates for skills/agents
  phase-audits/      Phase-specific audit prompts (1-6 + prompt-loop)
skills/              Lifecycle skills (symlinked to ~/.claude/skills/)
dk.sh                Main shell functions (zsh only, ~980 lines)
settings.json        Hook definitions template
install.sh           Quick-start installer (delegates to bin/install.sh)
```

Per-project (created by `dk init`):
```
.doyaken/
  doyaken.md         Project-specific config (tech stack, quality gates, integrations)
  CLAUDE.md          @import of doyaken.md (auto-discovered by Claude Code)
  rules/             Coding conventions (generated from codebase analysis)
  guards/            Project-specific guard rules (generated)
  worktrees/         Worktree directories (gitignored, ephemeral)
```

## Shell Conventions

### Language boundaries — this is critical

Never introduce zsh-only syntax in `lib/` or `hooks/`. Only `dk.sh` may use zsh features.

### Error handling

All scripts use `set -euo pipefail`. Use early returns, not deep nesting.

### Naming

- **Functions:** `dk_` prefix (public), `__dk_` prefix (internal), snake_case
- **Variables:** `local` for locals, `SCREAMING_SNAKE_CASE` with `DOYAKEN_` or `DK_` prefix for env vars
- **Files:** kebab-case for scripts and directories

### Library sourcing

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
```

Sourcing `common.sh` also sources `git.sh`, `session.sh`, `output.sh`, and `worktree.sh`.

### Output

Use `lib/output.sh` helpers (`dk_done`, `dk_ok`, `dk_warn`, `dk_skip`, `dk_info`, `dk_error`) for user-facing messages. Never raw `echo` for status output.

### Re-sourcing safety

In `dk.sh`, every function definition is preceded by `unalias <name> 2>/dev/null; unfunction <name> 2>/dev/null` so the file can be re-sourced without errors.

### Atomic file operations

When writing shared files (e.g., `~/.claude/settings.json`), use temp files + atomic `mv`.

### State files

All ephemeral state goes under `~/.claude/.doyaken-phases/` or `~/.claude/.doyaken-loops/`, keyed by session ID. Never store state inside the repo (except `.doyaken/worktrees/` which is gitignored).

## Skill Conventions

Each skill lives in `skills/<name>/SKILL.md` with markdown content (the YAML frontmatter is in the agent file, not skills).

- Directory naming: lowercase, `dk`-prefixed (`dkplan`, `dkimplement`, etc.)
- Exception: the orchestrator is `doyaken` (no prefix)
- Skills reference prompts via `@prompts/<file>.md` import syntax
- Skills are codebase-agnostic — they discover toolchains at runtime

### Vendor skills are NOT bundled

Doyaken does not ship third-party vendor skills (Figma, Asana, Linear, Notion, Slack, HubSpot, Microsoft 365, Gmail, Google Calendar, Fireflies, etc.). These are maintained by their vendors and distributed via Claude's official plugin/MCP integrations.

**Do not commit vendor skills into this repo.** If a vendor skill directory appears in `skills/` (e.g., `skills/figma-*/`), delete it — it was added by a Claude plugin install and should live in the user's `~/.claude/` or be enabled via the official integration, not in Doyaken.

When users need a vendor skill:

| Vendor | How to enable |
|--------|---------------|
| Figma  | <https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Dev-Mode-MCP-Server> |
| Linear | <https://linear.app/changelog/2025-05-01-mcp> |
| Asana, Notion, Slack, HubSpot, Microsoft 365, Gmail, Google Calendar, Fireflies | Enable the corresponding integration on <https://claude.ai/settings/connectors> |
| Other  | Browse the Claude plugin marketplace via `/plugin` inside Claude Code, or check the vendor's docs for their official MCP/skill integration |

The corresponding MCP servers are listed and authenticated through claude.ai or `claude mcp` — they show up as `mcp__claude_ai_<Vendor>__*` tools and are available to Doyaken's skills automatically when enabled.

## Agent Conventions

Agents live in `agents/*.md` with YAML frontmatter:

```yaml
---
name: agent-name
description: what it does
tools: Read, Glob, Grep, Bash    # allowed tools
model: opus                      # model selection
skills:
  - dkreview                      # skills it can invoke
memory: project                   # memory scope
---
```

## Guard Conventions

Guards are markdown files with YAML frontmatter in `hooks/guards/` (built-in) or `.doyaken/guards/` (project-specific).

```yaml
---
name: unique-guard-name
enabled: true
event: bash|file|commit|all
pattern: python-regex
action: warn|block
case_sensitive: false
---
```

- Patterns are Python regexes evaluated by `guard-handler.py`
- `block` exits with code 2 (prevents tool call). `warn` exits 0 (allows it).
- Frontmatter parser is regex-based — flat `key: value` only, no nested objects or arrays
- Built-in guards: `destructive-commands`, `sensitive-files`, `hardcoded-secrets` — don't duplicate these

## Prompt Conventions

Stored in `prompts/`. Referenced by skills/agents via `@prompts/<file>.md`.

- `guardrails.md` — Implementation discipline (shared across implement/review skills)
- `review.md` — 10-pass review criteria (A-J) with confidence scoring
- `commit-format.md` — Conventional Commits specification
- `pr-description.md` — PR description template
- `ticket-instructions.md` — Ticket intake workflow (injected by SessionStart hook)
- `init-analysis.md` — Codebase analysis prompt (used by `dk init`)
- `phase-audits/*.md` — Numbered 1-6 matching lifecycle phases, plus `prompt-loop.md`

## Key Architecture Concepts

### Hook integration

Four hooks defined in `settings.json`, referenced by paths to Doyaken scripts:

| Hook | Event | Script | Purpose |
|------|-------|--------|---------|
| SessionStart | Startup | `load-ticket-context.sh` | Load ticket context, detect focus areas |
| PreToolUse | Before Bash/Edit/Write | `guard-handler.py` | Block/warn on dangerous patterns |
| PostToolUse | After `git commit` | `post-commit-guard.sh` | Validate commit format via guards |
| Stop | Claude tries to stop | `phase-loop.sh` | Phase audit loop (when active) |

### Phase audit loops

When `DOYAKEN_LOOP_ACTIVE=1`, the Stop hook intercepts Claude's exit, injects a phase-specific audit prompt, and loops until a `.complete` signal file is written or max iterations (default 30) are reached.

### Session IDs

Derived from worktree names (`worktree-<name>`) or branch names (fallback). Used to key all state files. Path-based derivation makes them stable across branch renames.

### Worktree isolation

Each ticket gets its own git worktree in `.doyaken/worktrees/`. The `dk` shell function manages creation, cleanup, and resumption.

## Quality Gates

This project has no test suite, formatter, or unified check command. Linting is via `shellcheck` (if installed) on `dk.sh`, `bin/*.sh`, `hooks/*.sh`, `lib/*.sh`.

When modifying shell scripts, ensure they pass `shellcheck` if you have it available.

## Security Considerations

- Hooks run with the user's full permissions — treat all hook code as security-sensitive
- In `guard-handler.py`, pass subprocess arguments as lists, never `shell=True` with user input
- Exit code 2 means "block" in guards — other non-zero exits are errors, not blocks
- Never store secrets in state files or `settings.json`
- Session IDs are not cryptographically random — don't use them for authentication
- Keep guard patterns efficient — they run on every tool invocation

## Common Tasks

### Adding a new skill

1. Create `skills/<dkname>/SKILL.md`
2. Write the skill prompt as markdown
3. Reference shared prompts via `@prompts/<file>.md`
4. The symlink from `dk install` makes it available as `/<dkname>`

### Adding a new guard

1. Create a `.md` file in `hooks/guards/` (built-in) or `.doyaken/guards/` (project-specific)
2. Add YAML frontmatter with name, enabled, event, pattern, action
3. Write a human-readable message in the markdown body
4. Test the regex pattern against expected inputs

### Adding a new hook script

1. Create the script in `hooks/` with `#!/usr/bin/env bash`
2. Source common.sh: `source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"`
3. Add the hook definition to `settings.json`
4. Use `set -euo pipefail`

### Modifying dk.sh

1. This is zsh-only — zsh syntax is fine here
2. Prefix functions with `unalias/unfunction` guards for re-sourcing safety
3. After editing, users run `dk reload` to apply changes

### Adding a shared library function

1. Add to the appropriate file in `lib/` (`git.sh`, `session.sh`, `output.sh`, `worktree.sh`)
2. Or add a new `lib/<name>.sh` and source it from `common.sh`
3. Must be bash/zsh-compatible — no zsh-only syntax

### Modularizing large scripts

`dk.sh` is the largest file (~980 lines). When it grows further, extract shared logic into `lib/` modules. The pattern:

**When to extract:**
- Same logic appears in 2+ functions → extract to `lib/`
- A function exceeds ~50 lines of self-contained logic → candidate for library
- Logic is needed by both `dk.sh` (zsh) and `hooks/`/`bin/` (bash) → must go to `lib/`

**How to extract:**
1. Create or extend a `lib/<domain>.sh` file (e.g., `worktree.sh`, `session.sh`)
2. Source it from `lib/common.sh` (all scripts get it automatically)
3. Use `dk_` prefix for public functions, `__dk_` for internal
4. Replace inline code in callers with the new function call
5. Verify with `bash -n lib/<file>.sh` (bash compat) and `zsh -n dk.sh` (zsh syntax)

**Current library modules and their responsibilities:**

| Module | Purpose | Key functions |
|--------|---------|---------------|
| `common.sh` | Bootstrap, constants, sources all others | `dk_repo_root()` |
| `git.sh` | Git helpers | `dk_default_branch()`, `dk_slugify()` |
| `session.sh` | Session ID derivation, state file paths | `dk_session_id()`, `dk_cleanup_session()` |
| `output.sh` | Formatted user-facing output | `dk_done()`, `dk_ok()`, `dk_warn()`, `dk_error()`, etc. |
| `worktree.sh` | Worktree management utilities | `dk_wt_branch()`, `dk_wt_remove()`, `dk_cleanup_last_session()`, `dk_cleanup_stale_files()` |

**dk.sh internal structure** (sections in order, ~980 lines total):

| Lines | Section | Functions |
|-------|---------|-----------|
| 25-82 | CLI dispatcher | `doyaken()` |
| 84-118 | Phase config | Arrays: `DK_PHASE_NAMES`, `DK_PHASE_PROMISES`, `DK_PHASE_SKILLS` |
| 119-300 | Internal helpers | `__dk_is_ticket()`, `__dk_setup_worktree()`, `__dk_run_phases()` |
| 300-378 | Display helpers | `__dk_format_elapsed()`, `__dk_show_header()` |
| 380-492 | Phased lifecycle | `dk()` |
| 494-609 | Prompt loop | `dkloop()` |
| 611-779 | Worktree removal | `dkrm()` |
| 781-838 | Worktree listing | `dkls()` |
| 840-975 | Stale cleanup | `dkclean()` |

**Extraction candidates** if dk.sh grows past ~1000 lines:
- `__dk_run_phases()` + phase config → `lib/phases.sh` (but uses zsh syntax — would need refactoring to bash-compat, or keep as zsh-only `lib/phases.zsh`)
- `__dk_show_header()` + `__dk_format_elapsed()` → `lib/display.sh`

**What stays in dk.sh:** Functions that use zsh-specific syntax (`${(j: :)@}`, zsh arrays) or need `unalias/unfunction` re-sourcing guards. The public commands (`dk`, `dkloop`, `dkrm`, `dkls`, `dkclean`, `dkcomplete`, `dkreviewloop`, `doyaken`) must stay because they are shell functions loaded into the user's zsh session.

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `DOYAKEN_DIR` | Installation directory | `$HOME/work/doyaken` |
| `DK_STATE_DIR` | Phase state directory | `~/.claude/.doyaken-phases` |
| `DK_LOOP_DIR` | Loop state directory | `~/.claude/.doyaken-loops` |
| `DOYAKEN_LOOP_ACTIVE` | Enable phase audit loop | unset |
| `DOYAKEN_LOOP_PHASE` | Current phase (1-5 or "prompt-loop") | unset |
| `DOYAKEN_LOOP_PROMISE` | Completion signal string | unset |
| `DOYAKEN_LOOP_MAX_ITERATIONS` | Max loop iterations | 30 |
| `DOYAKEN_SESSION_ID` | Unique session ID (set by dkloop for stop hook) | unset |

## Files to Never Commit

- `.DS_Store`
- `__pycache__/`, `*.pyc`
- `.doyaken/worktrees/` (ephemeral)
- `~/.claude/settings.json` (user-specific)
- Anything containing secrets or credentials
