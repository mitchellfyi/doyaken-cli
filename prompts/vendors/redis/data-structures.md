# Redis Data Structures

Redis data types and their optimal usage patterns.

## When to Apply

Activate this guide when:
- Choosing Redis data types
- Modeling data in Redis
- Implementing efficient storage patterns
- Working with Redis commands

---

## 1. Strings

### Basic Operations

```redis
# Set and get
SET user:1:name "John Doe"
GET user:1:name

# With expiration
SET session:abc123 "user_data" EX 3600   # 1 hour
SETEX session:abc123 3600 "user_data"    # Same as above

# Only if not exists
SETNX lock:resource "locked"

# Atomic increment
INCR counter:visits
INCRBY counter:visits 5
INCRBYFLOAT price:total 9.99
```

### Use Cases

```redis
# Counter
INCR page:views:homepage

# Rate limiting
SET rate:user:123 1 EX 60 NX  # 1 request per minute

# Caching JSON
SET cache:user:1 '{"id":1,"name":"John"}' EX 300

# Feature flags
SET feature:dark_mode "enabled"
```

### Code Example (Node.js)

```typescript
// Caching with TTL
async function getCachedUser(userId: string) {
  const cached = await redis.get(`user:${userId}`);
  if (cached) return JSON.parse(cached);

  const user = await db.users.findById(userId);
  await redis.setex(`user:${userId}`, 300, JSON.stringify(user));
  return user;
}

// Atomic counter
async function trackPageView(page: string) {
  return redis.incr(`views:${page}:${today()}`);
}
```

---

## 2. Hashes

### Basic Operations

```redis
# Set fields
HSET user:1 name "John" email "john@example.com" age 30

# Get field
HGET user:1 name

# Get all fields
HGETALL user:1

# Increment field
HINCRBY user:1 age 1

# Check field exists
HEXISTS user:1 email

# Delete field
HDEL user:1 age
```

### Use Cases

```redis
# User profile
HSET user:1 name "John" email "john@example.com" plan "premium"
HGET user:1 plan

# Session data
HSET session:abc123 user_id 1 logged_in_at "2024-01-01" ip "192.168.1.1"
EXPIRE session:abc123 3600

# Shopping cart
HSET cart:user:1 product:123 2 product:456 1
HINCRBY cart:user:1 product:123 1  # Add one more
HDEL cart:user:1 product:456       # Remove item
```

### Code Example

```typescript
interface UserSession {
  userId: string;
  loginTime: string;
  ip: string;
}

async function setSession(sessionId: string, data: UserSession) {
  await redis.hset(`session:${sessionId}`, data);
  await redis.expire(`session:${sessionId}`, 3600);
}

async function getSession(sessionId: string): Promise<UserSession | null> {
  const data = await redis.hgetall(`session:${sessionId}`);
  return Object.keys(data).length ? data as UserSession : null;
}
```

---

## 3. Lists

### Basic Operations

```redis
# Push to list
LPUSH queue:tasks "task1"      # Left (front)
RPUSH queue:tasks "task2"      # Right (back)

# Pop from list
LPOP queue:tasks               # From front
RPOP queue:tasks               # From back
BLPOP queue:tasks 0            # Blocking pop

# Get range
LRANGE notifications:user:1 0 9   # First 10
LRANGE notifications:user:1 0 -1  # All items

# Length
LLEN queue:tasks

# Trim (keep only recent)
LTRIM notifications:user:1 0 99   # Keep last 100
```

### Use Cases

```redis
# Task queue
RPUSH queue:emails "send:welcome:user:1"
BLPOP queue:emails 30  # Worker blocks waiting

# Activity feed
LPUSH feed:user:1 '{"action":"post","id":123}'
LTRIM feed:user:1 0 99  # Keep last 100

# Recent items
LPUSH recent:products:user:1 "product:123"
LRANGE recent:products:user:1 0 4  # Last 5 viewed
```

### Code Example

```typescript
// Simple queue
async function enqueue(queue: string, task: object) {
  await redis.rpush(`queue:${queue}`, JSON.stringify(task));
}

async function dequeue(queue: string, timeout = 30) {
  const result = await redis.blpop(`queue:${queue}`, timeout);
  return result ? JSON.parse(result[1]) : null;
}

// Activity feed
async function addActivity(userId: string, activity: object) {
  const key = `feed:${userId}`;
  await redis.lpush(key, JSON.stringify(activity));
  await redis.ltrim(key, 0, 99); // Keep last 100
}
```

---

## 4. Sets

### Basic Operations

```redis
# Add members
SADD tags:post:1 "javascript" "redis" "tutorial"

# Check membership
SISMEMBER tags:post:1 "redis"  # 1 (true) or 0 (false)

# Get all members
SMEMBERS tags:post:1

# Remove member
SREM tags:post:1 "tutorial"

# Set operations
SINTER tags:post:1 tags:post:2     # Intersection
SUNION tags:post:1 tags:post:2     # Union
SDIFF tags:post:1 tags:post:2      # Difference

# Random member
SRANDMEMBER tags:post:1
SPOP tags:post:1                   # Remove and return
```

### Use Cases

