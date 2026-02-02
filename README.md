# Doyaken

A standalone multi-project autonomous agent CLI that works with any AI coding agent. Install once, use on any project.

**Aliases:** `doyaken`, `dk`

## Why Doyaken?

- **One install, all projects** - Global installation works across all your repos
- **Any AI agent** - Claude, Codex, Gemini, Copilot, Cursor, or OpenCode
- **Batteries included** - 40+ skills, 25+ prompts, 8-phase workflow out of the box
- **Zero config** - Works immediately after `dk init`

## Key Features

### Multi-Agent Configuration Sync

Automatically generates and syncs configuration files for all major AI coding agents:

```bash
dk sync  # Generates all agent files from single source of truth
```

| Generated File | Agent/Tool |
|---------------|------------|
| `AGENTS.md` | Codex, OpenCode (industry standard) |
| `CLAUDE.md` | Claude Code |
| `.cursorrules` | Cursor (legacy) |
| `.cursor/rules/*.mdc` | Cursor (modern rules) |
| `GEMINI.md` | Google Gemini |
| `.github/copilot-instructions.md` | GitHub Copilot |
| `.opencode.json` | OpenCode |

All files point to `.doyaken/` as the single source of truth. Edit once, sync everywhere.

### Prompt Library (25+ Methodologies)

Battle-tested prompts for common development tasks:

| Category | Prompts |
|----------|---------|
| **Code Quality** | `quality`, `refactor`, `debugging`, `errors` |
| **Reviews** | `review-architecture`, `review-security`, `review-debt`, `review-performance` |
| **Planning** | `planning`, `diagnose`, `research-features`, `research-competitors` |
| **Development** | `api-rest`, `ci`, `git`, `docs` |

```bash
# Use as slash commands in Claude Code
/quality      # Apply quality methodology
/debugging    # Debug current issue
/planning     # Create implementation plan
```

### Vendor-Specific Prompts

Pre-configured prompts for popular frameworks and services:

- **Frameworks**: Next.js, Rails, React
- **Databases**: PostgreSQL, Redis, Supabase
- **Platforms**: Vercel, DigitalOcean, Dokku
- **Tools**: GitHub Actions, Figma

### 8-Phase Workflow

Structured task execution with configurable timeouts:

```
EXPAND → TRIAGE → PLAN → IMPLEMENT → TEST → DOCS → REVIEW → VERIFY
```

Each phase has dedicated prompts in `.doyaken/prompts/phases/` that guide the agent through systematic task completion.

### Skills System (40+ Built-in)

Reusable, composable skills with MCP integration:

```bash
dk skills                    # List all skills
dk skill periodic-review     # Run comprehensive codebase review
dk skill audit-security      # OWASP-based security audit
dk skill ci-fix              # Diagnose and fix CI failures
```

### Claude Code Hooks

Automatic hooks that enhance Claude Code sessions:

| Hook | Purpose |
|------|---------|
| `check-quality.sh` | Run linters before commits |
| `check-security.sh` | Scan for security issues |
| `task-context.sh` | Inject current task context |
| `format-on-save.sh` | Auto-format code |
| `protect-sensitive-files.sh` | Prevent editing secrets |
| `inject-base-prompt.sh` | Add project context to prompts |

### Slash Command Generation

Auto-generates Claude Code slash commands from skills and prompts:

```bash
dk commands  # Regenerate .claude/commands/
```

Creates commands like `/workflow`, `/security`, `/testing` that you can invoke directly in Claude Code.

### Periodic Codebase Reviews

Automated comprehensive reviews covering:

- Code quality and maintainability
- Security vulnerabilities (OWASP)
- Technical debt assessment
- Performance analysis
- UX audit
- Documentation gaps

```bash
dk skill periodic-review  # Full review with auto-fix
```

### Additional Features

- **Self-Healing**: Automatic retries, model fallback, crash recovery
- **Parallel Agents**: Multiple agents work simultaneously with lock coordination
- **Project Registry**: Track projects by path, git remote, domains
- **MCP Integration**: Connect to GitHub, Linear, Slack, Jira
- **Test Automation**: `test-chaos` and `test-user` skills for robust testing

## Installation

### Option 1: npm (Recommended)

```bash
# Install globally
npm install -g @doyaken/doyaken

# Or use npx without installing
npx doyaken --help
```

### Option 2: curl (Per-User)

```bash
curl -sSL https://raw.githubusercontent.com/mitchellfyi/doyaken-cli/main/install.sh | bash
```

### Option 3: Clone & Install

```bash
git clone https://github.com/mitchellfyi/doyaken-cli.git
cd doyaken-cli
./install.sh
```

## Quick Start

