## Context: Previous Fix Attempt Failed

Your previous fix attempt did not resolve the CI failures. You need to understand what went wrong and try a different approach.

## Step 1: Review Previous Attempts

**Before making changes, understand what was already tried:**

```bash
# See what commits were made
git log --oneline origin/main..HEAD

# See what code was changed
git diff origin/main..HEAD --stat
git diff origin/main..HEAD
```

Understand why the previous approach didn't work. Don't repeat the same fix.

## Step 2: Read Project Documentation

Check for project-specific guidance:
- `AGENTS.md` in repo root — AI agent instructions
- `README.md` — project setup
- `.github/ai-automation/AGENTS.md` — automation guidance

## Step 3: Set Up Environment (Match CI Exactly)

**Read `.github/workflows/ci.yml` and run the EXACT same commands:**

1. Install dependencies using the CI's command (e.g., `npm ci`, `pnpm install --frozen-lockfile`, `bundle install`)
2. Run any codegen steps (Prisma, GraphQL, etc.)
3. Set up test databases if needed

## Step 4: Reproduce the NEW Failure

**These are NEW errors** — they may differ from the original failure.

1. Run the exact commands that failed in CI
2. Capture the full error output
3. Identify whether this is:
   - A new issue introduced by the previous fix
   - The original issue that wasn't fully resolved
   - A cascading failure from an earlier step

## Step 5: Fix the Root Cause

**Apply a proper fix:**
- Change only what's necessary
- Match existing code patterns
- Do NOT suppress, skip, or weaken checks
- Do NOT add ignore comments

**If the previous fix caused a regression:**
- Consider reverting part of it
- Fix the regression before addressing the original issue

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

## Step 7: Commit and Push

Only after ALL quality gates pass:

```bash
git add -A
git commit -m "fix: description of what this fix addresses"
git push
```

**Do NOT create a new PR** — push to this branch.

## Common Retry Mistakes

- ❌ Trying the same approach that already failed
- ❌ Pushing without running all quality gates locally
- ❌ Fixing one error but introducing another
- ❌ Not reading the NEW error messages carefully
- ❌ Adding workarounds instead of fixing root causes
