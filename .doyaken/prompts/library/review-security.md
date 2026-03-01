# Security (OWASP Top 10)

## Mindset

- **Assume breach** — minimize blast radius, defense in depth
- **Secure by default** — fail closed, not open. Debug mode off in production, security headers present, CORS properly configured
- **Least privilege** — only grant necessary permissions
- **Never weaken security controls** to fix a build or test failure — understand the root cause instead

## A01: Broken Access Control

- [ ] Authorization on ALL sensitive operations
- [ ] Least privilege enforced
- [ ] CORS properly configured
- [ ] Path traversal prevention
- [ ] IDOR checks
- [ ] Deny by default

## A02: Cryptographic Failures

- [ ] Sensitive data encrypted at rest and in transit
- [ ] TLS for data in transit
- [ ] No hardcoded secrets — ever. Use environment variables or a secrets manager
- [ ] Strong algorithms (no MD5/SHA1)
- [ ] No sensitive data in URLs, logs, or error messages

## A03: Injection

- [ ] Parameterized queries (no string concatenation for commands/queries)
- [ ] Command injection prevention
- [ ] XSS protection (output encoding)
- [ ] Template injection prevention
- [ ] Input validation uses allowlists over denylists

## A04: Insecure Design

- [ ] Threat modeling considered
- [ ] Business logic abuse reviewed
- [ ] Secure defaults

## A05: Security Misconfiguration

- [ ] Security headers present
- [ ] No stack traces to users
- [ ] Debug mode disabled in production
- [ ] No sensitive data exposed in error messages

## A06: Vulnerable Components

- [ ] Dependencies up to date
- [ ] No known CVEs (check before adding new dependencies)
- [ ] Minimal dependency surface
- [ ] License compatibility verified

## A07: Authentication Failures

- [ ] Secure session management
- [ ] Strong password hashing
- [ ] Rate limiting on login
- [ ] Secure password reset flow
- [ ] Credential rotation strategy

## A08: Data Integrity Failures

- [ ] Signed/verified updates
- [ ] CI/CD pipeline secured
- [ ] No unsigned deserialization

## A09: Logging and Monitoring

- [ ] Security events logged (auth failures, permission denials)
- [ ] No sensitive data in logs
- [ ] Audit trail for critical operations
- [ ] Alertable conditions distinguishable (expected vs unexpected failures)

## A10: SSRF

- [ ] URL validation for user input
- [ ] Allowlist for external requests

## Data Privacy

- [ ] PII (personally identifiable information) identified and tagged in data model
- [ ] Data minimization — only collect and store what's necessary
- [ ] Never log PII (emails, names, IPs, tokens) unless explicitly required and documented
- [ ] Anonymize or pseudonymize data in non-production environments
- [ ] Consider data retention — don't store data indefinitely without a reason
- [ ] Respect user consent and deletion requests (right to be forgotten)

## Secrets Management

- [ ] No hardcoded secrets in source code
- [ ] Secrets in environment variables or secrets manager, not in config files committed to version control
- [ ] No secrets passed as CLI arguments (visible in process lists)
- [ ] Credentials can be rotated without code changes
- [ ] No sensitive data in URLs (appears in logs, referrer headers, browser history)

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
