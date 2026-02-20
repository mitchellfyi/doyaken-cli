# AI Agent Instructions

This file is the source of truth for all AI coding agents working on this project.

## Project Context

Doyaken is a single-shot execution engine for AI coding agents. One prompt in, verified code out. It runs work through an 8-phase pipeline with verification gates that retry until the code builds, lints, and passes tests.

**Goals**: Robust output (code that actually works), agent agnostic (Claude/Cursor/Codex/Gemini/Copilot/OpenCode), single-shot execution (no task queue), self-healing (retries, fallback, crash recovery).

**Non-goals**: Not a task/project manager, not a replacement for any agent (it's an orchestrator), not an IDE extension — CLI only.

**Tech stack**: Bash 4.0+, npm for distribution, YAML config. Bash 3.x compat required (no associative array init syntax). All scripts must pass shellcheck (`npm run lint`). Run `npm run test` before committing.

## Quick Start

1. Follow the guidelines in `.doyaken/prompts/library/`
2. Use the 8-phase workflow for non-trivial tasks
3. Run `npm run lint` and `npm test` before committing

## Using Doyaken Artifacts (Without the CLI)

This project uses doyaken for AI-assisted development. Even if you are **not** running through the doyaken CLI (e.g., you're Claude Code, Cursor, Copilot, Gemini, or any other AI agent working directly on this repo), you MUST use the doyaken artifacts below as part of your workflow.

### Prompts — Read Before You Code

The `.doyaken/prompts/library/` directory contains methodology prompts. **Read the relevant prompt before doing that type of work:**

- Writing code -> read `quality.md`
- Writing tests -> read `testing.md`
- Debugging -> read `debugging.md`
- Refactoring -> read `refactor.md`
- Security-sensitive changes -> read `review-security.md`
- Planning -> read `planning.md`
- Code review -> read `review.md`
- Error handling -> read `errors.md`

These are not optional references — they contain the project's expected methodology.

### Skills — On-Demand Capabilities

The `.doyaken/skills/` directory contains reusable skill definitions. When a task matches a skill, **read and follow that skill's instructions**:

- Running quality checks -> read `check-quality.md`
- Security audit -> read `audit-security.md`
- Performance analysis -> read `audit-performance.md`
- Technical debt review -> read `audit-debt.md`
- Dependency audit -> read `audit-deps.md`
- Creating a PR -> read `github-pr.md`
- CI failures -> read `ci-fix.md`

### Hooks — Quality Enforcement

The `.doyaken/hooks/` directory contains shell scripts for quality enforcement. Run the relevant hook scripts as part of your workflow:

- Before committing -> run `check-quality-gates.sh`
- After editing code -> consider `check-quality.sh`, `check-security.sh`
- When touching sensitive files -> check `protect-sensitive-files.sh` for protected paths

### Phases — Structured Execution Workflow

For non-trivial work, follow the 8-phase workflow in `.doyaken/prompts/phases/`. Each phase has a dedicated prompt:

0. **Expand** (`0-expand.md`) — Turn a brief into a full spec
1. **Triage** (`1-triage.md`) — Validate feasibility, check dependencies
2. **Plan** (`2-plan.md`) — Gap analysis and implementation planning
3. **Implement** (`3-implement.md`) — Write the code
4. **Test** (`4-test.md`) — Add tests
5. **Docs** (`5-docs.md`) — Update documentation
6. **Review** (`6-review.md`) — Self-review the changes
7. **Verify** (`7-verify.md`) — Final verification and commit

When running through the doyaken CLI, verification gates (build, lint, format, test) run automatically after every phase. Each phase has a configurable retry budget — if gates fail and retries remain, the phase re-runs with the error output in context.

You don't need to run all 8 phases for every change. Use your judgment — a typo fix doesn't need phase 0, but a new feature should go through most phases.

### Vendor Prompts — Technology-Specific Guidance

If the project uses specific technologies, check `.doyaken/prompts/vendors/` for best practices (e.g., `nextjs/`, `react/`, `rails/`, `supabase/`). Read the relevant vendor prompts when working with those technologies.

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

## Commit Messages

Format: `type(scope): description`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

---

## Project Structure

```
.doyaken/
  prompts/
    library/          # Reusable prompt modules (source of truth)
    phases/           # 8-phase workflow prompts
  skills/             # On-demand skills
  logs/               # Execution logs
  state/              # Session recovery
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

For structured execution, use phases in `.doyaken/prompts/phases/`:

| Phase | File | Purpose |
|-------|------|---------|
| 0 | [0-expand.md](.doyaken/prompts/phases/0-expand.md) | Expand brief into full spec |
| 1 | [1-triage.md](.doyaken/prompts/phases/1-triage.md) | Validate feasibility, check deps |
| 2 | [2-plan.md](.doyaken/prompts/phases/2-plan.md) | Gap analysis, planning |
| 3 | [3-implement.md](.doyaken/prompts/phases/3-implement.md) | Write code |
| 4 | [4-test.md](.doyaken/prompts/phases/4-test.md) | Add tests |
| 5 | [5-docs.md](.doyaken/prompts/phases/5-docs.md) | Update documentation |
| 6 | [6-review.md](.doyaken/prompts/phases/6-review.md) | Code review |
| 7 | [7-verify.md](.doyaken/prompts/phases/7-verify.md) | Final verification |

All phases run verification gates after completion. Retry budgets are configurable per phase.

## Skills

On-demand skills in `.doyaken/skills/`:

| Skill | Purpose |
|-------|---------|
| [check-quality](.doyaken/skills/check-quality.md) | Run all quality checks |
| [audit-security](.doyaken/skills/audit-security.md) | Security code review |
| [audit-performance](.doyaken/skills/audit-performance.md) | Performance analysis |
| [audit-debt](.doyaken/skills/audit-debt.md) | Technical debt assessment |
| [audit-deps](.doyaken/skills/audit-deps.md) | Dependency security audit |

