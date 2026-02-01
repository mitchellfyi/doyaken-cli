# Task: Fix Incomplete sed Metacharacter Escaping in core.sh

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-003-quality-fix-sed-escaping`                     |
| Status      | `done`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-01 17:10`                                     |
| Started     | `2026-02-01 21:01`                                     |
| Completed   | `2026-02-01 21:13`                                     |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |  |
| Assigned At |  |

---

## Context

**Intent**: FIX

Security review identified incomplete sed metacharacter escaping in `lib/core.sh`. The current code at lines 955-956 only escapes `&` and `/` characters:

```bash
local escaped_agent_id="${AGENT_ID//&/\\&}"
escaped_agent_id="${escaped_agent_id////\\/}"
```

However, sed also interprets additional metacharacters:
- `\` - Backslash (escape character)
- `*` - Zero or more of preceding character
- `.` - Any single character
- `[` and `]` - Character classes
- `^` and `$` - Anchors
- `+` and `?` - (in extended regex)

While AGENT_ID is currently set from `AGENT_NAME` which is `worker-${WORKER_NUM}` (a controlled format), this creates a security vulnerability if:
1. The AGENT_NAME pattern changes in the future
2. The escaping function is reused elsewhere
3. A malicious value is injected through lock file manipulation

**Category**: Security / Input Validation
**Severity**: HIGH

**Affected Functions** (actual line numbers from current codebase):
- `assign_task()` at lib/core.sh:947-962 - uses escaped AGENT_ID in sed
- `unassign_task()` at lib/core.sh:965-976 - uses sed but with static values (safe)
- `refresh_assignment()` at lib/core.sh:978-990 - uses sed with timestamp only (safe)

---

## Acceptance Criteria

- [x] Create a helper function `update_task_metadata()` that safely updates markdown table rows
- [x] Function uses awk or bash string operations instead of sed with interpolated values
- [x] Replace sed calls in `assign_task()`, `unassign_task()`, and `refresh_assignment()` with the new helper
- [x] Add unit tests for metadata updates with special characters (`\ * . [ ] ^ $ & /`)
- [x] Verify existing task assignment workflow works unchanged
- [x] Tests written and passing
- [x] Quality gates pass
- [x] Changes committed with task reference

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| Create helper function `update_task_metadata()` | none | Function does not exist |
| Function uses awk or bash instead of sed | none | New implementation needed |
| Replace sed in assign/unassign/refresh | partial | sed used at lines 957-958, 970-971, 985 |
| Add unit tests for special characters | none | No tests for assignment functions |
| Verify existing workflow works unchanged | full | Existing tests cover basic workflow |
| Tests written and passing | partial | core.bats exists, needs new tests |
| Quality gates pass | full | CI infrastructure exists |
| Changes committed with task reference | none | No changes yet |

### Risks

- [ ] **awk portability**: POSIX awk features used in lib/skills.sh:104-159 work on both platforms - mitigate by testing
- [ ] **Atomic updates**: Current sed -i.bak approach must be preserved - use temp file + mv
- [ ] **Lock file injection**: AGENT_ID read from lock files could be malicious - this fix addresses it

### Steps

1. **Create `update_task_metadata()` helper function**
   - File: `lib/core.sh` (after line 945, before `assign_task()`)
   - Change: Add function that uses awk's `-v` option to safely pass values as literal strings (not regex patterns). The function will:
     - Take 3 args: `task_file`, `field_name`, `new_value`
     - Use awk to find lines matching `| <field_name> |` and replace the value portion
     - Write to temp file then mv for atomicity
   - Verify: `bash -n lib/core.sh` passes (syntax check)

2. **Replace sed calls in `assign_task()`**
   - File: `lib/core.sh:954-959`
   - Change: Remove escaped_agent_id variable, replace sed calls with:
     ```bash
     update_task_metadata "$task_file" "Assigned To" "\`$AGENT_ID\`"
     update_task_metadata "$task_file" "Assigned At" "\`$timestamp\`"
     ```
   - Verify: `bash -n lib/core.sh` passes

3. **Replace sed calls in `unassign_task()`**
   - File: `lib/core.sh:970-972`
   - Change: Replace sed calls with:
     ```bash
     update_task_metadata "$task_file" "Assigned To" ""
     update_task_metadata "$task_file" "Assigned At" ""
     ```
   - Verify: `bash -n lib/core.sh` passes

4. **Replace sed call in `refresh_assignment()`**
   - File: `lib/core.sh:985-986`
   - Change: Replace sed call with:
     ```bash
     update_task_metadata "$task_file" "Assigned At" "\`$timestamp\`"
     ```
   - Verify: `bash -n lib/core.sh` passes

5. **Add unit tests for metadata updates**
   - File: `test/unit/core.bats`
   - Change: Add new test section "Task metadata operations" with tests for:
     - Basic field update
     - Update with special characters: `\ * . [ ] ^ $ & /`
     - Empty value update
     - Non-existent field (graceful handling)
   - Verify: `bats test/unit/core.bats` passes

6. **Run integration verification**
   - Command: `npm run test`
   - Verify: All tests pass including existing workflow tests

7. **Run quality gates**
   - Command: `npm run lint && npm run test`
   - Verify: No errors

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 1 | `bash -n lib/core.sh` passes, function syntax valid |
| Step 4 | All sed calls replaced, `bash -n lib/core.sh` passes |
| Step 5 | `bats test/unit/core.bats` passes with special char tests |
| Step 7 | `npm run lint && npm run test` passes |

### Test Plan

- [ ] **Unit**: Test `update_task_metadata()` with normal values
- [ ] **Unit**: Test with sed metacharacters: `worker\.test`, `agent*1`, `[test]`, `^agent$`, `a&b`, `a/b`
- [ ] **Unit**: Test with backslash: `worker\1`
- [ ] **Unit**: Test empty value (unassign case)
- [ ] **Integration**: Verify existing task assignment workflow via `npm run test`

### Docs to Update

- None required (internal function change, no API change)

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review security findings

### 2026-02-01 21:00 - Task Expanded

- Intent: FIX
- Scope: Replace sed-based metadata updates with awk-based approach
- Key files: `lib/core.sh`, `test/unit/core.bats`
- Complexity: Low (localized change, clear pattern)
- Line numbers updated (original report was outdated)

### 2026-02-01 21:02 - Planning Complete

- Steps: 7
- Risks: 3 (all low, with mitigations)
- Test coverage: moderate (unit tests for helper + integration via existing tests)
- Key insight: awk `-v` passes values as literal strings, avoiding regex escaping entirely

### 2026-02-01 21:01 - Triage Complete

Quality gates:
- Lint: `npm run lint` (shellcheck via scripts/lint.sh)
- Types: N/A (bash project)
- Tests: `npm run test` (basic + bats tests)
- Build: N/A (no build step)

Task validation:
- Context: clear - affected functions identified with line numbers, vulnerability explained
- Criteria: specific - 8 testable acceptance criteria defined
- Dependencies: none - no blockers listed

Complexity:
- Files: few (lib/core.sh, test/unit/core.bats)
- Risk: low - localized changes to 3 functions, CI runs on macOS + Linux

Ready: yes

### 2026-02-01 21:04 - Implementation Progress

Step 1: Create `update_task_metadata()` helper function
- Files modified: lib/core.sh (added function at line 947)
- Uses awk's `index()` for literal string matching (not regex)
- Escapes backslashes before passing to awk -v (handles `\` character)
- Verification: `bash -n lib/core.sh` passes

Step 2: Replace sed calls in `assign_task()`
- Files modified: lib/core.sh:973-982
- Removed escaped_agent_id variable and sed calls
- Verification: `bash -n lib/core.sh` passes

Step 3: Replace sed calls in `unassign_task()`
- Files modified: lib/core.sh:985-993
- Verification: `bash -n lib/core.sh` passes

Step 4: Replace sed call in `refresh_assignment()`
- Files modified: lib/core.sh:995-1003
- Verification: `bash -n lib/core.sh` passes

Step 5: Add unit tests for metadata updates
- Files modified: test/unit/core.bats (added 12 new tests)
- Tests cover: basic update, ampersand, forward slash, backslash, asterisk, dot, brackets, caret/dollar, empty value, non-existent field/file, preservation of other fields
- Verification: `npx bats test/unit/core.bats` passes (28 tests)

Step 6: Run integration verification
- Command: `npm run test`
- Verification: 88 basic tests + 167 unit tests + 8 integration tests = all pass

Step 7: Run quality gates
- Command: `npm run lint && npm run test`
- Verification: 0 errors (5 warnings - pre-existing, unrelated)

### 2026-02-01 21:10 - Testing Complete

Tests written:
- `test/unit/core.bats` - 12 new tests (unit)

Quality gates:
- Lint: pass (0 errors, 5 warnings pre-existing)
- Types: N/A (bash project)
- Tests: pass (88 basic + 167 unit + 8 integration)
- Build: N/A

CI ready: yes
- Uses POSIX awk features only (index(), printf, -v)
- Temp file + mv for atomic writes
- No BSD-specific sed commands

Commit: 39cf8c0 "fix: Replace sed with awk for task metadata updates"

### 2026-02-01 21:12 - Documentation Sync

Docs updated:
- None required (internal function change, no API change)

Inline comments:
- `lib/core.sh:947-949` - Function purpose and security rationale
- `lib/core.sh:957` - Backslash escaping explanation
- `lib/core.sh:961` - Why index() is used for literal matching

Consistency: verified
- CONTRIBUTING.md: No references to task assignment internals
- SECURITY.md: No specific sed escaping documentation needed (general policy)
- README: No API changes to document

---

## Notes

**In Scope:**
- Create `update_task_metadata()` helper function
- Replace sed calls in task assignment functions
- Add unit tests for edge cases

**Out of Scope:**
- Other sed usages in the codebase (lib/taskboard.sh, lib/skills.sh) - these don't use user-provided values in the replacement string
- Refactoring the broader task assignment architecture

**Assumptions:**
- The markdown table format `| Field | Value |` is stable
- awk is available on all supported platforms (macOS, Linux)
- AGENT_ID values should be alphanumeric with hyphens and underscores only

**Edge Cases:**
- AGENT_ID containing: `\ * . [ ] ^ $ & / ` (newline)
- Empty AGENT_ID (should be handled gracefully)
- Very long AGENT_ID (no length limit enforced currently)

**Risks:**
- Low: awk implementation might differ slightly between macOS and Linux (mitigated by testing on both)
- Low: Backup file handling (`.bak`) is currently removed after each sed; new approach should also be atomic

---

## Links

- Security review finding: sed escaping vulnerability

### 2026-02-01 21:13 - Review Complete

Findings:
- Blockers: 0 - none
- High: 0 - none
- Medium: 0 - none
- Low: 0 - none

Review passes:
- Correctness: pass
- Design: pass
- Security: pass
- Performance: pass
- Tests: pass

All criteria met: yes
Follow-up tasks: none

Status: COMPLETE

### 2026-02-01 21:16 - Verification Complete

Criteria: all met
| Criterion | Status | Evidence |
|-----------|--------|----------|
| Create helper function `update_task_metadata()` | [x] | lib/core.sh:950-975 |
| Function uses awk instead of sed | [x] | Uses awk with index() for literal matching |
| Replace sed in assign/unassign/refresh | [x] | lib/core.sh:977-1008 |
| Add unit tests for special characters | [x] | test/unit/core.bats:142-312 (12 tests) |
| Verify existing workflow works unchanged | [x] | All integration tests pass |
| Tests written and passing | [x] | 167 unit + 8 integration tests pass |
| Quality gates pass | [x] | 0 errors, 5 pre-existing warnings |
| Changes committed with task reference | [x] | Commit 39cf8c0 |

Quality gates: all pass
- Lint: 0 errors (5 pre-existing warnings)
- Tests: 88 basic + 167 unit + 8 integration = pass
- Build: N/A (bash project)

CI: pass - https://github.com/mitchellfyi/doyaken-cli.git/actions/runs/21570395974
- Lint: pass
- Validate: pass
- Test (ubuntu-latest): pass
- Test (macos-latest): pass
- Package: pass
- Install Test (ubuntu-latest): pass
- Install Test (macos-latest): pass

Task location: 3.doing → 4.done
Reason: complete - all acceptance criteria met, quality gates pass, CI green
