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
| Assigned At | `2026-02-01 22:21` |

---

## Context

**Intent**: IMPROVE (Refactor to reduce code duplication)

Technical debt assessment identified that the task counting pattern `find ... | wc -l | tr -d ' '` is duplicated 30+ times across the codebase. Analysis reveals:

1. **lib/core.sh already has utility functions** at lines 1630-1638:
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
- [ ] Add unit tests for counting functions (empty dir, missing dir, files present)
- [ ] All existing tests continue to pass
- [ ] Quality gates pass

---

## Plan

### Step 1: Add utility functions to lib/project.sh
- File: lib/project.sh
- Add: `count_files(dir, pattern)` - generic file counting
- Add: `count_task_files(dir)` - wrapper for `*.md` pattern
- Verify: Functions work in isolation

### Step 2: Update lib/taskboard.sh
- File: lib/taskboard.sh
- Change: Lines 60-63 - replace 4 occurrences with `count_task_files()`
- Verify: `./bin/doyaken board` still works

### Step 3: Update lib/registry.sh
- File: lib/registry.sh
- Change: Lines 194-195, 239-240, 244-245 - replace 6 occurrences
- Verify: `./bin/doyaken list` still works

### Step 4: Update lib/cli.sh
- File: lib/cli.sh
- Change: Lines 76-77, 637-709, 792, 978-981, 1614 - replace ~12 occurrences
- Verify: Various CLI commands still work

### Step 5: Consolidate lib/core.sh
- File: lib/core.sh
- Change: Lines 1577, 1634, 1638 - use utility functions or keep internal versions
- Decision: Keep internal `count_tasks()` for backward compatibility, have it call project.sh

### Step 6: Add tests
- File: test/unit/project.bats (new) or test/unit/core.bats
- Add: Tests for count_files, count_task_files
- Cases: empty dir, missing dir, files present, special characters in names

### Step 7: Run quality gates
- Run: `./bin/doyaken check-quality` equivalent
- Verify: All tests pass, no regressions

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review technical debt findings

### 2026-02-01 22:18 - Task Expanded

- Intent: IMPROVE (refactor)
- Scope: Consolidate file counting patterns into utility functions
- Key files: lib/project.sh, lib/cli.sh, lib/registry.sh, lib/taskboard.sh, lib/core.sh
- Complexity: Medium - many files but mechanical changes
- Discovery: lib/core.sh already has count_tasks() and count_locked_tasks() at lines 1630-1638
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
- Files: some (5 files: cli.sh, registry.sh, taskboard.sh, core.sh, project.sh)
- Risk: low (mechanical refactoring, full test suite exists)

Verified findings:
- Pattern `wc -l | tr -d ' '` found 28 times across 5 lib/*.sh files
- Existing utility functions confirmed at lib/core.sh:1630-1638
- All target files exist
- Unit test directory exists with 6 test files

Ready: yes

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
