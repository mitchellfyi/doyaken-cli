# Task: Implement Secure File Permissions for Logs and State

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-001-security-secure-file-permissions`             |
| Status      | `done`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:00`                                     |
| Started     | `2026-02-01 21:36`                                     |
| Completed   | `2026-02-01 21:55`                                     |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 21:32` |

---

## Context

**Intent**: IMPROVE (Security Hardening)

Log files, state files, and lock files are created with default permissions (typically 755 for directories, 644 for files when umask is 0022), potentially allowing other users on the system to read sensitive information.

### Current State Analysis

**Sensitive Directories** (defined in `lib/core.sh:496-498`):
- `$LOGS_DIR` (`$DATA_DIR/logs/claude-loop`) - Contains agent output with code context, task content
- `$STATE_DIR` (`$DATA_DIR/state`) - Contains session state including agent IDs, task status
- `$LOCKS_DIR` (`$DATA_DIR/locks`) - Contains lock files with PIDs, task assignments

**Files Identified for Modification**:

| File | Lines | Issue |
|------|-------|-------|
| `lib/core.sh` | 588, 763, 1444-1445 | `mkdir -p` without chmod |
| `lib/cli.sh` | 366-373 | `init_directories()` uses `mkdir -p` without chmod |
| `install.sh` | 244-259 | Creates global dirs without chmod |
| `lib/review-tracker.sh` | 26 | Creates STATE_DIR without chmod |
| `lib/hooks.sh` | 195, 270 | Creates project dirs without chmod |

**Current Permission Pattern** (default umask 0022):
- Directories created as 755 (rwxr-xr-x) - **world readable**
- Files created as 644 (rw-r--r--) - **world readable**

**Impact**: On multi-user systems, any user can read:
- Agent execution logs containing code diffs, task content
- Session state showing what tasks are being worked on
- Lock files showing which agent/PID owns which task

**OWASP Category**: A01:2021 - Broken Access Control (CWE-276: Incorrect Default Permissions)

### Existing Cleanup Capability

`lib/cli.sh:621-712` has `cmd_cleanup()` which removes logs, state, locks, and done tasks. This addresses disk exhaustion via manual cleanup but doesn't implement automatic rotation.

---

## Acceptance Criteria

All must be checked before moving to done:

- [x] Set `umask 0077` at core.sh initialization (before any file operations)
- [x] Add `chmod 700` for `$LOGS_DIR`, `$STATE_DIR`, `$LOCKS_DIR` in `init_state()` and `init_locks()`
- [x] Add `chmod 700` in `init_directories()` (cli.sh) for logs, state, locks subdirectories
- [x] Add `chmod 700` in `install.sh` for sensitive global directories
- [x] Add automatic log rotation (delete logs >7 days) at run start
- [x] Document log location and `dk cleanup` command in README troubleshooting section
- [x] Tests verify permissions are 700 for sensitive directories
- [x] Quality gates pass (`npm run check`)
- [x] Changes committed with task reference

---

## Notes

**In Scope:**
- Adding umask at process initialization
- chmod 700 for logs, state, locks directories
- Automatic log rotation (7-day retention)
- README documentation update

**Out of Scope:**
- Changing permissions for task directories (tasks are project files, not runtime state)
- Changing permissions for prompts, templates, skills (these are code, not sensitive data)
- External logrotate configuration (using built-in rotation instead)
- File-level chmod 600 (umask 0077 handles new files automatically)

**Assumptions:**
- Users expect logs to be private by default
- 7-day log retention is sufficient for debugging
- `dk cleanup` command exists and is discoverable

**Edge Cases:**
- Existing installations: New permissions won't retroactively fix old directories
- Shared project directories: If `.doyaken/` is group-shared, 700 blocks collaborators (acceptable - state is per-agent)
- Root execution: chmod works differently; should still set 700

**Risks:**
| Risk | Mitigation |
|------|------------|
| Breaking existing scripts that read logs | Low risk - logs are not part of public API |
| Log rotation deleting needed debug data | 7-day window is reasonable; document `--keep-logs` option for future |
| Performance impact of chmod on every mkdir | Negligible - one-time per directory |

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| Set `umask 0077` at core.sh initialization | none | No umask set - add after shebang (line 27) |
| Add `chmod 700` in `init_state()` and `init_locks()` | none | Only `mkdir -p` used, no chmod |
| Add `chmod 700` in `init_directories()` (cli.sh) | none | Creates logs, state, locks without chmod |
| Add `chmod 700` in `install.sh` | none | Creates global dirs without chmod |
| Add automatic log rotation (>7 days) | none | No rotation exists |
| Document log location and `dk cleanup` in README | partial | Mentions local logs, not global or cleanup cmd |
| Tests verify 700 permissions | none | Only env var tests exist |

### Risks

- [ ] **Breaking existing scripts**: Low - logs are not public API; mitigate by documenting
- [ ] **Log rotation deletes debug data**: Low - 7-day window reasonable; mitigate by logging rotation
- [ ] **Existing installations**: Directories won't be retroactively fixed; mitigate by applying chmod on every init (idempotent)

### Steps

1. **Set umask in core.sh**
   - File: `lib/core.sh:27` (after `set -euo pipefail`)
   - Change: Add `umask 0077  # Secure file permissions (owner only)`
   - Verify: Run `dk run --dry-run` and check new files are 600

