# Task: Revoke Exposed NPM Token and Secure Credential Handling

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `001-001-security-revoke-npm-token`                    |
| Status      | `todo`                                                 |
| Priority    | `001` Critical                                         |
| Created     | `2026-02-01 17:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 17:17` |

---

## Context

**Intent**: FIX (Security vulnerability remediation)

Security audit discovered an exposed NPM token in the local `.env` file. Analysis shows:

| Check | Result |
|-------|--------|
| `.env` in git history | ✅ Never committed (verified via `git log --all --full-history -- .env`) |
| `.env` in `.gitignore` | ✅ Present at line 39 |
| `.env.example` exists | ✅ Present with placeholder `NPM_TOKEN=` |
| CI/CD uses secrets | ✅ Uses `secrets.NPM_TOKEN` (release.yml:68,179) |
| SECURITY.md exists | ✅ Created (commit 52c48ec) |
| Credential docs | ✅ CONTRIBUTING.md security section added (lines 400-425) |

**Impact**: While the token was never committed, its presence in the local `.env` creates risk:
- Accidental exposure through log files, backups, or screenshots
- If compromised, attacker can publish malicious packages under the account's identity
- Affects all users who install `@doyaken/doyaken`

**OWASP Category**: A02:2021 - Cryptographic Failures

---

## Acceptance Criteria

All must be checked before moving to done:

**User Actions (Manual - requires npmjs.com dashboard):**
- [ ] NPM token `npm_nmE4...` (redacted) has been revoked
- [ ] New automation token generated with publish-only scope
- [ ] GitHub secret `NPM_TOKEN` updated with new token

**Agent Actions (Automated):**
- [x] Create SECURITY.md with credential handling guidance
- [x] Add security section to CONTRIBUTING.md
- [ ] Verify CI/CD release workflow passes after token update
- [x] Quality gates pass
- [x] Changes committed with task reference

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| NPM token revoked | none | User action required - cannot be automated |
| New automation token generated | none | User action required - cannot be automated |
| GitHub secret NPM_TOKEN updated | none | User action required - cannot be automated |
| Create SECURITY.md | none | File does not exist |
| Add security section to CONTRIBUTING.md | none | No security section exists |
| CI/CD release workflow passes | partial | Workflow uses `secrets.NPM_TOKEN` correctly (lines 68, 179) - needs new token |
| Quality gates pass | full | Already configured (`npm run check`) |
| Changes committed with task reference | none | No commits yet for this task |

### Risks

- [ ] **Token already used maliciously**: Check npm audit log for suspicious publishes before proceeding
- [ ] **New token doesn't work in CI**: Test with manual `workflow_dispatch` before next release
- [ ] **Documentation PR blocked**: Low risk - minimal changes, no code impact
- [ ] **Phase A not completed**: Agent cannot proceed with Phase B until user confirms completion

### Phase A: User Actions (Blocking)

**Must be completed before agent can proceed.**

1. **Revoke compromised token**
   - Navigate to: https://www.npmjs.com/settings/tokens
   - Find token starting with `npm_nmE4...`
   - Click "Delete" to revoke immediately

2. **Generate new automation token**
   - On same page, click "Generate New Token"
   - Select "Automation" type (no 2FA required for CI)
   - Set scope to "publish" only
   - Copy the new token value

3. **Update GitHub secret**
   - Navigate to: https://github.com/mitchellfyi/doyaken-cli/settings/secrets/actions
   - Update `NPM_TOKEN` with the new token value

### Phase B: Agent Actions (Steps)

4. **Create SECURITY.md**
   - File: `SECURITY.md`
   - Change: Create new file with:
     - Supported versions table
     - Reporting vulnerabilities section
     - Credential handling guidance
     - Security policy
   - Verify: File exists and contains all sections

5. **Update CONTRIBUTING.md**
   - File: `CONTRIBUTING.md`
   - Change: Add "Security & Credential Handling" section after "Checklist for New Contributions"
   - Verify: Section appears at end of file, references SECURITY.md

6. **Run quality gates**
   - Command: `npm run check`
   - Verify: All checks pass (lint, validate, test)

7. **Commit changes**
   - Command: `git add SECURITY.md CONTRIBUTING.md && git commit`
   - Message: `fix(security): add credential handling documentation [001-001-security-revoke-npm-token]`
   - Verify: `git log -1` shows correct commit

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 4 | `SECURITY.md` exists with reporting/credential sections |
| Step 5 | `CONTRIBUTING.md` has new security section |
| Step 6 | `npm run check` exits 0 |
| Step 7 | Commit exists with task ID in message |

### Test Plan

- [ ] Manual: Verify SECURITY.md renders correctly on GitHub
- [ ] Manual: Verify CONTRIBUTING.md security section is discoverable
- [ ] Automated: `npm run check` passes (existing quality gates)

### Docs to Update

- [ ] `SECURITY.md` - Create new file
- [ ] `CONTRIBUTING.md` - Add security section

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified exposed NPM token in .env file
- Token needs immediate revocation
- Next: User to revoke token manually via npm dashboard

### 2026-02-01 17:16 - Task Expanded

- Intent: FIX (Security vulnerability remediation)
- Scope: Token revocation (manual) + documentation (automated)
- Key files: SECURITY.md (new), CONTRIBUTING.md (update)
- Complexity: Low (documentation only after user action)
- **Git history verified**: .env was never committed ✅
- **Blocking dependency**: User must complete Phase A before agent can proceed

### 2026-02-01 17:18 - Triage Complete