```bash
# Initialize a new project
cd /path/to/your/project
dk init

# Create a task
dk tasks new "Add user authentication"

# Run the agent
dk run 1     # Run 1 task
dk           # Run 5 tasks (default)

# Check status
dk status    # Project status
dk tasks     # Show taskboard
dk doctor    # Health check
```

## Commands

| Command | Description |
|---------|-------------|
| `dk` | Run 5 tasks in current project |
| `dk run [N]` | Run N tasks |
| `dk task "<prompt>"` | Create and immediately run a single task |
| `dk init [path]` | Initialize a new project |
| `dk register` | Register current project in global registry |
| `dk unregister` | Remove current project from registry |
| `dk tasks` | Show taskboard |
| `dk tasks new <title>` | Create a new task |
| `dk tasks view <id>` | View a specific task |
| `dk add "<title>"` | Alias for `tasks new` |
| `dk skills` | List available skills |
| `dk skill <name>` | Run a skill |
| `dk sync` | Sync all agent configuration files |
| `dk commands` | Regenerate slash commands |
| `dk review` | Run periodic codebase review |
| `dk review --status` | Show review status and counter |
| `dk mcp status` | Show MCP integration status |
| `dk mcp configure` | Generate MCP configs |
| `dk hooks` | List available CLI agent hooks |
| `dk hooks install` | Install hooks to .claude/settings.json |
| `dk status` | Show project status |
| `dk list` | List all registered projects |
| `dk manifest` | Show project manifest |
| `dk config` | Show/edit configuration |
| `dk upgrade` | Upgrade doyaken to latest version |
| `dk upgrade --check` | Check for available updates |
| `dk doctor` | Health check |
| `dk cleanup` | Clean locks, logs, state, done tasks, stale doing, registry |
| `dk version` | Show version |
| `dk help` | Show help |

> **Note:** `doyaken` and `dk` are interchangeable.

> **Tip:** When no tasks exist in the backlog, running `dk` displays an interactive menu with options for Code Review, Feature Discovery, or creating tasks.

## Multi-Agent Support

Doyaken supports multiple AI coding agents. Use `--agent` to switch between them:

```bash
dk --agent claude run 1      # Use Claude (default)
dk --agent cursor run 1      # Use Cursor
dk --agent codex run 1       # Use OpenAI Codex
dk --agent gemini run 1      # Use Google Gemini
dk --agent copilot run 1     # Use GitHub Copilot
dk --agent opencode run 1    # Use OpenCode
```

### Supported Agents & Models

| Agent | Command | Models | Install |
|-------|---------|--------|---------|
| **claude** (default) | `claude` | opus, sonnet, haiku | `npm i -g @anthropic-ai/claude-code` |
| **cursor** | `cursor agent` | claude-sonnet-4, gpt-4o | `curl https://cursor.com/install -fsS \| bash` |
| **codex** | `codex exec` | gpt-5, o3, o4-mini | `npm i -g @openai/codex` |
| **gemini** | `gemini` | gemini-2.5-pro, gemini-2.5-flash | `npm i -g @google/gemini-cli` |
| **copilot** | `copilot` | claude-sonnet-4.5, gpt-5 | `npm i -g @github/copilot` |
| **opencode** | `opencode run` | claude-sonnet-4, gpt-5 | `npm i -g opencode-ai` |

### Specifying Models

```bash
dk --agent codex --model o3 run 1
dk --agent gemini --model gemini-2.5-flash run 2
```

## Agent Workflow

The agent operates in 8 phases for each task:

| Phase | Timeout | Purpose |
|-------|---------|---------|
| **EXPAND** | 2min | Expand brief prompt into full task specification |
| **TRIAGE** | 2min | Validate task, check dependencies |
| **PLAN** | 5min | Gap analysis, detailed planning |
| **IMPLEMENT** | 30min | Execute the plan, write code |
| **TEST** | 10min | Run tests, add coverage |
| **DOCS** | 5min | Sync documentation |
| **REVIEW** | 10min | Code review, create follow-ups |
| **VERIFY** | 3min | Verify task management, commit |

### Parallel Execution

Run multiple agents simultaneously:

```bash
dk run 5 &
dk run 5 &
dk run 5 &
```

Agents coordinate via lock files in `.doyaken/locks/` and will not work on the same task.

## Skills

Skills are reusable prompts with YAML frontmatter that declare tool requirements:

```bash
# List available skills
dk skills

# Run a skill
dk skill github-import --filter=open

# Show skill info
dk skill github-import --info
```

Skills can also use vendor namespacing (`vendor:skill`) for platform-specific functionality, e.g., `vercel:deploy`, `github:pr-review`. See [skills/vendors/](skills/vendors/) for available vendor skills.

