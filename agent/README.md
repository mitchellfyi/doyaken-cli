# Claude Agent System

Phase-based autonomous agent for Claude Code with self-healing capabilities and parallel support.

## Overview

This agent system breaks task execution into 7 distinct phases, each with its own Claude session:

| Phase | Timeout | Purpose |
|-------|---------|---------|
| 1. TRIAGE | 2min | Validate task, check dependencies |
| 2. PLAN | 5min | Gap analysis, detailed planning |
| 3. IMPLEMENT | 30min | Execute the plan, write code |
| 4. TEST | 10min | Run tests, add coverage |
| 5. DOCS | 5min | Sync documentation |
| 6. REVIEW | 5min | Code review, create follow-ups |
| 7. VERIFY | 2min | Verify task management |

## Features

- **Phase Isolation**: Each phase runs in a fresh Claude session (clean context)
- **Auto-Retry**: Retries failed phases with exponential backoff
- **Model Fallback**: Automatically switches from opus to sonnet on rate limits
- **Session Persistence**: Saves state for crash recovery
- **Parallel Support**: Multiple agents can work simultaneously via lock files

## Usage

```bash
# Run 5 tasks (default)
./bin/agent

# Run specific number
./bin/agent 3

# Run in parallel
./bin/agent 5 &
./bin/agent 5 &
```

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_MODEL` | `opus` | Model to use |
| `AGENT_DRY_RUN` | `0` | Preview without executing |
| `AGENT_VERBOSE` | `0` | More output |
| `AGENT_QUIET` | `0` | Minimal output |
| `AGENT_PROGRESS` | `1` | One-line progress updates |
| `AGENT_MAX_RETRIES` | `2` | Retry attempts per phase |
| `AGENT_NAME` | auto | Agent identifier |

Phase timeouts can be customized:

```bash
TIMEOUT_IMPLEMENT=3600 ./bin/agent  # 1 hour for implementation
```

## Files

```
agent/
  run.sh           # Entry point
  install.sh       # Install to new project
  lib/
    core.sh        # Core logic
  prompts/
    1-triage.md    # Phase prompts
    2-plan.md
    3-implement.md
    4-test.md
    5-docs.md
    6-review.md
    7-verify.md
  scripts/
    taskboard.sh   # Generate TASKBOARD.md
```

## Installation

To install into a new project:

```bash
./install.sh /path/to/project
```

This creates the necessary directory structure and copies all agent files.
