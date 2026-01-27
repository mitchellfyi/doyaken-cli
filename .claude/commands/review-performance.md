---
description: Apply review-performance methodology
---

# Performance Optimization

## Principles

- **Measure first** - Don't optimize without data
- **80/20 rule** - Focus on the 20% that causes 80% of problems
- **Avoid premature optimization** - Make it work, make it right, make it fast
- **Understand the cost** - Every optimization has trade-offs

## Performance Investigation

### Step 1: Define the Problem
- What's slow? (specific operation, page, API)
- How slow? (quantify with metrics)
- When is it slow? (load, data size, time of day)
- What's acceptable? (target latency, throughput)

### Step 2: Measure
```javascript
// Simple timing
console.time('operation');
await doSomething();
console.timeEnd('operation');

// Detailed profiling
const start = performance.now();
await doSomething();
const duration = performance.now() - start;
```

### Step 3: Profile
- **CPU profiler** - Find hot functions
- **Memory profiler** - Find leaks, large allocations
- **Network tab** - Find slow requests, large payloads
- **Database explain** - Find slow queries

## Common Bottlenecks

### Database

| Problem | Symptom | Solution |
|---------|---------|----------|
| **Missing index** | Slow queries on filtered columns | Add appropriate index |
| **N+1 queries** | Many small queries instead of one | Use JOIN or batch loading |
| **Large result sets** | Memory issues, slow transfer | Pagination, streaming |
| **Lock contention** | Queries waiting | Optimize transactions |

```sql
-- Find slow queries
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- Add index
CREATE INDEX idx_users_email ON users(email);
```

### API/Network

| Problem | Symptom | Solution |
|---------|---------|----------|
| **Large payloads** | Slow transfer, high bandwidth | Compression, field selection |
| **Many requests** | High latency overhead | Batch endpoints, GraphQL |
| **No caching** | Repeated identical requests | Cache headers, CDN |
| **Synchronous calls** | Blocking on external services | Async, timeouts |

### Code

| Problem | Symptom | Solution |
|---------|---------|----------|
| **O(n²) algorithm** | Exponential slowdown | Better algorithm, data structure |
| **Blocking operations** | Thread starvation | Async I/O |
| **Memory leaks** | Growing memory over time | Proper cleanup, WeakRef |
| **Inefficient loops** | CPU-bound | Early exit, caching |

## Optimization Techniques

### Caching

```javascript
// In-memory cache
const cache = new Map();

async function getCached(key, fetchFn, ttl = 60000) {
  const cached = cache.get(key);
  if (cached && Date.now() < cached.expiry) {
    return cached.value;
  }

  const value = await fetchFn();
  cache.set(key, { value, expiry: Date.now() + ttl });
  return value;
}
```

**Cache invalidation strategies:**
- Time-based (TTL)
- Event-based (on write)
- Version-based (cache key includes version)

### Batch Processing

```javascript
// Bad: N+1 problem
for (const userId of userIds) {
  const user = await db.users.findById(userId);
}

// Good: Single query
const users = await db.users.findByIds(userIds);
```

### Lazy Loading

```javascript
// Load on demand
async function getUser(id) {
  return {
    id,
    name: await fetchName(id),
    get orders() {
      return fetchOrders(id); // Only loads when accessed
    }
  };
}
```

### Pagination

```javascript
// Cursor-based for large datasets
async function getItems(cursor, limit = 20) {
  const query = cursor
    ? { id: { $gt: cursor } }
    : {};

  return db.items
    .find(query)
    .sort({ id: 1 })
    .limit(limit + 1); // +1 to check hasMore
}
```

### Connection Pooling

```javascript
// Reuse database connections
const pool = new Pool({
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});
```

## Database Optimization

### Query Optimization
```sql
-- Bad: Full table scan
SELECT * FROM orders WHERE YEAR(created_at) = 2024;

-- Good: Index-friendly
SELECT * FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

### Index Strategy
- Index columns used in WHERE, JOIN, ORDER BY
- Composite indexes for multi-column queries
- Don't over-index (slows writes)
- Monitor unused indexes

### Denormalization
When read performance > write simplicity:
- Store computed values
- Duplicate data to avoid JOINs
- Use materialized views

## Frontend Performance

### Critical Rendering Path
1. Minimize critical CSS
2. Defer non-critical JavaScript
3. Optimize images (WebP, lazy loading)
4. Use CDN for static assets

### Bundle Optimization
- Code splitting
- Tree shaking
- Compression (gzip, brotli)
- Minimize dependencies

## Monitoring

### Key Metrics
- **Latency** - p50, p95, p99
- **Throughput** - Requests per second
- **Error rate** - Failures per total requests
- **Resource utilization** - CPU, memory, connections

### Alerting Thresholds
```yaml
alerts:
  - name: high_latency
    condition: p95_latency > 500ms
    duration: 5m

  - name: error_spike
    condition: error_rate > 1%
    duration: 1m
```

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **Premature optimization** | Wasted effort | Measure first |
| **Caching everything** | Memory bloat, stale data | Cache hot paths only |
| **Sync where async works** | Blocking threads | Use async I/O |
| **No connection pooling** | Connection overhead | Pool connections |
| **Ignoring database** | ORM hides problems | Check generated queries |

## Checklist

Before optimizing:
- [ ] Problem is quantified with metrics
- [ ] Target performance is defined
- [ ] Profiling identifies bottleneck

After optimizing:
- [ ] Improvement is measured
- [ ] No regressions introduced
- [ ] Trade-offs are documented
- [ ] Monitoring is in place

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
