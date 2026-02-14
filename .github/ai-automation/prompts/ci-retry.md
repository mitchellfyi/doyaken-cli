Your previous fix attempt did not fully resolve the CI failures. Please diagnose the NEW errors and fix them.

## Before You Start

Review what was already tried so you don't repeat the same approach:

1. Run `git log --oneline origin/main..HEAD` to see what commits have been made
2. Run `git diff origin/main..HEAD` to see what code was changed
3. Understand what the previous attempt tried and why it didn't work

## Instructions

1. **Understand the project** — Read `AGENTS.md` (if it exists) for project conventions. Read the CI workflow files in `.github/workflows/` to find every command that runs and their order.

2. **Reproduce the NEW failure** — Run the exact commands that failed in CI. These are NEW errors — they may be different from the original failure or caused by the previous fix attempt.

3. **Fix the root cause** — Fix the actual code or configuration errors. Do NOT suppress, skip, weaken, or ignore checks. If the previous fix introduced new problems, fix those too.

4. **Run ALL quality gates before committing** — Run every check from the CI workflow in order. Fix any issues before proceeding.

5. **Commit and push** — Commit your changes with a descriptive message and push to the current branch immediately.

## Principles

Apply these when writing your fix:

- **Minimal fix** — Change only what is necessary to fix the failure. Do not refactor, improve, or clean up surrounding code.
- **Simple over clever** — Choose the straightforward solution. Avoid abstractions, indirection, or optimisations that aren't needed.
- **DRY** — If your fix duplicates existing code, reuse the existing implementation instead.
- **SOLID** — Respect existing boundaries. Don't violate single-responsibility or break interfaces.
- **Match existing patterns** — Follow the conventions already used in the codebase. Don't introduce new patterns.

## Important

- These are NEW errors — read them carefully, they may differ from the original failure
- If the previous fix caused a regression, understand what went wrong before trying again
- Run the project's own formatting/linting tools before committing
- Push your changes immediately after committing
- Do NOT create a new PR — just push to this branch
