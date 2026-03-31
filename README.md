# Doyaken

Standalone workflow automation for Claude Code. Autonomous ticket lifecycle, worktree isolation, coding conventions — works with any repo.

## Quick Start

```bash
# One-time global install
bash ~/work/doyaken/install.sh
source ~/.zshrc

# Bootstrap a repo (analyzes codebase with Claude Code CLI)
cd ~/work/myproject
dk init

# Start work on a ticket
dk 999
```

## What needs `dk init`?

Most Doyaken features work immediately after `dk install` — no per-project setup required:

| Feature | Needs `dk init`? | Notes |
|---------|:---:|-------|
| `dkloop <prompt>` | No | Works in any git repo |
| `/dkloop`, `/dkplan`, `/dkimplement`, etc. | No | Skills work in any Claude Code session |
| Hooks (guards, commit validation, ticket context) | No | Installed globally by `dk install` |
| Agents (self-reviewer) | No | Symlinked globally by `dk install` |
| `dk <number>` / `dk "description"` | No | Worktrees work in any git repo |

**What `dk init` adds:** It runs Claude Code CLI to analyze your specific codebase and generates project-tailored configuration in `.doyaken/`:

- **Quality gates** (`doyaken.md`) — discovers your format, lint, typecheck, and test commands from package.json, Makefile, CI config, etc. Without init, skills discover these at runtime (slower, may miss non-obvious commands).
- **Coding conventions** (`rules/`) — generates rule files from observed patterns (naming, file structure, error handling). Without init, Claude infers conventions from context each time.
- **Project-specific guards** (`guards/`) — creates guards for files that should never be committed (environment files, generated configs). Without init, only the universal guards (destructive commands, secrets, sensitive files) are active.
- **Integration config** — configures ticket tracker (Linear, GitHub Issues), Figma, Sentry, etc. Without init, skills skip tracker updates.

In short: everything works without init, but init makes it faster and more accurate by caching project knowledge.

## Commands

```bash
# Global
dk install           # Symlink skills + agents, add hooks, source shell functions
dk uninstall         # Reverse everything install did
dk status            # Show what's installed and where

# Per-project
dk init              # Bootstrap current repo — analyzes codebase, generates config
dk config            # Configure integrations (ticket tracker, Figma, Sentry, etc.)
dk uninit            # Remove Doyaken from current repo

# Worktrees
dk <number>          # Create worktree, start Claude with ticket context
dk "<description>"   # Create worktree for a task (no ticket)
dk --resume          # Resume a previous session
dkrm <number|name>  # Remove worktree
dkrm --all          # Remove all worktrees
dkls                # List active worktrees
dkclean             # Prune stale worktrees, gone branches, orphan branches

# Prompt loop (no worktree or ticket needed)
dkloop <prompt>     # Run a prompt until fully implemented (from terminal)
/dkloop <prompt>    # Same, but from inside an existing Claude Code session

# Maintenance
dk reload            # Reload shell functions after editing dk.sh
```

## Structure

