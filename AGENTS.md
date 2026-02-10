# AI Agent Instructions

This file is the source of truth for all AI coding agents working on this project.

## Quick Start

1. Read `PROJECT.md` for project goals and tech stack
2. Check `.doyaken/tasks/` for current work items
3. Follow the guidelines in `.doyaken/prompts/library/`

## Using Doyaken Artifacts (Without the CLI)

This project uses doyaken for task management and AI-assisted development. Even if you are **not** running through the doyaken CLI (e.g., you're Claude Code, Cursor, Copilot, Gemini, or any other AI agent working directly on this repo), you MUST use the doyaken artifacts below as part of your workflow.

### Tasks — Pick Up Work

Before starting work, check for existing tasks:

1. Look in `.doyaken/tasks/2.todo/` for tasks ready to start
2. When you begin a task, move it to `.doyaken/tasks/3.doing/`
3. When done, move it to `.doyaken/tasks/4.done/`
4. If a user gives you a task that matches an existing task file, use that file for context

### Prompts — Read Before You Code

The `.doyaken/prompts/library/` directory contains methodology prompts. **Read the relevant prompt before doing that type of work:**

- Writing code → read `quality.md`
- Writing tests → read `testing.md`
- Debugging → read `debugging.md`
- Refactoring → read `refactor.md`
- Security-sensitive changes → read `review-security.md`
- Planning → read `planning.md`
- Code review → read `review.md`
- Error handling → read `errors.md`

These are not optional references — they contain the project's expected methodology.

### Skills — On-Demand Capabilities

The `.doyaken/skills/` directory contains reusable skill definitions. When a task matches a skill, **read and follow that skill's instructions**:

- Running quality checks → read `check-quality.md`
- Security audit → read `audit-security.md`
- Performance analysis → read `audit-performance.md`
- Technical debt review → read `audit-debt.md`
- Dependency audit → read `audit-deps.md`
- Creating a PR → read `github-pr.md`
- CI failures → read `ci-fix.md`

### Hooks — Quality Enforcement

The `.doyaken/hooks/` directory contains shell scripts for quality enforcement. Run the relevant hook scripts as part of your workflow:

- Before committing → run `check-quality-gates.sh`
- After editing code → consider `check-quality.sh`, `check-security.sh`
- When touching sensitive files → check `protect-sensitive-files.sh` for protected paths

### Phases — Structured Task Workflow

For non-trivial tasks, follow the 8-phase workflow in `.doyaken/prompts/phases/`. Read the phase prompt for each step:

0. **Expand** (`0-expand.md`) — Turn a brief into a full spec
1. **Triage** (`1-triage.md`) — Validate the task, check dependencies
2. **Plan** (`2-plan.md`) — Gap analysis and implementation planning
3. **Implement** (`3-implement.md`) — Write the code
4. **Test** (`4-test.md`) — Add tests
5. **Docs** (`5-docs.md`) — Update documentation
6. **Review** (`6-review.md`) — Self-review the changes
7. **Verify** (`7-verify.md`) — Final verification

You don't need to run all 8 phases for every change. Use your judgment — a typo fix doesn't need phase 0, but a new feature should go through most phases.

### Vendor Prompts — Technology-Specific Guidance

If the project uses specific technologies, check `.doyaken/prompts/vendors/` for best practices (e.g., `nextjs/`, `react/`, `rails/`, `supabase/`). Read the relevant vendor prompts when working with those technologies.

### Configuration

Read `.doyaken/manifest.yaml` for project-specific settings including quality gate commands.

---

## Core Guidelines

Read these prompts before writing code:

- **[Code Quality](.doyaken/prompts/library/quality.md)** - KISS, YAGNI, DRY, SOLID principles
- **[Testing](.doyaken/prompts/library/testing.md)** - Test methodology and structure
- **[Security](.doyaken/prompts/library/review-security.md)** - OWASP Top 10, security checklist

## Quality Gates

All code must pass before commit:
- Linting passes
- Type checking passes (if applicable)
- Tests pass
- Build succeeds

Check `.doyaken/manifest.yaml` for project-specific commands.

## Commit Messages

Format: `type(scope): description [task-id]`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

---

## Project Structure

```
.doyaken/
  manifest.yaml       # Project settings
  tasks/
    1.blocked/        # Blocked by dependencies
    2.todo/           # Ready to start
    3.doing/          # In progress
    4.done/           # Completed
  prompts/
    library/          # Reusable prompt modules
    phases/           # Workflow phase prompts
  skills/             # On-demand skills
```

## Prompts Library

Detailed methodology in `.doyaken/prompts/library/`:

| Prompt | Use When |
|--------|----------|
| [quality.md](.doyaken/prompts/library/quality.md) | Writing or reviewing code |
| [testing.md](.doyaken/prompts/library/testing.md) | Adding or modifying tests |
| [review.md](.doyaken/prompts/library/review.md) | Code review |
| [planning.md](.doyaken/prompts/library/planning.md) | Planning implementation |
| [review-security.md](.doyaken/prompts/library/review-security.md) | Security-sensitive code |
| [debugging.md](.doyaken/prompts/library/debugging.md) | Investigating issues |
| [errors.md](.doyaken/prompts/library/errors.md) | Error handling |
| [refactor.md](.doyaken/prompts/library/refactor.md) | Refactoring code |

## Workflow Phases

For structured tasks, use phases in `.doyaken/prompts/phases/`:

| Phase | File | Purpose |
|-------|------|---------|
| 0 | [0-expand.md](.doyaken/prompts/phases/0-expand.md) | Expand brief into full spec |
| 1 | [1-triage.md](.doyaken/prompts/phases/1-triage.md) | Validate task, check deps |
| 2 | [2-plan.md](.doyaken/prompts/phases/2-plan.md) | Gap analysis, planning |
| 3 | [3-implement.md](.doyaken/prompts/phases/3-implement.md) | Write code |
| 4 | [4-test.md](.doyaken/prompts/phases/4-test.md) | Add tests |
| 5 | [5-docs.md](.doyaken/prompts/phases/5-docs.md) | Update documentation |
| 6 | [6-review.md](.doyaken/prompts/phases/6-review.md) | Code review |
| 7 | [7-verify.md](.doyaken/prompts/phases/7-verify.md) | Final verification |

## Skills

On-demand skills in `.doyaken/skills/`:

| Skill | Purpose |
|-------|---------|
| [check-quality](.doyaken/skills/check-quality.md) | Run all quality checks |
| [audit-security](.doyaken/skills/audit-security.md) | Security code review |
| [audit-performance](.doyaken/skills/audit-performance.md) | Performance analysis |
| [audit-debt](.doyaken/skills/audit-debt.md) | Technical debt assessment |
| [audit-deps](.doyaken/skills/audit-deps.md) | Dependency security audit |

## Task Management

### Task File Format

Files in `.doyaken/tasks/` use format: `PPP-SSS-slug.md`
- PPP = Priority (001=Critical, 002=High, 003=Medium, 004=Low)
- SSS = Sequence number
- Priority is evaluated during EXPAND (recommended) and TRIAGE (compared against backlog) phases
- Use `rename_task_priority()` from `lib/project.sh` to change a task's priority prefix and metadata

### Task States

| State | Meaning |
|-------|---------|
| `1.blocked/` | Waiting on dependencies |
| `2.todo/` | Ready to start |
| `3.doing/` | Currently in progress |
| `4.done/` | Completed |

## Configuration

See `.doyaken/manifest.yaml` for:
- Project metadata
- Quality gate commands
- Agent settings
- Integration configuration
