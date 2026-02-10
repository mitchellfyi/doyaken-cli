# Task: Enhanced Spec Generation in EXPAND Phase (Spec-Kit Inspired)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-007-enhanced-spec-generation`                     |
| Status      | `doing`                                                |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-06 15:30`                                     |
| Started     | `2026-02-10 09:41`                                     |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-10 09:41` |

---

## Context

**Intent**: IMPROVE

The EXPAND phase (`0-expand.md`) currently generates expanded task descriptions with Context, Acceptance Criteria, and Notes sections. While functional, the output is unstructured prose that varies widely in quality between runs. GitHub's spec-kit demonstrated that structured specification formats (user stories, acceptance scenarios, success metrics) improve AI agent output quality by ~25% by giving downstream phases (PLAN, IMPLEMENT, TEST) concrete, testable requirements to work from.

The current EXPAND prompt is 72 lines. It instructs the agent to classify intent, define acceptance criteria, identify edge cases, and set scope boundaries — but provides no structured format beyond free-text markdown sections. The result is that PLAN and IMPLEMENT phases often receive vague specs, leading to scope creep and incomplete implementations.

This task enhances the EXPAND phase output format with structured user stories and acceptance scenarios, updates the TRIAGE phase to validate spec completeness, and updates the task template so new tasks include spec section placeholders.

**Key insight**: This is primarily a prompt engineering task. The existing phase pipeline, task file format, and template system all support arbitrary markdown sections — no shell code changes are needed for the core enhancement. The only code changes are: (1) updating the task template in `create_task_file()` and `templates/TASK.md`, and (2) minor TRIAGE prompt additions.

---

## Acceptance Criteria

- [ ] AC-1: EXPAND phase prompt (`0-expand.md`) includes instructions and examples for generating structured user stories in `As a <role>, I want <feature> so that <benefit>` format
- [ ] AC-2: EXPAND phase prompt instructs agent to write Given/When/Then acceptance scenarios for each user story
- [ ] AC-3: EXPAND phase prompt instructs agent to define measurable success metrics (e.g., "Tests pass", "No regressions", "Lint clean")
- [ ] AC-4: EXPAND phase prompt includes scope boundaries (in-scope / out-of-scope) — already partially exists in Notes section, formalize it
- [ ] AC-5: EXPAND phase prompt instructs agent to mark unclear items with `[NEEDS CLARIFICATION]`
- [ ] AC-6: EXPAND phase output includes a `## Specification` section with User Stories, Acceptance Criteria, Success Metrics, Scope, and Dependencies subsections
- [ ] AC-7: TRIAGE phase prompt (`1-triage.md`) validates spec completeness: checks for missing acceptance criteria, vague success metrics, and `[NEEDS CLARIFICATION]` markers
- [ ] AC-8: Task template (`create_task_file()` in `lib/project.sh` and `templates/TASK.md`) includes Specification section placeholders
- [ ] AC-9: For trivial tasks (bug fixes, typos), the EXPAND prompt explicitly allows abbreviated specs without full user stories — guided by task context, not a CLI flag
- [ ] AC-10: Tests written and passing
- [ ] AC-11: Quality gates pass
- [ ] AC-12: Changes committed with task reference

---

## Specification

### User Stories

- **US-1**: As a doyaken developer, I want the EXPAND phase to produce structured user stories and acceptance scenarios so that downstream phases (PLAN, IMPLEMENT, TEST) receive concrete, testable requirements instead of vague prose.
- **US-2**: As a doyaken developer, I want the TRIAGE phase to validate spec completeness so that poorly-specified tasks are caught before implementation begins.
- **US-3**: As a doyaken user, I want new task files to include Specification section placeholders so that the expected spec structure is visible from task creation.

### Acceptance Scenarios

**US-1:**
- Given a non-trivial task brief, When the EXPAND phase runs, Then the task file contains a `## Specification` section with User Stories (`As a... I want... so that...`), Given/When/Then acceptance scenarios, measurable success metrics, and scope boundaries
- Given a trivial task brief (typo fix), When the EXPAND phase runs, Then the task file contains an abbreviated Specification with "N/A" for user stories and only acceptance criteria + success metrics