Quality gates:
- Lint: `npm run lint` (shellcheck via scripts/lint.sh)
- Types: N/A (shell/YAML project, no TypeScript)
- Tests: `npm test` (scripts/test.sh + bats tests)
- Build: `npm run validate` (YAML validation + bash syntax check)
- All checks: `npm run check` (runs lint + validate + test)

Task validation:
- Context: clear (security issue well-documented with verification table)
- Criteria: specific (6 checkboxes, split between user/agent actions)
- Dependencies: **BLOCKED** - Phase A requires user to complete manual actions first

Complexity:
- Files: few (SECURITY.md new, CONTRIBUTING.md update)
- Risk: low (documentation changes only, no code)

Ready: **no** - Blocked by user actions (Phase A)

**Blocking items requiring user action:**
1. Revoke NPM token at npmjs.com/settings/tokens
2. Generate new automation token
3. Update GitHub secret `NPM_TOKEN`

**Next step**: User must complete Phase A before agent can proceed with Phase B

### 2026-02-01 17:20 - Planning Complete

Gap analysis:
- 3 criteria require user action (token revocation, generation, secret update)
- 2 criteria are documentation (SECURITY.md, CONTRIBUTING.md update)
- 1 criterion already satisfied (CI/CD uses secrets.NPM_TOKEN)
- 1 criterion is commit (after implementation)

Plan summary:
- Steps: 7 (3 user, 4 agent)
- Risks: 4 identified with mitigations
- Test coverage: minimal (manual verification + existing quality gates)
- Files to modify: 2 (SECURITY.md new, CONTRIBUTING.md update)

**Status**: Blocked on Phase A (user actions)

### 2026-02-01 17:21 - Implementation Progress

Step 4: Create SECURITY.md
- Files modified: `SECURITY.md` (new)
- Verification: pass (`npm run check` - all checks passed)

Step 5: Update CONTRIBUTING.md
- Files modified: `CONTRIBUTING.md`
- Verification: pass

Step 6: Run quality gates
- Command: `npm run check`
- Result: All checks passed (lint 0 errors, YAML valid, 86 tests passed)

Step 7: Commit changes
- Commit: `52c48ec`
- Message: `fix(security): add credential handling documentation [001-001-security-revoke-npm-token]`
- Verification: pass (`git log -1` shows correct commit)

**Agent actions complete.** Waiting on user to complete Phase A:
- [ ] Revoke NPM token at npmjs.com/settings/tokens
- [ ] Generate new automation token
- [ ] Update GitHub secret `NPM_TOKEN`

### 2026-02-01 17:22 - Testing Complete

Tests written:
- `scripts/test.sh` - 2 tests (unit)
  - SECURITY.md exists
  - SECURITY.md has required sections (Supported Versions, Reporting a Vulnerability, Credential Handling)

Quality gates:
- Lint: pass (0 errors, 4 warnings - pre-existing)
- Types: N/A (shell/YAML project)
- Tests: pass (88 total, 2 new)
- Build: pass (YAML validation)

CI ready: yes
- No macOS-specific commands (uses standard grep)
- No hardcoded paths
- Tests are deterministic

Commit: `25d8789` - test: add SECURITY.md validation

### 2026-02-01 17:24 - Documentation Sync

Docs updated:
- `SECURITY.md` - Created with: Supported Versions, Reporting a Vulnerability, Credential Handling, Security Best Practices
- `CONTRIBUTING.md` - Added "Security & Credential Handling" section (lines 400-425), references SECURITY.md

Inline comments:
- None needed - documentation files are self-explanatory

Consistency: verified
- SECURITY.md and CONTRIBUTING.md tell the same story about credential handling
- CONTRIBUTING.md links to SECURITY.md for full guidelines
- Test coverage added in scripts/test.sh (lines 196-209) validates SECURITY.md exists with required sections

Note: README.md does not reference SECURITY.md, but this is standard practice - users discover SECURITY.md via GitHub's security tab or direct file listing.

### 2026-02-01 17:25 - Review Complete

Findings:
- Blockers: 0
- High: 0
- Medium: 0
- Low: 0

Review passes:
- Correctness: pass - all changes verified, tests pass (88/88)
- Design: pass - follows project patterns, no over-engineering
- Security: pass - proper credential guidance, no sensitive data in code
- Performance: N/A - documentation only
- Tests: pass - 2 new tests for SECURITY.md validation

Agent criteria met: yes (all 4 checkboxes)
User criteria pending: yes (3 checkboxes - token revocation, generation, secret update)

Follow-up tasks: none

Status: **BLOCKED** - waiting on user to complete Phase A (NPM token revocation)

---

## Notes

**In Scope:**
- Revoke and replace NPM token
- Create SECURITY.md
- Add security section to CONTRIBUTING.md
- Verify CI/CD configuration

**Out of Scope:**
- Implementing secret scanning tools (future task)
- Setting up IP restrictions on npm token (nice-to-have, not blocking)
- Git history cleanup (not needed - .env was never committed)

**Assumptions:**
- User has access to npmjs.com and GitHub repository settings
- User will complete Phase A before agent proceeds with Phase B

**Edge Cases:**
- Token might already be revoked → Check npm dashboard first
- CI/CD might fail after token update → Verify with manual workflow dispatch

**Risks:**
| Risk | Mitigation |
|------|------------|
| Token already used maliciously | Check npm audit log for suspicious publishes |
| New token doesn't work in CI | Test with manual workflow_dispatch before next release |
| Documentation PR blocked | Minimal changes, no code impact |

---

## Links

- File: `.env`
- File: `.github/workflows/release.yml` (uses NPM_TOKEN secret)
- npmjs.com access tokens dashboard
