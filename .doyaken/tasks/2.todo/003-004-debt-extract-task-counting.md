# Task: Extract Task Counting to Utility Function

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-004-debt-extract-task-counting`                   |
| Status      | `doing`                                                |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:10`                                     |
| Started     | `2026-02-01 22:19`                                     |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-2` |
| Assigned At | `2026-02-01 22:30` |

---

## Context

**Intent**: IMPROVE (Refactor to reduce code duplication)

Technical debt assessment identified that the task counting pattern `find ... | wc -l | tr -d ' '` is duplicated 30+ times across the codebase. Analysis reveals:

1. **lib/core.sh already has utility functions** at lines 1708-1717:
   - `count_tasks(state)` - counts `.md` files in a task state folder
   - `count_locked_tasks()` - counts `.lock` files in locks dir

2. **The problem**: These functions exist but aren't being used consistently. Other files duplicate the pattern instead of calling the utility.

3. **Variations found**:
   - **Task files (*.md)**: `find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' '` (~20 occurrences)
   - **Lock files (*.lock)**: Similar pattern for .lock files (~3 occurrences)
   - **General files**: Various patterns counting logs, state, backups, etc. (~10 occurrences)

**Impact**: Maintenance burden, risk of inconsistent counting logic, harder to add features like caching.

---

## Acceptance Criteria

- [ ] Add `count_files()` utility function to lib/project.sh that accepts directory and optional glob pattern
- [ ] Add `count_task_files()` wrapper for `.md` files specifically
- [ ] Replace duplicated patterns in lib/cli.sh with utility function calls (~12 occurrences)
- [ ] Replace duplicated patterns in lib/registry.sh with utility function calls (~6 occurrences)
- [ ] Replace duplicated patterns in lib/taskboard.sh with utility function calls (~4 occurrences)
- [ ] Update lib/core.sh to use lib/project.sh functions or consolidate
- [ ] Replace duplicated patterns in lib/upgrade.sh with utility function calls (~2 occurrences)
- [ ] Add unit tests for counting functions (empty dir, missing dir, files present)
- [ ] All existing tests continue to pass
- [ ] Quality gates pass

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| `count_files()` utility function in lib/project.sh | none | Function doesn't exist; needs to be created |
| `count_task_files()` wrapper for .md files | none | Function doesn't exist; needs to be created |
| Replace patterns in lib/cli.sh (~13 occurrences) | none | All 13 occurrences still use inline pattern |
| Replace patterns in lib/registry.sh (~6 occurrences) | none | All 6 occurrences still use inline pattern |
| Replace patterns in lib/taskboard.sh (~4 occurrences) | none | All 4 occurrences still use inline pattern |
| Update lib/core.sh (3 occurrences) | partial | Functions exist (count_tasks, count_locked_tasks) but don't use shared utility |
| Replace patterns in lib/upgrade.sh (~2 occurrences) | none | Both occurrences still use inline pattern |
| Unit tests for counting functions | none | test/unit/project.bats doesn't exist |
| All existing tests pass | full | Tests currently pass (baseline) |
| Quality gates pass | full | Quality gates currently pass (baseline) |

### Risks

- [ ] **Regression in task counting** (Low): Many call sites being changed
  - Mitigation: Run full test suite after each file change; test commands manually
- [ ] **Source order dependency** (Low): project.sh must be sourced before files using utilities
  - Mitigation: Verified cli.sh sources project.sh at line 32, before all other libs
- [ ] **Semantic differences** (Low): Some patterns use `-type f`, others don't; some exclude `.gitkeep`
  - Mitigation: Create separate functions for each semantic: `count_files()` (general), `count_task_files()` (*.md), `count_files_excluding_gitkeep()` (for cleanup)
- [ ] **core.sh circular dependency** (Low): core.sh doesn't source project.sh
  - Mitigation: Keep core.sh functions internal; they work fine as-is and are only used within core.sh

### Steps

1. **Add utility functions to lib/project.sh**
   - File: `lib/project.sh`
   - Change: Add three functions after line 98 (after `create_task_file`):
     - `count_files(dir, pattern)` - generic file counting with optional pattern
     - `count_task_files(dir)` - wrapper for `*.md` files
     - `count_files_excluding_gitkeep(dir)` - for cleanup operations
   - Verify: Source file manually and test functions with echo

2. **Update lib/taskboard.sh**
   - File: `lib/taskboard.sh`
   - Change: Lines 60-63 - replace 4 occurrences with `count_task_files()`
   - Verify: `./bin/doyaken board` produces same output

3. **Update lib/registry.sh**
   - File: `lib/registry.sh`
   - Change: Lines 194-195, 239-240, 244-245 - replace 6 occurrences with `count_task_files()`
   - Verify: `./bin/doyaken list` produces same output

4. **Update lib/cli.sh (task counting)**
   - File: `lib/cli.sh`
   - Change: Lines 76-77, 792, 978-981 - replace 7 occurrences counting task files with `count_task_files()`
   - Verify: `./bin/doyaken status` and `./bin/doyaken add` work correctly

5. **Update lib/cli.sh (cleanup counting)**
   - File: `lib/cli.sh`
   - Change: Lines 637, 648, 659, 670, 709 - replace 5 occurrences with `count_files_excluding_gitkeep()`
   - Verify: `./bin/doyaken clean` works correctly

6. **Update lib/cli.sh (command counting)**
   - File: `lib/cli.sh`
   - Change: Line 1614 - replace with `count_files()` for counting .md command files
   - Verify: `./bin/doyaken sync` works correctly

7. **Update lib/upgrade.sh**
   - File: `lib/upgrade.sh`
   - Change: Line 282 - count backup directories (keep inline, pattern differs: `-type d -name "20*"`)
   - Change: Line 617 - replace with `count_files()` for counting files in source dir
   - Verify: Upgrade functionality still works (manual verification)

8. **Keep lib/core.sh unchanged**
   - File: `lib/core.sh`
   - Decision: Keep internal `count_tasks()` and `count_locked_tasks()` as-is
   - Reason: core.sh doesn't source project.sh; changing would require significant refactoring for minimal benefit

9. **Add unit tests**
   - File: `test/unit/project.bats` (new)
   - Tests:
     - `count_files: empty directory returns 0`
     - `count_files: missing directory returns 0`
     - `count_files: counts matching files correctly`
     - `count_files: respects pattern parameter`
     - `count_task_files: counts only .md files`
     - `count_files_excluding_gitkeep: excludes .gitkeep`
   - Verify: `npm test` or `test/run-bats.sh` passes

10. **Run quality gates**
    - Run: `npm test` (runs all bats tests)
    - Run: `npm run lint` (if exists)
    - Verify: All tests pass, no regressions

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 1 | Functions defined; can be sourced without error |
| Step 3 | `doyaken list` shows correct task counts |
| Step 5 | `doyaken clean --dry-run` shows correct file counts |
| Step 9 | All unit tests pass |
| Step 10 | Full test suite passes |

### Test Plan

- [ ] Unit: `count_files()` with empty dir, missing dir, files present
- [ ] Unit: `count_files()` with pattern filtering
- [ ] Unit: `count_task_files()` counts only .md files
- [ ] Unit: `count_files_excluding_gitkeep()` excludes .gitkeep
- [ ] Integration: Existing workflow.bats tests still pass
- [ ] Manual: `doyaken board`, `doyaken list`, `doyaken status` produce correct counts

### Docs to Update

- [ ] None required - internal refactoring only

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review technical debt findings

### 2026-02-01 22:18 - Task Expanded

- Intent: IMPROVE (refactor)
- Scope: Consolidate file counting patterns into utility functions
- Key files: lib/project.sh, lib/cli.sh, lib/registry.sh, lib/taskboard.sh, lib/core.sh, lib/upgrade.sh
- Complexity: Medium - many files but mechanical changes
- Discovery: lib/core.sh already has count_tasks() and count_locked_tasks() at lines 1708-1717
- Total occurrences: ~30 (more than originally estimated)

### 2026-02-01 22:19 - Triage Complete

Quality gates:
- Lint: `npm run lint` (scripts/lint.sh)
- Types: not applicable (bash project)
- Tests: `npm test` (scripts/test.sh + test/run-bats.sh)
- Build: not applicable (no build step)

Task validation:
- Context: clear
- Criteria: specific
- Dependencies: none

Complexity:
- Files: some (6 files: cli.sh, registry.sh, taskboard.sh, core.sh, project.sh, upgrade.sh)
- Risk: low (mechanical refactoring, full test suite exists)

Verified findings:
- Pattern `wc -l | tr -d ' '` found 28 times across 6 lib/*.sh files
- Existing utility functions confirmed at lib/core.sh:1708-1717
- All target files exist
- Unit test directory exists with 6 test files

Ready: yes

### 2026-02-01 22:30 - Task Expanded (Phase 0 Verification)

- Intent: IMPROVE (refactor)
- Verified 28 occurrences of `wc -l | tr -d ' '` pattern across 6 lib/*.sh files
- Corrected line numbers: core.sh utility functions at 1708-1717 (not 1630-1638)
- Discovered additional file: lib/upgrade.sh has 2 occurrences (added to scope)
- Test location confirmed: test/unit/project.bats (new file for utility tests)
- Pattern variations: .md files (~19), .lock files (~2), misc files (~7)
- All target files verified to exist

### 2026-02-01 22:33 - Planning Complete

- Steps: 10 (refined from original 7)
- Risks: 4 identified, all low severity with mitigations
- Test coverage: moderate (unit tests for utilities + existing integration tests)
- Key decisions:
  - Three utility functions needed: `count_files()`, `count_task_files()`, `count_files_excluding_gitkeep()`
  - Keep lib/core.sh unchanged (avoids circular dependency complexity)
  - Line 282 in upgrade.sh counts directories, not files - keep inline (different semantic)
- Source order verified: cli.sh sources project.sh at line 32 before all dependent files

### 2026-02-01 22:37 - Implementation Progress

Step 1: Add utility functions to lib/project.sh
- Files modified: lib/project.sh
- Added three functions: `count_files()`, `count_task_files()`, `count_files_excluding_gitkeep()`
- Verification: pass - functions source correctly and return expected counts

Step 2: Update lib/taskboard.sh (4 occurrences)
- Files modified: lib/taskboard.sh
- Added source of project.sh
- Replaced 4 find/wc patterns with `count_task_files()`
- Verification: pass - `doyaken tasks` produces correct output

Step 3: Update lib/registry.sh (6 occurrences)
- Files modified: lib/registry.sh
- Added source of project.sh
- Replaced 6 find/wc patterns with `count_task_files()`
- Verification: pass - `doyaken list` produces correct output

Step 4: Update lib/cli.sh - task counting (7 occurrences)
- Files modified: lib/cli.sh
- Replaced 7 find/wc patterns at lines 76-77, 792, 978-981 with `count_task_files()`
- Verification: pass - `doyaken status` works correctly

Step 5: Update lib/cli.sh - cleanup counting (4 occurrences)
- Files modified: lib/cli.sh
- Replaced 4 find/wc patterns at lines 637, 648, 659, 670 with `count_files_excluding_gitkeep()`
- Note: Line 709 (scratchpad) left unchanged - different semantics (recursive count)
- Verification: pass - `doyaken clean --dry-run` works correctly

Step 6: Update lib/cli.sh - command counting (1 occurrence)
- Files modified: lib/cli.sh
- Replaced find/wc pattern at line 1614 with `count_task_files()`
- Verification: pass - `doyaken sync` works correctly

Step 7: Update lib/upgrade.sh (1 occurrence)
- Files modified: lib/upgrade.sh
- Added source of project.sh
- Replaced find/wc pattern at line 622 with `count_files()`
- Note: Line 282 left unchanged - counts directories, not files
- Verification: pass

Step 8: Run quality gates
- Lint: pass (0 errors, 5 warnings - all pre-existing)
- Tests: pass (88 script tests, integration tests pass)
- Verification: all quality gates pass

---

## Notes

**In Scope:**
- Create/enhance utility functions for file counting
- Replace duplicated `find | wc -l | tr -d ' '` patterns in lib/*.sh
- Add unit tests for new functions

**Out of Scope:**
- Updating hooks/task-context.sh (standalone, not part of lib/)
- Updating test files (they should test the utilities, not use them)
- Updating scripts/test-upgrade.sh (separate utility script)
- Updating .doyaken/lib/* (these are copies synced from lib/)

**Pattern Distribution (28 total):**
- lib/cli.sh: 13 occurrences (lines 76, 77, 637, 648, 659, 670, 709, 792, 978, 979, 980, 981, 1614)
- lib/registry.sh: 6 occurrences (lines 194, 195, 239, 240, 244, 245)
- lib/taskboard.sh: 4 occurrences (lines 60, 61, 62, 63)
- lib/core.sh: 3 occurrences (lines 1655, 1712, 1716)
- lib/upgrade.sh: 2 occurrences (lines 282, 617)

**Assumptions:**
- lib/project.sh is sourced before files that need counting utilities
- All counting follows the same semantics (maxdepth 1, suppress errors)

**Edge Cases:**
- Empty directory: Should return 0 (current behavior)
- Missing directory: Should return 0 (current behavior with 2>/dev/null)
- No matching files: Should return 0
- Filenames with spaces/special chars: find handles these correctly

**Risks:**
- **Low**: Regression risk - many call sites
  - Mitigation: Run full test suite after each file change
- **Low**: Source order issues - project.sh must be sourced first
  - Mitigation: Verify source order in main entry points

---

## Links

- Technical debt review finding: code duplication
