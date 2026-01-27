---
description: OWASP-based security audit of the codebase
---

Run the doyaken skill: audit-security

```bash
doyaken skill audit-security $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# Security Audit

You are performing a comprehensive security audit of the codebase.

## Context

Project: {{DOYAKEN_PROJECT}}
Audit path: {{ARGS.path}}
Create follow-up tasks: {{ARGS.create-tasks}}

## Security Review Framework

{{include:library/review-security.md}}

## Audit Process

### 1. Reconnaissance

First, understand what you're auditing:
- Identify all entry points (APIs, CLI inputs, file uploads)
- Map authentication and authorization flows
- Locate sensitive data handling (passwords, tokens, PII)
- Find external service integrations
- Note dependencies and their versions

### 2. Automated Checks

Run security scanning tools:

```bash
# Dependency vulnerabilities
npm audit                    # JavaScript
pip-audit                    # Python
go list -json -m all | nancy # Go

# Secret scanning
grep -r "API_KEY\|SECRET\|PASSWORD\|TOKEN" --include="*.{js,ts,py,go}" .

# Static analysis
semgrep --config=p/security-audit .  # if available
```

### 3. Manual Review

Go through OWASP Top 10 systematically:

**A01: Broken Access Control**
- [ ] Check all endpoints for auth requirements
- [ ] Verify authorization on sensitive operations
- [ ] Look for IDOR vulnerabilities
- [ ] Check CORS configuration

**A02: Cryptographic Failures**
- [ ] Search for hardcoded secrets
- [ ] Verify TLS usage
- [ ] Check password hashing algorithms
- [ ] Review key management

**A03: Injection**
- [ ] Find all database queries - verify parameterization
- [ ] Check command execution - verify input sanitization
- [ ] Review template rendering for XSS
- [ ] Check XML parsing for XXE

**A04-A10**: [Continue through checklist in security.md]

### 4. Document Findings

For each vulnerability:

```
### Finding: [Title]

**Severity**: Critical / High / Medium / Low
**OWASP Category**: [A01-A10]
**CWE**: [CWE number if applicable]
**Location**: `file:line`

**Description**:
[What is vulnerable]

**Impact**:
[What could an attacker do]

**Proof of Concept**:
[How to reproduce - be specific but responsible]

**Remediation**:
[Exact steps to fix]

**References**:
- [relevant OWASP page]
- [CWE reference]
```

### 5. Create Tasks

{{#if create-tasks == "true"}}
Create high-priority tasks for each finding:

- Critical/High: Priority 001 (Critical)
- Medium: Priority 002 (High)
- Low: Priority 003 (Medium)

Task filename: `[priority]-XXX-security-[slug].md`
{{/if}}

## Output

```
## Security Audit Report

### Executive Summary
- Audit scope: {{ARGS.path}}
- Date: [date]
- Findings: Critical: X, High: Y, Medium: Z, Low: W

### Risk Assessment
[Overall security posture assessment]

### Critical Findings
[Any critical issues requiring immediate action]

### High-Risk Findings
[High severity issues]

### Medium-Risk Findings
[Medium severity issues]

### Low-Risk Findings
[Low severity issues for future improvement]

### Positive Findings
[Security controls that are working well]

### Recommendations

**Immediate Actions (24-48 hours):**
1. [Critical fixes]

**Short-term (1-2 weeks):**
1. [High priority fixes]

**Ongoing:**
1. [Security practices to implement]

### Tasks Created
[List of task files created]

### Appendix

**Dependencies with Vulnerabilities:**
[Output from npm audit / pip-audit]

**Files Reviewed:**
[List of security-sensitive files examined]
```
