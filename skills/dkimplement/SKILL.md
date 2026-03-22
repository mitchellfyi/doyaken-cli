# Skill: dkimplement

Execute the approved plan, working through tasks with TDD discipline.

## When to Use

- After the user has approved the plan from `/dkplan`
- When resuming implementation work on a ticket

## Steps

### 1. Work Through Tasks

Before starting, read the implementation guardrails from `prompts/guardrails.md`. Apply them throughout.

**Pre-flight: Expand scope with production defaults.**
Before starting task 1, check the guardrails for implied requirements that apply to this project type and add them to your task list — they are in-scope even when the task prompt does not mention them:
- **HTTP APIs**: CORS middleware (`cors` package), request body size limits (`express.json({ limit: '10kb' })`), UUID-based resource IDs (`crypto.randomUUID()`), graceful shutdown (SIGTERM/SIGINT → `server.close()`), PATCH endpoint for partial updates alongside PUT, route module separation.
- **Libraries/packages**: Compiled output importable via standard `require()`/`import` without a manual build step (for TypeScript: add `"prepare": "npm run build"` to package.json so `npm install` triggers `tsc`; set `"main"` to compiled output like `"dist/index.js"`). A README.md with usage examples and design decisions. Conventional export names matching the domain (e.g., `class RateLimiter`, not `class RL`).
- **HTTP API tests**: Use the ecosystem's standard HTTP testing library (e.g., `supertest` for Express.js, `httptest` for Go, `TestClient` for FastAPI) rather than raw `fetch()` calls. Structure tests with `describe`/`it` blocks.
- **All projects**: At least 10 focused test cases. Descriptive test names that reference the specific behavior being verified (see guardrails § Test Integrity).

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

**When running non-interactively** (no user to respond — e.g., `-p` mode, automated harness, or if the user is unavailable): do NOT stop on ambiguity. Instead, choose the **most comprehensive reasonable interpretation** and document your assumptions in a README. Specifically:
- For algorithmic or strategic choices: implement **at least two approaches** (e.g., fixed-window + token-bucket for rate limiting, multiple sort algorithms, etc.) and let the caller choose.
- For data modeling: default to **per-client/per-key isolation** and **configurable limits** with sensible defaults.
- For scope: when the prompt is vague, build a complete library with a clean exported API, comprehensive tests covering edge cases, and a README explaining design decisions and usage.

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
