# Skill: dkprreview

Critically evaluate PR review comments — fix what should be fixed, push back on what should not, and escalate what needs human judgement.

## When to Use

- Invoked by `/dkwatchpr` when new review comments are detected
- Invoked directly to address all outstanding PR comments in one pass
- After receiving review feedback on a PR

## Arguments

None. Operates on the current branch's open PR.

## Steps

### 1. Gather Context

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
PR_NUM=$(gh pr view --json number -q .number)
```

Fetch all review data:

```bash
# Reviews (approve/request-changes/comment verdicts)
gh api repos/$REPO/pulls/$PR_NUM/reviews

# Inline comments (the actual feedback)
gh api repos/$REPO/pulls/$PR_NUM/comments

# General PR-level comments (issue-style, not inline)
gh api repos/$REPO/issues/$PR_NUM/comments
```

Identify **unaddressed comments**: comments with no reply from the PR author. Filter out:
- Your own prior replies (from earlier `/dkprreview` or `/dkwatchpr` runs)
- Approval comments with no actionable content
- Bot comments that are purely informational (CI status, coverage reports, deploy previews)

If there are no unaddressed comments, report that and exit immediately.

### 2. Understand the Full Change

Before evaluating any comment, build context on the PR's scope and intent:

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
DEFAULT_BRANCH=$(dk_default_branch)
git diff origin/$DEFAULT_BRANCH...HEAD --stat
git log origin/$DEFAULT_BRANCH..HEAD --oneline
```

Read the PR description (`gh pr view $PR_NUM --json body -q .body`). This establishes what the change is trying to accomplish — essential for judging whether reviewer suggestions are in-scope.

### 3. Critically Evaluate Each Comment

For each unaddressed comment, classify it and decide on the action.

#### 3.1 Classification

| Type | Indicators |
|------|-----------|
| **Bug report** | Points to a specific failure mode, incorrect output, or broken edge case |
| **Security concern** | Identifies a vulnerability, missing validation, or data exposure |
| **Request-change** | Explicitly asks for a modification with a clear rationale |
| **Question** | Asks why something was done a certain way, or what a piece of code does |
| **Suggestion** | Proposes an alternative approach, naming change, or refactor |
| **Nitpick** | Minor style, formatting, or preference comment |
| **Approval** | Positive feedback, LGTM, acknowledgement |

#### 3.2 Decision Framework

**Tier 1 — Always fix (no evaluation needed):**
- Bug reports with evidence (specific input that fails, incorrect output, missing edge case)
- Security vulnerabilities (missing auth, injection, data exposure)
- Missing error handling the reviewer identified in new code
- Broken types or tests the reviewer found
- Factual errors in documentation or comments

**Tier 2 — Evaluate then decide:**

For each Tier 2 comment, assess four criteria:

1. **Correctness impact** — Does this fix an actual bug or prevent a real failure? If yes, lean toward fixing.
2. **Codebase consistency** — Does the suggestion align with existing patterns in this repo? Read nearby files and the project's conventions (CLAUDE.md, `.doyaken/rules/`). If the suggestion contradicts established patterns, lean toward not fixing.
3. **Scope alignment** — Is the change within this PR's scope? If it requires touching files outside the PR or changing the architectural approach, lean toward not fixing (or escalating).
4. **Effort-to-value ratio** — Trivial fix (< 5 min) with clear value: fix. Significant refactor with debatable benefit: do not fix.

Tier 2 applies to: style/naming preferences that conflict with codebase patterns, alternative implementations, performance concerns without evidence of actual impact, "use library X instead of Y" suggestions, refactoring suggestions that expand scope.

The decision is binary: **fix** or **do not fix**. Do not partially fix. If you would fix it differently than the reviewer suggests, fix it your way and explain the deviation in the reply.

**Tier 3 — Always escalate (never decide autonomously):**
- Architectural changes (affects the approach, multiple files outside PR scope, changes data model)
- Disagreements about requirements or acceptance criteria
- Unclear comments that could mean different things
- Requests that conflict with the approved plan or ticket scope

### 4. Implement Fixes

For all comments decided as "fix":

