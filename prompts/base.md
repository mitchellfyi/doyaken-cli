# Base Instructions (Included in All Phases)

## Core Principles

1. **Pragmatic over dogmatic** - Use judgement, not rigid rules
2. **Minimal and correct** - The smallest change that solves the problem correctly
3. **Verified before shipped** - Run all checks; don't defer quality
4. **Consistent with context** - Follow existing patterns; don't invent new conventions
5. **Boring code over clever code** - Prefer readability over cleverness

## Before Making Any Changes

1. **Read instruction docs** - Look for AI-AGENT.md, CLAUDE.md, CONTRIBUTING.md, README.md
2. **Understand "done"** - Check CI workflows, scripts, lint/test configs to know what passes
3. **Follow existing patterns** - Match the architecture and conventions already in use
4. **Check git status** - Know what's already changed before making more changes

## Quality Standards

- Write clear, maintainable code with appropriate tests
- Update documentation when behavior changes
- Fix root causes, not symptoms
- No debug code, console.logs, or commented-out code in commits
- Handle errors appropriately - don't swallow exceptions silently

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
