---
description: Apply review-security methodology
---

# Security (OWASP Top 10)

## Mindset

- **Assume breach** - What's the blast radius if exploited?
- **Defense in depth** - Don't rely on a single control
- **Secure by default** - Fail closed, not open
- **Least privilege** - Only grant necessary permissions

## A01: Broken Access Control

- [ ] Authorization on ALL sensitive operations
- [ ] Least privilege enforced
- [ ] CORS properly configured
- [ ] Path traversal prevention
- [ ] IDOR checks

## A02: Cryptographic Failures

- [ ] Sensitive data encrypted at rest
- [ ] TLS for data in transit
- [ ] No hardcoded secrets
- [ ] Strong algorithms (no MD5/SHA1)
- [ ] No sensitive data in URLs or logs

## A03: Injection

- [ ] Parameterized queries (no string concatenation)
- [ ] Command injection prevention
- [ ] XSS protection (output encoding)
- [ ] Template injection prevention

## A04: Insecure Design

- [ ] Threat modeling considered
- [ ] Business logic abuse reviewed
- [ ] Secure defaults

## A05: Security Misconfiguration

- [ ] Security headers present
- [ ] No stack traces to users
- [ ] Debug mode disabled in production

## A06: Vulnerable Components

- [ ] Dependencies up to date
- [ ] No known CVEs
- [ ] Minimal dependencies

## A07: Authentication Failures

- [ ] Secure session management
- [ ] Strong password hashing
- [ ] Rate limiting on login
- [ ] Secure password reset flow

## A08: Data Integrity Failures

- [ ] Signed/verified updates
- [ ] CI/CD pipeline secured
- [ ] No unsigned deserialization

## A09: Logging and Monitoring

- [ ] Security events logged
- [ ] No sensitive data in logs
- [ ] Audit trail for critical operations

## A10: SSRF

- [ ] URL validation for user input
- [ ] Allowlist for external requests

## Finding Format

```
### Finding: [Title]

**Severity**: Critical / High / Medium / Low
**Category**: [OWASP category]
**Location**: file:line

**Description**: [What is wrong]
**Impact**: [What could happen]
**Remediation**: [How to fix]
```

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