1. **Read the referenced code** — read the full file, not just the diff hunk. Understand the surrounding context.
2. **Implement the fix** — follow existing patterns. Keep the fix minimal and focused on what the reviewer raised.
3. **Run targeted verification** — run the project's quality checks (format, lint, typecheck, test) scoped to the affected files. Fix any issues introduced by the fix.
4. **Do not commit yet** — accumulate fixes, commit in Step 5.

If a fix introduces a new issue (breaks a test, causes a type error), resolve it before moving to the next comment. If the fix turns out to be complex enough to qualify as an architectural change, reclassify the comment to Tier 3 and escalate instead.

### 5. Commit and Push

After all fixes are implemented and verified:

1. **Group fixes logically** — if all fixes are small and related, use a single commit. If fixes address different concerns (e.g., one is a bug fix, another is a naming change), use separate commits.
2. **Commit format:** `fix(review): <description>`
   - Single fix: `fix(review): handle nil check in user lookup`
   - Multiple related fixes: `fix(review): address review feedback — nil check, error message, naming`
3. **Push once:**
   ```bash
   git push
   ```

### 6. Reply to Comments

After pushing (so commit SHAs are available), reply to every unaddressed comment. Use the appropriate API endpoint based on comment type:

**Inline comments (from pull request review):**
```bash
gh api repos/$REPO/pulls/$PR_NUM/comments/<comment-id>/replies \
  -f body="<reply>"
```

**PR-level comments (issue-style):**
```bash
gh api repos/$REPO/issues/$PR_NUM/comments \
  -f body="<reply>"
```

**Reply format by decision:**

| Decision | Format |
|----------|--------|
| **Fixed** | `Fixed in <short-sha>. <1-2 sentence explanation of the change.>` |
| **Not fixing** | `Keeping current approach: <concise reason referencing specific code or pattern>. Open to discussion if you see something I'm missing.` |
| **Question answered** | `<Direct answer referencing specific code context.>` |
| **Nitpick fixed** | `Fixed in <short-sha>.` |
| **Escalated** | No reply — handled in Step 7. |

**Reply rules:**
- Keep replies factual and concise. No filler ("Great catch!", "Thanks for the review!").
- Always reference specific code, files, or patterns when explaining a decision not to fix.
- Never dismiss a comment without reasoning. Even nitpicks get a reply.

### 7. Handle Escalations

If any comments were classified as Tier 3 (escalate):

**When invoked standalone (user ran `/dkprreview`):**
- Present each escalation to the user with:
  - The reviewer's comment (quoted)
  - The referenced code
  - Why this needs human judgement
  - 2-3 options for how to respond (if applicable)
- Wait for user direction before replying.

**When invoked from `/dkwatchpr` loop:**
- Return the escalation list. `/dkwatchpr` handles cancelling loops and reporting to the user.

### 8. Report

Print a summary:

```
## PR Review Comments Addressed

| # | Reviewer | Type | Decision | Detail |
|---|----------|------|----------|--------|
| 1 | @reviewer | Bug report | Fixed | <short-sha> — nil check in user lookup |
| 2 | @reviewer | Suggestion | Not fixing | Existing pattern uses X, not Y |
| 3 | @reviewer | Question | Answered | Explained caching strategy |
| 4 | @reviewer | Architectural | Escalated | Requires user decision |

**Fixed:** N comments (M commits pushed)
**Not fixing:** N comments (all replied with reasoning)
**Answered:** N questions
**Escalated:** N comments (awaiting user direction)
```

## Notes

- This skill critically evaluates comments. It does NOT blindly fix everything. Reviewers can be wrong, suggest personal preferences, or request changes that would make the code worse. The agent's job is to use judgement, not compliance.
- When not fixing a comment, the reasoning must be substantive — reference specific code, patterns, or constraints. "I disagree" is not sufficient.
- Do not resolve review threads — only GitHub's web UI or the reviewer should resolve threads.
- Do not dismiss reviews — reply and let the reviewer re-review.
- When invoked from `/dkwatchpr`, the comment fetching in Step 1 may duplicate what the caller already fetched. The skill re-fetches anyway for freshness and standalone compatibility.
