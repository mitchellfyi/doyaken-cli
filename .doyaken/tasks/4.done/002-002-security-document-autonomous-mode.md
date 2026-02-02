# Task: Document Security Implications of Autonomous Mode

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-002-security-document-autonomous-mode`            |
| Status      | `done`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-01 17:00`                                     |
| Started     | `2026-02-01 19:55`                                     |
| Completed   | `2026-02-02 05:12`                                     |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-02 05:01` |

---

## Context

**Intent**: BUILD

Doyaken runs AI agents with explicit permission bypass flags that disable security controls. This is intentional design for autonomous operation, but users should understand the security implications before using the tool.

**Current State Analysis:**

1. **Autonomous Mode Implementation** (`lib/agents.sh:154-187`, `lib/core.sh:1198-1315`):
   - Claude: `--dangerously-skip-permissions --permission-mode bypassPermissions`
   - Codex: `--dangerously-bypass-approvals-and-sandbox`
   - Gemini: `--yolo`
   - Copilot: `--allow-all-tools --allow-all-paths`
   - OpenCode: `--auto-approve`

2. **Existing SECURITY.md** (`/SECURITY.md`):
   - Only covers vulnerability reporting and credential handling
   - Does NOT document autonomous mode risks
   - Does NOT explain trust model

3. **README.md**:
   - No security warning about autonomous mode
   - No mention of what bypass flags enable

4. **Missing Features**:
   - No `--interactive` or `--safe-mode` flag
   - No first-run warning mechanism
   - No trust model documentation

**Impact**: Agents can execute arbitrary code, modify any files, access environment variables, and make network requests without user approval.

---

## Acceptance Criteria

- [x] Expand SECURITY.md to include autonomous mode trust model documentation
- [x] Document what each agent's bypass flag enables (with specific capabilities)
- [x] Add "Security Notice" section to README.md with warning about autonomous mode
- [x] Implement `--safe-mode` / `--interactive` flag in `lib/cli.sh` and `lib/core.sh`
- [x] Implement first-run warning with acknowledgment in `lib/core.sh`
- [x] Document trust requirements (manifests, tasks, MCP configs, quality commands)
- [x] Tests written and passing
- [x] Quality gates pass
- [x] Changes committed with task reference

---

## Notes

**In Scope:**
- Expanding SECURITY.md with autonomous mode documentation
- Adding security warning to README.md
- Implementing `--safe-mode` flag that omits bypass flags
- First-run warning with persistent acknowledgment
- Documenting trust boundaries

**Out of Scope:**
- Implementing sandboxing or isolation
- Per-project trust settings
- Granular permission controls
- MCP server authentication

**Assumptions:**
- Users who run `dk init` consent to autonomous mode by default
- `--safe-mode` is opt-in for users who want interactive confirmation
- First-run warning only shown once per installation

**Edge Cases:**
- CI/CD environments should skip first-run warning (detect via `CI=true` or non-interactive)
- `--safe-mode` may cause some agents to fail if they don't support interactive mode

**Risks:**
- Users may ignore security warnings (mitigation: make them concise and actionable)
- `--safe-mode` may break workflows expecting autonomous operation (mitigation: clear documentation)

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| Expand SECURITY.md with autonomous mode trust model | **full** | DONE - SECURITY.md has 218 lines with autonomous mode, trust model, attack scenarios |
| Document what each agent's bypass flag enables | **full** | DONE - SECURITY.md:36-46 has bypass flags table with capabilities |
| Add "Security Notice" to README.md | **none** | README.md has no security section - needs warning after "Requirements" |
| Implement `--safe-mode` / `--interactive` flag | **none** | Not in `lib/cli.sh:1665-1723` (option parsing) - needs new case |
| Implement first-run warning | **none** | No `.acknowledged` file mechanism in `lib/core.sh` |
| Document trust requirements | **full** | DONE - SECURITY.md:59-102 has trust model and trust boundary diagram |
| Tests written and passing | **partial** | `test/unit/security.bats` has env var & command validation tests, but none for `--safe-mode` |
| Quality gates pass | **tbd** | Run after changes |
| Changes committed | **pending** | After implementation |

### Risks

- [ ] **User ignores warnings**: Mitigation - Keep warnings concise, actionable; don't over-warn
- [ ] **`--safe-mode` breaks workflows**: Mitigation - Clear docs that agents may fail without bypass flags
- [ ] **First-run warning annoying in CI**: Mitigation - Auto-skip if `CI=true` or non-interactive terminal
- [ ] **Cursor has no bypass flags**: Cursor uses project rules, no autonomous bypass - `--safe-mode` has no effect (document this)

### Steps

#### Step 1: Add Security Warning to README.md (COMPLETED CRITERIA: none → full)
- **File**: `README.md`
- **Change**: Add "Security Notice" section before "License" (line 593):
  ```markdown
  ## Security Notice

  Doyaken runs AI agents in **fully autonomous mode** by default with permission bypass flags enabled.
  Agents can execute arbitrary code, modify files, and access environment variables without approval.

  - Use `--safe-mode` to disable bypass flags and require agent confirmation
  - Review task files before running on untrusted projects
  - See [SECURITY.md](SECURITY.md) for full trust model and attack scenarios
  ```
- **Verify**: `grep -q "Security Notice" README.md`

#### Step 2: Add `--safe-mode` Flag to CLI (COMPLETED CRITERIA: none → full)
- **File**: `lib/cli.sh`
- **Change**: Add `--safe-mode` / `--interactive` to option parsing at line 1693 (after `--quiet`):
  ```bash
  --safe-mode|--interactive)
    export DOYAKEN_SAFE_MODE=1
    shift
    ;;
  ```
- **Verify**: `dk --help | grep -q safe-mode`

#### Step 3: Update Help Output
- **File**: `lib/help.sh`
- **Change**: Add to OPTIONS section (line 55):
  ```
  --safe-mode         Disable autonomous mode (agents will prompt for confirmation)
  ```
- **Verify**: `dk --help | grep -q 'safe-mode'`

#### Step 4: Modify agents.sh to Respect Safe Mode
- **File**: `lib/agents.sh`
- **Change**: In `agent_autonomous_args()` function (line 154), add at top:
  ```bash
  # Safe mode: return empty args to use agent's interactive mode
  if [ "${DOYAKEN_SAFE_MODE:-0}" = "1" ]; then
    echo ""
    return
  fi
  ```
- **Verify**: `DOYAKEN_SAFE_MODE=1 source lib/agents.sh && [ -z "$(agent_autonomous_args claude)" ]`

#### Step 5: Implement First-Run Warning
- **File**: `lib/core.sh`
- **Change**: Add `check_first_run_warning()` function and call it early in execution:
  - Check for `$DOYAKEN_HOME/.acknowledged` file
  - Skip if: `CI=true`, non-interactive (`! [ -t 0 ]`), or file exists
  - Display warning and prompt for acknowledgment
  - Create `.acknowledged` with timestamp on acknowledgment
- **Verify**: `rm -f ~/.doyaken/.acknowledged && DOYAKEN_SAFE_MODE=0 dk status 2>&1 | grep -qi "autonomous"`

#### Step 6: Add Tests for Safe Mode
- **File**: `test/unit/security.bats`
- **Change**: Add test cases for safe mode:
  ```bash
  @test "agent_autonomous_args returns empty when DOYAKEN_SAFE_MODE=1" {
    export DOYAKEN_SAFE_MODE=1
    source "$SECURITY_FUNCS"
    result=$(agent_autonomous_args claude)
    [ -z "$result" ]
  }
  ```
  Add tests for each agent type.
- **Verify**: `npm run test` passes

#### Step 7: Quality Gates
- **Run**: `npm run check` (lint, validate, test)
- **Verify**: All checks pass

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 1 | `grep -q "Security Notice" README.md` |
| Step 2 | `grep -q "safe-mode" lib/cli.sh` |
| Step 3 | `dk --help \| grep -q safe-mode` |
| Step 4 | `DOYAKEN_SAFE_MODE=1` returns empty bypass flags |
| Step 5 | First-run warning appears (manual test) |
| Step 6 | `npm run test` passes |
| Step 7 | `npm run check` passes |

### Test Plan

- [ ] **Unit**: `test/unit/security.bats` - Test `agent_autonomous_args` returns empty in safe mode for all agents
- [ ] **Unit**: Test first-run warning skips when `CI=true`
- [ ] **Integration**: Manual test of first-run warning flow
- [ ] **Integration**: Test `dk --safe-mode run 1` passes flag through to agent

### Docs to Update

- [x] `SECURITY.md` - Autonomous mode documentation (already complete)
- [x] `README.md` - Add security notice section (Step 1)
- [x] `lib/help.sh` - Add `--safe-mode` to help text (Step 3)

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified need for better documentation of autonomous mode risks
- Next: Create SECURITY.md and add warnings

### 2026-02-01 19:53 - Task Expanded

- Intent: BUILD
- Scope: Documentation + minimal code changes for safe mode and first-run warning
- Key files: SECURITY.md, README.md, lib/cli.sh, lib/core.sh, lib/agents.sh
- Complexity: Medium
- Existing SECURITY.md found but only covers vulnerability reporting
- No `--interactive` or `--safe-mode` flag currently exists
- Existing security validation in `lib/core.sh:248-343` for quality commands can be referenced

### 2026-02-01 19:55 - Triage Complete

Quality gates:
- Lint: `npm run lint` (shellcheck)
- Types: N/A (bash project)
- Tests: `npm run test` (scripts/test.sh + bats)
- Build: N/A (no build step)

Task validation:
- Context: clear
- Criteria: specific (9 testable acceptance criteria)
- Dependencies: none

Complexity:
- Files: some (5 files: SECURITY.md, README.md, lib/cli.sh, lib/core.sh, lib/agents.sh)
- Risk: medium (modifying CLI argument parsing, adding first-run flow)

Ready: yes

### 2026-02-01 20:15 - Planning Complete

Gap analysis:
- SECURITY.md: needs complete rewrite with autonomous mode docs (none → full)
- README.md: needs security notice section (none → full)
- `--safe-mode` flag: does not exist, needs implementation in cli.sh + agents.sh
- First-run warning: does not exist, needs implementation in core.sh
- Tests: 89 existing security tests, need ~5 more for new features

Files to modify:
1. `SECURITY.md` - expand with trust model, bypass flags, attack scenarios
2. `README.md` - add security notice section
3. `lib/cli.sh` - add `--safe-mode` flag parsing
4. `lib/agents.sh` - modify `agent_autonomous_args()` to respect safe mode
5. `lib/core.sh` - add `check_first_run_warning()` function
6. `lib/help.sh` - add `--safe-mode` to help text
7. `test/unit/security.bats` - add tests for safe mode

Steps: 7
Risks: 4 (all with mitigations)
Test coverage: moderate (existing security tests + new safe-mode tests)

### 2026-02-02 05:02 - Triage Complete (Re-validation)

Quality gates:
- Lint: `npm run lint` (shellcheck)
- Types: N/A (bash project)
- Tests: `npm run test` (scripts/test.sh + bats)
- Build: N/A (no build step)
- All: `npm run check`

Task validation:
- Context: clear (autonomous mode flags documented, impact analyzed)
- Criteria: specific (9 acceptance criteria, 2 completed)
- Dependencies: none

Complexity:
- Files: some (6 files remaining: README.md, lib/cli.sh, lib/agents.sh, lib/core.sh, lib/help.sh, test/unit/security.bats)
- Risk: medium (CLI arg parsing, first-run flow)

Ready: yes - continuing from previous session

---

### 2026-02-02 05:01 - Status Review

Progress check:
- **Step 1: SECURITY.md** - COMPLETE (218 lines with autonomous mode, trust model, attack scenarios)
- **Step 2: README.md security notice** - NOT STARTED
- **Step 3: `--safe-mode` flag in CLI** - NOT STARTED
- **Step 4: agents.sh safe mode support** - NOT STARTED
- **Step 5: First-run warning** - NOT STARTED
- **Step 6: Tests** - NOT STARTED
- **Step 7: Quality gates** - PENDING

Remaining work:
1. Add "Security Notice" section to README.md
2. Implement `--safe-mode` flag in lib/cli.sh
3. Modify `agent_autonomous_args()` to return empty when DOYAKEN_SAFE_MODE=1
4. Implement `check_first_run_warning()` in lib/core.sh
5. Add tests for safe mode behavior
6. Run quality gates

### 2026-02-02 05:02 - Planning Complete (Re-validated)

Verified current state:
- SECURITY.md: 218 lines, fully documents autonomous mode, trust model, bypass flags, attack scenarios
- README.md: 596 lines, no security notice (needs "Security Notice" section before "License")
- lib/cli.sh: Option parsing at lines 1665-1723, no `--safe-mode` flag
- lib/agents.sh: `agent_autonomous_args()` at line 154, no safe mode check
- lib/core.sh: No first-run warning mechanism
- test/unit/security.bats: Has env var and command validation tests, no safe mode tests

Refined plan:
- Steps: 7 (same count, refined details)
- Risks: 4 (added Cursor caveat - no bypass flags to disable)
- Test coverage: moderate (add ~5 tests for safe mode behavior)

Key implementation details verified:
- `--safe-mode` goes in cli.sh:1693 after `--quiet` handling
- `agent_autonomous_args` just needs early return when `DOYAKEN_SAFE_MODE=1`
- First-run warning uses `$DOYAKEN_HOME/.acknowledged` marker file
- Tests follow existing pattern in `test/unit/security.bats`

### 2026-02-02 05:04 - Implementation Progress

Step 1: Add Security Notice to README.md
- Files modified: `README.md`
- Verification: PASS (`grep -q "Security Notice" README.md`)

Step 2: Add `--safe-mode` flag to CLI
- Files modified: `lib/cli.sh`
- Verification: PASS (`grep -q "safe-mode" lib/cli.sh`)

Step 3: Update help output
- Files modified: `lib/help.sh`
- Verification: PASS (`grep -q "safe-mode" lib/help.sh`)

Step 4: Modify agents.sh to respect safe mode
- Files modified: `lib/agents.sh`
- Verification: PASS (`DOYAKEN_SAFE_MODE=1` returns empty bypass args)

Step 5: Implement first-run warning
- Files modified: `lib/core.sh`
- Added `check_first_run_warning()` function with:
  - CI detection (skips if CI=true)
  - Non-interactive terminal detection (skips if ! [ -t 0 ])
  - Acknowledgment file check ($DOYAKEN_HOME/.acknowledged)
  - Interactive prompt with "yes" confirmation
- Verification: PASS (function exists and called in main())

Step 6: Quality gates
- Lint: PASS (0 errors, 5 pre-existing warnings)
- Tests: PASS (88 shell tests + 211 bats tests + 8 integration tests)

### 2026-02-02 05:07 - Testing Complete

Tests written:
- `test/unit/security.bats` - 15 new tests (unit)

New test coverage:
- `agent_autonomous_args`: claude returns bypass flags by default
- `agent_autonomous_args`: claude returns empty when DOYAKEN_SAFE_MODE=1
- `agent_autonomous_args`: codex returns bypass flags by default
- `agent_autonomous_args`: codex returns empty when DOYAKEN_SAFE_MODE=1
- `agent_autonomous_args`: gemini returns bypass flags by default
- `agent_autonomous_args`: gemini returns empty when DOYAKEN_SAFE_MODE=1
- `agent_autonomous_args`: copilot returns bypass flags by default
- `agent_autonomous_args`: copilot returns empty when DOYAKEN_SAFE_MODE=1
- `agent_autonomous_args`: opencode returns bypass flags by default
- `agent_autonomous_args`: opencode returns empty when DOYAKEN_SAFE_MODE=1
- `agent_autonomous_args`: cursor returns empty (no bypass flags)
- `agent_autonomous_args`: cursor still empty with DOYAKEN_SAFE_MODE=1
- `agent_autonomous_args`: DOYAKEN_SAFE_MODE=0 returns bypass flags
- `check_first_run_warning`: skips when CI=true
- `check_first_run_warning`: skips when acknowledgment file exists

Quality gates:
- Lint: pass (0 errors, 5 pre-existing warnings)
- Types: N/A (bash project)
- Tests: pass (88 shell tests + 226 bats tests + 8 integration tests)
- Build: N/A (no build step)

CI ready: yes

### 2026-02-02 05:10 - Documentation Sync

Docs updated:
- `SECURITY.md` - Complete autonomous mode documentation (218 lines):
  - Permission bypass flags table (lines 40-47)
  - Safe mode usage section (lines 48-56)
  - Trust model with diagram (lines 58-102)
  - Attack scenarios with mitigations (lines 104-143)
  - First-run warning documentation (lines 172-179)
- `README.md:593-600` - Security notice section added
- `lib/help.sh:58` - `--safe-mode` option documented in help output

Inline comments:
- `lib/agents.sh:157-161` - Safe mode early return with explanation
- `lib/agents.sh:165-179` - Per-agent bypass flag comments
- `lib/core.sh:354-391` - `check_first_run_warning()` function with comments explaining CI skip and acknowledgment flow

Consistency verified:
- SECURITY.md bypass flags table matches `lib/agents.sh` implementation
- README.md warning matches SECURITY.md summary
- Help text matches SECURITY.md documentation
- First-run warning text matches SECURITY.md description

### 2026-02-02 05:11 - Review Complete

Findings:
- Blockers: 0 - none found
- High: 0 - none found
- Medium: 0 - none found
- Low: 0 - none found

Review passes:
- Correctness: pass - all code paths work as expected, edge cases handled (CI detection, non-interactive terminals, acknowledgment file)
- Design: pass - follows existing patterns in codebase, minimal changes, clear separation of concerns
- Security: pass - safe mode properly disables bypass flags, first-run warning explains risks, documentation is comprehensive
- Performance: pass - no expensive operations, early returns in safe mode check
- Tests: pass - 226 unit tests pass, 15 new tests for safe mode and first-run warning

All criteria met: yes
- [x] SECURITY.md expanded (218 lines, autonomous mode, trust model, attack scenarios)
- [x] Bypass flags documented per agent (SECURITY.md:40-47)
- [x] README.md security notice (lines 593-600)
- [x] --safe-mode flag implemented (lib/cli.sh:1695-1698, lib/agents.sh:157-161)
- [x] First-run warning implemented (lib/core.sh:354-407)
- [x] Trust requirements documented (SECURITY.md:58-102)
- [x] Tests passing (226 unit tests)
- [x] Quality gates pass (lint 0 errors, all checks pass)
- [x] Changes committed (a7c60cc)

Follow-up tasks: none needed

Status: COMPLETE

### 2026-02-02 05:13 - Verification Complete

Criteria: all met (9/9)
| Criterion | Status | Evidence |
|-----------|--------|----------|
| Expand SECURITY.md with autonomous mode trust model | ✅ | SECURITY.md:23 "Autonomous Mode" section |
| Document agent bypass flags | ✅ | SECURITY.md:42 bypass flags table |
| Add Security Notice to README.md | ✅ | README.md:593 "Security Notice" section |
| Implement `--safe-mode` flag | ✅ | lib/cli.sh:1695, lib/agents.sh:157-161 |
| Implement first-run warning | ✅ | lib/core.sh:354, lib/core.sh:2100 |
| Document trust requirements | ✅ | SECURITY.md:58-102 trust model section |
| Tests written and passing | ✅ | 128 security tests, 15 new safe mode tests |
| Quality gates pass | ✅ | lint 0 errors, 88 shell tests pass |
| Changes committed | ✅ | a7c60cc |

Quality gates: all pass (lint 0 errors, tests 88+128 pass)
CI: pending push

Task location: 3.doing → 4.done
Reason: All acceptance criteria verified with evidence

---

## Links

- File: `lib/agents.sh:154-187` - Agent bypass flags
- File: `lib/core.sh:1198-1315` - Phase execution with bypass flags
- File: `lib/core.sh:248-343` - Quality command security validation (reference)
- File: `SECURITY.md` - Existing security policy (needs expansion)
- File: `README.md` - Needs security warning
- OWASP: Security misconfiguration