**US-2:**
- Given a task with missing acceptance scenarios, When the TRIAGE phase runs, Then it flags the missing scenarios in its output
- Given a task with `[NEEDS CLARIFICATION]` markers, When the TRIAGE phase runs, Then it STOPs and reports the unclear items

**US-3:**
- Given a user runs `dk tasks new`, When the task file is created, Then it contains `## Specification` with placeholder subsections (User Stories, Acceptance Scenarios, Success Metrics, Scope, Dependencies)

### Success Metrics

- [ ] All 588+ unit tests pass (no regressions)
- [ ] Lint passes with 0 errors
- [ ] New unit tests verify `create_task_file()` output contains all Specification subsection headers
- [ ] All 4 template locations have consistent Specification section structure

### Scope

**In Scope:**
- Update `0-expand.md` prompt with structured spec format, examples, and instructions
- Update `1-triage.md` prompt with spec completeness validation
- Update `create_task_file()` in `lib/project.sh` to include Specification section placeholder
- Update `templates/TASK.md` and `.doyaken/tasks/_templates/TASK.md` reference template
- Update `lib/cli.sh` fallback template
- Add unit tests for `create_task_file()` output

**Out of Scope:**
- Adding a `--quick` CLI flag (the existing `SKIP_EXPAND` config already handles skipping)
- Interactive user story prompting during `dk tasks new`
- Changes to PLAN, IMPLEMENT, or TEST phase prompts (they already consume task file content)
- Brownfield-specific instructions (redundant with planning.md include)

### Dependencies

- None

---

## Notes

**Assumptions:**
- The EXPAND phase agent has access to read the full codebase (confirmed — it runs as a full agent with file access)
- Task files are plain markdown and can accommodate new sections without breaking any parsing logic (confirmed — `lib/project.sh` functions use grep/awk on specific fields, not full-file parsing)
- The `{{include:library/planning.md}}` directive in `0-expand.md` will continue to be included (the new spec format augments, not replaces, the planning methodology)

**Edge Cases:**
- Task with no meaningful user story (e.g., "fix typo in README"): EXPAND prompt should allow abbreviated spec with just acceptance criteria, no user stories required
- Task with multiple user stories: Each should have its own Given/When/Then scenarios, numbered US-1, US-2, etc.
- Task imported from GitHub issue (via `github-import` skill): May already have structured context; EXPAND should augment, not overwrite
- `[NEEDS CLARIFICATION]` items found by TRIAGE: Current TRIAGE behavior is to flag and stop — this is correct, no change needed to the stop behavior

**Risks:**
- **Prompt bloat**: Adding examples and structure to `0-expand.md` could make it too long, causing the agent to lose focus. Mitigation: Keep the prompt concise with one good example, not exhaustive instructions.
- **Over-specification**: For small tasks, generating full user stories is wasteful and may cause the agent to over-engineer. Mitigation: Explicitly tell the EXPAND agent to scale spec depth to task complexity.
- **Template drift**: `create_task_file()`, `templates/TASK.md`, `_templates/TASK.md`, and `cli.sh` could diverge. Mitigation: Update all four in the same step and verify consistency.
- **Test breakage**: No existing tests assert on `create_task_file()` output — need to ADD tests for the new template.

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| AC-1: User stories in EXPAND prompt | none | `0-expand.md` has no user story format or instructions |
| AC-2: Given/When/Then scenarios | none | `0-expand.md` has no acceptance scenario format |
| AC-3: Measurable success metrics | none | `0-expand.md` says "testable" criteria but no structured metrics section |
| AC-4: Scope boundaries formalized | partial | Notes section has In Scope/Out of Scope but it's freeform prose in Notes, not a dedicated Scope subsection under Specification |
| AC-5: `[NEEDS CLARIFICATION]` markers | none | No instruction for marking unclear items |
| AC-6: `## Specification` output section | none | Output template has Context, AC, Notes — no Specification section |
| AC-7: TRIAGE validates spec completeness | none | `1-triage.md` validates context/criteria/scope but doesn't check for missing AC scenarios, vague metrics, or clarification markers |
| AC-8: Task template includes Specification placeholders | none | `create_task_file()`, `templates/TASK.md`, `_templates/TASK.md`, and cli.sh fallback template all lack a Specification section |
| AC-9: Abbreviated specs for trivial tasks | none | No guidance on scaling spec depth to task complexity |
| AC-10: Tests written and passing | none | No tests for `create_task_file()` output content exist (project.bats tests only cover counting/priority functions) |
| AC-11: Quality gates pass | pending | Will verify at end |
| AC-12: Changes committed | pending | Will do at end |