2. **Secure init_locks()**
   - File: `lib/core.sh:762-764`
   - Change: Add `chmod 700 "$LOCKS_DIR"` after mkdir
   - Verify: `stat -f %Lp "$LOCKS_DIR"` returns 700

3. **Secure early LOCKS_DIR creation**
   - File: `lib/core.sh:588`
   - Change: Add `chmod 700 "$LOCKS_DIR" 2>/dev/null || true` after mkdir
   - Verify: Worker lock dirs have correct permissions

4. **Secure init_state()**
   - File: `lib/core.sh:1443-1447`
   - Change: Add `chmod 700` for STATE_DIR and RUN_LOG_DIR after each mkdir
   - Verify: Both directories have 700 permissions

5. **Add log rotation to init_state()**
   - File: `lib/core.sh:1443-1447` (after creating RUN_LOG_DIR)
   - Change: Add `find "$LOGS_DIR" -maxdepth 1 -type d -mtime +7 ! -name 'logs' -exec rm -rf {} + 2>/dev/null || true`
   - Verify: Create old test dir, run, confirm deleted

6. **Secure init_directories() in cli.sh**
   - File: `lib/cli.sh:371-373`
   - Change: Add `chmod 700` after each mkdir for logs, state, locks
   - Verify: `dk init` in test dir, check permissions

7. **Secure install.sh global directories**
   - File: `install.sh:257-259`
   - Change: Add `chmod 700` for logs, state, locks after mkdir
   - Verify: Fresh install has 700 permissions

8. **Update README troubleshooting**
   - File: `README.md:497-509`
   - Change: Add global log location, `dk cleanup` command, and note about secure permissions
   - Verify: Documentation is accurate

9. **Add permission tests**
   - File: `test/unit/security.bats` (add to existing file)
   - Change: Add tests for directory permissions using `stat`
   - Verify: `npm run test` passes

### Checkpoints

- After step 4: All core.sh changes done - run `dk run --dry-run` to smoke test
- After step 7: All file changes done - run full `npm run test`
- After step 9: All tests pass - run `npm run check`

### Test Plan

- [ ] Unit: Verify `init_state()` creates 700 dirs
- [ ] Unit: Verify `init_locks()` creates 700 dir
- [ ] Unit: Verify log rotation deletes old directories
- [ ] Integration: `dk init` creates secure directories

### Docs to Update

- [ ] `README.md` - Add log locations (global/project), `dk cleanup` command, security note

---

## Implementation Reference

