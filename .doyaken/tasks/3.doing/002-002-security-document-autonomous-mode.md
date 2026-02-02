# Task: Document Security Implications of Autonomous Mode

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-002-security-document-autonomous-mode`            |
| Status      | `doing`                                                |
| Priority    | `002` High                                             |
| Created     | `2026-02-01 17:00`                                     |
| Started     | `2026-02-01 19:55`                                     |
| Completed   |                                                        |
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

- [ ] Expand SECURITY.md to include autonomous mode trust model documentation
- [ ] Document what each agent's bypass flag enables (with specific capabilities)
- [ ] Add "Security Notice" section to README.md with warning about autonomous mode
- [ ] Implement `--safe-mode` / `--interactive` flag in `lib/cli.sh` and `lib/core.sh`
- [ ] Implement first-run warning with acknowledgment in `lib/core.sh`
- [ ] Document trust requirements (manifests, tasks, MCP configs, quality commands)
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

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
| Expand SECURITY.md with autonomous mode trust model | none | SECURITY.md only covers vulnerability reporting/credentials (59 lines), no autonomous mode docs |
| Document what each agent's bypass flag enables | none | Bypass flags defined in `lib/agents.sh:154-187` but no user-facing documentation |
| Add "Security Notice" to README.md | none | README.md has no security section (563 lines, no warnings) |
| Implement `--safe-mode` / `--interactive` flag | none | No such flags in `lib/cli.sh` (1844 lines) - would need new flag handling |
| Implement first-run warning | none | No acknowledgment mechanism in `lib/core.sh` |
| Document trust requirements | partial | Quality command validation exists (`lib/core.sh:248-343`) but not documented for users |
| Tests written and passing | partial | `test/unit/security.bats` has 89 tests for env var & command validation, but none for --safe-mode or first-run warning |
| Quality gates pass | tbd | Need to run after changes |
| Changes committed | pending | After implementation |

### Risks

- [ ] **User ignores warnings**: Mitigation - Keep warnings concise, actionable; don't over-warn
- [ ] **`--safe-mode` breaks workflows**: Mitigation - Clear docs that agents may fail without bypass flags
- [ ] **First-run warning annoying in CI**: Mitigation - Auto-skip if `CI=true` or non-interactive terminal
- [ ] **Documentation gets stale**: Mitigation - Generate flag docs from `agent_autonomous_args()` where possible

### Steps

#### Step 1: Expand SECURITY.md with Autonomous Mode Documentation
- **File**: `SECURITY.md`
- **Change**: Add comprehensive sections:
  - "Autonomous Mode" - What it is and why it exists
  - "Trust Model" - What doyaken trusts (manifests, tasks, MCP configs, quality commands)
  - "Permission Bypass Flags" - Table of all agent flags with exact capabilities
  - "Attack Scenarios" - What a malicious manifest/task could do
  - "Mitigations" - How to reduce risk (review tasks, use `--safe-mode`, CI isolation)
- **Verify**: `grep -q "Autonomous Mode" SECURITY.md` returns 0

#### Step 2: Add Security Warning to README.md
- **File**: `README.md`
- **Change**: Add "Security Notice" section after "Requirements", before "License":
  - Brief warning about autonomous mode
  - Link to SECURITY.md for details
  - Mention `--safe-mode` flag
- **Verify**: `grep -q "Security Notice" README.md` returns 0

#### Step 3: Add `--safe-mode` Flag to CLI
- **File**: `lib/cli.sh`
- **Change**:
  - Add `--safe-mode` / `--interactive` to global option parsing (around line 1662)
  - Export `DOYAKEN_SAFE_MODE=1` when flag is present
  - Add to help output in `lib/help.sh`
- **Verify**: `dk --help | grep -q safe-mode`

#### Step 4: Modify agents.sh to Respect Safe Mode
- **File**: `lib/agents.sh`
- **Change**: In `agent_autonomous_args()` function (line 154):
  - Check `if [ "${DOYAKEN_SAFE_MODE:-0}" = "1" ]; then echo ""; return; fi`
  - This returns empty args, allowing agent to use its interactive/confirmation mode
- **Verify**: `DOYAKEN_SAFE_MODE=1 source lib/agents.sh && agent_autonomous_args claude` returns empty

#### Step 5: Implement First-Run Warning
- **File**: `lib/core.sh`
- **Change**: Add function `check_first_run_warning()` before `load_manifest` call (around line 488):
  - Check for `$DOYAKEN_HOME/.acknowledged` file
  - If missing and `[ -t 0 ]` (interactive) and `[ -z "${CI:-}" ]`:
    - Display security warning about autonomous mode
    - Ask user to type "I understand" or press Enter to acknowledge
    - Create `.acknowledged` file with timestamp
  - Skip warning in CI or non-interactive mode
- **Verify**: `rm -f ~/.doyaken/.acknowledged && dk status 2>&1 | grep -q "Security Notice"`

#### Step 6: Add Tests for New Features
- **File**: `test/unit/security.bats`
- **Change**: Add test cases:
  - `agent_autonomous_args returns empty when DOYAKEN_SAFE_MODE=1`
  - Test for each agent type
- **Verify**: `npm run test` passes

#### Step 7: Verify and Quality Gates
- **Run**: `npm run check` (lint, validate, test)
- **Verify**: All checks pass

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 1 | `grep -c "##" SECURITY.md` > 8 (multiple sections) |
| Step 2 | `grep -q "Security Notice" README.md` |
| Step 3 | `dk --help` shows `--safe-mode` |
| Step 4 | Safe mode returns empty bypass flags |
| Step 5 | First-run warning appears (manual test) |
| Step 6 | `npm run test` passes |
| Step 7 | `npm run check` passes |

### Test Plan

- [ ] **Unit**: `test/unit/security.bats` - Test `agent_autonomous_args` returns empty in safe mode
- [ ] **Unit**: Test `check_first_run_warning` skips in CI mode
- [ ] **Integration**: Manual test of first-run warning flow
- [ ] **Integration**: Test `dk --safe-mode run 1` (should run agent without bypass flags)

### Docs to Update

- [x] `SECURITY.md` - Add autonomous mode documentation (Step 1)
- [x] `README.md` - Add security notice section (Step 2)
- [ ] `lib/help.sh` - Add `--safe-mode` to help text (Step 3)

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

---

## Links

- File: `lib/agents.sh:154-187` - Agent bypass flags
- File: `lib/core.sh:1198-1315` - Phase execution with bypass flags
- File: `lib/core.sh:248-343` - Quality command security validation (reference)
- File: `SECURITY.md` - Existing security policy (needs expansion)
- File: `README.md` - Needs security warning
- OWASP: Security misconfiguration
