# Redis Patterns

Common Redis patterns for real-time features and distributed systems.

## When to Apply

Activate this guide when:
- Building real-time features
- Implementing distributed systems
- Creating job queues
- Building rate limiters

---

## 1. Pub/Sub Messaging

### Basic Pub/Sub

```typescript
// Publisher
async function publishMessage(channel: string, message: object) {
  await redis.publish(channel, JSON.stringify(message));
}

// Subscriber
async function subscribe(channel: string, handler: (msg: object) => void) {
  const subscriber = redis.duplicate();
  await subscriber.subscribe(channel);

  subscriber.on('message', (ch, message) => {
    if (ch === channel) {
      handler(JSON.parse(message));
    }
  });

  return () => subscriber.unsubscribe(channel);
}

// Usage
await publishMessage('notifications', { userId: '123', text: 'Hello!' });

subscribe('notifications', (msg) => {
  console.log('Received:', msg);
});
```

### Pattern Subscriptions

```typescript
// Subscribe to patterns
const subscriber = redis.duplicate();
await subscriber.psubscribe('events:*');

subscriber.on('pmessage', (pattern, channel, message) => {
  console.log(`[${channel}] ${message}`);
});

// Publish to specific channels
await redis.publish('events:user:created', JSON.stringify({ id: '123' }));
await redis.publish('events:order:placed', JSON.stringify({ id: '456' }));
```

### Chat Rooms

```typescript
async function joinRoom(roomId: string, userId: string) {
  await redis.sadd(`room:${roomId}:members`, userId);
  await redis.publish(`room:${roomId}:events`, JSON.stringify({
    type: 'join',
    userId
  }));
}

async function sendMessage(roomId: string, userId: string, text: string) {
  const message = {
    id: crypto.randomUUID(),
    roomId,
    userId,
    text,
    timestamp: Date.now()
  };

  // Store in history
  await redis.lpush(`room:${roomId}:messages`, JSON.stringify(message));
  await redis.ltrim(`room:${roomId}:messages`, 0, 99);

  // Broadcast
  await redis.publish(`room:${roomId}:messages`, JSON.stringify(message));
}
```

---

## 2. Distributed Locks

### Simple Lock

```typescript
async function acquireLock(
  resource: string,
  ttl = 10000
): Promise<string | null> {
  const lockId = crypto.randomUUID();
  const key = `lock:${resource}`;

  const acquired = await redis.set(key, lockId, 'PX', ttl, 'NX');
  return acquired ? lockId : null;
}

async function releaseLock(resource: string, lockId: string): Promise<boolean> {
  const key = `lock:${resource}`;

  // Only release if we own the lock
  const script = `
    if redis.call("get", KEYS[1]) == ARGV[1] then
      return redis.call("del", KEYS[1])
    else
      return 0
    end
  `;

  const result = await redis.eval(script, 1, key, lockId);
  return result === 1;
}

// Usage
async function processOrder(orderId: string) {
  const lockId = await acquireLock(`order:${orderId}`);
  if (!lockId) {
    throw new Error('Could not acquire lock');
  }

  try {
    await doProcessing(orderId);
  } finally {
    await releaseLock(`order:${orderId}`, lockId);
  }
}
```

### Lock with Retry

```typescript
async function acquireLockWithRetry(
  resource: string,
  ttl = 10000,
  retries = 3,
  retryDelay = 200
): Promise<string | null> {
  for (let i = 0; i < retries; i++) {
    const lockId = await acquireLock(resource, ttl);
    if (lockId) return lockId;

    await sleep(retryDelay * (i + 1));
  }
  return null;
}

// Auto-release wrapper
async function withLock<T>(
  resource: string,
  fn: () => Promise<T>,
  options?: { ttl?: number; retries?: number }
): Promise<T> {
  const lockId = await acquireLockWithRetry(
    resource,
    options?.ttl,
    options?.retries
  );

  if (!lockId) {
    throw new Error(`Failed to acquire lock: ${resource}`);
  }

  try {
    return await fn();
  } finally {
    await releaseLock(resource, lockId);
  }
}

// Usage
await withLock('critical-section', async () => {
  await updateSharedResource();
});
```

---

## 3. Rate Limiting

### Fixed Window

