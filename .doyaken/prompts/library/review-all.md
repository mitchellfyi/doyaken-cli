# Comprehensive Periodic Review

## Purpose

This is a comprehensive codebase review that runs after completing a threshold of tasks. The goal is to catch issues early, maintain code quality, and ensure technical debt doesn't accumulate.

## Critical Requirements

**Every finding MUST result in action:**
1. **Auto-fix**: If the issue can be fixed automatically (formatting, simple refactors, obvious bugs), fix it immediately
2. **Create task**: If the issue requires manual intervention or more analysis, document it as a follow-up

No passive reporting. Every issue must be either fixed or tracked.

## Review Sequence

Execute each review type in order, documenting findings as you go:

### 1. Code Quality Review

{{include:library/quality.md}}

**Focus Areas:**
- Code complexity and maintainability
- Naming conventions and consistency
- Dead code and unused imports
- Code duplication
- Error handling patterns

### 2. Security Audit

{{include:library/review-security.md}}

**Focus Areas:**
- Authentication and authorization
- Input validation
- Data protection
- Dependency vulnerabilities
- Secrets management

### 3. Performance Analysis

{{include:library/review-performance.md}}

**Focus Areas:**
- Database query efficiency
- Memory usage patterns
- Caching opportunities
- Bundle size (frontend)
- API response times

### 4. Technical Debt Assessment

{{include:library/review-debt.md}}

**Focus Areas:**
- Legacy patterns that should be updated
- TODOs and FIXMEs
- Deprecated dependencies
- Code that needs refactoring
- Test coverage gaps

### 5. UX Review

{{include:library/review-ux.md}}

**Focus Areas:**
- User flow clarity
- Error messages and feedback
- Accessibility (WCAG)
- Mobile responsiveness
- Loading states

### 6. Documentation Review

{{include:library/review-docs.md}}

**Focus Areas:**
- README accuracy
- API documentation
- Architecture docs
- Code comments
- Configuration documentation

## Findings Ledger

Track all findings in a structured format:

| ID | Severity | Category | Location | Issue | Action |
|----|----------|----------|----------|-------|--------|
| 1 | [severity] | [category] | file:line | [description] | [fixed/task-XXX] |

**Severity Levels:**
- **blocker**: Critical issues that must be fixed immediately
- **high**: Security vulnerabilities, significant bugs
- **medium**: Performance issues, maintainability concerns
- **low**: Style issues, minor improvements

**Categories:**
- security, performance, quality, debt, ux, docs

## Action Requirements

### Auto-Fix Criteria

Fix immediately if:
- Formatting issues (run formatter)
- Unused imports/variables
- Obvious typos in strings/comments
- Simple null checks
- Missing error handling that follows established patterns
- Dependency updates with no breaking changes

### Task Creation Criteria

Create a task if:
- Fix requires design decisions
- Multiple files need coordinated changes
- Tests need to be written
- Breaking changes involved
- Security issue needs careful remediation
- Performance fix needs benchmarking

### Follow-Up Format

Document issues that need separate work:

```
[FOLLOW-UP] [severity] [category]: [description]
  Location: [file:line]
  Fix: [recommended approach]
```

## Output Summary

At the end of the review, provide:

```
## Periodic Review Summary

### Stats
- Total findings: [N]
- Auto-fixed: [X]
- Tasks created: [Y]
- Remaining: [Z] (should be 0)

### By Category
| Category | Findings | Fixed | Tasks |
|----------|----------|-------|-------|
| Security | N | X | Y |
| Quality | N | X | Y |
| Performance | N | X | Y |
| Debt | N | X | Y |
| UX | N | X | Y |
| Docs | N | X | Y |

### Fixes Applied
1. [Brief description of fix 1]
2. [Brief description of fix 2]

### Follow-Ups
1. [severity] [category]: [Brief description]
2. [severity] [category]: [Brief description]

### Blockers (Require Immediate Attention)
[List any blocker-severity items]

### Next Steps
[Recommendations for follow-up]
```
