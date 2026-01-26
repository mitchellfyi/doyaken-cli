---
name: redis:cache-setup
description: Set up application caching with Redis
requires:
  - redis
args:
  - name: strategy
    description: Caching strategy (cache-aside, write-through, stale-while-revalidate)
    default: "cache-aside"
  - name: framework
    description: Framework (node, rails, django, generic)
    default: "node"
---

# Redis Cache Setup

You are setting up Redis caching for an application.

## Context

Project: {{DOYAKEN_PROJECT}}
Strategy: {{ARGS.strategy}}
Framework: {{ARGS.framework}}

## Setup Process

### 1. Connection Setup

{{#if framework == "node"}}
**Node.js/TypeScript**

```typescript
import { createClient } from 'redis';

const redis = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

await redis.connect();
```

{{else if framework == "rails"}}
**Ruby on Rails**

```ruby
# config/initializers/redis.rb
$redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')

# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

{{/if}}

### 2. Implement Caching Strategy

{{include:vendors/redis/caching.md}}

{{#if strategy == "cache-aside"}}
**Cache-Aside Pattern**

```typescript
async function getCached<T>(
  key: string,
  fetch: () => Promise<T>,
  ttl = 300
): Promise<T> {
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);

  const data = await fetch();
  await redis.setex(key, ttl, JSON.stringify(data));
  return data;
}
```

{{else if strategy == "write-through"}}
**Write-Through Pattern**

```typescript
async function saveWithCache<T>(
  key: string,
  data: T,
  save: (data: T) => Promise<T>,
  ttl = 300
): Promise<T> {
  const saved = await save(data);
  await redis.setex(key, ttl, JSON.stringify(saved));
  return saved;
}
```

{{else if strategy == "stale-while-revalidate"}}
**Stale-While-Revalidate Pattern**

Serve stale data while refreshing in background.

{{/if}}

### 3. Add Cache Invalidation

Implement invalidation strategy:
- Direct invalidation on updates
- Pattern-based invalidation
- Event-based invalidation

### 4. Add Monitoring

Track cache hit/miss rates.

## Output

```markdown
## Cache Setup Complete

**Strategy**: {{ARGS.strategy}}
**Framework**: {{ARGS.framework}}

### Files Created/Modified
- [List of files]

### Cache Configuration
| Setting | Value |
|---------|-------|
| Default TTL | 300s |
| Key Prefix | app: |
| Serialization | JSON |

### Usage Example
```{{ARGS.framework}}
[Example code]
```

### Next Steps
- [ ] Add cache warming for critical data
- [ ] Set up monitoring
- [ ] Configure key eviction policy
- [ ] Test invalidation
```
