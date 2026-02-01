# Task: Optimize Manifest Loading (Reduce yq Calls)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-003-perf-optimize-manifest-loading`               |
| Status      | `doing`                                                |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:10`                                     |
| Started     | `2026-02-01 22:13`                                     |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 22:13` |

---

## Context

**Intent**: IMPROVE

Performance analysis identified that `load_manifest()` in `lib/core.sh:355-463` makes excessive yq calls on the same manifest file. Each yq invocation spawns a process and parses the entire YAML, causing 50-200ms per call.

**Current Call Count Analysis:**
- 7 fixed calls for agent/quality settings (lines 367-390)
- 1 call for env keys list (line 432)
- N calls for env values in loop (line 442) - **N+1 pattern**
- 16 calls for skill hooks (8 phases × 2 hook types, line 459)
- **Total: 24 + N calls per manifest load** (worse than originally estimated)

**Performance Impact:**
- At 50-200ms per yq call, total overhead is 1.2-4.8 seconds per agent startup
- This delay occurs on every `doyaken run` invocation
- The env var loop (N+1 pattern) scales poorly with number of env vars

**Location**: `lib/core.sh:355-463`
**Category**: Performance
**Severity**: HIGH (impacts every agent run)

---

## Acceptance Criteria

- [ ] Reduce yq calls from 24+ to 1-3 per manifest load
- [ ] Eliminate N+1 pattern for environment variable loading
- [ ] Eliminate N pattern for skill hooks loading (16 calls → 1)
- [ ] Maintain backward compatibility with existing manifest format
- [ ] All existing tests pass (test/unit/core.bats, test/unit/config.bats)
- [ ] Security validation for env vars preserved (is_safe_env_var still called)
- [ ] Security validation for quality commands preserved (validate_quality_command still called)
- [ ] Measure and document performance improvement (before/after benchmark)

---

## Notes

**In Scope:**
- Optimize `load_manifest()` function in lib/core.sh
- Batch yq calls to extract multiple values at once
- Extract env vars as JSON object in single call
- Extract hooks as JSON in single call

**Out of Scope:**
- Optimizing yq calls in lib/config.sh (uses `_yq_get()` helper, called elsewhere)
- Optimizing yq calls in lib/mcp.sh (different concern, MCP server parsing)
- Optimizing yq calls in lib/registry.sh (project registry, separate feature)
- Changing manifest.yaml schema

**Assumptions:**
- yq v4 is available (uses `-o=json` output format)
- jq is available for JSON parsing (or bash string parsing)
- Manifest files are small (<100KB) so reading entire file is acceptable

**Edge Cases:**
- Missing manifest file (already handled, returns early)
- yq not installed (already handled, returns early)
- Empty env section (must not break)
- Empty hooks section (must not break)
- Malformed YAML (yq error handling preserved)

**Risks:**
- **Risk**: JSON parsing errors if manifest contains special characters
  - **Mitigation**: Use yq's native JSON output which handles escaping
- **Risk**: Performance regression if JSON parsing is slow
  - **Mitigation**: Benchmark before committing, bash string ops are fast
- **Risk**: Breaking existing env var security validation
  - **Mitigation**: Keep is_safe_env_var() calls, just change how we iterate

**Implementation Approach:**
```bash
# Strategy 1: Single yq call to JSON, parse with bash/jq
manifest_json=$(yq -o=json '.' "$MANIFEST_FILE" 2>/dev/null)
manifest_agent=$(echo "$manifest_json" | jq -r '.agent.name // ""')
# etc...

# Strategy 2: Single yq call with multi-value extraction
eval "$(yq '
  "MANIFEST_AGENT=\"" + (.agent.name // "") + "\"",
  "MANIFEST_MODEL=\"" + (.agent.model // "") + "\"",
  ...
' "$MANIFEST_FILE")"

# Strategy 3: yq with -o=shell for safe variable assignment
```

