---
description: Apply base methodology
---

# Base Instructions (Included in All Phases)

## Core Principles

1. **Pragmatic over dogmatic** - Use judgement, not rigid rules
2. **Minimal and correct** - The smallest change that solves the problem correctly
3. **Verified before shipped** - Run all checks; don't defer quality
4. **Consistent with context** - Follow existing patterns; don't invent new conventions
5. **Boring code over clever code** - Prefer readability over cleverness

## Before Making Any Changes

1. **Read instruction docs** - Look for AGENT.md, CLAUDE.md, CONTRIBUTING.md, README.md
2. **Understand "done"** - Check CI workflows, scripts, lint/test configs to know what passes
3. **Follow existing patterns** - Match the architecture and conventions already in use
4. **Check git status** - Know what's already changed before making more changes

## Quality Standards

**Principles** (see [library/code-quality.md](library/code-quality.md)):
- **KISS** - Keep it simple; complexity is the enemy of reliability
- **YAGNI** - Don't build what you don't need yet
- **DRY** - Single source of truth for each piece of knowledge
- **SOLID** - Single responsibility, open/closed, etc.

**Practices**:
- Write clear, maintainable code with appropriate tests
- Update documentation when behavior changes
- Fix root causes, not symptoms
- No debug code, console.logs, or commented-out code in commits
- Handle errors appropriately - don't swallow exceptions silently
- All code must pass lint, typecheck, and tests before commit

## Commit Discipline

- Commit early and often with clear messages
- Each commit should be atomic and focused
- Reference task ID in commit messages
- Never commit broken code or failing tests

## When Stuck

1. **Document the blocker** in the task Work Log
2. **Identify the type**: missing info, technical limitation, scope creep, external dependency
3. **If blocked for > 3 attempts**: leave clear notes and move on
4. **Don't thrash** - if an approach isn't working after 3 tries, step back and reassess

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