### Built-in Skills

**Quality & Audits:**
| Skill | Description |
|-------|-------------|
| `setup-quality` | Set up quality gates, CI, and git hooks |
| `check-quality` | Run all quality checks and report issues |
| `audit-security` | OWASP-based security audit |
| `audit-deps` | Audit dependencies for vulnerabilities |
| `audit-debt` | Technical debt assessment |
| `audit-performance` | Performance analysis |
| `audit-ux` | User experience audit |

**Development:**
| Skill | Description |
|-------|-------------|
| `review-codebase` | Comprehensive codebase review |
| `research-features` | Discover next best feature to build |
| `ci-fix` | Diagnose and fix CI/CD failures |
| `workflow` | Run the 8-phase task workflow |
| `sync-agents` | Sync agent config files to project |

**Integrations** (require MCP servers):
| Skill | Description | Requires |
|-------|-------------|----------|
| `github-import` | Import GitHub issues as tasks | GitHub MCP |
| `github-sync` | Sync task status to GitHub | GitHub MCP |
| `github-pr` | Create PR from recent commits | GitHub MCP |
| `notify-slack` | Send Slack notifications | Slack MCP |
| `mcp-status` | Check MCP integration status | - |

### Creating Custom Skills

Create a `.md` file in `~/.doyaken/skills/` (global) or `.doyaken/skills/` (project):

```markdown
---
name: my-skill
description: What this skill does
requires:
  - github                     # MCP servers needed
args:
  - name: filter
    description: Filter option
    default: "open"
---

# My Skill Prompt

Instructions for the AI agent...
```

## MCP Integration

Doyaken supports MCP (Model Context Protocol) tools for external integrations:

```bash
# Show integration status
dk mcp status

# Generate MCP configs for enabled integrations
dk mcp configure
```

### Enabling Integrations

Edit `.doyaken/manifest.yaml`:

```yaml
integrations:
  github:
    enabled: true
  linear:
    enabled: false
  slack:
    enabled: false
  jira:
    enabled: false
```

After enabling, run `dk mcp configure` to generate the MCP configuration.

### Supported Integrations

| Integration | Description | Required Env Var |
|-------------|-------------|------------------|
| GitHub | Issues, PRs, repos | `GITHUB_TOKEN` |
| Linear | Issues, projects | `LINEAR_API_KEY` |
| Slack | Messages, channels | `SLACK_BOT_TOKEN` |
| Jira | Issues, sprints | `JIRA_API_TOKEN` |

### MCP Security

Doyaken validates MCP packages against an allowlist. Unofficial packages trigger warnings by default.

```bash
# Enable strict mode to block unofficial packages
DOYAKEN_MCP_STRICT=1 dk mcp configure
```

See [docs/security/mcp-security.md](docs/security/mcp-security.md) for allowlist management and security details.

### Skill Hooks

Auto-run skills at specific workflow points:

```yaml
# In manifest.yaml
skills:
  hooks:
    before-triage:
      - github-import       # Sync issues before starting
    after-verify:
      - github-sync         # Update issues after completion
```

## Project Structure

After running `dk init`, your project will have:

```
your-project/
├── .doyaken/
│   ├── manifest.yaml        # Project configuration
│   ├── tasks/
│   │   ├── 1.blocked/       # Blocked tasks
│   │   ├── 2.todo/          # Ready to start
│   │   ├── 3.doing/         # In progress
│   │   └── 4.done/          # Completed
│   ├── prompts/
│   │   ├── library/         # 25+ methodology prompts
│   │   └── phases/          # 8-phase workflow prompts
│   ├── skills/              # Project-specific skills
│   ├── hooks/               # Claude Code hooks
│   ├── logs/                # Execution logs
│   ├── state/               # Session recovery
│   └── locks/               # Parallel coordination
├── .claude/
│   └── commands/            # Auto-generated slash commands
├── .cursor/
│   └── rules/               # Cursor modern rules (.mdc)
├── AGENTS.md                # Multi-agent instructions
├── CLAUDE.md                # Claude Code config
├── .cursorrules             # Cursor legacy config
├── GEMINI.md                # Gemini config
└── TASKBOARD.md             # Generated task overview
```

### Keeping Agent Files in Sync

When you update prompts or skills, sync all agent configuration files:

```bash
dk sync      # Regenerate all agent files
dk commands  # Regenerate slash commands
dk upgrade   # Update doyaken itself
```

## Project Manifest

Configure your project in `.doyaken/manifest.yaml`:

