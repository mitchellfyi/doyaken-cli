A code review has requested changes on this PR. Please address the feedback.

## Instructions

1. **Understand the project context** — Read `AGENTS.md` (if it exists) for project conventions and coding standards.

2. **Read each piece of feedback** — Understand what the reviewer is asking for. Check the line-level comments and the overall review body.

3. **Evaluate each comment for validity** — Before making changes, critically assess whether each piece of feedback is correct:
   - Does the reviewer's concern reflect an actual bug, security issue, or pattern violation?
   - Is the suggested change technically sound, or would it introduce new problems?
   - Does the feedback align with the project's established conventions?
   - If a comment is based on a misunderstanding of the code, **do not implement it** — instead, respond explaining why the current code is correct.

4. **Make the valid changes** — Address each comment you've determined to be valid. If a comment is unclear, make a reasonable interpretation and note your reasoning.

5. **Run ALL quality gates before committing** — Read the CI workflow in `.github/workflows/` to find every check that runs (formatting, linting, type checking, tests, build, etc.) and run them all. Fix any issues.

6. **Commit and push** — Commit your changes with a descriptive message explaining what review feedback was addressed. Push to the current branch immediately.

## Principles

Apply these when implementing fixes:

- **Minimal fix** — Change only what the review asks for. Do not refactor, improve, or clean up surrounding code.
- **Simple over clever** — Choose the straightforward solution. Avoid abstractions, indirection, or optimisations that aren't needed.
- **DRY** — If your fix duplicates existing code, reuse the existing implementation instead.
- **SOLID** — Respect existing boundaries. Don't violate single-responsibility or break interfaces.
- **Match existing patterns** — Follow the conventions already used in the codebase. Don't introduce new patterns.

## Important

- Evaluate validity first — do not blindly implement every suggestion
- If you disagree with a comment, explain your reasoning clearly as a reply rather than silently ignoring it
- Follow existing code patterns and conventions in the project
- Do NOT create a new PR — just push to this branch
