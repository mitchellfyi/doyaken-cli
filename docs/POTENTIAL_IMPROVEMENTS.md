# Potential Improvements for Doyaken

Research-based improvement suggestions from analysis of the deprecated doyaken project and 14 external tools in the autonomous AI coding space.

## Project Mission Reference

From `PROJECT.md`, doyaken is:
- **Agent-agnostic orchestration** for autonomous code development
- **CLI only** (explicitly NOT a GUI or IDE extension)
- **Bash 4.0+** with minimal dependencies
- **Multi-project** via global installation
- **8-phase execution** with self-healing and parallel agent coordination

**Non-goals:** Not a replacement for any AI agent, won't implement AI capabilities, won't be a GUI.

---

## Research Sources

| Source | Type | URL |
|--------|------|-----|
| doyaken-(deprecated) | Internal | Local project |
| Claude-Flow | Multi-agent orchestration | [github.com/ruvnet/claude-flow](https://github.com/ruvnet/claude-flow) |
| Open Ralph Wiggum | Iterative loops | [github.com/Th0rgal/open-ralph-wiggum](https://github.com/Th0rgal/open-ralph-wiggum) |
| Everything Claude Code | Plugin ecosystem | [github.com/affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) |
| SilenNaihin Gist | Global config | [gist.github.com/SilenNaihin/3f6b6cc...](https://gist.github.com/SilenNaihin/3f6b6ccdc1f24911cfdec78dbc334547) |
| Ralph Playbook | Methodology | [github.com/ClaytonFarr/ralph-playbook](https://github.com/ClaytonFarr/ralph-playbook) |
| Auto-Claude | Desktop app | [github.com/AndyMik90/Auto-Claude](https://github.com/AndyMik90/Auto-Claude) |
| Atoms | Business platform | [atoms.dev](https://atoms.dev/) |
| Pickle Rick | Gemini extension | [github.com/galz10/pickle-rick-extension](https://github.com/galz10/pickle-rick-extension) |
| Skillshare | Skill sync | [github.com/runkids/skillshare](https://github.com/runkids/skillshare) |
| Agent Loop | GitHub automation | [github.com/bentossell/agent-loop](https://github.com/bentossell/agent-loop) |
| Gas Town | Workspace manager | [github.com/steveyegge/gastown](https://github.com/steveyegge/gastown) |
| AutoCoder | Test-driven | [github.com/leonvanzyl/autocoder](https://github.com/leonvanzyl/autocoder) |
| Ralph Marketer | Marketing workflows | [github.com/muratcankoylan/ralph-wiggum-marketer](https://github.com/muratcankoylan/ralph-wiggum-marketer) |
| ActualCode | Multi-agent A2A | [github.com/muratcankoylan/actual_code](https://github.com/muratcankoylan/actual_code) |

---

# Part 1: In-Scope Improvements

These improvements align with doyaken's mission as an agent-agnostic CLI orchestrator.

---

## 1. Workflow Execution

### 1.1 Completion Signals

Allow agents to self-declare completion instead of relying on timeouts.

```yaml
# .doyaken/manifest.yaml
completion:
  signal: "<promise>COMPLETE</promise>"
  # Or test-based
  test_command: "npm test"
  success_pattern: "All tests passed"
```

**Source:** Open Ralph Wiggum, Pickle Rick

---

### 1.2 Mid-Execution Hints

Inject guidance into a running workflow without interrupting it.

```bash
dk hint "Focus on error handling"  # Applied next iteration
dk hint --clear                     # Remove pending hints
dk status                           # Show pending hints
```

**Source:** Open Ralph Wiggum

---

### 1.3 Struggle Detection

Detect when an agent is stuck and suggest intervention.

```bash
dk status
# Warning: No file changes in last 3 iterations
# Suggestion: Try `dk hint "..."` or reduce task scope
```

**Source:** Open Ralph Wiggum

---

### 1.4 Background Execution

Run tasks without holding a terminal.

```bash
dk run 10 --background   # Run in background
dk attach                 # Attach to running session
dk logs                   # View background logs
```

**Source:** Agent Loop

---

### 1.5 Task Size Classification

Auto-adjust phase timeouts based on task complexity.

```yaml
# In task frontmatter
size: quick | standard | epic
```

| Size | EXPAND | PLAN | IMPLEMENT |
|------|--------|------|-----------|
| quick | 1min | 2min | 10min |
| standard | 2min | 5min | 30min |
| epic | 5min | 10min | 60min |

**Source:** doyaken-(deprecated)

---

### 1.6 Checkpoints & Resume

Save state mid-workflow; resume after crashes.

```bash
dk resume <task-id>   # Resume from last checkpoint
```

Store in `.doyaken/checkpoints/<task-id>/`

**Source:** doyaken-(deprecated), Gas Town

---

## 2. Model & Agent Management

### 2.1 Model Fallback Chain

Automatic fallback on rate limits or errors.

```yaml
# .doyaken/manifest.yaml
agent:
  model: opus
  fallback: [sonnet, haiku]
  fallback_on: [rate_limit, timeout]
```

**Source:** Claude-Flow

---

### 2.2 Complexity-Based Routing

Route simple tasks to cheaper/faster models.

```yaml
routing:
  simple:
    patterns: ["typo", "rename", "fix import"]
    model: haiku
  complex:
    patterns: ["refactor", "new feature", "architecture"]
    model: opus
```

**Source:** Claude-Flow

---

## 3. Skills & Prompts

### 3.1 Skill Priority System

Resolve conflicts when multiple skills match.

```yaml
# skills/vercel/react-review.yaml
priority: 9  # Higher wins
```

**Source:** doyaken-(deprecated)

---

### 3.2 Skill Tool Restrictions

Limit which tools a skill can use.

```yaml
# skills/security-audit.yaml
allowed_tools: [Read, Grep, Glob]
disallowed_tools: [Bash, Write, Edit]
```

**Source:** doyaken-(deprecated), AutoCoder

---

### 3.3 Skill Composition

Bundle skills for complex domains.

```yaml
# skills/fullstack-nextjs.yaml
includes:
  - vercel/react-review
  - vercel/api-patterns
  - database/postgres
```

**Source:** doyaken-(deprecated)

---

### 3.4 Template Variables

Parameterize prompts with defaults.

```yaml
---
variables:
  focus_areas: ["security", "performance"]
---
Review focusing on: {{focus_areas}}
```

**Source:** doyaken-(deprecated)

---

### 3.5 Intent Classification

Route tasks to intent-specific prompts.

```bash
dk task --intent fix "Login fails on mobile"
```

| Intent | Key Question | Key Output |
|--------|--------------|------------|
| BUILD | What should this do? | Acceptance criteria |
| FIX | What's broken? | Root cause + test |
| IMPROVE | What metric improves? | Before/after evidence |
| REVIEW | What's wrong? | Prioritized findings |

**Source:** doyaken-(deprecated)

---

## 4. MCP & Tool Integration

### 4.1 Tool Setup Instructions

Self-documenting MCP requirements.

```yaml
# config/mcp/github.yaml
setup:
  required_env: [GITHUB_TOKEN]
  instructions: |
    Create PAT at https://github.com/settings/tokens
    Required scopes: repo, read:org
  verify_command: gh auth status
```

`dk doctor` validates these.

**Source:** doyaken-(deprecated)

---

### 4.2 Tool Health Checks

Verify integrations are working.

```yaml
health_check:
  command: gh auth status
  expect_exit: 0
```

**Source:** doyaken-(deprecated)

---

### 4.3 Conditional Tool Loading

Auto-enable MCP based on project files.

```yaml
mcp:
  auto_detect: true
  conditionals:
    - if_exists: package.json
      load: [github, npm]
    - if_exists: Gemfile
      load: [github, bundler]
```

**Source:** doyaken-(deprecated)

---

## 5. CLI Enhancements

### 5.1 Dry-Run Mode

Preview without executing.

```bash
dk run 1 --dry-run     # Show what would run
dk task "..." --dry-run # Show task that would be created
```

**Source:** doyaken-(deprecated)

---

### 5.2 Taskboard Intent Display

Show task type at a glance.

```
TODO (3 tasks)
  [BUILD]  001-003-add-auth-flow.md
  [FIX]    002-001-login-bug.md
  [REVIEW] 003-002-security-audit.md
```

**Source:** doyaken-(deprecated)

---

### 5.3 Validation Command

Catch config errors early.

```bash
dk validate            # Validate all configs
dk validate --fix      # Auto-fix simple issues
```

**Source:** doyaken-(deprecated)

---

### 5.4 Project Registry Enhancements

Better multi-project management.

```yaml
# ~/.doyaken/registry.yaml
projects:
  /path/to/project:
    name: my-project
    last_active: 2024-01-15T10:30:00Z
    primary_agent: claude
    stack: [typescript, react]
```

```bash
dk list --recent       # Sort by last active
dk stats               # Aggregate statistics
```

**Source:** doyaken-(deprecated)

---

## 6. Error Handling

### 6.1 Batch Error Reporting

Show all problems at once.

```bash
dk validate
# Found 3 errors:
#   skills/broken.yaml: invalid YAML at line 5
#   tasks/todo/001.md: missing 'scope' section
#   manifest.yaml: unknown field 'typo'
```

**Source:** doyaken-(deprecated)

---

### 6.2 Actionable Error Messages

Include fix suggestions.

```
ERROR: Task missing required 'scope' field
  File: .doyaken/tasks/todo/001-feature.md

  To fix, add:
    ## Scope
    - Acceptance criteria here
```

**Source:** doyaken-(deprecated)

---

### 6.3 Configurable Strictness

Let projects choose error tolerance.

```yaml
error_handling:
  missing_skill: warn    # warn|error|ignore
  invalid_prompt: error
  mcp_failure: warn
```

**Source:** doyaken-(deprecated)

---

## 7. Security

### 7.1 Destructive Operation Guards

Require confirmation for dangerous commands.

```yaml
guards:
  destructive:
    patterns: ["rm -rf", "git reset --hard", "DROP TABLE"]
    action: confirm  # confirm|block|warn
  secrets:
    patterns: [".env", "credentials", "*.pem"]
    action: block
```

**Source:** SilenNaihin Gist, Auto-Claude

---

### 7.2 Secret Scanning

Warn before creating tasks with potential secrets.

```bash
dk task "Set API_KEY=sk-abc123..."
# Warning: Task may contain secrets. Continue? [y/N]
```

**Source:** doyaken-(deprecated)

---

### 7.3 Audit Logging

Track sensitive operations.

```bash
# .doyaken/audit.log
2024-01-15T10:30:00Z task:create task=001-feature
2024-01-15T10:35:00Z phase:implement agent=claude
2024-01-15T10:40:00Z mcp:call tool=github action=create_pr
```

**Source:** General best practice

---

## 8. Documentation

### 8.1 Getting Started Guide

Step-by-step onboarding in `docs/GETTING_STARTED.md`.

**Source:** doyaken-(deprecated)

---

### 8.2 Quick Reference Card

All commands on one page in `docs/QUICK_REFERENCE.md`.

**Source:** doyaken-(deprecated)

---

### 8.3 Agent-Specific Tips

Per-agent guidance in `docs/AGENTS.md`.

**Source:** doyaken-(deprecated)

---

### 8.4 Anti-Patterns Guide

What to avoid in `prompts/library/anti-patterns.md`.

**Source:** doyaken-(deprecated)

---

## 9. Parallel Agent Coordination

### 9.1 Git Worktree Isolation

Each agent works in isolated worktree.

```bash
dk worktree create agent-001  # Create workspace
dk worktree list              # Show workspaces
dk worktree merge agent-001   # Merge back
```

**Source:** Auto-Claude, Gas Town

---

### 9.2 Phase-Specific Parallelization

Configure parallelism per phase.

```yaml
phases:
  2-plan:
    subagents: 5     # Fan out for research
  3-implement:
    subagents: 1     # Sequential for builds
```

**Source:** Ralph Playbook

---

## 10. GitHub Integration

### 10.1 Bidirectional GitHub Issues Sync

Full two-way sync between GitHub Issues and local tasks.

```bash
dk github pull           # Import open issues as local tasks
dk github push           # Push local task updates to GitHub
dk github sync           # Bidirectional sync
dk run --from-issues 5   # Process 5 issues directly
```

Features:
- Map issue labels to task priority/intent
- Sync status changes (close issue when task completes)
- Link PRs to originating issues
- Import issue comments as task context

Already partially exists via `github-import` skill; promote to core with bidirectional support.

**Source:** Agent Loop, doyaken-(deprecated)

---

### 10.2 GitHub Actions Integration

Trigger skills on GitHub events.

```yaml
# .github/workflows/doyaken.yml
on:
  pull_request:
    types: [opened]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: doyaken/action@v1
        with:
          skill: security-audit
```

**Source:** doyaken-(deprecated)

---

## 11. Cross-Tool Config Generation

Doyaken is agent-agnostic - it should generate appropriate configs for ALL supported agents from a single source of truth.

### 11.1 Multi-Tool Config Generation

Generate tool-specific instruction files from doyaken skills/prompts:

```bash
dk generate              # Generate configs for all detected agents
dk generate --agent claude   # Generate CLAUDE.md only
dk generate --agent cursor   # Generate .cursorrules only
dk generate --all            # Generate for all supported agents
```

**Output files per agent:**

| Agent | Generated Files |
|-------|-----------------|
| Claude | `CLAUDE.md`, `.claude/settings.json` |
| Cursor | `.cursorrules`, `.cursor/mcp.json` |
| Codex | `AGENTS.md`, `.codex/config.json` |
| Copilot | `.github/copilot-instructions.md` |
| Gemini | `GEMINI.md`, `.gemini/settings.json` |
| OpenCode | `AGENTS.md`, `opencode.json` |

**Source:** doyaken-(deprecated), Skillshare

---

### 11.2 Single Source of Truth

All agent configs derive from `.doyaken/`:

```
.doyaken/
├── manifest.yaml          # Project config (generates agent settings)
├── prompts/               # Shared prompts (generates instruction files)
├── skills/                # Skills (generates tool configs)
└── mcp/                   # MCP configs (generates per-agent MCP settings)
```

```bash
dk status                  # Show sync status across all agents
dk generate --check        # CI-friendly: fail if configs out of sync
```

**Source:** doyaken-(deprecated)

---

### 11.3 Managed Content Markers

Safe updates that preserve user customizations:

```markdown
<!-- DOYAKEN:BEGIN -->
This content is managed by doyaken.
Edit .doyaken/ sources, not this file.
<!-- DOYAKEN:END -->

## My Custom Instructions
(preserved across regeneration)
```

**Source:** doyaken-(deprecated)

---

### 11.4 Drift Detection

Detect when generated files diverge from source:

```bash
dk status
# CLAUDE.md: in sync
# .cursorrules: DRIFTED (manual edits detected)
# .github/copilot-instructions.md: missing

dk generate --force       # Regenerate, overwriting drift
dk generate --merge       # Regenerate, preserving user sections
```

**Source:** doyaken-(deprecated)

---

# Part 2: Out-of-Scope / External Projects

These don't fit doyaken's mission but could be separate tools or documented integrations.

---

## A. GUI & Web Dashboards

**Why out of scope:** PROJECT.md explicitly states "Not an IDE extension or GUI tool - CLI only."

### A.1 Web Dashboard

React-based dashboard with WebSocket streaming for agent output and task status.

**Source:** AutoCoder

**Alternative:** Document how to tail `.doyaken/logs/` or use existing terminal dashboards like `wtf` or `lazygit`.

---

### A.2 Kanban Web UI

Visual task board with drag-and-drop.

**Source:** Auto-Claude

**Alternative:** The existing `dk tasks` and `TASKBOARD.md` serve this need in CLI form.

---

## B. Advanced Multi-Agent Orchestration

**Why out of scope:** Doyaken orchestrates tasks, not agent hierarchies. Complex multi-agent coordination requires a different architecture.

### B.1 Agent Hierarchies (Queen/Worker/Polecat)

Coordinator agents delegating to specialized workers.

**Source:** Claude-Flow, Gas Town

**Complementary Tool:** [Gas Town](https://github.com/steveyegge/gastown) - Use when scaling to 20-30 agents.

---

### B.2 Consensus Mechanisms

Raft, Byzantine fault tolerance, weighted voting for multi-agent decisions.

**Source:** Claude-Flow

**Why skip:** Overkill for file-based lock coordination that doyaken uses.

---

### B.3 Mailbox-Based Coordination

Agents poll persistent mailboxes for work.

**Source:** Gas Town

**Why skip:** Doyaken's lock + task folder system is simpler and sufficient.

---

### B.4 Race Mode (Competing Agents)

Multiple agents compete; best output selected.

**Source:** Atoms

**Why skip:** Expensive (3x+ cost), complex selection criteria.

---

## C. Database-Backed State

**Why out of scope:** Doyaken uses file-based state for simplicity and portability.

### C.1 SQLite Feature Queue

Features stored in SQLite with MCP-exposed status tracking.

**Source:** AutoCoder

**Why skip:** Adds dependency, file-based task folders are sufficient.

---

### C.2 Beads Ledger

Git-backed structured ledger with unique work item IDs.

**Source:** Gas Town

**Why skip:** Task filenames (`001-002-slug.md`) already serve as IDs.

---

## D. Token Optimization Infrastructure

**Why out of scope:** Requires significant infrastructure beyond a bash CLI.

### D.1 WASM-Based Simple Transforms

Skip LLM for regex-based transforms (var→const, add TypeScript annotations).

**Source:** Claude-Flow

**Why skip:** Requires WASM runtime, complex pattern matching.

---

### D.2 Cached Reasoning Retrieval

Vector database for caching similar prompts/responses.

**Source:** Claude-Flow

**Why skip:** Requires database infrastructure.

---

## E. Domain-Specific Platforms

**Why out of scope:** These are full products, not CLI tools.

### E.1 Marketing Automation

Content pipelines, SEO optimization, copywriting workflows.

**Source:** Ralph Wiggum Marketer

**Alternative:** Create domain skill packs in `skills/domains/marketing/`.

---

### E.2 Assessment Generation

Multi-agent assessment generation with QA validation.

**Source:** ActualCode

**Why skip:** Very specialized use case.

---

## F. IDE Extensions

**Why out of scope:** Explicitly a non-goal in PROJECT.md.

### F.1 AfterAgent Hook Loops

Intercept session exits to create self-contained feedback loops.

**Source:** Pickle Rick

**Why skip:** IDE/extension-specific; doyaken's bash loop is simpler.

---

## G. Session Memory Persistence

**Why partially out of scope:** Agents manage their own context; doyaken orchestrates tasks.

### G.1 Session Lifecycle Hooks

Automatically save/load context across sessions.

**Source:** Everything Claude Code

**Partial fit:** Could add hooks in manifest, but context management is agent-specific.

---

### G.2 Context Transfer Commands

Export context from degraded sessions.

**Source:** SilenNaihin Gist

**Why skip:** Agent-specific; not doyaken's responsibility.

---

# Summary: Prioritized Improvements

## Quick Wins (Days)

| # | Improvement | Source | Effort |
|---|------------|--------|--------|
| 1 | Dry-run mode (`--dry-run`) | deprecated | Low |
| 2 | Intent display in taskboard | deprecated | Low |
| 3 | Anti-patterns documentation | deprecated | Low |
| 4 | Quick reference card | deprecated | Low |
| 5 | MCP setup instructions | deprecated | Low |
| 6 | Completion signals | Ralph Wiggum | Low |

## Medium Effort (Weeks)

| # | Improvement | Source | Effort |
|---|------------|--------|--------|
| 7 | Model fallback chain | Claude-Flow | Medium |
| 8 | Skill priority system | deprecated | Medium |
| 9 | Skill tool restrictions | deprecated | Medium |
| 10 | Batch error reporting | deprecated | Medium |
| 11 | Destructive operation guards | SilenNaihin | Medium |
| 12 | Background execution mode | Agent Loop | Medium |
| 13 | Mid-execution hints | Ralph Wiggum | Medium |
| 14 | Bidirectional GitHub sync | Agent Loop, deprecated | Medium |
| 15 | Managed content markers | deprecated | Medium |

## Larger Investments (Sprints)

| # | Improvement | Source | Effort |
|---|------------|--------|--------|
| 16 | Cross-tool config generation | deprecated, Skillshare | High |
| 17 | Drift detection | deprecated | High |
| 18 | Checkpoints & resume | deprecated, Gas Town | High |
| 19 | Git worktree isolation | Auto-Claude | High |
| 20 | GitHub Actions integration | deprecated | High |
| 21 | Complexity-based routing | Claude-Flow | High |
| 22 | Struggle detection | Ralph Wiggum | High |
| 23 | Task size classification | deprecated | High |
| 24 | Validation command | deprecated | High |

## Complementary External Tools

| Tool | Use Case | When to Use |
|------|----------|-------------|
| [Gas Town](https://github.com/steveyegge/gastown) | Massive parallelism | 20-30+ concurrent agents |

**Note:** Cross-tool config sync and GitHub Issues sync are now in-scope for doyaken.

---

*Generated: 2026-01-26*
*Research: 1 deprecated project + 14 external tools*
