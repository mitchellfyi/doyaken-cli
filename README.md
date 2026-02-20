# Doyaken

[![CI](https://github.com/mitchellfyi/doyaken-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/mitchellfyi/doyaken-cli/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/@doyaken/doyaken.svg)](https://www.npmjs.com/package/@doyaken/doyaken)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A coding agent that delivers robust, working code. One prompt in, verified code out.

**Aliases:** `doyaken`, `dk`

## Why Doyaken?

Most AI coding tools generate code and hope for the best. Doyaken runs your prompt through an 8-phase pipeline with built-in verification loops -- it implements, tests, reviews, and retries until the code actually works.

- **One prompt, working code** - `dk run "Add JWT authentication"` and walk away
- **Verification gates** - Build, lint, and test checks run automatically after key phases. Failures trigger retries with error context.
- **Any AI agent** - Claude, Codex, Gemini, Copilot, Cursor, or OpenCode
- **One install, all projects** - Global installation works across all your repos
- **Batteries included** - 40+ skills, 25+ prompts, 8-phase workflow out of the box

## How It Works

```
dk run "Add user authentication with JWT"
```

Doyaken takes your prompt and runs it through an 8-phase pipeline:

```
EXPAND → TRIAGE → PLAN → IMPLEMENT → TEST → DOCS → REVIEW → VERIFY
                              ↑            ↑             ↑
                              └── gates ───┘── gates ────┘
                              retry on failure with error context
```

**Verification gates** run your project's quality commands (build, lint, format, test) after IMPLEMENT, TEST, and REVIEW. If a gate fails, the phase retries with the error output injected into the prompt -- so the agent sees exactly what broke and fixes it. Each phase has a configurable retry budget (default: 5 for implement, 3 for test/review).

**Accumulated context** flows between phases and retries, so later phases know what happened earlier. No work is lost.

## Quick Start

```bash
# Install globally
npm install -g @doyaken/doyaken

# Initialize a project
cd /path/to/your/project
dk init

# Run the agent
dk run "Add a health check endpoint at /api/health"

# Check status
dk status
dk doctor
```

## Commands

| Command | Description |
|---------|-------------|
| `dk run "<prompt>"` | Execute a prompt through the 8-phase pipeline |
| `dk init [path]` | Initialize a new project |
| `dk register` | Register current project in global registry |
| `dk unregister` | Remove current project from registry |
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
| `dk cleanup` | Clean logs, state, and registry |
| `dk version` | Show version |
| `dk help` | Show help |

> **Note:** `doyaken` and `dk` are interchangeable.

## 8-Phase Pipeline

Each phase runs in a fresh agent context with dedicated prompts:

| Phase | Timeout | Purpose |
|-------|---------|---------|
| **EXPAND** | 2min | Expand brief prompt into full specification |
| **TRIAGE** | 2min | Validate feasibility, check dependencies |
| **PLAN** | 5min | Gap analysis, detailed implementation plan |
| **IMPLEMENT** | 30min | Write the code (with verification gates) |
| **TEST** | 10min | Run tests, add coverage (with verification gates) |
| **DOCS** | 5min | Sync documentation |
| **REVIEW** | 10min | Code review, quality check (with verification gates) |
| **VERIFY** | 3min | Final verification, commit |

### Verification Gates

Gates are configured via your project's quality commands in `.doyaken/manifest.yaml`:

```yaml
quality:
  build_command: "npm run build"
  lint_command: "npm run lint"
  format_command: "npm run format"
  test_command: "npm test"

retry_budget:
  implement: 5    # Max retries for IMPLEMENT phase
  test: 3         # Max retries for TEST phase
  review: 3       # Max retries for REVIEW phase
```

When no quality commands are configured, gates are skipped and phases run in single-pass mode.

### Self-Healing

- **Model fallback**: If the primary model hits rate limits, automatically falls back to a cheaper model (e.g., opus -> sonnet)
- **Crash recovery**: Interrupted runs can resume from the last completed phase
- **Rate limiting**: Automatic backoff and retry on API rate limits

## Multi-Agent Support

Doyaken works with any AI coding agent. Use `--agent` to switch:

```bash
dk --agent claude run "Add auth"      # Claude (default)
dk --agent codex run "Add auth"       # OpenAI Codex
dk --agent gemini run "Add auth"      # Google Gemini
dk --agent cursor run "Add auth"      # Cursor
dk --agent copilot run "Add auth"     # GitHub Copilot
dk --agent opencode run "Add auth"    # OpenCode
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

```bash
dk --agent codex --model o3 run "Optimize database queries"
dk --agent gemini --model gemini-2.5-flash run "Fix the login bug"
```

## Key Features

### Multi-Agent Configuration Sync

Generates and syncs configuration files for all major AI coding agents from a single source:

```bash
dk sync  # Generates all agent files from .doyaken/
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
| `format-on-save.sh` | Auto-format code |
| `protect-sensitive-files.sh` | Prevent editing secrets |
| `inject-base-prompt.sh` | Add project context to prompts |

### Slash Command Generation

Auto-generates Claude Code slash commands from skills and prompts:

```bash
dk commands  # Regenerate .claude/commands/
```

### Periodic Codebase Reviews

Automated comprehensive reviews covering code quality, security vulnerabilities, technical debt, performance, UX, and documentation gaps:

```bash
dk skill periodic-review  # Full review with auto-fix
```

## Skills

Skills are reusable prompts with YAML frontmatter that declare tool requirements:

```bash
dk skills                          # List available skills
dk skill github-import --filter=open  # Run a skill
dk skill github-import --info         # Show skill info
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
| `workflow` | Run the 8-phase workflow |
| `sync-agents` | Sync agent config files to project |

**Integrations** (require MCP servers):
| Skill | Description | Requires |
|-------|-------------|----------|
| `github-import` | Import GitHub issues | GitHub MCP |
| `github-sync` | Sync status to GitHub | GitHub MCP |
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
dk mcp status       # Show integration status
dk mcp configure    # Generate MCP configs
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
DOYAKEN_MCP_STRICT=1 dk mcp configure  # Block unofficial packages
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
│   ├── prompts/
│   │   ├── library/         # 25+ methodology prompts
│   │   └── phases/          # 8-phase workflow prompts
│   ├── skills/              # Project-specific skills
│   ├── hooks/               # Claude Code hooks
│   ├── logs/                # Execution logs
│   └── state/               # Session recovery
├── .claude/
│   └── commands/            # Auto-generated slash commands
├── .cursor/
│   └── rules/               # Cursor modern rules (.mdc)
├── AGENTS.md                # Multi-agent instructions
├── CLAUDE.md                # Claude Code config
├── .cursorrules             # Cursor legacy config
└── GEMINI.md                # Gemini config
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
  build_command: "npm run build"
  test_command: "npm test"
  lint_command: "npm run lint"
  format_command: "npm run format"

retry_budget:
  implement: 5
  test: 3
  review: 3

agent:
  name: "claude"
  model: "opus"
  max_retries: 2
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOYAKEN_AGENT` | `claude` | AI agent to use |
| `DOYAKEN_MODEL` | agent-specific | Model for the selected agent |
| `AGENT_DRY_RUN` | `0` | Preview without executing |
| `AGENT_VERBOSE` | `0` | Detailed output |
| `AGENT_QUIET` | `0` | Minimal output |
| `AGENT_MAX_RETRIES` | `2` | Retries per phase (rate limit retries) |
| `RETRY_BUDGET_IMPLEMENT` | `5` | Verification gate retries for IMPLEMENT |
| `RETRY_BUDGET_TEST` | `3` | Verification gate retries for TEST |
| `RETRY_BUDGET_REVIEW` | `3` | Verification gate retries for REVIEW |
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

# Clean up old logs and state
dk cleanup
```

**Note**: Logs, state, and backup directories are created with 700 permissions (owner-only access) for security. Logs older than 7 days are automatically rotated.

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

### Testing

Tests use the [Bats](https://github.com/bats-core/bats-core) framework with mock agent CLIs for isolated testing.

```bash
# Run all tests
npm run test

# Run specific test file
bats test/unit/core.bats

# Run tests matching a pattern
bats test/unit/core.bats --filter "session"
```

**Test Coverage:**
- Unit tests for model fallback, session state, health checks, verification gates, prompt processing
- Integration tests for workflow execution, failure recovery, interrupt handling
- Mock agent scripts (`test/mocks/`) simulate CLI behavior without API calls

See [test/README.md](test/README.md) for test patterns and mock configuration.

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
- Review prompts before running on untrusted projects
- See [SECURITY.md](SECURITY.md) for full trust model and attack scenarios

## License

MIT
