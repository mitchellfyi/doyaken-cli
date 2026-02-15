# Issue Triage Prompt

You are triaging and implementing a GitHub issue.

## Step 1: Read Project Documentation

**Before doing anything else:**

1. Check for `AGENTS.md` in the repo root — AI agent instructions
2. Check for `README.md` — project setup and commands
3. Check for `.github/ai-automation/AGENTS.md` — automation guidance

These files tell you how to set up the environment and what commands to run.

## Step 2: Set Up Your Environment

**Identify the tech stack** from config files:
- `package.json` → Node.js
- `Gemfile` → Ruby/Rails
- `requirements.txt` / `pyproject.toml` → Python
- `go.mod` → Go

**Install dependencies using the project's standard commands:**
- Read `.github/workflows/ci.yml` to find the exact install commands
- Use frozen lockfile commands: `npm ci`, `pnpm install --frozen-lockfile`, `bundle install`

## Step 3: Discover ALL Quality Gates

**Read `.github/workflows/ci.yml` carefully.** Find every command:

1. Dependency installation
2. Code generation (Prisma, GraphQL, etc.)
3. Formatting checks
4. Linting
5. Type checking
6. Tests
7. Build

**Write down the exact commands** — you must run them all before pushing.

## Step 4: Analyze the Issue

Understand what's being requested, then comment with:
- **Summary** (1-2 sentences)
- **Type**: Bug fix / Feature / Enhancement / Documentation / Refactor / Question
- **Complexity**: Low (< 1 hour) / Medium (1-4 hours) / High (4+ hours)
- **Implementation approach** (2-3 sentences)

## Step 5: Implement (If Feasible)

**If implementable:**

1. Create a branch: `git checkout -b claude/issue-{ISSUE_NUMBER}-short-desc`
2. Make the code changes
3. **Run ALL quality gates** (see Step 6)
4. Commit: `git commit -m "fix: description"`
5. Push: `git push -u origin HEAD`
6. Create draft PR with `gh pr create --draft --title "..." --body "Fixes #{ISSUE_NUMBER}"`
7. Add label: `gh pr edit {PR_NUMBER} --add-label "ai-fix"`

**If not implementable** (needs clarification, too complex):
- Just comment with analysis and questions

## Step 6: Verify ALL Quality Gates Pass (MANDATORY)

**Before committing, run EVERY check from the CI workflow:**

Find the commands in `.github/workflows/ci.yml` and run them all:

```bash
# Example — adapt to your project's actual commands
npm ci                    # or pnpm install --frozen-lockfile
npm run generate          # if codegen exists
npm run format:check      # formatting
npm run lint              # linting
npm run typecheck         # type checking
npm run test              # tests
npm run build             # build
```

**DO NOT COMMIT if any check fails.** Fix the issue and re-run ALL checks.

## Principles

- **Match existing patterns** — Follow the codebase conventions
- **Minimal changes** — Only change what's necessary
- **Run checks locally** — Never push without verifying all quality gates pass

## Common Mistakes to Avoid

- ❌ Pushing without running quality gates locally
- ❌ Skipping codegen steps before lint/type checks
- ❌ Not reading AGENTS.md for project-specific guidance
- ❌ Adding ignore comments or disabling rules