### Risks

- [ ] **Prompt bloat**: Adding structured spec format + example to `0-expand.md` could make it too long → Mitigation: Keep one concise example, use the spec format template as the output section (not separate instructions + output)
- [ ] **Template drift**: Four template locations must stay in sync (`create_task_file()`, `templates/TASK.md`, `.doyaken/tasks/_templates/TASK.md`, cli.sh fallback) → Mitigation: Update all four in the same step, verify consistency visually
- [ ] **Test breakage**: No existing tests assert on `create_task_file()` output, so no breakage risk — but we need to ADD tests for the new template
- [ ] **Existing task files**: Adding a Specification section to the template doesn't affect existing task files since they're already created — EXPAND phase will add the section dynamically when it runs

### Steps

1. **Update EXPAND prompt with structured spec format**
   - File: `.doyaken/prompts/phases/0-expand.md`
   - Change: Add instructions for generating structured Specification section with User Stories (AC-1), Given/When/Then scenarios (AC-2), Success Metrics (AC-3), formalized Scope (AC-4), `[NEEDS CLARIFICATION]` markers (AC-5), and abbreviated spec guidance for trivial tasks (AC-9). Update the Output template to include `## Specification` section (AC-6). Add one concise example.
   - Verify: Read the file, confirm all 6 criteria addressed, prompt is <120 lines total

2. **Update TRIAGE prompt with spec validation**
   - File: `.doyaken/prompts/phases/1-triage.md`
   - Change: Add step to Phase Instructions: validate spec completeness — check for missing acceptance scenarios, vague success metrics, and `[NEEDS CLARIFICATION]` markers. Add corresponding output to the Work Log template. (AC-7)
   - Verify: Read the file, confirm spec validation step exists

3. **Update `create_task_file()` template in project.sh**
   - File: `lib/project.sh`
   - Change: Add `## Specification` section with placeholder subsections (User Stories, Acceptance Scenarios, Success Metrics, Scope, Dependencies) between Acceptance Criteria and Plan sections. Keep it minimal — just headers and "(To be filled in during EXPAND phase)" placeholder. (AC-8)
   - Verify: Run `source lib/project.sh && create_task_file "test-001" "Test" "003" "Medium" "/tmp"` and inspect output

4. **Update reference template `templates/TASK.md`**
   - File: `templates/TASK.md`
   - Change: Add matching `## Specification` section with subsection headers and instructional placeholder text, consistent with step 3. (AC-8)
   - Verify: Diff against `create_task_file()` output structure — sections should match

5. **Update project-level template `.doyaken/tasks/_templates/TASK.md`**
   - File: `.doyaken/tasks/_templates/TASK.md`
   - Change: Add matching `## Specification` section, same structure as step 4. (AC-8)
   - Verify: Diff against `templates/TASK.md` — should be identical

6. **Update cli.sh fallback template**
   - File: `lib/cli.sh` (lines 506-562, inside `init_task_template()`)
   - Change: Add `## Specification` section with placeholder subsections to the inline heredoc fallback template, matching structure from steps 3-5. (AC-8)
   - Verify: Read cli.sh, confirm fallback template matches

7. **Add unit tests for `create_task_file()` output**
   - File: `test/unit/project.bats`
   - Change: Add tests verifying `create_task_file()` output includes: `## Specification` header, `### User Stories` header, `### Acceptance Scenarios` header, `### Success Metrics` header, `### Scope` header, `### Dependencies` header. Also verify existing sections (Metadata, Context, AC, Plan, Work Log, Notes, Links) are still present. (AC-10)
   - Verify: `npx bats test/unit/project.bats` — all tests pass

