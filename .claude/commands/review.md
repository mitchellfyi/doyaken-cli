---
description: Apply review methodology
---

# Code Review

## Mindset

- Review like you will own this code for 2 years
- Prefer boring code - minimize cleverness
- Assume edge cases exist until disproven

## Findings Ledger

Track issues systematically by severity:
- **blocker**: Bugs, data loss, auth bypass, crashes
- **high**: Security issues, significant correctness problems
- **medium**: Performance, maintainability concerns
- **low**: Style, minor improvements

## Multi-Pass Review

### Pass A: Correctness
- Trace the happy path end-to-end
- Trace failure/edge paths
- Look for: silent failures, wrong defaults, missing error handling

### Pass B: Design
- Does it fit existing patterns?
- Could this be simpler?
- Can a new developer understand it?

### Pass C: Security
- Input validation
- Auth/authz on sensitive operations
- No hardcoded secrets
- Proper error messages

### Pass D: Performance
- N+1 queries or expensive loops?
- Timeouts for external calls?
- Race conditions?

### Pass E: Tests & Docs
- Tests cover behaviour and edge cases?
- Docs match implementation?

## Common Issues

### Correctness
- [ ] Off-by-one errors
- [ ] Null/undefined handling
- [ ] Empty collection handling

### Security
- [ ] Injection vectors
- [ ] Auth bypass
- [ ] Sensitive data in logs

### Performance
- [ ] N+1 queries
- [ ] Unbounded loops
- [ ] Missing pagination

### Maintainability
- [ ] Dead code
- [ ] Duplicated logic
- [ ] Magic numbers

## Checklist

- [ ] All passes completed
- [ ] No blocker/high issues remaining
- [ ] Tests exist and pass
- [ ] Code is understandable
- [ ] Changes match stated intent

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
