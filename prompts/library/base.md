# Base Instructions (Included in All Phases)

## Core Principles

1. **Pragmatic over dogmatic** - Use judgement, not rigid rules
2. **Minimal and correct** - The smallest change that solves the problem correctly
3. **Verified before shipped** - Run all checks; don't defer quality. "Looks right" ≠ "Is right"
4. **Consistent with context** - Follow existing patterns; don't invent new conventions
5. **Boring code over clever code** - Prefer readability over cleverness
6. **Stay in scope** - Do what was asked, suggest improvements separately

## Before Making Any Changes

1. **Read instruction docs** - Look for AGENT.md, CLAUDE.md, CONTRIBUTING.md, README.md
2. **Understand "done"** - Check CI workflows, scripts, lint/test configs to know what passes
3. **Follow existing patterns** - Match the architecture and conventions already in use
4. **Check git status** - Know what's already changed before making more changes
5. **Verify assumptions** - If you're assuming something about the code, verify it first

## Scope Discipline

Before making changes, check:
- **Was this asked for?** If no, don't do it.
- **Am I adding extras?** Features, refactors, "improvements" not requested → resist.
- **"While I'm here..."** → Stop. Complete the task first. Note improvements separately.

Complete requested work. Suggest improvements as follow-ups.

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

1. **Document the blocker** clearly in your output
2. **Identify the type**: missing info, technical limitation, scope creep, external dependency
3. **Track approaches**: what you tried, why it failed
4. **HARD LIMIT: 3 attempts per approach** - after 3 failures:
   - STOP trying the same thing
   - Document why it didn't work
   - Try a fundamentally different approach
   - Escalate if no approaches remain
5. **Don't thrash** - repeating the same failing approach wastes time

## Verification

Before claiming something works:
- **Run it** - don't assume code is correct because it looks correct
- **Test the specific thing** - not just the happy path
- **Show evidence** - command output, test results, not just assertions

"Done" means verified, not implemented.

## Capturing Learnings

When something fails or takes longer than expected:
- **Document failed approaches** - what was tried, why it didn't work
- **Note the insight** - what finally worked and why
- **Would do differently** - lessons for next time

Failed approaches are valuable knowledge. Don't discard them.