```bash
# Step 1: At core.sh:27 (after set -euo pipefail)
umask 0077  # Secure file permissions (owner only)

# Step 2: init_locks() at core.sh:762-764
init_locks() {
  mkdir -p "$LOCKS_DIR"
  chmod 700 "$LOCKS_DIR"
}

# Step 3: Early LOCKS_DIR creation at core.sh:588
mkdir -p "$LOCKS_DIR" 2>/dev/null || true
chmod 700 "$LOCKS_DIR" 2>/dev/null || true

# Step 4 & 5: init_state() at core.sh:1443-1447
init_state() {
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  mkdir -p "$RUN_LOG_DIR"
  chmod 700 "$RUN_LOG_DIR"
  # Auto-rotate old logs (>7 days) - exclude the 'logs' directory itself
  find "$LOGS_DIR" -maxdepth 1 -type d -mtime +7 ! -name 'logs' -exec rm -rf {} + 2>/dev/null || true
  init_locks
}

# Step 6: init_directories() at cli.sh:371-373
mkdir -p "$ai_agent_dir/logs"
chmod 700 "$ai_agent_dir/logs"
mkdir -p "$ai_agent_dir/state"
chmod 700 "$ai_agent_dir/state"
mkdir -p "$ai_agent_dir/locks"
chmod 700 "$ai_agent_dir/locks"

# Step 7: install.sh:257-259
mkdir -p "$DOYAKEN_HOME/logs"
chmod 700 "$DOYAKEN_HOME/logs"
mkdir -p "$DOYAKEN_HOME/state"
chmod 700 "$DOYAKEN_HOME/state"
mkdir -p "$DOYAKEN_HOME/locks"
chmod 700 "$DOYAKEN_HOME/locks"
```

---

## Work Log

### 2026-02-01 21:59 - Verification Complete

Criteria: all met (9 of 9)
Quality gates: all pass (lint: 0 errors/5 warnings, tests: 88 pass)
CI: pass - https://github.com/mitchellfyi/doyaken-cli/actions/runs/21570882580

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Set `umask 0077` at core.sh initialization | ✓ | `lib/core.sh:28` |
| Add `chmod 700` in `init_state()` and `init_locks()` | ✓ | `lib/core.sh:764,1447-1449` |
| Add `chmod 700` in `init_directories()` (cli.sh) | ✓ | `lib/cli.sh:371-376` |
| Add `chmod 700` in `install.sh` | ✓ | `install.sh:257-262` |
| Add automatic log rotation (>7 days) | ✓ | `lib/core.sh:1453` |
| Document log location and `dk cleanup` in README | ✓ | `README.md:497-517` |
| Tests verify 700 permissions | ✓ | `test/unit/security.bats:814-905` (7 tests) |
| Quality gates pass | ✓ | `npm run check` - all pass |
| Changes committed with task reference | ✓ | `92c6479`, `65f65ea` |

Task location: 3.doing → 4.done
Reason: complete - all criteria met, CI green

### 2026-02-01 21:55 - Review Complete

Findings:
- Blockers: 0 - none
- High: 0 - none
- Medium: 0 - none
- Low: 1 - redundant `! -name 'logs'` filter (harmless defensive code, not addressed)

Review passes:
- Correctness: pass
- Design: pass
- Security: pass
- Performance: pass
- Tests: pass (7 new tests, 174 total)

All criteria met: yes
Follow-up tasks: none

Status: COMPLETE

### 2026-02-01 21:46 - Documentation Sync

Docs updated:
- `README.md:497-517` - Already updated with troubleshooting section covering global/project log locations, `dk cleanup` command, and security note about 700 permissions + 7-day rotation

Inline comments:
- `lib/core.sh:28-29` - umask with security explanation
- `lib/core.sh:590-591` - Secure permissions comment for early LOCKS_DIR creation
- `lib/core.sh:1453` - Log rotation explanation comment
- `test/unit/security.bats:814-816` - Section header for permission tests

Consistency: verified
- README "700 permissions" matches `chmod 700` in code
- README "7 days" matches `-mtime +7` in find command
- README documents both project (`.doyaken/`) and global (`~/.doyaken/`) paths which are both secured
- Test file documents expected behavior with clear comments

No additional documentation needed - implementation already included appropriate comments at each security-relevant change.

### 2026-02-01 21:42 - Testing Complete

Tests written:
- `test/unit/security.bats` - 7 tests (unit)
  - 3 tests for directory permissions (logs, state, locks)
  - 2 tests for umask behavior (files, directories)
  - 2 tests for log rotation (deletion, preservation)

Quality gates:
- Lint: pass (0 errors, 5 warnings - preexisting)
- Types: N/A (bash project)
- Tests: pass (174 total, 7 new)
- Build: N/A (bash project)

