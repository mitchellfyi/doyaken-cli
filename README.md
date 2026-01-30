# Doyaken

A standalone multi-project autonomous agent CLI that works with any AI coding agent. Install once, use on any project.

**Aliases:** `doyaken`, `dk`

## Features

- **Agent Agnostic**: Works with Claude, Codex, Gemini, Copilot, or OpenCode
- **Multi-Project Support**: Manage multiple projects from a single global installation
- **8-Phase Execution**: Expand → Triage → Plan → Implement → Test → Docs → Review → Verify
- **Self-Healing**: Automatic retries, model fallback, crash recovery
- **Parallel Agents**: Multiple agents can work simultaneously with lock coordination
- **Skills System**: Reusable prompts with MCP tool integration
- **MCP Integration**: Connect to GitHub, Linear, Slack, Jira via MCP tools
- **Project Registry**: Track projects by path, git remote, domains, and services

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
| `dk tasks` | Show taskboard |
| `dk tasks new <title>` | Create a new task |
| `dk tasks view <id>` | View a specific task |
| `dk skills` | List available skills |
| `dk skill <name>` | Run a skill |
| `dk mcp status` | Show MCP integration status |
| `dk mcp configure` | Generate MCP configs |
| `dk status` | Show project status |
| `dk list` | List all registered projects |
| `dk manifest` | Show project manifest |
| `dk doctor` | Health check |
| `dk help` | Show help |

> **Note:** `doyaken` and `dk` are interchangeable.

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
│   ├── logs/                # Execution logs
│   ├── state/               # Session recovery
│   └── locks/               # Parallel coordination
├── AGENT.md                 # Project-specific agent notes
└── TASKBOARD.md             # Generated task overview
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
| `TIMEOUT_EXPAND` | `300` | Expand phase timeout (seconds) |
| `TIMEOUT_TRIAGE` | `180` | Triage phase timeout (seconds) |
| `TIMEOUT_PLAN` | `300` | Plan phase timeout (seconds) |
| `TIMEOUT_IMPLEMENT` | `1800` | Implement phase timeout (seconds) |
| `TIMEOUT_TEST` | `600` | Test phase timeout (seconds) |
| `TIMEOUT_DOCS` | `300` | Docs phase timeout (seconds) |
| `TIMEOUT_REVIEW` | `600` | Review phase timeout (seconds) |
| `TIMEOUT_VERIFY` | `300` | Verify phase timeout (seconds) |
| `DOYAKEN_HOME` | `~/.doyaken` | Global installation directory |

## Troubleshooting

```bash
# Health check
dk doctor

# View logs
ls -la .doyaken/logs/

# Reset stuck state
rm -rf .doyaken/locks/*.lock
mv .doyaken/tasks/doing/*.md .doyaken/tasks/todo/
```

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

## License

MIT
