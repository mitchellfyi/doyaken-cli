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

## Timeouts

**Set timeouts on ALL external calls** — network, database, file system, third-party APIs. A missing timeout can hang an entire system when a dependency is slow or unresponsive.

## Retry Patterns

### Exponential Backoff with Jitter
For transient failures (5xx, timeouts, connection resets):
- Start with short delay
- Double delay on each retry
- **Add jitter** (random variation) to prevent thundering herd
- Cap maximum attempts
- Only retry transient errors — never retry validation failures, auth failures, or 4xx responses

### Circuit Breaker
For external dependencies:
- Track failure count
- Open circuit after threshold — stop calling the failing service
- Allow periodic probe requests
- Close circuit on success
- Recover automatically

## Resilience Patterns

### Graceful Degradation
If a non-critical dependency fails, continue with reduced functionality rather than failing entirely.

### Fallback Strategies
- Cached data when primary source is unavailable
- Default values when configuration service is down
- Simplified responses when an enrichment service fails

### Idempotency
Operations that may be retried (API endpoints, message handlers, jobs) must produce the same result on repeat calls. Use idempotency keys, database constraints, or conditional writes.

### Graceful Shutdown
Handle termination signals (SIGTERM, SIGINT):
1. Stop accepting new work
2. Drain in-flight requests/jobs
3. Release resources (connections, file handles, locks)
4. Exit cleanly

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
- Internal paths or sensitive configuration

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **Swallowing errors** | Silent failure | Log and rethrow or handle |
| **Generic messages** | "An error occurred" | Specific, actionable message |
| **Exposing internals** | "SQL syntax error near..." | Generic external, detailed internal |
| **No correlation ID** | Can't trace issues | Include request ID everywhere |
| **Retrying everything** | Validation errors don't get better | Only retry transient failures |
| **No timeouts** | System hangs on slow dependency | Set timeouts on every external call |
| **Removing validation to compile** | Masks real problems | Understand why it fails; fix root cause |

## Checklist

- [ ] Errors have consistent format
- [ ] Error messages are user-friendly
- [ ] Stack traces only in development
- [ ] All errors are logged with context
- [ ] No sensitive data in error messages or logs
- [ ] Validation errors specify which fields
- [ ] External failures have retry logic with backoff and jitter
- [ ] Timeouts set on all external calls
- [ ] Correlation IDs propagate through system
- [ ] Critical errors trigger alerts
- [ ] Graceful shutdown handles in-flight work