8. **Run quality gates**
   - Command: `npm run check` (scripts/check-all.sh)
   - Verify: All checks pass (lint, tests, build) (AC-11)

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 1 | `0-expand.md` is <120 lines, addresses AC-1 through AC-6, AC-9 |
| Step 2 | `1-triage.md` has spec validation step (AC-7) |
| Step 6 | All 4 template locations have consistent Specification section (AC-8) |
| Step 7 | `npx bats test/unit/project.bats` passes |
| Step 8 | `npm run check` passes (AC-11) |

### Test Plan

- [ ] Unit: `create_task_file()` output contains `## Specification` and all subsection headers
- [ ] Unit: `create_task_file()` output still contains all existing sections (no regressions)
- [ ] Unit: `create_task_file()` output contains placeholder text for Specification subsections
- [ ] Manual: Review `0-expand.md` prompt produces well-structured spec when run through a real task (not automatable)

### Docs to Update

- [ ] `templates/TASK.md` — add Specification section (step 4)
- [ ] `.doyaken/tasks/_templates/TASK.md` — add Specification section (step 5)
- [ ] No README/AGENTS.md changes needed — they reference task file structure generically

---

## Work Log

### 2026-02-10 - Implementation Progress (Step 7)

Step 7: Added unit tests for `create_task_file()` output
- Files modified: `test/unit/project.bats`
- Changes: 18 new tests verifying `create_task_file()` output contains all expected sections (Metadata, Context, Acceptance Criteria, Specification with 5 subsections, Plan, Work Log, Notes, Links), correct section ordering, custom/default context, placeholder text, and metadata values
- Verification: pass (51/51 project.bats tests, 606/606 total unit tests)

Step 8: Quality gates
- Lint: pass (0 errors)
- Tests: pass (606/606 unit tests)
- Build: pass (`npm run check` all checks passed)

### 2026-02-10 09:41 - Triage Complete

Quality gates:
- Lint: `npm run lint` (scripts/lint.sh)
- Types: N/A (shell project)
- Tests: `npm run test:unit` (npx bats test/unit/)
- Build: `npm run check` (scripts/check-all.sh)

Task validation:
- Context: clear — well-defined problem, solution, and implementation plan with 8 steps; steps 1-6 already completed
- Criteria: specific — 12 acceptance criteria (AC-1 through AC-12), each testable
- Dependencies: none

Spec validation:
- Acceptance scenarios: present — US-1, US-2, US-3 each have Given/When/Then scenarios
- Success metrics: measurable — 588+ unit tests pass, lint 0 errors, new tests verify template output, 4 template locations consistent
- Clarification needed: none

Complexity:
- Files: few — 6 files modified (steps 1-6 done) + test file (step 7 remaining)
- Risk: low — primarily prompt/template changes, most already implemented and verified

Priority check:
- Task priority: 003 (Medium)
- EXPAND recommended: 003 (Medium)
- Match: yes, no discrepancy

Backlog check:
- 003-008 project-setup-wizard (Medium)
- 003-009 plan-mode (Medium)
- 003-010 context-file-management (Medium)
- 003-011 session-continuity (Medium)
- 003-012 through 003-019 (Medium, workflow tasks)
- 004-007 hooks-lifecycle-events (Low)
- 004-008 memory-learning-system (Low)
- 005-001 through 005-011 (Research)
- No higher-priority (001/002) unblocked tasks exist in 2.todo/

Ready: yes — task is well-specified with structured spec, 6/8 steps already implemented with passing quality gates. Remaining: step 7 (unit tests), step 8 (quality gates).

### 2026-02-10 09:39 - Task Expanded (Re-expansion)

- Intent: IMPROVE
- Scope: Added structured `## Specification` section to the task file itself (US-1/2/3, acceptance scenarios, success metrics, scope). Previously this task used the old format with specs in Notes section only.
- Key files: `.doyaken/prompts/phases/0-expand.md`, `.doyaken/prompts/phases/1-triage.md`, `lib/project.sh`, `templates/TASK.md`, `.doyaken/tasks/_templates/TASK.md`, `lib/cli.sh`, `test/unit/project.bats`
- Complexity: Low-Medium (primarily prompt/template changes, minor code changes; Steps 1-6 already complete)
- Recommended priority: 003 Medium - Feature improvement, not urgent, no users blocked
- Implementation status: Steps 1-6 complete. Remaining: Step 7 (unit tests for `create_task_file()`), Step 8 (quality gates).

