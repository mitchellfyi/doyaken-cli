# Redis Caching

Caching strategies and patterns with Redis.

## When to Apply

Activate this guide when:
- Implementing application caching
- Reducing database load
- Improving response times
- Managing cache invalidation

---

## 1. Caching Patterns

### Cache-Aside (Lazy Loading)

```typescript
async function getUser(userId: string): Promise<User> {
  const cacheKey = `user:${userId}`;

  // 1. Check cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);
  }

  // 2. Load from database
  const user = await db.users.findById(userId);

  // 3. Store in cache
  if (user) {
    await redis.setex(cacheKey, 300, JSON.stringify(user));
  }

  return user;
}
```

### Write-Through

```typescript
async function updateUser(userId: string, data: Partial<User>): Promise<User> {
  // 1. Update database
  const user = await db.users.update(userId, data);

  // 2. Update cache
  const cacheKey = `user:${userId}`;
  await redis.setex(cacheKey, 300, JSON.stringify(user));

  return user;
}
```

### Write-Behind (Async)

```typescript
async function updateUserAsync(userId: string, data: Partial<User>) {
  const cacheKey = `user:${userId}`;

  // 1. Update cache immediately
  const user = { ...(await getUser(userId)), ...data };
  await redis.setex(cacheKey, 300, JSON.stringify(user));

  // 2. Queue database write
  await queue.add('db:write', { userId, data });

  return user;
}
```

---

## 2. Cache Invalidation

### Direct Invalidation

```typescript
// Delete on update
async function updatePost(postId: string, data: object) {
  await db.posts.update(postId, data);
  await redis.del(`post:${postId}`);
  await redis.del(`posts:list`); // Invalidate list cache
}

// Pattern-based invalidation
async function invalidateUserCaches(userId: string) {
  const keys = await redis.keys(`user:${userId}:*`);
  if (keys.length) {
    await redis.del(...keys);
  }
}
```

### Time-Based (TTL)

```typescript
// Short TTL for frequently changing data
await redis.setex('trending:posts', 60, JSON.stringify(posts));

// Longer TTL for stable data
await redis.setex('user:profile:1', 3600, JSON.stringify(profile));

// Very long TTL with manual invalidation
await redis.setex('static:config', 86400, JSON.stringify(config));
```

### Event-Based

```typescript
// Publish invalidation event
async function onUserUpdate(userId: string) {
  await redis.publish('cache:invalidate', JSON.stringify({
    type: 'user',
    id: userId
  }));
}

// Subscribe to invalidations
async function setupInvalidationListener() {
  const subscriber = redis.duplicate();
  await subscriber.subscribe('cache:invalidate');

  subscriber.on('message', async (channel, message) => {
    const { type, id } = JSON.parse(message);
    await redis.del(`${type}:${id}`);
  });
}
```

---

## 3. Cache Stampede Prevention

### Mutex/Lock

```typescript
async function getWithLock(key: string, fetch: () => Promise<any>, ttl = 300) {
  // Try cache
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);

  // Acquire lock
  const lockKey = `lock:${key}`;
  const acquired = await redis.set(lockKey, '1', 'EX', 10, 'NX');

  if (!acquired) {
    // Wait and retry
    await sleep(100);
    return getWithLock(key, fetch, ttl);
  }

  try {
    // Fetch and cache
    const data = await fetch();
    await redis.setex(key, ttl, JSON.stringify(data));
    return data;
  } finally {
    await redis.del(lockKey);
  }
}
```

### Probabilistic Early Expiration

```typescript
interface CacheEntry {
  data: any;
  expiry: number;
  delta: number;
}

async function getWithEarlyExpiry(
  key: string,
  fetch: () => Promise<any>,
  ttl = 300
) {
  const entry = await redis.get(key);

  if (entry) {
    const { data, expiry, delta } = JSON.parse(entry) as CacheEntry;
    const now = Date.now();

    // Probabilistic early refresh
    const shouldRefresh = now - delta * Math.log(Math.random()) >= expiry;

    if (!shouldRefresh) {
      return data;
    }
  }

  // Fetch fresh data
  const start = Date.now();
  const data = await fetch();
  const delta = Date.now() - start;

  const cacheEntry: CacheEntry = {
    data,
    expiry: Date.now() + ttl * 1000,
    delta
  };

  await redis.setex(key, ttl, JSON.stringify(cacheEntry));
  return data;
}
```

---

## 4. Multi-Layer Caching

### Local + Redis