```redis
# Tags
SADD tags:post:1 "redis" "cache" "database"
SMEMBERS tags:post:1

# Unique visitors
SADD visitors:2024-01-15 "user:1" "user:2" "user:3"
SCARD visitors:2024-01-15  # Count unique

# Online users
SADD online:users "user:1"
SREM online:users "user:1"
SISMEMBER online:users "user:1"

# Followers
SADD followers:user:1 "user:2" "user:3"
SADD following:user:2 "user:1"
SINTER followers:user:1 followers:user:2  # Mutual followers
```

### Code Example

```typescript
// Unique tracking
async function trackVisitor(date: string, userId: string) {
  await redis.sadd(`visitors:${date}`, userId);
}

async function getUniqueVisitors(date: string) {
  return redis.scard(`visitors:${date}`);
}

// Tags
async function addTags(postId: string, tags: string[]) {
  await redis.sadd(`tags:post:${postId}`, ...tags);
}

async function findPostsByTag(tag: string) {
  return redis.smembers(`posts:tag:${tag}`);
}
```

---

## 5. Sorted Sets

### Basic Operations

```redis
# Add with score
ZADD leaderboard 100 "user:1" 85 "user:2" 90 "user:3"

# Get by rank (ascending)
ZRANGE leaderboard 0 9               # Top 10 lowest
ZREVRANGE leaderboard 0 9            # Top 10 highest

# Get with scores
ZREVRANGE leaderboard 0 9 WITHSCORES

# Get by score range
ZRANGEBYSCORE leaderboard 80 100     # Score 80-100

# Increment score
ZINCRBY leaderboard 5 "user:1"       # Add 5 points

# Get rank
ZREVRANK leaderboard "user:1"        # 0-indexed position
ZSCORE leaderboard "user:1"          # Get score
```

### Use Cases

```redis
# Leaderboard
ZADD game:leaderboard 1500 "player:1"
ZINCRBY game:leaderboard 100 "player:1"  # Won game
ZREVRANGE game:leaderboard 0 9 WITHSCORES

# Time-based events
ZADD events:scheduled 1704067200 "event:1"  # Unix timestamp
ZRANGEBYSCORE events:scheduled 0 NOW        # Get due events
ZREM events:scheduled "event:1"              # Remove processed

# Rate limiting (sliding window)
ZADD requests:user:1 NOW "request:uuid"
ZREMRANGEBYSCORE requests:user:1 0 (NOW-60)  # Remove old
ZCARD requests:user:1                         # Count recent
```

### Code Example

```typescript
// Leaderboard
async function addScore(userId: string, points: number) {
  await redis.zincrby('leaderboard', points, userId);
}

async function getTopPlayers(count = 10) {
  return redis.zrevrange('leaderboard', 0, count - 1, 'WITHSCORES');
}

async function getPlayerRank(userId: string) {
  const rank = await redis.zrevrank('leaderboard', userId);
  const score = await redis.zscore('leaderboard', userId);
  return { rank: rank !== null ? rank + 1 : null, score };
}

// Sliding window rate limiter
async function checkRateLimit(userId: string, limit: number, window: number) {
  const key = `ratelimit:${userId}`;
  const now = Date.now();
  const windowStart = now - window * 1000;

  await redis.zremrangebyscore(key, 0, windowStart);
  const count = await redis.zcard(key);

  if (count >= limit) return false;

  await redis.zadd(key, now, `${now}:${Math.random()}`);
  await redis.expire(key, window);
  return true;
}
```

---

## 6. Streams

### Basic Operations

```redis
# Add entry
XADD events:orders * action "created" order_id "123"

# Read entries
XREAD STREAMS events:orders 0          # From beginning
XREAD BLOCK 5000 STREAMS events:orders $  # Wait for new

# Consumer groups
XGROUP CREATE events:orders workers $ MKSTREAM
XREADGROUP GROUP workers worker1 COUNT 1 STREAMS events:orders >
XACK events:orders workers <message-id>

# Get range
XRANGE events:orders - +               # All entries
XRANGE events:orders - + COUNT 10      # Last 10
```

### Code Example

```typescript
// Event producer
async function publishEvent(stream: string, event: object) {
  return redis.xadd(stream, '*', event);
}

// Event consumer
async function consumeEvents(stream: string, group: string, consumer: string) {
  const entries = await redis.xreadgroup(
    'GROUP', group, consumer,
    'COUNT', 10,
    'STREAMS', stream, '>'
  );

  for (const [id, fields] of entries || []) {
    await processEvent(fields);
    await redis.xack(stream, group, id);
  }
}
```

---

## 7. Key Design Patterns

### Naming Conventions

```
# Pattern: type:id:field
user:123:profile
user:123:settings
session:abc123
cache:api:users:list

# Pattern: type:entity:id
cart:user:123
feed:user:123
notifications:user:123

# Pattern: resource:date
visits:2024-01-15
events:2024-01-15:hour:14
```

### TTL Strategy

```redis
# Set TTL on creation
SET cache:user:1 "{...}" EX 300

# Update TTL
EXPIRE cache:user:1 300

# Check TTL
TTL cache:user:1

# Persist (remove TTL)
PERSIST cache:user:1
```

## References

- [Redis Data Types](https://redis.io/docs/data-types/)
- [Redis Commands](https://redis.io/commands/)
