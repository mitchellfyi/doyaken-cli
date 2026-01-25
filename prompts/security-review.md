# Security Review (OWASP-Focused Audit)

You are performing a security-focused code review.

## Security Methodology

{{include:modules/security.md}}

## Findings Format

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

**References**:
- [relevant OWASP cheat sheet or documentation]
```

## Output Summary

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

Positive Observations:
- [things done well]
```

## Rules

- Focus on real vulnerabilities, not theoretical concerns
- Prioritize by actual risk (likelihood x impact)
- Provide specific, actionable remediation steps
- Don't just flag issues - suggest fixes
- Consider the application context when assessing severity
