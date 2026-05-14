---
name: "dkreviewloop"
description: "Run full-scope Doyaken review waves in fresh independent subagents until three clean reports in a row."
---

# Skill: dkreviewloop

Run `/dkreview --single-pass` as a sequence of fresh full review waves until
**3 clean reports in a row** (max 20 iterations). This is the default Review
phase used by `dk`.

The outer guarantee remains strict: three consecutive full-scope waves must
write `CLEAN`. A wave that finds and fixes issues writes `FINDINGS_FIXED:N`, so
the clean counter resets and the next fresh wave re-reviews the full change set.

## When To Use

- When the user invokes `/dkreviewloop`
- Before committing or pushing significant work
- As the in-session counterpart to the `dkreviewloop` shell function

## Why Fresh Full Waves

A single reviewer can convince itself that its own fixes are sufficient. Fresh
waves reduce that motivated-reasoning risk. The improvement here is that each
wave spends time efficiently: context pack first, deterministic checks first,
parallel read-only specialist reviewers, verifier triage, batch fixes, and then
targeted recheck. The outer loop still demands three full clean passes.

## Steps

### 1. Detect The Review Scope

Review the **full current change set**, not just the first category that happens
to have changes. Include all of these when present:

- **Committed branch changes** - prefer `git diff origin/<default>...HEAD` when
  the default branch ref exists; use `git diff @{u}...HEAD` only as fallback.
- **Staged changes** - `git diff --cached`
- **Unstaged changes** - `git diff`
- **Untracked files** - `git ls-files --others --exclude-standard`, with contents
  represented by `git diff --no-index -- /dev/null <file>` for each file.

If there are no changes, stop and tell the user there is nothing to review.

Print the scope name, review commands, and unique file count before spawning the
first pass.

### 2. Spawn Fresh Review-Wave Sessions

For each iteration (up to **20**), spawn a fresh subagent via the Agent tool
with `subagent_type: "general-purpose"`. Each Agent invocation is a fresh
context window.

The subagent is a **review-wave orchestrator**. It may fix verified findings, but
the specialist reviewers it spawns inside the wave must be read-only.

When running inside a `dk` lifecycle (`DOYAKEN_SESSION_ID` is present), mark the
review pass as in progress before spawning/waiting on each subagent, then remove
the marker immediately after that subagent returns:

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
SESSION_ID="${DOYAKEN_SESSION_ID:-$(dk_session_id)}"
BUSY_FILE="$(dk_phase_busy_file "$SESSION_ID" 3)"
printf '%s\t%s\n' "$(date +%s)" "dkreviewloop pass ${ITERATION}/${MAX_ITERATIONS}; clean ${CLEAN_COUNT}/${REQUIRED_CLEAN}" > "$BUSY_FILE"
# spawn and wait for exactly one fresh review-wave subagent
rm -f "$BUSY_FILE" "$(dk_phase_busy_notice_file "$SESSION_ID" 3)"
```

The Stop hook uses this marker to avoid counting audit iterations while a review
pass is still running. Do not leave it behind.

The subagent prompt must include:

- the full-scope diff/stat/file-name commands from Step 1
- the review context pack path from `dk_review_context_file "$SESSION_ID"`
- an instruction to materialize a non-empty context pack before broad semantic
  exploration or specialist spawning
- an instruction to invoke `/dkreview --single-pass`
- an instruction to follow `prompts/review-wave.md`
- the specialist roster, including `review-frontend` and `review-devops` when
  relevant
- a request to report the final result signal exactly: `CLEAN`,
  `FINDINGS_FIXED:N`, `FINDINGS:N`, or `BLOCKED:reason`
- a reminder not to commit, push, create branches, create PRs, update PRs, or
  request external reviewers

If no plan or acceptance criteria are available, tell the subagent to mark
criteria-dependent evidence as **N/A** and continue.

Do not let a stale session prompt, previous conversation turn, session title, or
unrelated ticket file become acceptance criteria for this review scope.

If the Agent tool is unavailable for fresh review-wave sessions, stop with
`BLOCKED:agent-tool-unavailable`; do not simulate fresh passes in the same
context.

### 3. Track Consecutive Clean Passes

After each subagent returns, classify its result:

- `CLEAN` - `clean_count += 1`
- `FINDINGS_FIXED:N` - `clean_count = 0`; immediately run the next fresh
  full-scope wave
- `FINDINGS:N` - `clean_count = 0`; fix what is safe in the orchestrator if the
  pass did not, otherwise stop with the residual findings
- `BLOCKED:reason` - `clean_count = 0`; stop unless the block can be resolved
  locally without user judgment
- missing/unknown result - treat as non-clean and stop if you cannot recover

Only `CLEAN` can increment the counter.

### 4. Exit Conditions

- **Success** - `clean_count >= 3` consecutive clean waves.
- **Safety net** - 20 iterations reached without 3 clean waves.
- **User interrupt** - halt and surface the current count.

### 5. Report

Print a final summary:

```markdown
## dkreviewloop Result

- Scope: full current change set
- Iterations: N / 20
- Consecutive clean: M / 3
- Result: SUCCESS | SAFETY-NET-EXIT | BLOCKED
- Findings fixed this run: K
```

If the loop exits without success, list the residual or recurring findings.

## Notes

- Fresh waves matter. Do not carry review conclusions across iterations beyond
  `clean_count`, scope, and the compact context pack.
- Specialist reviewers are read-only; wave orchestrators own fixes.
- Same-session `dk <ticket>` Phase 3 uses this skill, with the Stop hook auditing
  the final `SUCCESS` report.
- Do not commit, push, create or update PRs, or request external reviewers from
  this skill. External review feedback belongs to Phase 5/6 and `/dkprreview`.
- If commits, pushes, PR creation, or PR updates already happened during Phase 3,
  report the ordering violation but continue only after `/dkreviewloop` reaches
  `SUCCESS`.