```
doyaken/
  agents/                    # Sub-agents -> symlinked to ~/.claude/agents/
    self-reviewer.md         # Read-only code reviewer with persistent memory
  bin/                       # CLI scripts
    install.sh               # Global install
    uninstall.sh             # Global uninstall
    init.sh                  # Per-project bootstrap (uses Claude Code CLI)
    uninit.sh                # Per-project removal
    config.sh                # Integration configuration (ticket tracker, Figma, etc.)
    status.sh                # Show installation status
  docs/                      # Extended documentation
    guards.md                # Guard system (hookify-style rules)
    autonomous-mode.md       # Phase audit loops and autonomous execution
  skills/                    # Lifecycle skills -> symlinked to ~/.claude/skills/
                             # Each skill is a directory containing SKILL.md
    doyaken/                 # Orchestrate full ticket lifecycle
    dkplan/                  # Implementation planning (multi-approach)
    dkimplement/             # TDD implementation with self-review
    dkreview/                # Four-phase agentic review with confidence scoring
    dkverify/                # Discover and run project quality gates
    dkcommit/                # Atomic conventional commits
    dkpr/                    # PR description, reviews, monitoring
    dkwatchci/              # CI monitoring via /loop
    dkwatchpr/              # PR review monitoring via /loop
    dkprreview/              # Critically evaluate and address PR review comments
    dkcomplete/              # Final verification, ticket closure
    dkloop/                  # In-session prompt loop (run until done)
  lib/                       # Shared shell library (sourced by dk.sh and hook scripts)
    common.sh                # Constants, bootstrap (sources other lib files)
    git.sh                   # Git helpers (default branch detection, slugify)
    session.sh               # Session ID and state file path helpers
    output.sh                # Formatted output ([done], [ok], [warn], etc.)
  hooks/                     # Hook scripts (referenced from ~/.claude/settings.json)
    load-ticket-context.sh   # SessionStart — ticket context + focus area detection
    post-commit-guard.sh     # PostToolUse — commit validation via guards
    guard-handler.py         # PreToolUse — markdown-based guard evaluation
    phase-loop.sh            # Stop — phase audit loop (quality-gated execution)
    guards/                  # Markdown guard rules (universal)
      destructive-commands.md
      sensitive-files.md
      hardcoded-secrets.md
  prompts/                   # Prompts referenced by skills and agents
    review.md                # 10-pass review criteria + confidence scoring
    guardrails.md            # AI discipline + implementation principles (referenced by skills)
    pr-description.md        # PR description template
    commit-format.md         # Conventional commit format + grouping rules
    ticket-instructions.md   # Ticket intake workflow (injected by SessionStart hook)
    init-analysis.md         # Codebase analysis prompt (used by dk init)
    phase-audits/            # Phase-specific audit prompts (injected by Stop hook)
      1-plan.md              # Plan quality audit
      2-implement.md         # Implementation audit (loops until PASS)
      3-verify.md            # Verification + commit audit
      4-pr.md                # PR quality audit
      5-complete.md          # Completion criteria audit
      prompt-loop.md         # Prompt loop audit (used by dkloop)
  dk.sh                      # Shell functions (dk, dkrm, dkls, dkclean, dkloop, doyaken)
  install.sh                 # Quick-start installer (delegates to bin/install.sh)
  settings.json              # Hook definitions template
```

### Per-project structure (created by `dk init`)

```
.doyaken/
  doyaken.md                 # Project-specific config (generated by Claude Code CLI)
  CLAUDE.md                  # @import of doyaken.md (auto-discovered by Claude Code)
  rules/                     # Coding conventions (generated from codebase analysis)
  guards/                    # Project-specific guard rules (generated)
  worktrees/                 # Worktree directories (created by dk)
```