```typescript
async function checkRateLimit(
  key: string,
  limit: number,
  windowSeconds: number
): Promise<{ allowed: boolean; remaining: number }> {
  const current = await redis.incr(key);

  if (current === 1) {
    await redis.expire(key, windowSeconds);
  }

  return {
    allowed: current <= limit,
    remaining: Math.max(0, limit - current)
  };
}

// Usage
const { allowed, remaining } = await checkRateLimit(
  `ratelimit:api:${userId}`,
  100, // 100 requests
  60   // per minute
);

if (!allowed) {
  throw new RateLimitError(`Rate limit exceeded. Retry in ${remaining}s`);
}
```

### Sliding Window

```typescript
async function slidingWindowRateLimit(
  key: string,
  limit: number,
  windowMs: number
): Promise<boolean> {
  const now = Date.now();
  const windowStart = now - windowMs;

  // Remove old entries
  await redis.zremrangebyscore(key, 0, windowStart);

  // Count current window
  const count = await redis.zcard(key);

  if (count >= limit) {
    return false;
  }

  // Add current request
  await redis.zadd(key, now, `${now}:${Math.random()}`);
  await redis.pexpire(key, windowMs);

  return true;
}
```

### Token Bucket

```typescript
async function tokenBucket(
  key: string,
  capacity: number,
  refillRate: number // tokens per second
): Promise<boolean> {
  const now = Date.now();
  const script = `
    local key = KEYS[1]
    local capacity = tonumber(ARGV[1])
    local refill_rate = tonumber(ARGV[2])
    local now = tonumber(ARGV[3])

    local bucket = redis.call('hmget', key, 'tokens', 'last_refill')
    local tokens = tonumber(bucket[1]) or capacity
    local last_refill = tonumber(bucket[2]) or now

    -- Refill tokens
    local elapsed = (now - last_refill) / 1000
    tokens = math.min(capacity, tokens + elapsed * refill_rate)

    if tokens >= 1 then
      tokens = tokens - 1
      redis.call('hmset', key, 'tokens', tokens, 'last_refill', now)
      redis.call('expire', key, 3600)
      return 1
    end

    return 0
  `;

  const result = await redis.eval(script, 1, key, capacity, refillRate, now);
  return result === 1;
}
```

---

## 4. Job Queues

### Simple Queue

```typescript
interface Job {
  id: string;
  type: string;
  data: object;
  createdAt: number;
}

async function enqueue(queue: string, type: string, data: object): Promise<string> {
  const job: Job = {
    id: crypto.randomUUID(),
    type,
    data,
    createdAt: Date.now()
  };

  await redis.rpush(`queue:${queue}`, JSON.stringify(job));
  return job.id;
}

async function dequeue(queue: string, timeout = 30): Promise<Job | null> {
  const result = await redis.blpop(`queue:${queue}`, timeout);
  if (!result) return null;

  return JSON.parse(result[1]);
}

// Worker
async function startWorker(queue: string, handlers: Record<string, Function>) {
  while (true) {
    const job = await dequeue(queue);
    if (!job) continue;

    try {
      const handler = handlers[job.type];
      if (handler) {
        await handler(job.data);
      }
    } catch (error) {
      console.error(`Job ${job.id} failed:`, error);
      // Add to dead letter queue
      await redis.rpush(`queue:${queue}:failed`, JSON.stringify(job));
    }
  }
}
```

### Delayed Jobs

```typescript
async function scheduleJob(
  queue: string,
  job: object,
  delayMs: number
): Promise<string> {
  const id = crypto.randomUUID();
  const executeAt = Date.now() + delayMs;

  await redis.zadd(
    `queue:${queue}:delayed`,
    executeAt,
    JSON.stringify({ id, ...job })
  );

  return id;
}

async function processDueJobs(queue: string) {
  const now = Date.now();

  // Get due jobs
  const jobs = await redis.zrangebyscore(
    `queue:${queue}:delayed`,
    0,
    now
  );

  for (const jobStr of jobs) {
    // Move to main queue
    await redis.rpush(`queue:${queue}`, jobStr);
    await redis.zrem(`queue:${queue}:delayed`, jobStr);
  }
}

// Run periodically
setInterval(() => processDueJobs('default'), 1000);
```

---

## 5. Session Management

### Session Store

