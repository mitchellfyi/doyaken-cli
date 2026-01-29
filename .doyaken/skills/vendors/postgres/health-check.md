---
name: postgres:health-check
description: PostgreSQL database health and performance check
args:
  - name: verbose
    description: Include detailed metrics
    default: "false"
---

# PostgreSQL Health Check

You are performing a health check on a PostgreSQL database.

## Context

Project: {{DOYAKEN_PROJECT}}
Verbose: {{ARGS.verbose}}

## Health Check Process

### 1. Connection Status

```sql
-- Active connections
SELECT
  datname,
  count(*) as connections,
  state
FROM pg_stat_activity
GROUP BY datname, state;

-- Connection limit
SHOW max_connections;
```

### 2. Database Size

{{include:vendors/postgres/operations.md}}

```sql
-- Database size
SELECT
  pg_database.datname,
  pg_size_pretty(pg_database_size(pg_database.datname)) as size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;

-- Table sizes
SELECT
  relname,
  pg_size_pretty(pg_total_relation_size(relid)) as total_size,
  pg_size_pretty(pg_relation_size(relid)) as table_size,
  pg_size_pretty(pg_indexes_size(relid)) as index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
```

### 3. Cache Performance

```sql
-- Cache hit ratio (should be > 99%)
SELECT
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit) as heap_hit,
  round(
    sum(heap_blks_hit) * 100.0 /
    nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
  ) as cache_hit_ratio
FROM pg_statio_user_tables;

-- Index cache hit ratio
SELECT
  sum(idx_blks_read) as idx_read,
  sum(idx_blks_hit) as idx_hit,
  round(
    sum(idx_blks_hit) * 100.0 /
    nullif(sum(idx_blks_hit) + sum(idx_blks_read), 0), 2
  ) as index_hit_ratio
FROM pg_statio_user_indexes;
```

### 4. Vacuum Status

```sql
-- Tables needing vacuum
SELECT
  relname,
  last_vacuum,
  last_autovacuum,
  n_dead_tup,
  n_live_tup,
  round(n_dead_tup * 100.0 / nullif(n_live_tup, 0), 2) as dead_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;
```

### 5. Index Health

```sql
-- Unused indexes
SELECT
  relname,
  indexrelname,
  idx_scan,
  pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexrelname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Index bloat (simplified)
SELECT
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexname::regclass)) as size
FROM pg_indexes
WHERE schemaname = 'public';
```

### 6. Slow Queries

```sql
-- Slow queries (requires pg_stat_statements)
SELECT
  calls,
  round(total_exec_time::numeric, 2) as total_time_ms,
  round(mean_exec_time::numeric, 2) as mean_time_ms,
  query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 7. Lock Issues

```sql
-- Current locks
SELECT
  pid,
  locktype,
  relation::regclass,
  mode,
  granted
FROM pg_locks
WHERE NOT granted;
```

## Output

```markdown
## Database Health Report

**Database**: [name]
**Version**: [PostgreSQL version]
**Checked**: [timestamp]

### Overall Status: [Good/Warning/Critical]

### Key Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Cache Hit Ratio | [X]% | [OK/Warning] |
| Connections | [X]/[max] | [OK/Warning] |
| Database Size | [X GB] | [Info] |
| Dead Tuples | [X] | [OK/Warning] |

### Issues Found

#### Critical
- [None or list of critical issues]

#### Warnings
- [List of warnings]

### Recommendations

1. **[Category]**: [Recommendation]
   ```sql
   [SQL to fix]
   ```

### Detailed Metrics

{{#if verbose == "true"}}
#### Table Statistics
| Table | Size | Dead Tuples | Last Vacuum |
|-------|------|-------------|-------------|
| [table] | [size] | [count] | [date] |

#### Index Statistics
| Index | Size | Scans | Usage |
|-------|------|-------|-------|
| [index] | [size] | [count] | [high/low] |

#### Top Slow Queries
| Query | Avg Time | Calls |
|-------|----------|-------|
| [query] | [Xms] | [count] |
{{/if}}

### Action Items
- [ ] [Action 1]
- [ ] [Action 2]
- [ ] Schedule next health check
```
