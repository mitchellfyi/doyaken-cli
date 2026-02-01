# Task: Add MCP Server Validation and Security Checks

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-002-security-mcp-server-validation`               |
| Status      | `doing`                                                |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:00`                                     |
| Started     | `2026-02-01 21:51`                                     |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 21:51` |

---

## Context

**Intent**: BUILD

MCP (Model Context Protocol) servers are configured via YAML files in `config/mcp/servers/` and executed with `npx`. The current implementation (`lib/mcp.sh`) has several security gaps that need to be addressed to prevent potential abuse:

### Current State Analysis

**MCP Flow:**
1. `doyaken mcp configure` calls `mcp_configure()` in `lib/mcp.sh:214-266`
2. Reads enabled integrations from `.doyaken/manifest.yaml` via `get_enabled_integrations()` at line 30-36
3. Loads each server definition YAML file from `config/mcp/servers/`
4. Extracts `command`, `args`, `env` via yq without validation (lines 54-60)
5. Expands `${VAR}` patterns in env values via `expand_env_vars()` at lines 191-210
6. Generates JSON/TOML config written to `.doyaken/mcp/`
7. User copies config to agent's config location (e.g., `.mcp.json`)
8. AI agent reads config and **executes the commands**

**Security Gaps Identified:**

| Gap | Location | Severity | OWASP |
|-----|----------|----------|-------|
| No env var validation before config generation | `lib/mcp.sh:40-79` | HIGH | A08:2021 |
| No package allowlist - any npm package can be specified | All server configs | HIGH | A08:2021 |
| Missing token masking in output | `lib/mcp.sh` output functions | MEDIUM | A09:2021 |
| Unofficial packages (slack-mcp-server, figma-developer-mcp) used | `config/mcp/servers/slack.yaml`, `figma.yaml` | MEDIUM | A06:2021 |
| `npx -y` auto-confirms without user approval | All server configs | LOW | A08:2021 |

**Existing Security Patterns to Follow:**
- `lib/core.sh:251-291` - `is_safe_env_var()` validates env vars with blocklist/allowlist
- `lib/core.sh:301-346` - `validate_quality_command()` validates commands with patterns
- `test/unit/security.bats` - Comprehensive security tests follow bats pattern

**Current Unofficial Packages:**
- `slack.yaml`: Uses `slack-mcp-server` (not @modelcontextprotocol/* or @anthropic/*)
- `figma.yaml`: Uses `figma-developer-mcp` (not official)

---

## Acceptance Criteria

All must be checked before moving to done:

- [x] **Env var validation**: `mcp_validate_integration()` function checks required env vars exist before config generation; fails with clear error if missing in strict mode, warns otherwise
- [x] **Package allowlist**: `config/mcp/allowed-packages.yaml` defines official packages with glob patterns (`@modelcontextprotocol/*`, `@anthropic/mcp-server-*`)
- [x] **Package validation**: `mcp_validate_package()` function checks if package is in allowlist; warns for unofficial, blocks in strict mode
- [x] **Strict mode flag**: `DOYAKEN_MCP_STRICT=1` env var or `--mcp-strict` flag blocks unofficial packages and missing env vars
- [x] **Token masking**: `mask_token()` function replaces token values with `***` in logged output (keeps first 4 chars for debugging)
- [x] **Documentation**: `docs/security/mcp-security.md` explains MCP security model and allowlist management
- [x] **Unit tests**: `test/unit/mcp-security.bats` covers all new validation functions
- [x] Tests written and passing (`bats test/unit/mcp-security.bats`)
- [x] Quality gates pass (`shellcheck lib/mcp.sh`)
- [ ] Changes committed with task reference

---

## Notes

**In Scope:**
- Add validation functions to `lib/mcp.sh`
- Create `config/mcp/allowed-packages.yaml` allowlist
- Add `--mcp-strict` flag to `mcp configure` subcommand
- Add `mask_token()` utility function
- Write security documentation
- Write bats unit tests

**Out of Scope:**
- Changing how MCP servers are actually executed (that happens in the AI agent, not doyaken)
- Sandboxing npm package execution
- Runtime monitoring of MCP servers
- Modifying existing server YAML files to use official packages (separate task)

**Assumptions:**
- Official packages use `@modelcontextprotocol/*` or `@anthropic/mcp-server-*` naming
- yq and jq are available (already checked in `mcp_doctor`)
- Env var patterns follow `${VAR_NAME}` or `${VAR_NAME:-default}` format

**Edge Cases:**
1. **Missing env var with default**: `${VAR:-default}` should not warn/fail
2. **Partially matching package**: `my-modelcontextprotocol-server` should NOT match allowlist
3. **Empty allowlist**: If allowlist file missing, treat all as unofficial (warn only, don't block)
4. **Multiple env vars**: Validate all, report all failures together

**Risks:**
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing integrations | Medium | High | Default to warn-only mode; strict is opt-in |
| Allowlist maintenance burden | Low | Low | Use glob patterns; document how to add packages |
| False positives on package names | Low | Medium | Exact match for non-glob entries |

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| Env var validation function | none | `mcp_doctor()` checks env vars but no dedicated `mcp_validate_integration()` function; no strict mode support |
| Package allowlist file | none | No `config/mcp/allowed-packages.yaml` exists |
| Package validation function | none | No `mcp_validate_package()` function exists |
| Strict mode flag | none | No `DOYAKEN_MCP_STRICT` support in `mcp_configure()` |
| Token masking | none | No `mask_token()` function; tokens logged in plain text |
| Documentation | none | No `docs/security/mcp-security.md` exists |
| Unit tests | none | No `test/unit/mcp-security.bats` exists |

### Risks

- [ ] **Breaking existing integrations**: Mitigate with warn-only default mode; strict is opt-in via env var
- [ ] **Allowlist maintenance burden**: Mitigate with glob patterns (`@modelcontextprotocol/*`, `@anthropic/mcp-server-*`)
- [ ] **False positives on package names**: Mitigate with exact match for non-glob entries; glob only for scoped packages
- [ ] **mcp_doctor refactor scope creep**: Mitigate by reusing new functions rather than rewriting existing logic

### Steps

#### Step 1: Add token masking utility
- **File**: `lib/mcp.sh`
- **Change**: Add `mask_token()` function after line 10 (after MCP_SERVERS_DIR variable)
  ```bash
  # Mask sensitive tokens for logging
  # Keeps first 4 chars for identification, replaces rest with ***
  # Usage: mask_token "ghp_abc123..."
  mask_token() {
    local token="$1"
    local min_visible=4
    if [ ${#token} -le $min_visible ]; then
      echo "***"
    else
      echo "${token:0:$min_visible}***"
    fi
  }
  ```
- **Verify**: `source lib/mcp.sh && mask_token "ghp_abc123xyz789"` returns `ghp_***`

#### Step 2: Add package allowlist file
- **File**: `config/mcp/allowed-packages.yaml`
- **Change**: Create new file with official package patterns
  ```yaml
  # MCP Package Allowlist
  # Packages matching these patterns are considered "official" and trusted
  # Non-matching packages trigger a warning (or block in strict mode)

  patterns:
    # Official Model Context Protocol packages
    - "@modelcontextprotocol/*"
    # Official Anthropic MCP packages
    - "@anthropic/mcp-server-*"

  # Exact match packages (community packages explicitly trusted)
  # Add packages here after security review
  trusted:
    # - "some-community-package"
  ```
- **Verify**: `yq '.patterns[0]' config/mcp/allowed-packages.yaml` returns `@modelcontextprotocol/*`

#### Step 3: Add package validation function
- **File**: `lib/mcp.sh`
- **Change**: Add `mcp_validate_package()` after `expand_env_vars()` (after line 210)
  ```bash
  # Validate if an MCP package is in the allowlist
  # Returns:
  #   0 = official (matches pattern or trusted list)
  #   1 = unofficial (not in allowlist) - warn only
  #
  # Usage: mcp_validate_package "@modelcontextprotocol/server-github"
  mcp_validate_package() {
    local package="$1"
    local allowlist_file="${DOYAKEN_HOME}/config/mcp/allowed-packages.yaml"

    # If allowlist file missing, treat all as unofficial (warn only)
    [ -f "$allowlist_file" ] || return 1

    # Check glob patterns (scoped packages)
    local pattern
    while IFS= read -r pattern; do
      [ -z "$pattern" ] && continue
      # Convert glob to regex: @foo/* -> ^@foo/
      local regex="${pattern%\*}"
      regex="^${regex//\//\\/}"
      if [[ "$package" =~ $regex ]]; then
        return 0
      fi
    done < <(yq -r '.patterns[]?' "$allowlist_file" 2>/dev/null)

    # Check exact match in trusted list
    local trusted
    while IFS= read -r trusted; do
      [ -z "$trusted" ] && continue
      [ "$package" = "$trusted" ] && return 0
    done < <(yq -r '.trusted[]?' "$allowlist_file" 2>/dev/null)

    return 1
  }
  ```
- **Verify**: `mcp_validate_package "@modelcontextprotocol/server-github"` returns 0; `mcp_validate_package "slack-mcp-server"` returns 1

#### Step 4: Add env var validation function
- **File**: `lib/mcp.sh`
- **Change**: Add `mcp_validate_env_vars()` after `mcp_validate_package()`
  ```bash
  # Validate required env vars for an MCP integration
  # Returns:
  #   0 = all required env vars are set
  #   1 = one or more env vars missing
  #
  # Sets MCP_MISSING_VARS with list of missing vars (for error reporting)
  #
  # Usage: mcp_validate_env_vars "github"
  mcp_validate_env_vars() {
    local integration="$1"
    local server_file="$MCP_SERVERS_DIR/${integration}.yaml"

    MCP_MISSING_VARS=""
    [ -f "$server_file" ] || return 1

    local missing=()
    while IFS= read -r env_line; do
      [ -z "$env_line" ] && continue
      local value="${env_line#*: }"

      # Check if it's a variable reference without default
      if [[ "$value" =~ ^\$\{([A-Z_][A-Z0-9_]*)\}$ ]]; then
        local var_name="${BASH_REMATCH[1]}"
        if [ -z "${!var_name:-}" ]; then
          missing+=("$var_name")
        fi
      fi
      # ${VAR:-default} syntax has a default, so skip those
    done < <(yq -r '.env | to_entries | .[] | "\(.key): \(.value)"' "$server_file" 2>/dev/null || true)

    if [ ${#missing[@]} -gt 0 ]; then
      MCP_MISSING_VARS="${missing[*]}"
      return 1
    fi
    return 0
  }
  ```
- **Verify**: With `GITHUB_TOKEN` unset, `mcp_validate_env_vars "github"` returns 1 and `$MCP_MISSING_VARS` contains "GITHUB_TOKEN"

#### Step 5: Add integration validation wrapper
- **File**: `lib/mcp.sh`
- **Change**: Add `mcp_validate_integration()` that combines package and env var validation with strict mode support
  ```bash
  # Validate an MCP integration (package + env vars)
  # Returns:
  #   0 = valid (or non-strict mode with warnings)
  #   1 = invalid (strict mode blocks unofficial or missing vars)
  #
  # Usage: mcp_validate_integration "github" [strict]
  mcp_validate_integration() {
    local integration="$1"
    local strict="${2:-}"
    local server_file="$MCP_SERVERS_DIR/${integration}.yaml"

    [ -f "$server_file" ] || return 1

    local package
    package=$(yq -r '.args[] | select(test("^@|^[a-z]"))' "$server_file" 2>/dev/null | head -1)

    local has_issues=false

    # Validate package
    if [ -n "$package" ]; then
      if ! mcp_validate_package "$package"; then
        if [ "$strict" = "strict" ]; then
          echo "[BLOCK] $integration: Unofficial package '$package' blocked in strict mode" >&2
          return 1
        else
          echo "[WARN] $integration: Unofficial package '$(mask_token "$package")'" >&2
          has_issues=true
        fi
      fi
    fi

    # Validate env vars
    if ! mcp_validate_env_vars "$integration"; then
      if [ "$strict" = "strict" ]; then
        echo "[BLOCK] $integration: Missing required env vars: $MCP_MISSING_VARS" >&2
        return 1
      else
        echo "[WARN] $integration: Missing env vars: $MCP_MISSING_VARS" >&2
        has_issues=true
      fi
    fi

    return 0
  }
  ```
- **Verify**: `DOYAKEN_MCP_STRICT=1` + unofficial package returns 1; without strict, returns 0 with warning

#### Step 6: Integrate validation into config generation
- **File**: `lib/mcp.sh`
- **Change**: Add validation call at the start of each generate function's loop, after line 49 in `generate_claude_mcp_config()`, similar for codex/gemini
  - Insert after `[ -f "$server_file" ] || continue`:
  ```bash
  # Validate integration (skip if strict mode blocks it)
  local strict_mode=""
  [ "${DOYAKEN_MCP_STRICT:-}" = "1" ] && strict_mode="strict"
  if ! mcp_validate_integration "$integration" "$strict_mode"; then
    continue
  fi
  ```
- **Verify**: With `DOYAKEN_MCP_STRICT=1`, slack integration is skipped from output

#### Step 7: Update mcp_doctor to use new validation
- **File**: `lib/mcp.sh`
- **Change**: In `mcp_doctor()` (starting line 384), replace the manual env var checking with calls to new functions:
  - After `[ -f "$server_file" ] || continue`, add package validation:
  ```bash
  # Check package allowlist
  local package
  package=$(yq -r '.args[] | select(test("^@|^[a-z]"))' "$server_file" 2>/dev/null | head -1)
  if [ -n "$package" ] && ! mcp_validate_package "$package"; then
    echo "  [!!] $integration: Unofficial package '$package'"
    has_issues=true
  fi
  ```
- **Verify**: `doyaken mcp doctor` shows "Unofficial package" warning for slack/figma

#### Step 8: Add unit tests
- **File**: `test/unit/mcp-security.bats` (new file)
- **Change**: Create test file following pattern from `test/unit/security.bats`
  - Tests for `mask_token()`: empty, short, normal tokens
  - Tests for `mcp_validate_package()`: official patterns, unofficial, missing allowlist
  - Tests for `mcp_validate_env_vars()`: all set, missing vars, vars with defaults
  - Tests for `mcp_validate_integration()`: strict mode blocking, warn mode
- **Verify**: `bats test/unit/mcp-security.bats` all tests pass

#### Step 9: Add documentation
- **File**: `docs/security/mcp-security.md` (new file, new directory)
- **Change**: Create documentation covering:
  - MCP security model overview
  - Package allowlist management
  - Strict mode usage
  - How to add trusted community packages
  - Environment variable requirements
- **Verify**: File exists with all sections

#### Step 10: Run quality gates
- **Verify**: `shellcheck lib/mcp.sh` passes
- **Verify**: `bats test/unit/mcp-security.bats` passes

---

## Checkpoints

| After Step | Verify |
|------------|--------|
| Step 1 | `source lib/mcp.sh && mask_token "ghp_abc123xyz"` returns `ghp_***` |
| Step 3 | `mcp_validate_package "@modelcontextprotocol/server-github"` returns 0 |
| Step 3 | `mcp_validate_package "slack-mcp-server"` returns 1 |
| Step 4 | `mcp_validate_env_vars "github"` returns 1 if GITHUB_TOKEN unset |
| Step 5 | `mcp_validate_integration "slack"` warns about unofficial package |
| Step 6 | `DOYAKEN_MCP_STRICT=1 doyaken mcp configure` excludes slack from output |
| Step 7 | `doyaken mcp doctor` shows unofficial package warning for slack |
| Step 8 | `bats test/unit/mcp-security.bats` all tests pass |
| Step 10 | `shellcheck lib/mcp.sh` returns 0 |

---

## Test Plan

### Unit Tests (`test/unit/mcp-security.bats`)

- [ ] `mask_token`: returns `***` for empty string
- [ ] `mask_token`: returns `***` for string <= 4 chars
- [ ] `mask_token`: returns first 4 chars + `***` for longer strings
- [ ] `mcp_validate_package`: returns 0 for `@modelcontextprotocol/server-github`
- [ ] `mcp_validate_package`: returns 0 for `@anthropic/mcp-server-linear`
- [ ] `mcp_validate_package`: returns 1 for `slack-mcp-server`
- [ ] `mcp_validate_package`: returns 1 for `figma-developer-mcp`
- [ ] `mcp_validate_package`: returns 1 if allowlist file missing (graceful degradation)
- [ ] `mcp_validate_package`: rejects partial match like `my-modelcontextprotocol-server`
- [ ] `mcp_validate_env_vars`: returns 0 when all vars set
- [ ] `mcp_validate_env_vars`: returns 1 when required var missing
- [ ] `mcp_validate_env_vars`: returns 0 for vars with defaults `${VAR:-default}`
- [ ] `mcp_validate_integration`: returns 0 in non-strict mode (warns only)
- [ ] `mcp_validate_integration`: returns 1 in strict mode for unofficial package
- [ ] `mcp_validate_integration`: returns 1 in strict mode for missing env vars

### Integration Tests (manual verification)

- [ ] `doyaken mcp doctor` shows unofficial package warnings
- [ ] `doyaken mcp configure` generates valid JSON with warnings
- [ ] `DOYAKEN_MCP_STRICT=1 doyaken mcp configure` excludes unofficial packages

---

## Docs to Update

- [ ] `docs/security/mcp-security.md` - Create new file documenting MCP security model

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified MCP server validation gaps
- Next: Implement validation and allowlist

### 2026-02-01 21:51 - Task Expanded

- Intent: BUILD
- Scope: Add validation functions, allowlist, strict mode, and tests to MCP subsystem
- Key files: `lib/mcp.sh`, `config/mcp/allowed-packages.yaml`, `test/unit/mcp-security.bats`, `docs/security/mcp-security.md`
- Complexity: Medium (9 steps, follows existing patterns in codebase)
- Dependencies: None (task 003-001 completed secure file permissions, patterns established)

### 2026-02-01 21:54 - Triage Complete

Quality gates:
- Lint: `npm run lint` / `bash scripts/lint.sh` (shellcheck)
- Types: N/A (bash project)
- Tests: `npm run test:unit` / `bats test/unit/*.bats`
- Build: N/A (bash scripts, no build step)

Task validation:
- Context: clear - detailed analysis of security gaps with OWASP references, specific line numbers in `lib/mcp.sh`
- Criteria: specific - 10 testable acceptance criteria with function names and file paths
- Dependencies: none - task 003-001 completed, security patterns established in `lib/core.sh`

Complexity:
- Files: some (4 new/modified: `lib/mcp.sh`, `config/mcp/allowed-packages.yaml`, `test/unit/mcp-security.bats`, `docs/security/mcp-security.md`)
- Risk: low - follows established patterns from `lib/core.sh:251-346`, default warn-only mode preserves existing behavior

Existing patterns to follow:
- `is_safe_env_var()` at `lib/core.sh:251-291` - blocklist/allowlist pattern
- `validate_quality_command()` at `lib/core.sh:301-346` - tiered return codes (0=safe, 1=warn, 2=block)
- `test/unit/security.bats` - comprehensive test structure

Ready: yes

### 2026-02-01 22:10 - Planning Complete

**Gap Analysis**: All 7 acceptance criteria have status "none" - nothing exists yet.

**Codebase Analysis**:
- Current MCP servers: 6 total (4 official, 2 unofficial: slack, figma)
- `lib/mcp.sh`: 425 lines, no validation currently
- `mcp_doctor()` already checks env vars (lines 391-405) but no package validation
- Existing patterns in `lib/core.sh:251-346` provide template for tiered validation

**Plan Summary**:
- Steps: 10
- New files: 3 (`config/mcp/allowed-packages.yaml`, `test/unit/mcp-security.bats`, `docs/security/mcp-security.md`)
- Modified files: 1 (`lib/mcp.sh` - add 4 functions + integration into 3 generators)
- Test coverage: 15+ unit tests planned
- Risks: 3 identified, all mitigated by warn-only default mode

**Key Design Decisions**:
1. Glob patterns for scoped packages (`@modelcontextprotocol/*`) - efficient, maintainable
2. Tiered return codes (0=official, 1=unofficial) - matches existing patterns
3. `MCP_MISSING_VARS` global for error reporting - simple, effective
4. Strict mode via env var (`DOYAKEN_MCP_STRICT=1`) - opt-in, non-breaking

Ready for implementation.

### 2026-02-01 21:57 - Implementation Progress

Step 1: Add mask_token() utility
- Files modified: `lib/mcp.sh`
- Verification: shellcheck pass
- Function added after MCP_SERVERS_DIR variable

Step 2: Create package allowlist
- Files created: `config/mcp/allowed-packages.yaml`
- Verification: yq can parse patterns

Step 3: Add mcp_validate_package()
- Files modified: `lib/mcp.sh`
- Verification: shellcheck pass

Step 4: Add mcp_validate_env_vars()
- Files modified: `lib/mcp.sh`
- Verification: shellcheck pass

Step 5: Add mcp_validate_integration()
- Files modified: `lib/mcp.sh`
- Verification: shellcheck pass

Step 6: Integrate validation into config generation
- Files modified: `lib/mcp.sh`
- Added validation calls to generate_claude_mcp_config, generate_codex_mcp_config, generate_gemini_mcp_config
- Verification: shellcheck pass

Step 7: Update mcp_doctor
- Files modified: `lib/mcp.sh`
- Replaced manual env var checking with mcp_validate_env_vars()
- Added package allowlist checking
- Verification: shellcheck pass

Step 8: Add unit tests
- Files created: `test/unit/mcp-security.bats`
- 33 new tests covering all validation functions
- Verification: bats tests pass (207 total tests)

Step 9: Add documentation
- Files created: `docs/security/mcp-security.md`
- Covers security model, allowlist management, strict mode

Step 10: Quality gates
- Verification: shellcheck lib/mcp.sh - only pre-existing warnings (SC2034)
- Verification: npm run test:unit - all 207 tests pass
- Verification: npm run lint - 0 errors, 5 pre-existing warnings

---

## Links

- File: `lib/mcp.sh` (main implementation)
- File: `config/mcp/servers/*.yaml` (server definitions)
- File: `lib/core.sh:251-346` (security validation patterns to follow)
- File: `test/unit/security.bats` (test patterns to follow)
- CWE-829: Inclusion of Functionality from Untrusted Control Sphere
- OWASP A08:2021: Software and Data Integrity Failures
