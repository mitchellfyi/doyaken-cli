# Skill: dkimplement

Execute the approved plan, working through tasks with TDD discipline.

## When to Use

- After the user has approved the plan from `/dkplan`
- When resuming implementation work on a ticket

## Steps

### 1. Work Through Tasks

Before starting, read the implementation guardrails from `prompts/guardrails.md`. Apply them throughout.

For each task in the approved plan:

1. `TaskUpdate(task_id, "in_progress")`
2. Implement the task:
   - Follow the patterns and conventions established in the codebase (check AGENTS.md, README.md, and existing code in the area you're modifying).
   - If the project has code generation (API clients, DB types, OpenAPI specs), run the generator after schema or API changes.
3. Follow **Red-Green-Refactor** (TDD) where the project has a test suite:
   - Write a failing test first.
   - Write the minimum code to make it pass.
   - Refactor while keeping tests green.
4. After completing the task, run deterministic quality checks (format, lint, typecheck) on changed files only. Fix issues before moving to the next task — this prevents error accumulation across tasks.
5. Codebase stewardship: if you encounter dead code, stale comments, or outdated references in files you are modifying, clean them up — but do not expand scope to files outside the plan.
6. `TaskUpdate(task_id, "completed")`

### 2. Keep `.doyaken/` in Sync

After completing each task, check if your changes require updating project documentation in `.doyaken/`:

- **New dependencies added** (package.json, go.mod, etc.) → update `.doyaken/doyaken.md` § Tech Stack or Quality Gates
- **New code patterns established** (new conventions, architectural patterns) → add or update the relevant `.doyaken/rules/*.md` file
- **Security boundaries changed** (new auth, sensitive file paths, restricted APIs) → add a guard in `.doyaken/guards/`
- **Integration added/changed** (new MCP, new CI step) → update `.doyaken/doyaken.md` § Integrations

Only update when the change is meaningful and lasting — don't document one-off implementation details.

### 3. Handle Scope Changes

If during implementation you discover:
- **A requirement is ambiguous**: STOP. Present 2-3 options with trade-offs. Ask the user to choose.
- **The plan needs to change**: STOP. Explain the change and its impact. Ask for approval.
- **A dependency is blocked**: STOP. Document the blocker. Ask how to proceed.

When stopping for scope changes, do NOT output a completion promise (e.g., `PHASE_2_COMPLETE`). Simply halt and wait for user input. The phase audit loop will detect that the completion signal file was not written and keep the session alive. Once the user provides direction, resume implementation from where you left off.

Update the ticket via the configured tracker (see doyaken.md § Integrations) with the scope change details. If no tracker is configured, inform the user in conversation.

### 4. Self-Review Loop (Merged-Inventory Approach)

After all tasks are completed, run a two-perspective review to catch issues you may have missed:

**Step 1 — Your own inventory (find only, no fixes):**
Walk through all changed files and build a numbered findings list. For each file, check: correctness (try to break it), design (workarounds, complexity), documentation (non-obvious logic explained?), and consistency (patterns match across files). Record each issue as `[INV-N] file:line | description`. Do NOT fix anything yet.

**Step 2 — Independent review via self-reviewer agent:**
Spawn the `self-reviewer` agent with:
- The acceptance criteria from the approved plan (copy verbatim)
- The base branch and current branch name
- Which areas of the codebase have changed files

The agent reviews independently and produces its own findings report.

**Step 3 — Merge inventories:**
Combine your findings (Step 1) with the agent's findings (Step 2). Deduplicate by file:line. The union is the master inventory.

**Step 4 — Batch fix:**
Fix all items from the merged inventory in severity order (high first).

**Step 5 — Re-verify:**
Re-spawn the self-reviewer agent to verify fixes against the FULL change set (not just fixed files). If new findings emerge, fix and re-spawn. Maximum 3 total agent spawns.

**Step 6 — Evidence table:**
Before declaring PASS, produce an acceptance criteria evidence table:

| # | Criterion | Implementation (`file:line`) | Test (`test:line`) | Status |
|---|-----------|------------------------------|--------------------|---------|

Every criterion must have status MET with specific file:line evidence. Any NOT FOUND blocks completion.

If the final agent result is PASS and the evidence table has zero NOT FOUND entries: implementation is complete. When run via `/doyaken`, the next phase (verify) follows automatically.

## Notes

- Stay in scope. Only implement what's in the plan.
- If you think of improvements outside the plan, note them but don't implement them.
- Keep the user informed at natural milestones (e.g., "3 of 5 tasks complete").
