# PostgreSQL Optimization

Query optimization, indexing strategies, and performance tuning.

## When to Apply

Activate this guide when:
- Optimizing slow queries
- Designing indexes
- Tuning database performance
- Analyzing query plans

---

## 1. Query Analysis

### Using EXPLAIN

```sql
-- Basic explain
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- With execution stats (actually runs query)
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- Full details
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM users WHERE email = 'test@example.com';

-- JSON output for programmatic analysis
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM users WHERE email = 'test@example.com';
```

### Reading Query Plans

```
Key metrics to check:
- Seq Scan vs Index Scan (Index is usually better for large tables)
- Rows (estimated vs actual)
- Loops (watch for high loop counts)
- Buffers (shared hit vs shared read)
- Planning Time vs Execution Time
```

```sql
-- Example plan interpretation
                                    QUERY PLAN
---------------------------------------------------------------------------
Index Scan using users_email_idx on users  (cost=0.42..8.44 rows=1 width=40)
                                           (actual time=0.025..0.026 rows=1 loops=1)
  Index Cond: (email = 'test@example.com'::text)
  Buffers: shared hit=3
Planning Time: 0.080 ms
Execution Time: 0.045 ms
```

### Identifying Problems

```sql
-- Seq Scan on large table = missing index
Seq Scan on users  (cost=0.00..1234567.00 rows=10000000 width=40)

-- High loops = N+1 query pattern
Nested Loop  (cost=...)
  -> Index Scan ...  (actual time=... loops=10000)

-- Bitmap Heap Scan with high rows removed = poor selectivity
Bitmap Heap Scan on orders
  Rows Removed by Index Recheck: 50000
```

---

## 2. Index Types

### B-Tree (Default)

```sql
-- Best for: equality and range queries
CREATE INDEX users_email_idx ON users(email);
CREATE INDEX orders_date_idx ON orders(created_at);

-- Use for:
WHERE email = 'test@example.com'
WHERE created_at > '2024-01-01'
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY created_at
```

### Hash

```sql
-- Best for: exact equality only (=)
CREATE INDEX users_email_hash_idx ON users USING HASH(email);

-- Faster than B-tree for equality, but:
-- - No range queries
-- - No ORDER BY
-- - Less commonly used
```

### GIN (Generalized Inverted Index)

```sql
-- Best for: arrays, JSONB, full-text search
CREATE INDEX posts_tags_idx ON posts USING GIN(tags);
CREATE INDEX users_metadata_idx ON users USING GIN(metadata);
CREATE INDEX posts_search_idx ON posts USING GIN(to_tsvector('english', title || ' ' || content));

-- Use for:
WHERE tags @> ARRAY['postgresql']
WHERE metadata @> '{"role": "admin"}'
WHERE to_tsvector('english', content) @@ to_tsquery('postgresql')
```

### GiST (Generalized Search Tree)

```sql
-- Best for: geometric data, ranges, full-text
CREATE INDEX locations_geom_idx ON locations USING GIST(geom);
CREATE INDEX reservations_during_idx ON reservations USING GIST(during);

-- Use for:
WHERE geom && ST_MakeEnvelope(...)
WHERE during && '[2024-01-01, 2024-01-31]'::daterange
```

### BRIN (Block Range Index)

```sql
-- Best for: large tables with naturally ordered data (time-series)
CREATE INDEX events_created_brin_idx ON events USING BRIN(created_at);

-- Much smaller than B-tree for append-only tables
-- Works well when data is physically ordered
```

---

## 3. Index Strategies

### Composite Indexes

```sql
-- Column order matters!
CREATE INDEX orders_user_date_idx ON orders(user_id, created_at);

-- Works for:
WHERE user_id = 1                           -- ✓ Uses index
WHERE user_id = 1 AND created_at > '...'    -- ✓ Uses both columns
WHERE user_id = 1 ORDER BY created_at       -- ✓ Efficient

-- Does NOT work efficiently:
WHERE created_at > '...'                    -- ✗ Can't use index
ORDER BY created_at                         -- ✗ Wrong column first
```

### Partial Indexes

```sql
-- Index only relevant rows
CREATE INDEX orders_pending_idx ON orders(created_at)
WHERE status = 'pending';

-- Much smaller, faster for specific queries
SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at;
```

### Expression Indexes

```sql
-- Index computed values
CREATE INDEX users_email_lower_idx ON users(LOWER(email));

-- Use for:
WHERE LOWER(email) = 'test@example.com'

-- Common patterns:
CREATE INDEX orders_date_idx ON orders(DATE(created_at));
CREATE INDEX users_name_search_idx ON users(LOWER(first_name || ' ' || last_name));
```