Claude Code automatically discovers `CLAUDE.md` files in the project directory and all subdirectories (see [Claude Code docs: CLAUDE.md](https://docs.anthropic.com/en/docs/claude-code/memory#claudemd)). `.doyaken/CLAUDE.md` uses the `@doyaken.md` import directive to pull in the generated project config, so Claude sees it as part of the project context in every session.

## How It Works

### Init (codebase analysis)

`dk init` creates a `.doyaken/` directory, then uses **Claude Code CLI** to analyze the codebase and generate project-specific configuration:

- **Quality gates** — discovers format, lint, typecheck, test commands from package.json, Makefile, CI config
- **Coding conventions** — generates rule files from observed patterns in the codebase
- **Guards** — creates guards for files that should never be committed (environment files, generated configs)
- **Integrations** — asks which integrations to use (ticket tracker, Figma, Sentry, Vercel, Grafana)

Flags:
- `--skip-analysis` — skip codebase analysis (still runs integration config unless `--skip-config` is also set)
- `--skip-config` — skip integration configuration (run `dk config` later)

To reconfigure integrations at any time: `dk config`

### Skills (immediate updates)

Skills are symlinked: `~/.claude/skills/ -> ~/work/doyaken/skills/`. Claude Code auto-discovers them as slash commands (`/doyaken`, `/dkplan`, etc.). Edit a skill file — change takes effect in the next Claude invocation.

All skills are **codebase-agnostic**. They discover the project's toolchain, conventions, and quality gates from the codebase itself rather than prescribing specific commands.

### Agents (immediate updates)

Agents are symlinked: `~/.claude/agents/ -> ~/work/doyaken/agents/`. Claude Code auto-discovers them and delegates tasks based on their descriptions.

### Hooks (immediate updates)

Hooks are defined in `~/.claude/settings.json` with paths to Doyaken scripts (see [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)). Four hook types:

| Hook | Event | Script | Purpose |
|------|-------|--------|---------|
| SessionStart | Session begins | `load-ticket-context.sh` | Load ticket context, detect focus areas |
| PreToolUse | Before Bash/Edit/Write | `guard-handler.py` | Block/warn on dangerous patterns |
| PostToolUse | After Bash (git commit) | `post-commit-guard.sh` | Validate commits via guards |
| Stop | Claude tries to stop | `phase-loop.sh` | Phase audit loop (when active) |

### Guards (immediate updates)

Markdown files with YAML frontmatter. Universal guards (destructive commands, sensitive files, hardcoded secrets) ship with Doyaken in `hooks/guards/`. Project-specific guards are generated during `dk init` in `.doyaken/guards/`. See [docs/guards.md](docs/guards.md).

### Shell Functions (reload needed)

`dk.sh` defines `dk`, `dkrm`, `dkls`, `dkclean`, `dkloop`, and `doyaken`. After editing, run `dk reload` to apply.

## Ticket Lifecycle

Run `/doyaken` inside a worktree to kick off the full autonomous workflow:

| Phase | Skills | What Happens | User Action |
|-------|--------|-------------|-------------|
| 1. Plan | `/dkplan` | Reads ticket, explores code, presents 2-3 approaches, drafts plan | Approve plan |
| 2. Implement | `/dkimplement` + `/dkreview` | TDD per task, audit loop until PASS with zero findings | Clarify if needed |
| 3. Verify & Commit | `/dkverify` + `/dkcommit` | Quality gates, atomic conventional commits, push | — |
| 4. PR | `/dkpr` | PR description, update tracker | Approve to mark ready |
| 5. Complete | `/dkwatchci` + `/dkwatchpr` + `/dkcomplete` | Monitor CI/reviews, update tracker, print summary | Escalations only |

### Autonomous Mode

When started via `dk` (number or string), a phase audit loop is active. The Stop hook prevents Claude from stopping prematurely and injects a phase-specific audit prompt that critically reviews the work done. The loop continues until:

- **Completion promise** (`DOYAKEN_TICKET_COMPLETE`) is output — all tasks done, PR merged/approved, checks green
- **Max iterations** (default 30) reached — safety net for cost control
- **User interrupts** — always possible

Claude still escalates to the user for: secrets scan failures, architectural review comments, 3+ failed fix attempts, and scope changes. See [docs/autonomous-mode.md](docs/autonomous-mode.md).

## Confidence Scoring

Self-review findings include a confidence score (0-100). Only findings scoring >= 50 are reported:

| Score | Meaning |
|-------|---------|
| 90-100 | Certain — verifiable bug, missing guard |
| 75-89 | Highly confident — real issue with evidence |
| 50-74 | Moderately confident — likely issue |
| 0-49 | Filtered out — noise, pre-existing, or linter territory |

## Adding a New Project

1. `cd` into the repo
2. `dk init` — analyzes the codebase and generates `.doyaken/` config
3. Review the generated config in `.doyaken/` — edit rules and guards as needed
4. Commit `.doyaken/` to the repo (worktree artifacts are gitignored)

To re-run codebase analysis after significant changes:
```bash
claude -p "$(cat $DOYAKEN_DIR/prompts/init-analysis.md)"
```

## Configuration

### Environment

`DOYAKEN_DIR` — Override the install location (default: `$HOME/work/doyaken`). Set before running install or sourcing dk.sh.

### Guards

Project-specific guards are generated during `dk init` in `.doyaken/guards/`. You can also add guards manually — see [docs/guards.md](docs/guards.md) for the format and examples.

### Autonomous mode

Control via environment variables:
- `DOYAKEN_LOOP_ACTIVE=1` — Enable the phase audit loop (set automatically by `dk`)
- `DOYAKEN_LOOP_MAX_ITERATIONS=30` — Max iterations before forced stop
- `DOYAKEN_LOOP_PROMISE=DOYAKEN_TICKET_COMPLETE` — Completion signal string
