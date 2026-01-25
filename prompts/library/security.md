# Security Review (OWASP Top 10)

## Mindset

- **Assume breach** - What's the blast radius if this is exploited?
- **Defense in depth** - Don't rely on a single security control
- **Secure by default** - Fail closed, not open
- **Least privilege** - Only grant necessary permissions

## A01: Broken Access Control

- [ ] Authorization checks on ALL sensitive operations
- [ ] Principle of least privilege enforced
- [ ] CORS properly configured (not `*` in production)
- [ ] Path traversal prevention (no `../` in file paths)
- [ ] IDOR (Insecure Direct Object Reference) checks
- [ ] Rate limiting on sensitive endpoints
- [ ] Session invalidation on logout/password change

## A02: Cryptographic Failures

- [ ] Sensitive data encrypted at rest
- [ ] TLS for data in transit
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Secrets in environment variables or secret manager
- [ ] Strong algorithms (no MD5, SHA1 for security)
- [ ] Proper key management (rotation, storage)
- [ ] No sensitive data in URLs or logs

## A03: Injection

- [ ] Parameterized queries for SQL (no string concatenation)
- [ ] NoSQL injection prevention
- [ ] Command injection prevention (no shell interpolation)
- [ ] XSS protection (output encoding, CSP)
- [ ] LDAP injection prevention
- [ ] XML/XXE injection prevention
- [ ] Template injection prevention

## A04: Insecure Design

- [ ] Threat modeling considered
- [ ] Business logic abuse scenarios reviewed
- [ ] Multi-tenant isolation verified
- [ ] Secure defaults (opt-in to dangerous features)
- [ ] Feature flags for sensitive operations

## A05: Security Misconfiguration

- [ ] Security headers present (HSTS, CSP, X-Frame-Options)
- [ ] Error handling doesn't leak stack traces
- [ ] Unnecessary features/endpoints disabled
- [ ] Default credentials changed
- [ ] Debug mode disabled in production
- [ ] Directory listing disabled

## A06: Vulnerable Components

- [ ] Dependencies up to date
- [ ] No known CVEs in dependencies
- [ ] Dependency audit clean: `npm audit` / `pip-audit` / etc.
- [ ] Minimal dependencies (reduce attack surface)
- [ ] License compliance checked

## A07: Authentication Failures

- [ ] Secure session management
- [ ] Password hashing with bcrypt/argon2 (not MD5/SHA1)
- [ ] Password policies enforced
- [ ] MFA available for sensitive accounts
- [ ] Rate limiting on login attempts
- [ ] Account lockout after failed attempts
- [ ] Secure password reset flow

## A08: Data Integrity Failures

- [ ] Signed/verified updates
- [ ] CI/CD pipeline secured
- [ ] Integrity checks on critical data
- [ ] No unsigned deserialization of untrusted data

## A09: Logging and Monitoring

- [ ] Security events logged (login, access denied, admin actions)
- [ ] No sensitive data in logs (passwords, tokens, PII)
- [ ] Log injection prevention
- [ ] Audit trail for critical operations
- [ ] Alerting on suspicious activity

## A10: Server-Side Request Forgery (SSRF)

- [ ] URL validation for user-provided URLs
- [ ] Allowlist for external requests
- [ ] No internal network access from user input
- [ ] DNS rebinding prevention

## Finding Format

For each vulnerability found:

```
### Finding: [Title]

**Severity**: Critical / High / Medium / Low
**Category**: [OWASP category, e.g., A03 Injection]
**Location**: `file:line`

**Description**:
[What is wrong]

**Impact**:
[What could happen if exploited]

**Proof of Concept** (if applicable):
[How to reproduce]

**Remediation**:
[Specific steps to fix]
```

## Summary Template

```
### Security Review Summary

Scope:
- [files/components reviewed]

Findings:
- Critical: [count]
- High: [count]
- Medium: [count]
- Low: [count]

Top Issues:
1. [most critical finding]
2. [second most critical]
3. [third most critical]

Recommendations:
- [prioritized list of fixes]
```

## Quick Reference

### Input Validation
```javascript
// Bad
const query = `SELECT * FROM users WHERE id = ${userId}`;

// Good
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);
```

### Output Encoding
```javascript
// Bad
element.innerHTML = userInput;

// Good
element.textContent = userInput;
// Or use a sanitization library
```

### Authentication
```javascript
// Bad
if (password === storedPassword) { ... }

// Good
const match = await bcrypt.compare(password, storedHash);
```

## References

- [OWASP Top 10 (2021)](https://owasp.org/Top10/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