```yaml
project:
  name: "my-app"
  description: "My awesome app"

git:
  remote: "git@github.com:user/my-app.git"
  branch: "main"

domains:
  production: "https://my-app.com"
  staging: "https://staging.my-app.com"

quality:
  test_command: "npm test"
  lint_command: "npm run lint"

agent:
  name: "claude"
  model: "opus"
  max_retries: 2
```

## Task System

### Task Priority

Tasks use the naming format `PPP-SSS-slug.md`:

| Priority | Code | Use For |
|----------|------|---------|
| Critical | 001  | Blocking, security, broken |
| High     | 002  | Important features, bugs |
| Medium   | 003  | Normal work |
| Low      | 004  | Nice-to-have, cleanup |

Example: `002-001-add-user-auth.md` = High priority, first in sequence

### Creating Tasks

```bash
# Via CLI
dk tasks new "Add user authentication"

# Manually create in .doyaken/tasks/todo/
# Use the template format
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOYAKEN_AGENT` | `claude` | AI agent to use |
| `DOYAKEN_MODEL` | agent-specific | Model for the selected agent |
| `DOYAKEN_AUTO_TIMEOUT` | `60` | Auto-select menu options after N seconds (0 to disable) |
| `AGENT_DRY_RUN` | `0` | Preview without executing |
| `AGENT_VERBOSE` | `0` | Detailed output |
| `AGENT_QUIET` | `0` | Minimal output |
| `AGENT_MAX_RETRIES` | `2` | Retries per phase |
| `AGENT_NO_PROMPT` | `0` | Auto-resume orphaned tasks without prompting |
| `TIMEOUT_EXPAND` | `300` | Expand phase timeout (seconds) |
| `TIMEOUT_TRIAGE` | `180` | Triage phase timeout (seconds) |
| `TIMEOUT_PLAN` | `300` | Plan phase timeout (seconds) |
| `TIMEOUT_IMPLEMENT` | `1800` | Implement phase timeout (seconds) |
| `TIMEOUT_TEST` | `600` | Test phase timeout (seconds) |
| `TIMEOUT_DOCS` | `300` | Docs phase timeout (seconds) |
| `TIMEOUT_REVIEW` | `600` | Review phase timeout (seconds) |
| `TIMEOUT_VERIFY` | `300` | Verify phase timeout (seconds) |
| `DOYAKEN_HOME` | `~/.doyaken` | Global installation directory |
| `DOYAKEN_MCP_STRICT` | `0` | Block unofficial MCP packages and missing env vars |

## Troubleshooting

```bash
# Health check
dk doctor

# View logs (project-level)
ls -la .doyaken/logs/

# View logs (global installation)
ls -la ~/.doyaken/logs/

# Clean up old logs, state, locks, and done tasks
dk cleanup

# Reset stuck state
rm -rf .doyaken/locks/*.lock
mv .doyaken/tasks/doing/*.md .doyaken/tasks/todo/
```

**Note**: Logs, state, and locks directories are created with 700 permissions (owner-only access) for security. Logs older than 7 days are automatically rotated.

## Development

### Setup

```bash
git clone https://github.com/mitchellfyi/doyaken-cli.git
cd doyaken-cli

# Install git hooks
npm run setup

# Run all checks
npm run check
```

### Quality Scripts

| Script | Description |
|--------|-------------|
| `npm run lint` | Lint shell scripts with shellcheck |
| `npm run validate` | Validate YAML files |
| `npm run test` | Run test suite |
| `npm run check` | Run all quality checks |
| `npm run setup` | Install git hooks |

### Git Hooks

The repository includes git hooks for quality assurance:

- **pre-commit**: Lints staged shell scripts and YAML files
- **pre-push**: Runs the full test suite

To bypass temporarily: `git commit --no-verify`

## Requirements

- At least one AI coding agent CLI installed:
  - [Claude Code](https://claude.ai/code) (default)
  - [Cursor CLI](https://cursor.com/docs/cli)
  - [OpenAI Codex](https://github.com/openai/codex)
  - [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)
  - [GitHub Copilot CLI](https://github.com/github/copilot-cli)
  - [OpenCode](https://opencode.ai)
- [yq](https://github.com/mikefarah/yq) - YAML processor (required for project registry)
- Bash 3.2+ (macOS default works)
- Git
- macOS or Linux
- Node.js 16+ (for npm install)

## Security Notice

Doyaken runs AI agents in **fully autonomous mode** by default with permission bypass flags enabled.
Agents can execute arbitrary code, modify files, and access environment variables without approval.

- Use `--safe-mode` to disable bypass flags and require agent confirmation
- Review task files before running on untrusted projects
- See [SECURITY.md](SECURITY.md) for full trust model and attack scenarios

## License

MIT
