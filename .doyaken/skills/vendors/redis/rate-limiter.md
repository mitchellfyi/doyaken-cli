---
name: redis:rate-limiter
description: Implement rate limiting with Redis
requires:
  - redis
args:
  - name: type
    description: Rate limit type (fixed-window, sliding-window, token-bucket)
    default: "sliding-window"
  - name: limit
    description: Request limit
    default: "100"
  - name: window
    description: Time window in seconds
    default: "60"
---

# Redis Rate Limiter

You are implementing rate limiting with Redis.

## Context

Project: {{DOYAKEN_PROJECT}}
Type: {{ARGS.type}}
Limit: {{ARGS.limit}} requests
Window: {{ARGS.window}} seconds

## Implementation

### 1. Choose Algorithm

{{include:vendors/redis/patterns.md}}

{{#if type == "fixed-window"}}
**Fixed Window**

Simple counter per time window.

```typescript
async function checkRateLimit(key: string): Promise<boolean> {
  const current = await redis.incr(key);
  if (current === 1) {
    await redis.expire(key, {{ARGS.window}});
  }
  return current <= {{ARGS.limit}};
}
```

{{else if type == "sliding-window"}}
**Sliding Window**

More accurate, prevents boundary bursts.

```typescript
async function checkRateLimit(key: string): Promise<boolean> {
  const now = Date.now();
  const windowStart = now - {{ARGS.window}} * 1000;

  await redis.zremrangebyscore(key, 0, windowStart);
  const count = await redis.zcard(key);

  if (count >= {{ARGS.limit}}) return false;

  await redis.zadd(key, now, `${now}:${Math.random()}`);
  await redis.expire(key, {{ARGS.window}});
  return true;
}
```

{{else if type == "token-bucket"}}
**Token Bucket**

Allows bursts while maintaining average rate.

```typescript
// Implemented via Lua script for atomicity
```

{{/if}}

### 2. Integrate with Application

**Express Middleware**
```typescript
async function rateLimitMiddleware(req, res, next) {
  const key = `ratelimit:${req.ip}`;
  const allowed = await checkRateLimit(key);

  if (!allowed) {
    return res.status(429).json({
      error: 'Too Many Requests',
      retryAfter: {{ARGS.window}}
    });
  }

  next();
}
```

### 3. Add Headers

```typescript
res.set({
  'X-RateLimit-Limit': {{ARGS.limit}},
  'X-RateLimit-Remaining': remaining,
  'X-RateLimit-Reset': resetTime
});
```

## Output

```markdown
## Rate Limiter Implemented

**Algorithm**: {{ARGS.type}}
**Limit**: {{ARGS.limit}} requests per {{ARGS.window}}s

### Configuration
| Setting | Value |
|---------|-------|
| Algorithm | {{ARGS.type}} |
| Limit | {{ARGS.limit}} |
| Window | {{ARGS.window}}s |
| Key Pattern | ratelimit:{identifier} |

### Integration Points
- [Where rate limiting is applied]

### Response Headers
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

### Testing
```bash
# Test rate limit
for i in {1..110}; do curl -s http://localhost/api; done
```

### Next Steps
- [ ] Configure per-endpoint limits
- [ ] Add user-based limits
- [ ] Set up monitoring/alerting
```