```typescript
import { LRUCache } from 'lru-cache';

const localCache = new LRUCache<string, any>({
  max: 1000,
  ttl: 60 * 1000 // 1 minute
});

async function getCached(key: string, fetch: () => Promise<any>) {
  // L1: Local memory
  if (localCache.has(key)) {
    return localCache.get(key);
  }

  // L2: Redis
  const redisValue = await redis.get(key);
  if (redisValue) {
    const data = JSON.parse(redisValue);
    localCache.set(key, data);
    return data;
  }

  // L3: Database
  const data = await fetch();

  // Populate both caches
  localCache.set(key, data);
  await redis.setex(key, 300, JSON.stringify(data));

  return data;
}
```

### Stale-While-Revalidate

```typescript
interface SWREntry {
  data: any;
  staleAt: number;
  expireAt: number;
}

async function getSWR(
  key: string,
  fetch: () => Promise<any>,
  staleTime = 60,
  maxAge = 300
) {
  const entry = await redis.get(key);
  const now = Date.now();

  if (entry) {
    const { data, staleAt, expireAt } = JSON.parse(entry) as SWREntry;

    // Still fresh
    if (now < staleAt) {
      return data;
    }

    // Stale but valid - return and refresh in background
    if (now < expireAt) {
      refreshInBackground(key, fetch, staleTime, maxAge);
      return data;
    }
  }

  // Expired or missing - fetch synchronously
  return fetchAndCache(key, fetch, staleTime, maxAge);
}

async function refreshInBackground(
  key: string,
  fetch: () => Promise<any>,
  staleTime: number,
  maxAge: number
) {
  setImmediate(async () => {
    try {
      await fetchAndCache(key, fetch, staleTime, maxAge);
    } catch (error) {
      console.error('Background refresh failed:', error);
    }
  });
}
```

---

## 5. Cache Patterns by Use Case

### API Response Caching

```typescript
// Cache full responses
async function getCachedApiResponse(
  endpoint: string,
  params: object,
  fetch: () => Promise<any>
) {
  const key = `api:${endpoint}:${hashParams(params)}`;
  return getCached(key, fetch);
}

// With vary headers
async function cacheWithVary(
  path: string,
  headers: { accept: string; authorization?: string },
  fetch: () => Promise<any>
) {
  const vary = headers.authorization ? 'auth' : 'anon';
  const key = `response:${path}:${headers.accept}:${vary}`;
  return getCached(key, fetch);
}
```

### Query Result Caching

```typescript
async function getCachedQuery<T>(
  queryName: string,
  params: object,
  query: () => Promise<T[]>
): Promise<T[]> {
  const key = `query:${queryName}:${JSON.stringify(params)}`;

  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);

  const results = await query();
  await redis.setex(key, 60, JSON.stringify(results));

  return results;
}

// Usage
const users = await getCachedQuery(
  'activeUsers',
  { role: 'admin' },
  () => db.users.find({ active: true, role: 'admin' })
);
```

### Session Caching

```typescript
interface Session {
  userId: string;
  data: object;
  expiresAt: number;
}

async function getSession(sessionId: string): Promise<Session | null> {
  const data = await redis.hgetall(`session:${sessionId}`);
  if (!Object.keys(data).length) return null;

  return {
    userId: data.userId,
    data: JSON.parse(data.data || '{}'),
    expiresAt: parseInt(data.expiresAt)
  };
}

async function setSession(sessionId: string, session: Session) {
  const key = `session:${sessionId}`;
  await redis.hset(key, {
    userId: session.userId,
    data: JSON.stringify(session.data),
    expiresAt: session.expiresAt.toString()
  });
  await redis.expireat(key, Math.floor(session.expiresAt / 1000));
}
```

---

## 6. Monitoring Cache Performance

### Hit Rate Tracking

```typescript
async function getCachedWithMetrics(
  key: string,
  fetch: () => Promise<any>
) {
  const cached = await redis.get(key);

  if (cached) {
    await redis.incr('metrics:cache:hits');
    return JSON.parse(cached);
  }

  await redis.incr('metrics:cache:misses');
  const data = await fetch();
  await redis.setex(key, 300, JSON.stringify(data));

  return data;
}

async function getCacheHitRate(): Promise<number> {
  const [hits, misses] = await Promise.all([
    redis.get('metrics:cache:hits'),
    redis.get('metrics:cache:misses')
  ]);

  const h = parseInt(hits || '0');
  const m = parseInt(misses || '0');
  const total = h + m;

  return total > 0 ? h / total : 0;
}
```

### Memory Usage

```redis
# Check memory usage
INFO memory
MEMORY USAGE key_name

# Get big keys
redis-cli --bigkeys

# Scan for patterns
SCAN 0 MATCH "cache:*" COUNT 100
```

## References

- [Caching Strategies](https://redis.io/docs/manual/client-side-caching/)
- [Cache Stampede](https://en.wikipedia.org/wiki/Cache_stampede)
