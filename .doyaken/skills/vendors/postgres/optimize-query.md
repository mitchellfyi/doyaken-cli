---
name: postgres:optimize-query
description: Analyze and optimize slow PostgreSQL queries
args:
  - name: query
    description: SQL query to optimize
    default: ""
  - name: threshold
    description: Slow query threshold in ms
    default: "100"
---

# PostgreSQL Query Optimization

You are analyzing and optimizing PostgreSQL queries.

## Context

Project: {{DOYAKEN_PROJECT}}
Query: {{ARGS.query}}
Threshold: {{ARGS.threshold}}ms

## Optimization Process

### 1. Analyze Query Plan

{{include:vendors/postgres/optimization.md}}

Run EXPLAIN ANALYZE:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
{{ARGS.query}};
```

Look for:
- **Seq Scan**: Full table scans (need index?)
- **Nested Loop**: O(n*m) joins (need better join?)
- **Sort**: Memory sorts (need index for ORDER BY?)
- **Hash Join**: Large hash tables (memory issue?)

### 2. Check Index Usage

```sql
-- Available indexes on tables in query
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename IN ([tables from query]);

-- Index usage stats
SELECT
  relname,
  indexrelname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname IN ([tables from query]);
```

### 3. Identify Bottlenecks

Common issues:
- Missing indexes on WHERE/JOIN columns
- Selecting too many columns (SELECT *)
- N+1 query patterns
- Inefficient JOINs
- Missing LIMIT for large results

### 4. Apply Optimizations

**Add Missing Index**:
```sql
CREATE INDEX CONCURRENTLY idx_table_column
ON table_name (column_name);
```

**Rewrite Query**:
- Use specific columns instead of *
- Add appropriate WHERE clauses
- Use EXISTS instead of IN for subqueries
- Consider CTEs for complex queries

**Partial Index** (for filtered queries):
```sql
CREATE INDEX idx_active_users
ON users (email)
WHERE status = 'active';
```

**Composite Index** (for multi-column queries):
```sql
CREATE INDEX idx_user_status_created
ON users (status, created_at DESC);
```

### 5. Verify Improvement

Run EXPLAIN ANALYZE again and compare:
- Execution time
- Buffer usage
- Scan types

## Output

```markdown
## Query Optimization Report

**Original Query Time**: [X]ms
**Optimized Query Time**: [Y]ms
**Improvement**: [Z]%

### Analysis

**Execution Plan Issues**:
- [Issue 1]: [Description]
- [Issue 2]: [Description]

### Recommendations

1. **Add Index**
   ```sql
   CREATE INDEX CONCURRENTLY [index_name] ON [table] ([columns]);
   ```

2. **Rewrite Query**
   ```sql
   -- Optimized query
   [rewritten SQL]
   ```

### Before/After

| Metric | Before | After |
|--------|--------|-------|
| Execution Time | [X]ms | [Y]ms |
| Rows Scanned | [X] | [Y] |
| Buffer Hits | [X] | [Y] |
| Scan Type | Seq Scan | Index Scan |

### Implementation
- [ ] Create recommended indexes
- [ ] Update application query
- [ ] Monitor performance
- [ ] ANALYZE affected tables
```
