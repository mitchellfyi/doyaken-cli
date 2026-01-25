# Error Handling Patterns

## Principles

- **Fail fast** - Detect and report errors as early as possible
- **Fail loudly** - Don't swallow errors silently
- **Fail gracefully** - Degrade functionality rather than crash
- **Provide context** - Include information needed to diagnose

## Error Categories

| Type | Examples | Handling Strategy |
|------|----------|-------------------|
| **Validation** | Bad input, missing fields | Return 400, show user what's wrong |
| **Authentication** | Invalid token, expired session | Return 401, redirect to login |
| **Authorization** | No permission | Return 403, log attempt |
| **Not Found** | Missing resource | Return 404, clear message |
| **Conflict** | Duplicate, concurrent edit | Return 409, explain conflict |
| **Server Error** | Bugs, crashes | Return 500, log everything, alert |
| **External Failure** | API down, timeout | Retry with backoff, degrade gracefully |

## Error Response Format

### Consistent Structure
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email address is invalid",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address"
      }
    ],
    "requestId": "req_abc123"
  }
}
```

### What to Include
- Machine-readable error code
- Human-readable message
- Field-specific errors for validation
- Request ID for debugging
- Timestamp (in logs)

### What NOT to Include
- Stack traces (in production responses)
- Internal implementation details
- Database error messages
- Sensitive data

## Error Handling Patterns

### Try-Catch with Context
```javascript
// Bad - loses context
try {
  await processOrder(order);
} catch (e) {
  throw e;
}

// Good - adds context
try {
  await processOrder(order);
} catch (e) {
  throw new Error(`Failed to process order ${order.id}: ${e.message}`, { cause: e });
}
```

### Custom Error Classes
```javascript
class AppError extends Error {
  constructor(message, code, statusCode = 500) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.statusCode = statusCode;
  }
}

class ValidationError extends AppError {
  constructor(message, details = []) {
    super(message, 'VALIDATION_ERROR', 400);
    this.details = details;
  }
}

class NotFoundError extends AppError {
  constructor(resource, id) {
    super(`${resource} with id ${id} not found`, 'NOT_FOUND', 404);
  }
}
```

### Centralized Error Handler
```javascript
// Express middleware
function errorHandler(err, req, res, next) {
  // Log full error internally
  logger.error({
    error: err,
    requestId: req.id,
    path: req.path,
    userId: req.user?.id
  });

  // Send safe response to client
  const statusCode = err.statusCode || 500;
  const response = {
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: statusCode === 500
        ? 'An unexpected error occurred'
        : err.message,
      requestId: req.id
    }
  };

  res.status(statusCode).json(response);
}
```

## Retry Patterns

### Exponential Backoff
```javascript
async function withRetry(fn, maxAttempts = 3, baseDelay = 1000) {
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry on client errors (4xx)
      if (error.statusCode >= 400 && error.statusCode < 500) {
        throw error;
      }

      if (attempt < maxAttempts) {
        const delay = baseDelay * Math.pow(2, attempt - 1);
        await sleep(delay);
      }
    }
  }

  throw lastError;
}
```

### Circuit Breaker
```javascript
class CircuitBreaker {
  constructor(threshold = 5, timeout = 30000) {
    this.failures = 0;
    this.threshold = threshold;
    this.timeout = timeout;
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.nextAttempt = Date.now();
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is open');
      }
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failures = 0;
    this.state = 'CLOSED';
  }

  onFailure() {
    this.failures++;
    if (this.failures >= this.threshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.timeout;
    }
  }
}
```

## Logging Errors

### What to Log
```javascript
logger.error({
  // Error details
  message: error.message,
  stack: error.stack,
  code: error.code,

  // Context
  requestId: req.id,
  userId: req.user?.id,
  path: req.path,
  method: req.method,

  // Timing
  timestamp: new Date().toISOString(),
  duration: Date.now() - req.startTime,

  // Safe input (sanitized)
  input: sanitize(req.body)
});
```

### What NOT to Log
- Passwords
- API keys
- Full credit card numbers
- Session tokens
- Personal data (PII) without consent

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **Swallowing errors** | `catch (e) {}` | Log and rethrow or handle |
| **Generic messages** | "An error occurred" | Specific, actionable message |
| **Exposing internals** | "SQL syntax error near..." | Generic external, detailed internal |
| **No request ID** | Can't correlate logs | Include request ID everywhere |
| **Retrying everything** | 400 errors don't get better | Only retry transient failures |

## Checklist

- [ ] Errors have consistent format
- [ ] Error messages are user-friendly
- [ ] Stack traces only in development
- [ ] All errors are logged with context
- [ ] No sensitive data in error messages
- [ ] Validation errors specify which fields
- [ ] External API failures have retry logic
- [ ] Request IDs propagate through system
- [ ] Critical errors trigger alerts
