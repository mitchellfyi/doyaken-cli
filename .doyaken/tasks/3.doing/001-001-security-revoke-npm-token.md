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
| Assigned At | `2026-02-01 17:16` |

---

## Context

Security audit discovered an exposed NPM token in `.env` file. While `.env` is correctly listed in `.gitignore`, the token `npm_nmE4... (redacted)` is exposed in the working directory and could have been committed previously or leaked through other means.

**Impact**: Attacker with this token can publish malicious packages under the account's identity, potentially affecting all users who install this package.

**OWASP Category**: A02:2021 - Cryptographic Failures

---

## Acceptance Criteria

All must be checked before moving to done:

- [ ] NPM token has been revoked via npm dashboard (npmjs.com)
- [ ] New token generated with minimal required scopes (publish only if needed)
- [ ] Verify `.env` is in `.gitignore` (already is, but verify)
- [ ] Check git history for any committed `.env` files (use `git log --all --full-history -- .env`)
- [ ] If found in history, consider git filter-branch or BFG to remove
- [ ] Document secure credential handling in CONTRIBUTING.md or SECURITY.md
- [ ] Consider using npm automation tokens with IP restrictions
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

1. **Step 1**: Revoke token immediately
   - Go to npmjs.com > Access Tokens
   - Revoke token starting with `npm_nmE4...`

2. **Step 2**: Check git history
   - Command: `git log --all --full-history -- .env`
   - If committed, use BFG Repo-Cleaner to remove

3. **Step 3**: Generate new token
   - Use automation token type
   - Enable IP restrictions if possible
   - Set minimal scopes (publish only)

4. **Step 4**: Update CI/CD
   - Verify GitHub secrets are properly configured
   - Use `${{ secrets.NPM_TOKEN }}` in workflows (already done)

5. **Step 5**: Document
   - Add note to README about never committing .env
   - Consider adding .env.example with dummy values

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified exposed NPM token in .env file
- Token needs immediate revocation
- Next: User to revoke token manually via npm dashboard

---

## Notes

- This is a CRITICAL security issue requiring immediate user action
- The token cannot be revoked programmatically - requires npm dashboard access
- After revocation, ensure CI/CD still works with new token

---

## Links

- File: `.env`
- File: `.github/workflows/release.yml` (uses NPM_TOKEN secret)
- npmjs.com access tokens dashboard
