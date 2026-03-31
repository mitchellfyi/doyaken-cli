Before stopping, run a thorough audit of your implementation. Do NOT stop until every step below passes.

If you haven't already, read the implementation guardrails from `prompts/guardrails.md` — they inform what to look for in the review passes below.

## Step 1: Self-Review via /dkreview (find only — no fixes yet)

Run /dkreview on the latest changes (if you haven't already since your last code change).

Read the report carefully. Do NOT fix anything yet — record all findings for the inventory in Step 4.

## Step 2: Multi-Perspective Inventory

**CRITICAL: Do NOT fix anything during this step. Only find and record.**

Perform four manual review passes in addition to the /dkreview findings. For each issue, record: `[INV-N] file:line | Pass | Severity | Description`

Reference `prompts/review.md` for the full criteria behind each pass.

### Pass A: Logic & Correctness

For each acceptance criterion, trace the implementing code end-to-end:
- Happy path, failure paths, edge cases (empty/null/zero/boundary)
- Try to BREAK each function — construct inputs that cause failure, states that cause inconsistency
- Off-by-one errors, null checks, race conditions
- Missing error handling — swallowed errors, generic catch-alls, empty catch blocks
- Resource cleanup — are opened resources closed on both success and failure paths?

### Pass B: Structure, Design & Documentation

- Workarounds, hacks, TODOs, or hardcoded values?
- Unnecessary complexity or abstraction?
- Unused imports, dead code, commented-out code?
- N+1 queries, unbounded loops, performance anti-patterns?
- Does every new public function/method have a corresponding test?
- Non-obvious logic has a "why" comment? Complex regexes explained? Magic numbers named?
- New public APIs have doc comments?

### Pass C: Security

Review all changes for security gaps (reference `prompts/review.md` Pass C for full criteria):
- New endpoints/routes have appropriate authentication and authorization?
- No hardcoded secrets, credentials, or API keys?
- No sensitive data in logs, error messages, or API responses?
- Input validated at system boundaries?
- Database queries use parameterized queries — no string interpolation?
- Secure defaults — features restricted by default, not permissive?

### Pass D: Holistic Consistency & Dependencies

Run `git diff` against the base branch and review ALL changes together:
- Naming, error handling, and logging consistent across all changed files?
- Patterns established in one file followed in all files?
- Code consistent with existing codebase conventions?
- If you changed a contract (type, API, schema), trace consumers up to 3 hops deep using `Grep` — are all consumers updated?

## Step 3: Independent Self-Reviewer Agent

Spawn the `self-reviewer` agent to get an independent review perspective. Provide:
- The acceptance criteria from the approved plan (copy verbatim)
- The current branch name and base branch (from `git rev-parse --abbrev-ref HEAD` and the default branch)
- Which areas of the codebase have changed files (from `git diff --name-only`)

The agent reviews independently and produces its own findings report. Do NOT fix anything based on the agent's findings yet — they feed into the merged inventory in Step 4.

## Step 4: Merged Inventory Output

Merge findings from all sources into a single inventory. Deduplicate by file:line. Print the complete inventory:

```
## Findings Inventory

| # | File:Line | Source | Pass | Severity | Description |
|---|-----------|--------|------|----------|-------------|
| INV-1 | ... | dkreview | A | high | ... |
| INV-2 | ... | manual | C | medium | ... |
| INV-3 | ... | agent | B | high | ... |

Total: N findings (X high, Y medium, Z low)
```

Source values: `dkreview`, `manual`, `agent`.

- If the inventory is **empty** → skip to Step 6.
- If **non-empty** → proceed to Step 5.

### Findings Hash (for stuck detection)

After building the inventory, compute and record a findings hash so the stop hook can detect stuck loops (same findings recurring across iterations):

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
FINDINGS_HASH=$(echo "<sorted list of INV-N descriptions>" | shasum -a 256 | cut -c1-16)
echo "$FINDINGS_HASH" >> "$(dk_findings_file "${DOYAKEN_SESSION_ID:-$(dk_session_id)}")"
```

Replace `<sorted list of INV-N descriptions>` with the actual finding descriptions from your inventory, sorted alphabetically, one per line. If the inventory is empty, use the string "EMPTY".

## Step 5: Batch Fix and Holistic Re-verification

1. Fix all inventory items in severity order (high → medium → low).
2. After ALL fixes are applied:
   - Re-run /dkreview on the **full scope** (not just modified files).
   - Re-run your manual passes (Step 2) on the **entire change set** — fixes can regress untouched files.
   - Re-spawn the self-reviewer agent to verify fixes against the FULL change set. **Maximum 3 total agent spawns** (including the initial spawn in Step 3).
3. If new findings → add to inventory, fix, and re-verify. Maximum 3 cycles.

## Step 5.5: Failure Recovery Check

If Step 5 has run 2+ cycles without reaching an empty inventory:

1. Read `prompts/failure-recovery.md` for recovery strategy guidance.
2. Identify findings that keep recurring across cycles.
3. For each recurring finding, run the failure analysis to choose a strategy.
4. If any findings are accepted as DEBT, record them in the debt ledger and remove them from the inventory before checking the completion gate.

Recurring findings accepted as debt do NOT block completion, but they MUST appear in the debt ledger and the PR description.

## Step 6: Evidence Table

For each acceptance criterion, fill in the evidence table:

```
## Evidence

| # | Criterion | Implementation (`file:line`) | Test (`test:line`) | Status |
|---|-----------|------------------------------|--------------------|---------
| 1 | ... | `file:line` | `test-file:line` | MET |
| 2 | ... | `file:line` | — | NOT MET |
```

**Rules:**
- Implementation evidence must be a specific `file:line` in production code.
- Test evidence must be a specific test name or `test-file:line`.
- Prose claims ("I verified this") are NOT evidence. Cite specific locations.
- Any NOT MET or NOT FOUND entry blocks completion — go back and implement/test it.

## Step 7: `.doyaken/` Freshness

Check if your implementation introduced any of these:
- New dependencies or tooling changes → `.doyaken/doyaken.md` § Tech Stack / Quality Gates updated?
- New code patterns or conventions → relevant `.doyaken/rules/*.md` updated?
- New security boundaries or sensitive paths → `.doyaken/guards/` updated?

If updates are needed but missing, make them now.

## Step 8: Knowledge Propagation

If you discovered conventions, failure patterns, or interface details during this task that would help subsequent tasks, append them to `.doyaken/learnings.md`:

```markdown
## Conventions Discovered
- [pattern found, e.g., "this project uses barrel exports in src/index.ts"]

## Failure Patterns
- [what went wrong and how it was fixed, e.g., "Jest needs setupFilesAfterEnv for custom matchers"]

## Interface Notes
- [API contracts discovered, e.g., "error responses use {error: string, code: number} shape"]
```

Only add entries that are non-obvious and would save time in future tasks. Skip if nothing noteworthy was discovered.

## Completion Criteria

Only output PHASE_2_COMPLETE when ALL of these are true:
- /dkreview result is PASS — OR result is PASS WITH WARNINGS and all remaining warnings are tracked as DEBT in the debt ledger
- The findings inventory from your last re-verification (Step 5) is empty — OR all remaining findings are LOW/MEDIUM severity and tracked as DEBT
- Every acceptance criterion has status MET in the evidence table (Step 6) — OR criteria with status RELAXED have a corresponding DEBT entry
- Any needed `.doyaken/` updates are staged
- You have run /dkreview AFTER your most recent code change

If any findings are tracked as debt, output a debt summary before the completion signal:

```
## Debt Summary
[List each debt item from the debt ledger file]
```

Do NOT output PHASE_2_COMPLETE if any HIGH severity findings remain unresolved, or any criterion is NOT MET without a DEBT entry. Fix first, then re-audit from Step 2.

Before outputting PHASE_2_COMPLETE, write the completion signal file:

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh" && touch "$(dk_complete_file "$(dk_session_id)")"
```
