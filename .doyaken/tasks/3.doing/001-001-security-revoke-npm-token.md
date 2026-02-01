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
| SECURITY.md exists | ❌ Missing |
| Credential docs | ❌ CONTRIBUTING.md lacks security guidance |

**Impact**: While the token was never committed, its presence in the local `.env` creates risk:
- Accidental exposure through log files, backups, or screenshots
- If compromised, attacker can publish malicious packages under the account's identity
- Affects all users who install `@doyaken/doyaken`

**OWASP Category**: A02:2021 - Cryptographic Failures

---

## Acceptance Criteria

All must be checked before moving to done:

**User Actions (Manual - requires npmjs.com dashboard):**
- [ ] NPM token `npm_nmE4... (redacted)` has been revoked
- [ ] New automation token generated with publish-only scope
- [ ] GitHub secret `NPM_TOKEN` updated with new token

**Agent Actions (Automated):**
- [ ] Create SECURITY.md with credential handling guidance
- [ ] Add security section to CONTRIBUTING.md
- [ ] Verify CI/CD release workflow passes after token update
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

**Phase A: User Actions (Blocking - must be done first)**

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

**Phase B: Agent Actions (After Phase A complete)**

4. **Create SECURITY.md**
   - File: `SECURITY.md`
   - Contents: Credential handling, reporting vulnerabilities, supported versions

5. **Update CONTRIBUTING.md**
   - Add section: "Security & Credential Handling"
   - Reference SECURITY.md
   - Warn about never committing secrets

6. **Verify CI/CD**
   - Confirm release workflow uses `secrets.NPM_TOKEN` (already does)
   - Test that GitHub Actions can publish (requires manual trigger or version bump)

7. **Commit changes**
   - Format: `fix(security): add credential handling documentation [001-001-security-revoke-npm-token]`

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