```typescript
interface Session {
  userId: string;
  createdAt: number;
  lastActivity: number;
  data: Record<string, any>;
}

async function createSession(userId: string): Promise<string> {
  const sessionId = crypto.randomUUID();
  const session: Session = {
    userId,
    createdAt: Date.now(),
    lastActivity: Date.now(),
    data: {}
  };

  await redis.hset(`session:${sessionId}`, flattenObject(session));
  await redis.expire(`session:${sessionId}`, 3600);

  // Track user sessions
  await redis.sadd(`user:${userId}:sessions`, sessionId);

  return sessionId;
}

async function getSession(sessionId: string): Promise<Session | null> {
  const data = await redis.hgetall(`session:${sessionId}`);
  if (!Object.keys(data).length) return null;

  // Update last activity
  await redis.hset(`session:${sessionId}`, 'lastActivity', Date.now());
  await redis.expire(`session:${sessionId}`, 3600);

  return unflattenObject(data) as Session;
}

async function destroySession(sessionId: string) {
  const session = await getSession(sessionId);
  if (session) {
    await redis.srem(`user:${session.userId}:sessions`, sessionId);
  }
  await redis.del(`session:${sessionId}`);
}

async function destroyAllUserSessions(userId: string) {
  const sessions = await redis.smembers(`user:${userId}:sessions`);
  for (const sessionId of sessions) {
    await redis.del(`session:${sessionId}`);
  }
  await redis.del(`user:${userId}:sessions`);
}
```

---

## 6. Real-Time Counters

### View Counter

```typescript
async function incrementViews(resourceId: string): Promise<number> {
  return redis.incr(`views:${resourceId}`);
}

async function getViews(resourceId: string): Promise<number> {
  const views = await redis.get(`views:${resourceId}`);
  return parseInt(views || '0');
}

// Time-windowed counts
async function incrementHourlyViews(resourceId: string): Promise<void> {
  const hour = new Date().toISOString().slice(0, 13);
  const key = `views:${resourceId}:${hour}`;

  await redis.incr(key);
  await redis.expire(key, 86400 * 7); // Keep for 7 days
}

async function getViewsOverTime(
  resourceId: string,
  hours: number
): Promise<number[]> {
  const keys: string[] = [];
  const now = new Date();

  for (let i = 0; i < hours; i++) {
    const date = new Date(now.getTime() - i * 3600000);
    const hour = date.toISOString().slice(0, 13);
    keys.push(`views:${resourceId}:${hour}`);
  }

  const values = await redis.mget(...keys);
  return values.map(v => parseInt(v || '0'));
}
```

### HyperLogLog for Unique Counts

```typescript
async function trackUniqueVisitor(pageId: string, visitorId: string) {
  await redis.pfadd(`unique:${pageId}`, visitorId);
}

async function getUniqueVisitorCount(pageId: string): Promise<number> {
  return redis.pfcount(`unique:${pageId}`);
}

// Merge multiple pages
async function getTotalUniqueVisitors(pageIds: string[]): Promise<number> {
  const keys = pageIds.map(id => `unique:${id}`);
  return redis.pfcount(...keys);
}
```

---

## 7. Presence/Online Status

```typescript
async function setOnline(userId: string) {
  const now = Date.now();
  await redis.zadd('users:online', now, userId);
}

async function setOffline(userId: string) {
  await redis.zrem('users:online', userId);
}

async function getOnlineUsers(): Promise<string[]> {
  // Users active in last 5 minutes
  const cutoff = Date.now() - 5 * 60 * 1000;
  return redis.zrangebyscore('users:online', cutoff, '+inf');
}

async function isOnline(userId: string): Promise<boolean> {
  const cutoff = Date.now() - 5 * 60 * 1000;
  const score = await redis.zscore('users:online', userId);
  return score !== null && parseInt(score) > cutoff;
}

// Cleanup old entries periodically
async function cleanupOfflineUsers() {
  const cutoff = Date.now() - 5 * 60 * 1000;
  await redis.zremrangebyscore('users:online', 0, cutoff);
}
```

## References

- [Redis Pub/Sub](https://redis.io/docs/interact/pubsub/)
- [Distributed Locks](https://redis.io/docs/manual/patterns/distributed-locks/)
- [Redis Streams](https://redis.io/docs/data-types/streams/)
