# Task: Validate Environment Variable Keys from Manifest

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-004-quality-validate-env-keys`                    |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-01 17:10`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 21:18` |

---

## Context

Security review identified that environment variable keys loaded from `manifest.yaml` are not validated before export. A malicious manifest could set dangerous environment variables like `LD_PRELOAD`, `PATH`, or other system-affecting variables.

**Location**: `lib/core.sh:194-205`
**Category**: Security / Input Validation
**Severity**: MEDIUM

---

## Acceptance Criteria

- [ ] Add validation for environment variable names (whitelist pattern)
- [ ] Reject keys with special characters, spaces, or shell metacharacters
- [ ] Log warnings for rejected keys
- [ ] Document allowed env var naming convention

---

## Plan

1. Add regex validation: `[A-Z][A-Z0-9_]*` pattern for valid env keys
2. Add blocklist for dangerous system variables (LD_PRELOAD, PATH, HOME, etc.)
3. Log warning when key is rejected

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review security findings

---

## Notes

Pattern to enforce:
```bash
if [[ "$key" =~ ^[A-Z][A-Z0-9_]*$ ]] && [[ ! "$key" =~ ^(PATH|LD_|HOME|USER|SHELL).*$ ]]; then
  export "$key=$value"
fi
```

---

## Links

- Security review finding: unvalidated env vars from manifest