### 2026-02-10 09:42 - Planning Validated (Phase 2 Re-entry)

Plan re-validated — all 8 steps still accurate. Steps 1-6 confirmed complete:
- `0-expand.md`: 118 lines, addresses AC-1 through AC-6, AC-9 (user stories, scenarios, metrics, scope, clarification markers, abbreviated specs)
- `1-triage.md`: Spec validation step added (AC-7), checks scenarios/metrics/clarification markers
- All 4 template locations have consistent `## Specification` section with 5 subsections (AC-8)

Remaining work:
- Step 7: Add unit tests for `create_task_file()` to `test/unit/project.bats` (AC-10)
- Step 8: Run quality gates (AC-11)

No plan changes needed. Proceeding to IMPLEMENT.

- Steps: 8 (6 complete, 2 remaining)
- Risks: 4 (all low, mitigated)
- Test coverage: moderate (unit tests for template output + manual prompt quality verification)

### 2026-02-10 - Planning Complete

- Steps: 8
- Risks: 4 (prompt bloat, template drift, test breakage — low, existing task files — no impact)
- Test coverage: moderate (unit tests for template output, manual verification for prompt quality)
- Key insight: No existing tests for `create_task_file()` output content — need to add
- Template locations: 4 (project.sh, templates/TASK.md, _templates/TASK.md, cli.sh fallback)

### 2026-02-10 - Implementation Progress

Step 1: Updated EXPAND prompt with structured spec format
- Files modified: `.doyaken/prompts/phases/0-expand.md`
- Changes: Added user story format (AC-1), Given/When/Then scenarios (AC-2), success metrics (AC-3), formalized scope (AC-4), `[NEEDS CLARIFICATION]` markers (AC-5), `## Specification` output section (AC-6), abbreviated spec guidance for trivial tasks (AC-9), scaling guidance
- Verification: pass (118 lines, under 120 target)

Step 2: Updated TRIAGE prompt with spec validation
- Files modified: `.doyaken/prompts/phases/1-triage.md`
- Changes: Added step 3 (validate spec completeness), spec validation output section, rule to STOP on `[NEEDS CLARIFICATION]` markers (AC-7)
- Verification: pass

Step 3: Updated `create_task_file()` template in project.sh
- Files modified: `lib/project.sh`
- Changes: Added `## Specification` section with User Stories, Acceptance Scenarios, Success Metrics, Scope, Dependencies subsections between AC and Plan (AC-8)
- Verification: pass (lint pass, 33/33 project.bats tests pass)

Step 4: Updated reference template `templates/TASK.md`
- Files modified: `templates/TASK.md`
- Changes: Added matching `## Specification` section with example subsections (AC-8)
- Verification: pass

Step 5: Updated project-level template `.doyaken/tasks/_templates/TASK.md`
- Files modified: `.doyaken/tasks/_templates/TASK.md`
- Changes: Added matching `## Specification` section (AC-8)
- Verification: pass (identical structure to templates/TASK.md)

Step 6: Updated cli.sh fallback template
- Files modified: `lib/cli.sh`
- Changes: Added `## Specification` section with placeholder subsections in init_task_template() heredoc (AC-8)
- Verification: pass (consistent with other templates)

Quality gates:
- Lint: pass (0 errors)
- Tests: pass (588/588 unit tests)

### 2026-02-10 04:46 - Triage Complete (Re-validation)

Quality gates:
- Lint: `npm run lint` (scripts/lint.sh)
- Types: N/A (shell project)
- Tests: `npm run test:unit` (npx bats test/unit/)
- Build: `npm run check` (scripts/check-all.sh)

Task validation:
- Context: clear — well-defined problem, clear solution, detailed plan with 8 steps
- Criteria: specific — 12 acceptance criteria (AC-1 through AC-12), each testable
- Dependencies: none — no blockers listed

