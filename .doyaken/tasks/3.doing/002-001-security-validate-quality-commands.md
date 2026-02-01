# Task: Validate and Sanitize Quality Gate Commands from Manifest

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-001-security-validate-quality-commands`           |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-01 17:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 19:30` |

---

## Context

Quality gate commands (`QUALITY_TEST_CMD`, `QUALITY_LINT_CMD`, `QUALITY_FORMAT_CMD`, `QUALITY_BUILD_CMD`) are loaded from the manifest and executed without validation. These could contain malicious commands.

**Vulnerable Code** (`lib/core.sh:188-191`):
```bash
export QUALITY_TEST_CMD=$(yq -e '.quality.test_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
export QUALITY_LINT_CMD=$(yq -e '.quality.lint_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
export QUALITY_FORMAT_CMD=$(yq -e '.quality.format_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
export QUALITY_BUILD_CMD=$(yq -e '.quality.build_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
```

**Impact**: Malicious manifest could execute arbitrary commands during quality gates.

**OWASP Category**: A03:2021 - Injection

---

## Acceptance Criteria

All must be checked before moving to done:

- [ ] Implement command validation/sanitization
- [ ] Block dangerous patterns: `|`, `$()`, backticks, `;`, `&&` chains with external commands
- [ ] Allow only package manager commands: npm, yarn, pnpm, cargo, go, make, etc.
- [ ] Consider using a command allowlist approach
- [ ] Log warning when suspicious command is detected
- [ ] Document security model for quality commands
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

1. **Step 1**: Define allowed command prefixes
   - Files: `lib/core.sh`
   - Allowlist: npm, yarn, pnpm, cargo, go, make, pytest, jest, etc.

2. **Step 2**: Implement validation
   - Files: `lib/core.sh`
   - Add function `validate_quality_command()`
   - Parse command to check for shell metacharacters

3. **Step 3**: Apply validation during manifest load
   - Files: `lib/core.sh:188-191`
   - Validate before export, warn if suspicious

4. **Step 4**: Document security model
   - Files: `README.md` or `SECURITY.md`
   - Explain what commands are allowed and why

---

## Design Considerations

**Option A: Strict allowlist** (more secure)
- Only allow specific commands: npm test, npm run lint, etc.
- Pros: Very secure
- Cons: Less flexible

**Option B: Blocklist dangerous patterns** (more flexible)
- Block shell metacharacters and dangerous commands
- Pros: More flexible for users
- Cons: Harder to cover all attack vectors

**Recommendation**: Start with Option B with warnings, add strict mode flag for high-security environments.

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified command injection via quality commands
- Next: Implement command validation

---

## Links

- File: `lib/core.sh:188-191`
- CWE-78: Improper Neutralization of Special Elements used in an OS Command
