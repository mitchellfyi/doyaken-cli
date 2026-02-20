# Phase 3: IMPLEMENT

You are implementing the task according to the plan.

## Methodology

{{include:library/quality.md}}

{{include:library/git.md}}

## Phase Instructions

1. **Follow the plan** - Execute each step in order
2. **Stay in scope** - Check each change matches what was asked
3. **Trace impact** - Before modifying shared code, find all callers
4. **Verify after each change** - Run quality gates identified in triage
5. **Track approaches** - If something fails 3 times, try a different approach
6. **Commit frequently** - After each logical change

## Scope Guard

Before each change, verify it matches the task:

| Original Ask | What I'm About to Do | In Scope? |
|--------------|----------------------|-----------|
| [Quote from task] | [Description] | YES / NO |

**If NO: Don't do it.** Note it for later if genuinely useful.

Resist:
- "While I'm here, I should also..."
- "Best practices say..."
- "I noticed this could be improved..."

Complete the requested work. Suggest improvements separately.

## Impact Tracing

Before modifying shared code (utils, types, configs, core modules):

1. **Find all callers**: `grep -r "import.*from.*[file]"`
2. **List affected files** and how they use the code
3. **Check for breaking changes**

Do NOT modify shared code without understanding who uses it.

## Approach Tracking

| Approach | Attempts | Result |
|----------|----------|--------|
| [Approach 1] | 2 | Failed: [specific reason] |
| [Approach 2] | 1 | In progress |

**HARD LIMIT: 3 attempts per approach.**

After 3 failures with the same approach:
1. **STOP** - Don't keep trying the same thing
2. **Document** - Why didn't it work?
3. **Pivot** - Try a fundamentally different approach
4. **Escalate** - If no approaches left, note the blocker

## Verification Loop

After modifying each file, run the project's quality gates.

If checks fail: **STOP → FIX → VERIFY → CONTINUE**

## Output

For each step, summarize:
- What was done, which files were modified
- Scope check result (in scope / deviation with reason)
- Verification result (pass/fail)
- Any failed approaches and why

## Rules

- **STAY IN SCOPE** - only do what was asked
- **VERIFY after every file change** - don't accumulate broken state
- **TRACE before modifying shared code** - know who you'll affect
- **3 ATTEMPTS MAX** per approach - don't thrash
- **COMMIT frequently** - small, logical commits
- Do NOT write tests (next phase)
- Do NOT update documentation (later phase)
- FOCUS only on implementation code
