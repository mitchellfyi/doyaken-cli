# Task: Add Environment Variable Whitelist for Manifest Loading

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `001-002-security-validate-manifest-env`               |
| Status      | `todo`                                                 |
| Priority    | `001` Critical                                         |
| Created     | `2026-02-01 17:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

The `load_manifest_config()` function in `lib/core.sh:193-205` exports arbitrary environment variables from the manifest file without validation. An attacker could set dangerous variables like `PATH`, `LD_PRELOAD`, `PYTHONPATH`, etc.

**Vulnerable Code** (`lib/core.sh:193-205`):
```bash
env_keys=$(yq -e '.env | keys | .[]' "$MANIFEST_FILE" 2>/dev/null || echo "")
if [ -n "$env_keys" ]; then
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    local value
    value=$(yq -e ".env.${key}" "$MANIFEST_FILE" 2>/dev/null || echo "")
    if [ -n "$value" ]; then
      export "$key=$value"  # DANGEROUS: exports arbitrary vars
    fi
  done <<< "$env_keys"
fi
```

**Impact**: Supply chain attack or compromised project manifest could execute arbitrary code by setting `LD_PRELOAD` or modifying `PATH`.

**OWASP Category**: A03:2021 - Injection

---

## Acceptance Criteria

All must be checked before moving to done:

- [ ] Implement allowlist of safe environment variable names
- [ ] Block dangerous variables: PATH, LD_*, DYLD_*, PYTHONPATH, NODE_PATH, HOME, USER, SHELL, etc.
- [ ] Log warning when blocked variable is attempted
- [ ] Add manifest validation function
- [ ] Document allowed env vars in README or manifest schema
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

1. **Step 1**: Create blocked variable list
   - Files: `lib/core.sh`
   - Add array of blocked prefixes/names

2. **Step 2**: Implement validation
   - Files: `lib/core.sh`
   - Add function `is_safe_env_var()` to check against blocklist
   - Log warning for blocked attempts

3. **Step 3**: Update load_manifest_config
   - Files: `lib/core.sh:193-205`
   - Call validation before export

4. **Step 4**: Add tests
   - Files: `test/security_test.bats` or similar
   - Test that dangerous vars are blocked
   - Test that safe vars are exported

---

## Implementation Notes

Blocked variable patterns should include:
- `PATH`, `LD_*`, `DYLD_*` (library injection)
- `PYTHONPATH`, `NODE_PATH`, `RUBYLIB` (code injection)
- `HOME`, `USER`, `SHELL`, `TERM` (system vars)
- `IFS`, `PS1`, `PROMPT_COMMAND` (shell injection)
- `http_proxy`, `https_proxy` (network interception)
- `SSH_*`, `GPG_*` (credential access)

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified arbitrary env var export vulnerability
- Next: Implement allowlist validation

---

## Links

- File: `lib/core.sh:193-205`
- CWE-78: Improper Neutralization of Special Elements used in an OS Command