Preferred: Strategy 1 (JSON cache) - cleaner, safer, better error handling.

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| Reduce yq calls from 24+ to 1-3 | none | Need to batch all yq calls into 1-2 calls |
| Eliminate N+1 pattern for env vars | none | Need to extract all env vars in single call |
| Eliminate N pattern for hooks (16→1) | none | Need to extract all hooks in single call |
| Maintain backward compatibility | full | No schema changes, just internal optimization |
| All existing tests pass | full | Tests exist in test/unit/core.bats, test/unit/security.bats |
| Security validation for env vars | full | `is_safe_env_var()` exists at core.sh:251-291, must still be called |
| Security validation for quality cmds | full | `validate_quality_command()` exists at core.sh:301-345, must still be called |
| Performance benchmark | none | Need to add before/after timing measurement |

### Risks

- [ ] **JSON parsing with special chars**: Use yq's `-o=json` which handles escaping; test with manifest containing quotes, backslashes
- [ ] **jq not available**: Check for jq availability early, fall back to current behavior if missing
- [ ] **Empty sections crash**: Test with manifests missing `env:`, `skills.hooks:`, or `quality:` sections
- [ ] **Security validation bypass**: Keep `is_safe_env_var()` in the iteration loop, not skipped
- [ ] **Hook value whitespace**: Current code uses `tr '\n' ' '` - preserve this behavior

### Steps

1. **Benchmark current performance**
   - File: N/A (command line)
   - Change: Run `time doyaken run --help` multiple times to establish baseline
   - Verify: Record average time (expect 1-5 seconds)

2. **Add jq availability check**
   - File: `lib/core.sh:360-363`
   - Change: Add `command -v jq` check alongside yq check; set `USE_JSON_CACHE=1` if both available
   - Verify: Function gracefully falls back if jq missing

3. **Create `_load_manifest_json()` helper**
   - File: `lib/core.sh` (insert before `load_manifest()` at line ~354)
   - Change: Add function that runs single `yq -o=json '.' "$MANIFEST_FILE"` and caches result in `MANIFEST_JSON` variable
   - Verify: Echo `$MANIFEST_JSON | jq .` shows valid JSON

4. **Create `_jq_get()` helper**
   - File: `lib/core.sh` (insert after `_load_manifest_json()`)
   - Change: Add `_jq_get() { echo "$MANIFEST_JSON" | jq -r "$1 // \"\""; }` for consistent null handling
   - Verify: `_jq_get '.agent.name'` returns expected value

5. **Replace agent settings yq calls with jq**
   - File: `lib/core.sh:367-368`
   - Change: Replace `yq -e '.agent.name // ""'` → `_jq_get '.agent.name'`; same for `.agent.model`
   - Verify: `echo $DOYAKEN_AGENT $DOYAKEN_MODEL` still shows correct values

6. **Replace max_retries yq call with jq**
   - File: `lib/core.sh:380`
   - Change: Replace `yq -e '.agent.max_retries // ""'` → `_jq_get '.agent.max_retries'`
   - Verify: `echo $AGENT_MAX_RETRIES` still correct

7. **Replace quality command yq calls with jq**
   - File: `lib/core.sh:387-390`
   - Change: Replace 4x `yq -e '.quality.X // ""'` → `_jq_get '.quality.X'`
   - Verify: Security validation still runs via `validate_quality_command()`

8. **Replace env var N+1 loop with batch extraction**
   - File: `lib/core.sh:431-447`
   - Change: Replace yq key enumeration + value loop with:
     ```bash
     local env_json
     env_json=$(_jq_get '.env // {}')
     while IFS='=' read -r key value; do
       [ -z "$key" ] && continue
       if ! is_safe_env_var "$key"; then
         log_warn "Blocked unsafe env var: $key"
         continue
       fi
       export "$key=$value"
     done < <(echo "$env_json" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
     ```
   - Verify: Env vars exported correctly; security validation preserved

