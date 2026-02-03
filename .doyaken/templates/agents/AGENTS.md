# AI Agent Instructions

This file is the source of truth for all AI coding agents working on this project.

## Quick Start

1. Read `PROJECT.md` for project goals and tech stack
2. Check `.doyaken/tasks/` for current work items
3. Follow the guidelines in `.doyaken/prompts/library/`

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

---

## Project Knowledge

*This section is updated by agents as they learn about the codebase. It captures patterns, gotchas, and hard-won knowledge that future agents should know.*

### Architecture Patterns

<!-- Add patterns discovered while working on this codebase -->
<!-- Example: "Auth is handled in route handlers, not middleware" -->

### Gotchas

<!-- Add surprising behaviors or non-obvious things -->
<!-- Example: "Config changes require server restart" -->

### Conventions

<!-- Add project-specific conventions discovered -->
<!-- Example: "Use kebab-case for all file names" -->

### Don't Do

<!-- Add approaches that were tried and failed -->
<!-- Example: "Don't use library X, conflicts with Y" -->

---

*Knowledge above is captured during task completion (Phase 7). Update when you discover something future agents should know.*