### Covering Indexes (INCLUDE)

```sql
-- Include non-key columns to enable index-only scans
CREATE INDEX orders_user_idx ON orders(user_id)
INCLUDE (total, status);

-- Query can be satisfied from index alone:
SELECT total, status FROM orders WHERE user_id = 1;
```

---

## 4. Query Optimization

### Avoid Seq Scans

```sql
-- BAD: Function on indexed column
WHERE YEAR(created_at) = 2024

-- GOOD: Range query
WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'

-- BAD: Type mismatch
WHERE id = '123'  -- id is integer

-- GOOD: Correct type
WHERE id = 123
```

### Fix N+1 Queries

```sql
-- BAD: Query per row
FOR user_id IN user_ids LOOP
  SELECT * FROM orders WHERE user_id = user_id;
END LOOP;

-- GOOD: Single query with IN
SELECT * FROM orders WHERE user_id = ANY(user_ids);

-- GOOD: JOIN
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.id = ANY(user_ids);
```

### Optimize JOINs

```sql
-- Ensure join columns are indexed
CREATE INDEX orders_user_id_idx ON orders(user_id);

-- Use EXISTS instead of IN for large subqueries
-- BAD:
SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE total > 100);

-- GOOD:
SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.total > 100);
```

### Pagination

```sql
-- BAD: OFFSET for deep pages
SELECT * FROM posts ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- GOOD: Keyset pagination
SELECT * FROM posts
WHERE created_at < '2024-01-15T10:30:00'
ORDER BY created_at DESC
LIMIT 20;

-- Store last seen value, use in next query
```

---

## 5. Statistics & Maintenance

### Update Statistics

```sql
-- Analyze specific table
ANALYZE users;

-- Analyze all tables
ANALYZE;

-- Set statistics target for specific column
ALTER TABLE users ALTER COLUMN status SET STATISTICS 1000;
ANALYZE users;
```

### Vacuum

```sql
-- Regular vacuum (reclaim space, update stats)
VACUUM users;

-- Full vacuum (rewrites table, locks it)
VACUUM FULL users;

-- Vacuum with analyze
VACUUM ANALYZE users;

-- Check vacuum stats
SELECT relname, last_vacuum, last_autovacuum, last_analyze
FROM pg_stat_user_tables;
```

### Reindex

```sql
-- Rebuild bloated index
REINDEX INDEX users_email_idx;

-- Rebuild all indexes on table
REINDEX TABLE users;

-- Concurrent reindex (no locks, PG12+)
REINDEX INDEX CONCURRENTLY users_email_idx;
```

---

## 6. Monitoring

### Slow Queries

```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find slowest queries by total time
SELECT
  calls,
  total_exec_time::numeric(10,2) as total_ms,
  mean_exec_time::numeric(10,2) as avg_ms,
  query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Find queries with most calls
SELECT
  calls,
  mean_exec_time::numeric(10,2) as avg_ms,
  query
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```

### Index Usage

```sql
-- Find unused indexes
SELECT
  schemaname,
  relname as table,
  indexrelname as index,
  idx_scan as scans,
  pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find missing indexes (seq scans on large tables)
SELECT
  relname as table,
  seq_scan,
  seq_tup_read,
  idx_scan,
  n_live_tup as rows
FROM pg_stat_user_tables
WHERE seq_scan > 0
  AND n_live_tup > 10000
ORDER BY seq_tup_read DESC;
```

### Table Bloat

```sql
-- Check table bloat
SELECT
  relname as table,
  pg_size_pretty(pg_total_relation_size(relid)) as total_size,
  pg_size_pretty(pg_relation_size(relid)) as table_size,
  n_dead_tup as dead_rows,
  n_live_tup as live_rows,
  round(n_dead_tup::numeric / nullif(n_live_tup, 0) * 100, 2) as dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

---

## Optimization Checklist

### Before Production

- [ ] All WHERE clause columns have indexes
- [ ] JOIN columns are indexed
- [ ] Composite indexes match query patterns
- [ ] No unnecessary indexes
- [ ] Statistics are up to date
- [ ] Query plans reviewed for critical queries

### Ongoing

- [ ] Monitor slow query log
- [ ] Review pg_stat_statements weekly
- [ ] Check for index bloat
- [ ] Verify autovacuum is running
- [ ] Review unused indexes quarterly

## References

- [PostgreSQL EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html)
- [Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
- [Performance Tips](https://www.postgresql.org/docs/current/performance-tips.html)
