# AI Agent Framework

A standalone, phase-based autonomous agent system for Claude Code that enables fully autonomous task execution with self-healing capabilities and parallel operation support.

## Features

- **7-Phase Execution**: Each task goes through Triage, Plan, Implement, Test, Docs, Review, and Verify phases
- **Self-Healing**: Automatic retries with exponential backoff, model fallback, and crash recovery
- **Parallel Support**: Multiple agents can work simultaneously with lock-based coordination
- **Task Management**: File-based task tracking with priority ordering and dependency management
- **Quality Gates**: Integrated quality checks at each phase

## Quick Start

### 1. Install into Your Project

```bash
# Clone this repo
git clone https://github.com/your-org/ai-agent.git

# Install into your project
cd ai-agent
./agent/install.sh /path/to/your/project
```

### 2. Create Your First Task

```bash
cd /path/to/your/project
cp .claude/tasks/_templates/task.md .claude/tasks/todo/003-001-my-first-task.md
# Edit the task file with your requirements
```

### 3. Run the Agent

```bash
# Run single task
./bin/agent 1

# Run 5 tasks (default)
./bin/agent

# Run in parallel
./bin/agent 5 &
./bin/agent 5 &
```

## Directory Structure

```
.claude/
  agent/
    run.sh           # Entry point script
    install.sh       # Installation script
    lib/
      core.sh        # Core agent logic (1400+ lines)
    prompts/
      1-triage.md    # Phase 1: Validate task
      2-plan.md      # Phase 2: Gap analysis & planning
      3-implement.md # Phase 3: Write code
      4-test.md      # Phase 4: Run tests
      5-docs.md      # Phase 5: Sync documentation
      6-review.md    # Phase 6: Code review
      7-verify.md    # Phase 7: Task verification
    scripts/
      taskboard.sh   # Generate TASKBOARD.md
  tasks/
    todo/            # Tasks ready to start
    doing/           # Tasks in progress
    done/            # Completed tasks
    _templates/
      task.md        # Task file template
  logs/              # Run logs
  state/             # Session state for recovery
  locks/             # Lock files for parallel ops

bin/
  agent              # Main agent script (symlink)

CLAUDE.md            # Agent operating manual
TASKBOARD.md         # Generated task overview
MISSION.md           # Project goals (you create this)
```

## Task Priority System

Tasks are named with priority prefixes:

| Prefix | Priority | Use For |
|--------|----------|---------|
| 001    | Critical | Blocking issues, security, broken functionality |
| 002    | High     | Important features, significant bugs |
| 003    | Medium   | Normal work, improvements |
| 004    | Low      | Nice-to-have, cleanup |

Example: `002-001-add-user-auth.md` = High priority, first in sequence

## Configuration

Environment variables for customization:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_MODEL` | `opus` | Model to use (opus, sonnet, haiku) |
| `AGENT_DRY_RUN` | `0` | Preview without executing |
| `AGENT_VERBOSE` | `0` | More output |
| `AGENT_MAX_RETRIES` | `2` | Max retry attempts per phase |
| `AGENT_NAME` | `worker-N` | Agent identifier |

Phase timeouts (in seconds):

| Variable | Default | Phase |
|----------|---------|-------|
| `TIMEOUT_TRIAGE` | 120 | Triage (2min) |
| `TIMEOUT_PLAN` | 300 | Planning (5min) |
| `TIMEOUT_IMPLEMENT` | 1800 | Implementation (30min) |
| `TIMEOUT_TEST` | 600 | Testing (10min) |
| `TIMEOUT_DOCS` | 300 | Documentation (5min) |
| `TIMEOUT_REVIEW` | 300 | Review (5min) |
| `TIMEOUT_VERIFY` | 120 | Verification (2min) |

## Requirements

- Claude Code CLI installed and authenticated
- Bash 4.0+
- Git
- macOS or Linux


### Use with Claude

`claude --dangerously-skip-permissions --model opus --permission-mode bypassPermissions`


## License

MIT
