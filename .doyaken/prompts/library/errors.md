# Error Handling Patterns

## Principles

- **Fail fast** - Detect and report errors as early as possible
- **Fail loudly** - Don't swallow errors silently
- **Fail gracefully** - Degrade functionality rather than crash
- **Provide context** - Include information needed to diagnose

## Error Categories

| Type | Examples | Handling Strategy |
|------|----------|-------------------|
| **Validation** | Bad input, missing fields | Reject early, show user what's wrong |
| **Authentication** | Invalid credentials, expired session | Reject, prompt for re-authentication |
| **Authorization** | No permission | Reject, log attempt |
| **Not Found** | Missing resource | Clear message about what's missing |
| **Conflict** | Duplicate, concurrent edit | Explain conflict, suggest resolution |
| **Internal Error** | Bugs, crashes | Log everything, alert, safe message to user |
| **External Failure** | Dependency down, timeout | Retry with backoff, degrade gracefully |

## Error Response Design

### What to Include
- Machine-readable error code
- Human-readable message
- Field-specific errors for validation
- Request/correlation ID for debugging
- Timestamp (in logs)

### What NOT to Include
- Stack traces (in production responses)
- Internal implementation details
- Database error messages
- Sensitive data

## Error Handling Patterns

### Wrap Errors with Context
When catching errors, add context about what operation was being attempted:
- What was the high-level operation?
- What input was being processed?
- Where in the flow did it fail?

### Custom Error Types
Create distinct error types for different categories:
- Validation errors with field details
- Not found errors with resource info
- Authorization errors with required permissions

### Centralized Error Handler
Use a single handler that:
- Logs full error internally
- Sends safe response externally
- Maps internal errors to user-friendly messages
- Includes correlation IDs for debugging

## Retry Patterns

### Exponential Backoff
For transient failures:
- Start with short delay
- Double delay on each retry
- Cap maximum attempts
- Only retry transient errors (don't retry validation failures)

### Circuit Breaker
For external dependencies:
- Track failure count
- Open circuit after threshold
- Allow periodic test requests
- Close circuit on success

## Logging Errors

### What to Log
- Error message and type
- Stack trace
- Context (user, operation, input)
- Request/correlation ID
- Timing information

### What NOT to Log
- Passwords
- API keys
- Full credit card numbers
- Session tokens
- Personal data (PII) without consent

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **Swallowing errors** | Silent failure | Log and rethrow or handle |
| **Generic messages** | "An error occurred" | Specific, actionable message |
| **Exposing internals** | "SQL syntax error near..." | Generic external, detailed internal |
| **No correlation ID** | Can't trace issues | Include request ID everywhere |
| **Retrying everything** | Validation errors don't get better | Only retry transient failures |

## Checklist

- [ ] Errors have consistent format
- [ ] Error messages are user-friendly
- [ ] Stack traces only in development
- [ ] All errors are logged with context
- [ ] No sensitive data in error messages
- [ ] Validation errors specify which fields
- [ ] External failures have retry logic
- [ ] Correlation IDs propagate through system
- [ ] Critical errors trigger alerts
