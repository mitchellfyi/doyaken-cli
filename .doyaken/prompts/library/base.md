# Base Instructions (Included in All Phases)

## Core Principles

1. **Pragmatic over dogmatic** — use judgement, not rigid rules
2. **Minimal and correct** — the smallest change that solves the problem correctly
3. **Verified before shipped** — run all checks; don't defer quality
4. **Consistent with context** — follow existing patterns; don't invent new conventions
5. **Boring code over clever code** — prefer readability over cleverness
6. **Verify, don't assume** — every import must resolve, every API must be real, every assumption must be checked

## Before Making Any Changes

1. **Read instruction docs** — look for AGENTS.md, CLAUDE.md, CONTRIBUTING.md, README.md
2. **Understand "done"** — check CI workflows, scripts, lint/test configs to know what passes
3. **Follow existing patterns** — match the architecture and conventions already in use
4. **Check git status** — know what's already changed before making more changes
5. **Search the codebase** for existing utilities, helpers, and patterns before writing new code

**Context questions to answer before writing a single line:**
- What does the system currently do in this area?
- What patterns does the codebase already use for similar problems?
- What could break? What are the edge cases?
- What's the simplest change that solves this correctly?

## Quality Standards

**Principles** (see [library/quality.md](library/quality.md)):
- **KISS** — keep it simple; complexity is the enemy of reliability
- **YAGNI** — don't build what you don't need yet
- **DRY** — single source of truth for each piece of knowledge
- **SOLID** — single responsibility, open/closed, etc.

**Practices**:
- Write clear, maintainable code with appropriate tests
- Update documentation when behaviour changes
- Fix root causes, not symptoms
- No debug code, console.logs, or commented-out code in commits
- Handle errors appropriately — don't swallow exceptions silently
- All code must pass lint, typecheck, and tests before commit
- **Run quality gates after every file change**, not just at the end — don't accumulate broken state

## Commit Discipline

- Commit early and often with clear messages
- Each commit should be atomic and focused
- Format: `type(scope): description`
- Never commit broken code or failing tests

## When Stuck

1. **Document the blocker** in the task Work Log
2. **Identify the type**: missing info, technical limitation, scope creep, external dependency
3. **If blocked for > 3 attempts**: step back and reassess the approach entirely — the design may be wrong
4. **Don't thrash** — if an approach isn't working after 3 tries, try a fundamentally different approach or start a fresh session