9. **Replace hooks 16-call loop with batch extraction**
   - File: `lib/core.sh:449-462`
   - Change: Extract all hooks as JSON object, iterate phases in bash:
     ```bash
     local hooks_json
     hooks_json=$(_jq_get '.skills.hooks // {}')
     local phases="expand triage plan implement test docs review verify"
     for phase in $phases; do
       for hook_type in before after; do
         local hook_key="${hook_type}-${phase}"
         local var_name="HOOKS_$(echo "$hook_type" | tr '[:lower:]' '[:upper:]')_$(echo "$phase" | tr '[:lower:]' '[:upper:]')"
         local hook_value
         hook_value=$(echo "$hooks_json" | jq -r ".\"$hook_key\" // [] | .[]" | tr '\n' ' ')
         export "$var_name=$hook_value"
       done
     done
     ```
   - Verify: All 16 hook variables set correctly

10. **Add fallback for missing jq**
    - File: `lib/core.sh:360-363`
    - Change: If jq not available, keep existing yq-based implementation (performance hit acceptable for rare case)
    - Verify: Remove jq temporarily, verify function still works

11. **Run all tests**
    - File: N/A
    - Change: `./scripts/test.sh`
    - Verify: All tests pass, especially test/unit/core.bats and test/unit/security.bats

12. **Benchmark after optimization**
    - File: N/A
    - Change: Run `time doyaken run --help` multiple times
    - Verify: Measure improvement (target: >50% reduction)

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 4 | `_jq_get '.agent.name'` returns correct value from test manifest |
| Step 7 | Quality commands still validated; run security.bats tests |
| Step 8 | Env vars with special chars (quotes, spaces) handled correctly |
| Step 9 | All 16 hook variables populated; test with sample manifest |
| Step 11 | Full test suite passes: `./scripts/test.sh` |
| Step 12 | Performance improvement documented (before/after timing) |

### Test Plan

- [x] Unit: Existing `test/unit/core.bats` - manifest tests (lines 127-139)
- [x] Unit: Existing `test/unit/security.bats` - `is_safe_env_var()` and `validate_quality_command()` tests
- [ ] Manual: Create manifest with env vars containing special chars (quotes, backslashes, spaces)
- [ ] Manual: Create manifest with empty `env:` section, verify no crash
- [ ] Manual: Create manifest with empty `skills.hooks:` section, verify no crash
- [ ] Manual: Benchmark before/after with `time` command

### Docs to Update

- [ ] None - internal optimization, no API or config changes

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review performance findings

### 2026-02-01 22:13 - Task Expanded

- Intent: IMPROVE
- Scope: Optimize load_manifest() yq calls from 24+N to 1-3
- Key files: lib/core.sh (lines 355-463)
- Complexity: Medium
- Analysis: Actual call count is 24+N (worse than original estimate of 8-12)
- Approach: JSON caching with jq/bash parsing

### 2026-02-01 22:15 - Triage Complete

Quality gates:
- Lint: `npm run lint` (bash scripts/lint.sh)
- Types: N/A (bash project)
- Tests: `npm test` (scripts/test.sh + test/run-bats.sh)
- Build: N/A (no build step for bash)

Task validation:
- Context: clear - specific function, line numbers, call count analysis provided
- Criteria: specific - 8 measurable acceptance criteria with clear targets
- Dependencies: none - task has no blockers

Complexity:
- Files: few (1 primary: lib/core.sh:355-463)
- Risk: medium (performance optimization, security validation must be preserved)

Environment verified:
- yq v4.50.1 installed (supports -o=json)
- jq 1.8.1 installed (for JSON parsing)
- Test files exist: test/unit/core.bats, test/unit/config.bats

Ready: yes

### 2026-02-01 22:16 - Planning Complete

- Steps: 12
- Risks: 5 identified with mitigations
- Test coverage: moderate (existing unit tests + manual edge case tests)
- Strategy: JSON caching with jq parsing, fallback to current yq if jq unavailable
- Key insight: Security validation functions unchanged, only iteration method changes
- yq calls reduced: 24+N → 1 (single `yq -o=json '.'` call)
- jq calls added: ~20 (but jq is much faster than yq - no YAML parsing overhead)

---

## Links

- Performance review finding: yq overhead
- Related: lib/config.sh uses _yq_get() helper (different optimization target)
- Related: test/unit/config.bats (existing tests to preserve)