Spec validation:
- Acceptance scenarios: N/A — this task predates the Specification section format (it's the task that adds it); uses traditional AC format which is well-structured
- Success metrics: measurable — AC-10 (tests pass), AC-11 (quality gates pass), AC-12 (committed)
- Clarification needed: none

Complexity:
- Files: few — 6 files to modify + tests (0-expand.md, 1-triage.md, project.sh, templates/TASK.md, _templates/TASK.md, cli.sh)
- Risk: low — primarily prompt/template changes, Steps 1-6 already complete with passing quality gates

Backlog check:
- 003-008 project-setup-wizard (Medium)
- 003-009 plan-mode (Medium)
- 003-010 context-file-management (Medium)
- 003-011 session-continuity (Medium)
- 003-012 through 003-019 (Medium, workflow tasks)
- 004-007 hooks-lifecycle-events (Low)
- 004-008 memory-learning-system (Low)
- 005-001 through 005-011 (Research)
- No higher-priority (001/002) unblocked tasks exist in 2.todo/

Implementation status: Steps 1-6 complete (EXPAND prompt, TRIAGE prompt, all 4 template locations). Remaining: Step 7 (unit tests), Step 8 (quality gates).

Ready: yes — task is well-specified, partially implemented (6/8 steps done), all quality gates available and previously passing (588/588 tests, lint clean)

### 2026-02-10 04:37 - Triage Complete

Quality gates:
- Lint: `npm run lint` (scripts/lint.sh)
- Types: N/A (shell project)
- Tests: `npm run test:unit` (bats 1.13.0 available)
- Build: `npm run check` (scripts/check-all.sh)

Task validation:
- Context: clear — well-defined problem (unstructured EXPAND output), clear solution (structured spec format)
- Criteria: specific — 12 acceptance criteria, each testable; AC-1 through AC-9 are functional, AC-10-12 are process gates
- Dependencies: none — no blockers listed, all referenced files exist and are accessible

Complexity:
- Files: few — 5 files to modify (0-expand.md, 1-triage.md, lib/project.sh, templates/TASK.md, .doyaken/tasks/_templates/TASK.md) plus tests
- Risk: low — primarily prompt engineering changes; code changes limited to template output in create_task_file(); existing tests will need updating

Priority check:
- Task priority: 003 (Medium)
- EXPAND recommended: 003 (Medium)
- Match: yes, no discrepancy

Backlog check:
- 003-008 project-setup-wizard (Medium)
- 003-009 plan-mode (Medium)
- 003-010 context-file-management (Medium)
- 003-011 session-continuity (Medium)
- 003-012 through 003-019 (Medium, various workflow tasks)
- 004-007, 004-008 (Low)
- 005-001 through 005-011 (Research)
- No higher-priority (001/002) unblocked tasks exist in 2.todo/

Ready: yes — task is well-specified, all dependencies satisfied, all target files exist, quality gates available

### 2026-02-10 04:35 - Task Expanded

- Intent: IMPROVE
- Scope: Enhance EXPAND phase prompt with structured spec format (user stories, acceptance scenarios, success metrics), update TRIAGE prompt with spec validation, update task template
- Key files:
  - `.doyaken/prompts/phases/0-expand.md` (primary change)
  - `.doyaken/prompts/phases/1-triage.md` (add spec validation)
  - `lib/project.sh` lines 29-100 (`create_task_file()` template)
  - `templates/TASK.md` (reference template)
  - `.doyaken/tasks/_templates/TASK.md` (project template)
  - `test/unit/` (tests for template changes)
- Complexity: Low-Medium (primarily prompt engineering, minor code changes)
- Recommended priority: 003 Medium - Feature improvement, not urgent, no users blocked

---

## Links

- Related research: `.doyaken/tasks/2.todo/005-003-research-spec-kit-task-specs.md`
- Current EXPAND prompt: `.doyaken/prompts/phases/0-expand.md`
- Current TRIAGE prompt: `.doyaken/prompts/phases/1-triage.md`
- Task creation code: `lib/project.sh:29-100`
- Planning methodology: `.doyaken/prompts/library/planning.md`
