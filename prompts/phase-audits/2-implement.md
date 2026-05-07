Before stopping, audit your implementation for completeness. Do NOT stop until every step below passes.

The dedicated Review phase (Phase 3) will handle adversarial code review. Your job here is to ensure the implementation is **functionally complete** — all tasks done, tests passing, no obvious gaps.

## Step 1: Task Completion Check

For each task in the approved plan:

1. **Implemented?** — Is the task fully implemented (not partially)?
2. **Tested?** — Does a test verify the implementation? (TDD: test should exist before or alongside the implementation)
3. **Passing?** — Run the test suite. Do all tests pass?

If any task is incomplete, implement it now. If any test is missing, write it now.

## Step 2: Basic Implementation Quality

Quick scan for obvious issues (the Review phase will do deep analysis):

- No TODO/FIXME/HACK left behind (unless intentionally deferred and documented)
- No console.log/print debugging statements left in production code
- No commented-out code blocks
- Code compiles/transpiles without errors
- No obvious runtime errors (undefined variables, missing imports, broken references)

Fix anything found before proceeding.

## Step 3: Evidence Table

For each acceptance criterion from the plan, fill in the evidence table:

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
- Any NOT MET entry blocks completion — go back and implement/test it.

## Step 4: `.doyaken/` Freshness

Check if your implementation introduced any of these:
- New dependencies or tooling changes → `.doyaken/doyaken.md` § Tech Stack / Quality Gates updated?
- New code patterns or conventions → relevant `.doyaken/rules/*.md` updated?
- New security boundaries or sensitive paths → `.doyaken/guards/` updated?

If updates are needed but missing, make them now.

## Step 5: Knowledge Propagation

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

## Step 6: UI Capture Evidence

If the implementation affects browser UI, run `/dkuicapture` before stopping.

Required evidence for UI-affecting changes:

- Desktop screenshot for each changed representative route/view
- Mobile screenshot when layout, responsive behavior, shared components, or CSS changed
- Playwright trace for captured routes/views
- Video for interactive flows (clicks, forms, navigation, modals, menus, drag/drop, auth, checkout, onboarding, uploads)
- Console, page, network, and HTTP error logs checked
- Absolute links to all screenshots/videos/traces/logs included in the evidence table or final Phase 2 summary

Artifacts must live under Doyaken's artifact directory (`${DK_ARTIFACT_DIR:-~/.claude/.doyaken-artifacts}`) and must not be committed or staged.

If the implementation does not affect browser UI, include:

```text
UI capture: N/A — no UI-affecting files changed
```

## Completion Criteria

ALL of these must be true before you stop:
- Every task from the approved plan is implemented
- Every acceptance criterion has status MET in the evidence table (Step 3)
- All tests pass (run the test suite one final time to confirm)
- No TODO/FIXME/debugging artifacts remain
- Any needed `.doyaken/` updates are staged
- UI capture evidence is linked for UI-affecting changes, or UI capture is explicitly N/A

When all criteria are met, stop. The Stop hook will verify your work and provide completion instructions. The next phase (Review) will perform deep adversarial code review.
