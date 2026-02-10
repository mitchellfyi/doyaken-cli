# Interactive Mode & Competitor Analysis Research

## Date: 2026-02-06

## Executive Summary

Doyaken currently runs as a **batch-mode autonomous executor** — it picks up tasks, runs 8 phases sequentially, and exits. There is no interactive chat, no mid-task human intervention, no undo/revert, and no pause/resume beyond Ctrl+C interrupt recovery. Every major competitor now offers rich interactive modes. Adding interactive capabilities would make doyaken competitive as both an autonomous runner AND an interactive planning/execution companion.

---

## Competitor Analysis

### Claude Code (Anthropic)
- **Interactive mode**: Full REPL chat with streaming responses
- **Plan mode**: Read-only exploration mode, generates markdown plan files, user approves before execution
- **Slash commands**: /help, /clear, /compact, /review, /init, /doctor, /commit
- **Permissions**: 3-tier (default, acceptEdits, bypassPermissions) — user approves/denies each tool use
- **Subagents**: Background/foreground agents with isolated context, resumable by ID
- **Session management**: Persistent sessions, auto-compaction at 95% context, resumable across restarts
- **Undo**: Git-based via diff tracking
- **Skills system**: Reusable prompt modules loaded on-demand (similar to doyaken's prompts library)
- **Hooks**: PreToolUse/PostToolUse lifecycle hooks for validation
- **Key UX pattern**: AskUserQuestion tool for mid-task clarification

### OpenCode (Open Source - Go/Bubble Tea)
- **TUI**: Rich terminal UI with split panes (messages, editor, sidebar)
- **Client-server architecture**: TUI is just one client of an HTTP server (headless mode)
- **Session management**: SQLite persistence, lazy session creation, auto-compaction at 95%
- **Agents**: Build (full access), Plan (read-only), General (subagent), Explore (read-only subagent)
- **Undo/Redo**: `/undo` and `/redo` revert messages AND file changes via Git
- **Slash commands**: /sessions, /new, /compact, /export, /share, /undo, /redo, /models, /themes, /connect, /editor, /details, /thinking
- **Permission model**: Allow/Deny/Ask per tool (dialog overlay)
- **Skills**: SKILL.md files loaded on-demand
- **Provider agnostic**: 75+ LLM providers with auto-detection
- **Key UX pattern**: Tab to switch between Build/Plan agents

### OpenAI Codex CLI
- **Interactive TUI**: Full-screen terminal UI with inline approval
- **Approval modes**: Auto, Read-only, Full Access (3 tiers)
- **Slash commands**: /review, /fork, /plan, /resume, /compact, /model
- **Session management**: resume (--last or picker), fork (branch sessions into new threads)
- **Sandbox**: macOS Seatbelt / Linux Landlock sandboxing for shell commands
- **Non-interactive mode**: `codex exec` for CI/CD with JSON output streaming
- **Key UX patterns**: @ for file references, Esc×2 to edit previous message

### Google Gemini CLI
- **Interactive REPL**: Full chat mode with rich terminal UI
- **Checkpointing**: Save/resume/delete conversation checkpoints with tags
- **Slash commands**: /chat (save/resume/delete), /compress, /restore, /rewind, /resume, /model, /theme, /vim, /memory, /init, /introspect, /hooks, /skills, /tools, /settings
- **Extensions**: Plugin system for extending capabilities
- **Vim mode**: Toggle vim keybindings for editing
- **Footer/status bar**: Configurable display (CWD, sandbox status, model, context usage)
- **Key UX patterns**: ! for shell commands, @ for file injection

### GitHub Copilot CLI
- **Built-in agents**: Explore, Task, Plan, Code-review (auto-delegated)
- **Delegate command**: /delegate hands off to Copilot coding agent on GitHub
- **Memory system**: Repository-scoped cross-agent memory with citations and self-healing
- **Slash commands**: /delegate, /review, /agent, /usage, /model
- **Key innovation**: Cross-agent shared memory with verification

### Aider
- **Interactive chat**: Python-based REPL with prompt-toolkit
- **Slash commands**: /add, /drop, /undo, /diff, /run, /test, /commit, /architect, /ask, /code, /model, /map, /paste, /web, /lint, /clear, /help, /voice, /editor
- **Undo**: /undo reverts last AI commit via git
- **File context management**: /add and /drop to control which files are in chat
- **Architect mode**: Plan-first mode that generates code changes without applying
- **Watch mode**: Auto-run on file changes
- **Auto-commit**: Automatic git commits after each change
- **Session**: No persistence (loses context on restart) — major limitation
- **Key UX pattern**: Explicit file context management (/add, /drop)

### Cline / Roo Code (VS Code Extensions)
- **Checkpoint system**: Auto-save before every tool use, restore workspace + conversation separately
- **Approval workflow**: Show diff → user approves → apply
- **Plan-execute-review**: Multi-step with human review at each step

---

## GitHub Spec-Kit Analysis

### What It Is
GitHub's spec-kit implements **Spec-Driven Development (SDD)** — a 4-phase workflow:
1. **Spec** (spec.md): User stories, acceptance criteria, success metrics — NO implementation details
2. **Plan** (plan.md): Technical design, architecture decisions, file changes
3. **Tasks** (tasks.md): Concrete implementation steps with checkboxes
4. **Build**: Execute tasks with AI agent

### File Structure
```
specs/
  NNN-feature-name/
    spec.md        # Requirements (user stories, acceptance criteria)
    plan.md        # Technical design
    tasks.md       # Implementation checklist
```

### Spec Template Structure
- User Stories: "As a..." format with Given/When/Then acceptance scenarios
- Priority levels (P1-P3) per story
- Functional Requirements: FR-001 through FR-N with "System MUST" language
- Success Criteria: SC-001 through SC-N with measurable metrics
- Explicit "NEEDS CLARIFICATION" markers for ambiguity

### What's Good
- Forces clear thinking before coding
- Measurable success criteria
- Spec-anchored (specs evolve with project, not discarded)
- 37% reduction in redundant module creation in studies
- Good for greenfield features and standalone builds

### What's Bad (Criticisms)
- "Reinvented waterfall" — heavy upfront documentation
- Slow: changing spec requires regenerating plan and tasks
- Diminishing returns in brownfield/large codebases
- Agents don't consistently follow specs
- Double review burden (review spec, then review code)
- Best alternative: iterative prompting with small, sequential problems

### Relevance to Doyaken
Doyaken already has a spec-like pipeline (EXPAND → TRIAGE → PLAN → IMPLEMENT → TEST → DOCS → REVIEW → VERIFY) that's more pragmatic than spec-kit's heavyweight approach. The key takeaway is: **lightweight spec generation in EXPAND phase is valuable, but the full SDD workflow is too heavy**. Doyaken should enhance its EXPAND phase to generate better specs (user stories, acceptance criteria) but keep the iterative execution model.

---

## Common Patterns Across All Tools

### Universal Slash Commands
Every tool has: /help, /model, /clear, /compact (or /compress)

### Near-Universal
- /undo (all except Aider session persistence)
- /review (code review)
- /plan (planning mode)
- Session resume/fork

### Standard Keyboard Patterns
- @ for file references
- ! for shell commands
- / for slash commands
- Esc to cancel
- Ctrl+C to interrupt

### Permission Models
All tools implement some form of: Allow / Ask / Deny per operation

### Session Management
All modern tools support: create, list, resume, fork, export, compact

---

## Gap Analysis: Doyaken vs Competitors

| Feature | Doyaken | Claude | OpenCode | Codex | Gemini | Aider |
|---------|---------|--------|----------|-------|--------|-------|
| Interactive chat | No | Yes | Yes | Yes | Yes | Yes |
| Slash commands | No* | Yes | Yes | Yes | Yes | Yes |
| Plan mode | Phase-based | Yes | Yes | Yes | No | Architect |
| Undo/revert | No | Git | Git | Git | /restore | Git |
| Pause/resume | Ctrl+C only | Session | Session | Session | Checkpoint | No |
| Session management | Basic | Full | Full | Full | Checkpoint | No |
| Permission model | None (auto) | 3-tier | 3-tier | 3-tier | Ask | No |
| Progress display | Basic | Rich | Rich | Rich | Rich | Basic |
| Multi-provider | Yes | No** | Yes | No | No | Yes |
| Task management | Built-in | Todo | Todo | No | No | No |
| Skills/prompts | Built-in | Skills | Skills | Custom | Extensions | No |
| Spec generation | EXPAND phase | Plan mode | Plan agent | /plan | No | Architect |

*Doyaken has `dk` subcommands but no in-session slash commands
**Claude Code only uses Claude models

### Doyaken's Unique Strengths
1. **Agent agnostic** — works with ANY AI coding agent
2. **8-phase structured execution** — most comprehensive pipeline
3. **Built-in task management** — kanban-style task lifecycle
4. **Prompt library** — reusable methodology prompts
5. **Multi-agent coordination** — lock-based parallel execution
6. **Skills system** — already has on-demand skill loading

### Biggest Gaps
1. **No interactive mode** — can't intervene mid-execution
2. **No undo/revert** — can't roll back agent changes
3. **No session persistence** — no way to resume a conversation
4. **No permission model** — runs fully autonomous, no human checkpoints
5. **Poor progress UX** — basic text output, no rich TUI
6. **No spec quality** — EXPAND phase doesn't generate structured specs
