# Code Review Methodology

## Mindset

- Review like you will own this code for 2 years
- Prefer boring code - minimize cleverness
- Assume edge cases exist until disproven
- If unsure, verify in the repo - don't invent behaviour

## Findings Ledger

Track all issues systematically:

```
| ID | Severity | Category | Location | Issue | Fix |
|----|----------|----------|----------|-------|-----|
| 1  | blocker  | correctness | file:line | [what's wrong] | [how to fix] |
```

**Severity levels:**
- **blocker**: Bugs, data loss, auth bypass, crashes
- **high**: Security issues, significant correctness problems
- **medium**: Performance issues, maintainability concerns
- **low**: Style, minor improvements
- **nit**: Trivial (only mention after everything else is clean)

**Categories:**
- correctness, security, performance, reliability, maintainability, tests, docs

## Multi-Pass Review

Don't stop after one pass. Review explicitly in multiple passes:

### Pass A: Intent & Correctness
- What does this change claim to do?
- Trace the happy path end-to-end
- Trace at least 3 failure/edge paths
- Look for: silent failures, wrong defaults, partial writes, missing error handling

### Pass B: Design & Complexity
- Does it fit the existing codebase patterns?
- Could this be simpler?
- Are there unnecessary abstractions?
- Can a new developer understand it quickly?
- Any premature optimization?

### Pass C: Security
- Input validation (injection, XSS)
- Auth/authz checks on sensitive operations
- No hardcoded secrets or credentials
- Proper error messages (no stack traces to users)
- Rate limiting where appropriate

### Pass D: Performance & Reliability
- Obvious N+1 queries or expensive loops?
- Timeouts/retries for external calls?
- Concurrency hazards or race conditions?
- Resource cleanup (connections, file handles)?

### Pass E: Tests & Documentation
- Do tests cover behaviour and edge cases?
- Do docs match implementation?
- Is error output helpful for debugging?
- Are there tests for the failure paths?

## Common Issues Checklist

### Correctness
- [ ] Off-by-one errors in loops/indices
- [ ] Null/undefined handling
- [ ] Empty collection handling
- [ ] Integer overflow/underflow
- [ ] Floating point comparison issues
- [ ] Time zone handling
- [ ] Unicode/encoding issues

### Security
- [ ] SQL/NoSQL injection vectors
- [ ] XSS vulnerabilities
- [ ] CSRF protection
- [ ] Authentication bypass
- [ ] Authorization bypass (IDOR)
- [ ] Sensitive data in logs
- [ ] Hardcoded credentials

### Performance
- [ ] N+1 queries
- [ ] Unbounded loops
- [ ] Missing pagination
- [ ] Large objects in memory
- [ ] Synchronous blocking operations
- [ ] Missing indexes (database)

### Maintainability
- [ ] Dead code
- [ ] Duplicated logic
- [ ] God objects/functions
- [ ] Magic numbers without explanation
- [ ] Inconsistent naming
- [ ] Missing error context

## Giving Feedback

**Be specific:**
- Bad: "This is confusing"
- Good: "This function does 3 things (parse, validate, save). Consider splitting into separate functions."

**Explain the why:**
- Bad: "Use `const` instead of `let`"
- Good: "Use `const` since this value is never reassigned - signals intent to readers"

**Offer solutions:**
- Bad: "This won't scale"
- Good: "This O(n²) loop will be slow for large datasets. Consider using a Map for O(1) lookup."

**Distinguish blocking from suggestions:**
- Use "nit:" prefix for trivial suggestions
- Be clear what must be fixed vs what's optional

## Review Checklist

Before approving:

- [ ] All passes completed (A through E)
- [ ] No blocker or high severity issues remaining
- [ ] Tests exist and pass
- [ ] Code is understandable without explanation
- [ ] No obvious security vulnerabilities
- [ ] Changes match stated intent