CI ready: yes
- Cross-platform stat commands (macOS + Linux)
- Cross-platform date commands with fallback
- No hardcoded paths
- No flaky tests

### 2026-02-01 21:38 - Implementation Complete

Step 1: Set umask in core.sh
- Files modified: `lib/core.sh:28`
- Change: Added `umask 0077` after `set -euo pipefail`
- Verification: shellcheck pass

Step 2: Secure init_locks()
- Files modified: `lib/core.sh:764`
- Change: Added `chmod 700 "$LOCKS_DIR"` after mkdir
- Verification: shellcheck pass

Step 3: Secure early LOCKS_DIR creation
- Files modified: `lib/core.sh:590`
- Change: Added `chmod 700 "$LOCKS_DIR" 2>/dev/null || true`
- Verification: shellcheck pass

Step 4 & 5: Secure init_state() + log rotation
- Files modified: `lib/core.sh:1445-1451`
- Change: Added chmod 700 for STATE_DIR and RUN_LOG_DIR, added 7-day log rotation with find
- Verification: shellcheck pass

Step 6: Secure init_directories() in cli.sh
- Files modified: `lib/cli.sh:371-376`
- Change: Added chmod 700 for logs, state, locks directories
- Verification: shellcheck pass

Step 7: Secure install.sh global directories
- Files modified: `install.sh:257-262`
- Change: Added chmod 700 for logs, state, locks directories
- Verification: shellcheck pass

Step 8: Update README troubleshooting
- Files modified: `README.md:497-513`
- Change: Added global log location, `dk cleanup` command, security note
- Verification: N/A (docs)

Step 9: Add permission tests
- Files modified: `test/unit/security.bats:814-905`
- Change: Added 5 tests for directory permissions and umask behavior
- Verification: `npm run test:unit` - 172 tests pass

Final verification:
- `npm run check` - All checks passed
- `npm run test:unit` - 172 tests pass (including 5 new permission tests)

### 2026-02-01 - Planning Complete

Gap analysis:
- 6 criteria need implementation (none status)
- 1 criterion needs update (partial status - README docs)

Implementation plan:
- Steps: 9
- Files: 4 to modify (`lib/core.sh`, `lib/cli.sh`, `install.sh`, `README.md`), 1 to update tests (`test/unit/security.bats`)
- Risks: 3 (all low, mitigations identified)
- Test coverage: moderate (unit tests for permissions + integration via quality gates)

Checkpoints defined at steps 4, 7, 9.

### 2026-02-01 21:36 - Triage Complete

Quality gates:
- Lint: `npm run lint` (shellcheck)
- Types: N/A (bash project)
- Tests: `npm run test` (bats + scripts/test.sh)
- Build: N/A (bash project)
- All gates: `npm run check` ✅ passing

Task validation:
- Context: clear - detailed analysis of affected files with line numbers
- Criteria: specific - 9 testable acceptance criteria
- Dependencies: none - no blockers listed

Complexity:
- Files: some (6 files to modify + 1 new test file)
- Risk: low - straightforward chmod/umask additions
- Existing test file: `test/unit/security.bats` exists (tests env var security, not file permissions)

Ready: yes

### 2026-02-01 21:32 - Task Expanded

- Intent: IMPROVE (Security Hardening)
- Scope: Add umask 0077, chmod 700 for sensitive directories, auto-rotate logs, document cleanup
- Key files: `lib/core.sh`, `lib/cli.sh`, `install.sh`, `README.md`, `test/security.bats` (new)
- Complexity: Low-Medium (multiple files, straightforward changes)
- Analysis: Found 6 files with `mkdir -p` for sensitive directories lacking chmod
- Existing cleanup: `cmd_cleanup()` in cli.sh provides manual cleanup
- Test gap: No existing permission tests

### 2026-02-01 17:00 - Created

- Security audit identified world-readable logs
- Next: Implement secure permissions

---

## Links

- Primary: `lib/core.sh:496-498` (directory definitions), `lib/core.sh:762-764` (init_locks), `lib/core.sh:1443-1447` (init_state)
- Secondary: `lib/cli.sh:361-382` (init_directories), `install.sh:244-259` (global install)
- Reference: CWE-276 (Incorrect Default Permissions), OWASP A01:2021 (Broken Access Control)
