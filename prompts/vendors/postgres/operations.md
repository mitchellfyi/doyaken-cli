# PostgreSQL Operations

Database administration, maintenance, and operational best practices.

## When to Apply

Activate this guide when:
- Managing PostgreSQL servers
- Performing maintenance tasks
- Troubleshooting issues
- Setting up monitoring

---

## 1. Configuration

### Key Settings

```ini
# postgresql.conf

# Memory
shared_buffers = 256MB           # 25% of RAM (up to 8GB)
effective_cache_size = 768MB     # 75% of RAM
work_mem = 16MB                  # Per-operation memory
maintenance_work_mem = 128MB     # For VACUUM, CREATE INDEX

# Connections
max_connections = 100
connection_timeout = 30000       # 30 seconds

# Write-Ahead Log
wal_level = replica              # For replication
max_wal_size = 1GB
min_wal_size = 80MB

# Query Planning
random_page_cost = 1.1           # SSD (4.0 for HDD)
effective_io_concurrency = 200   # SSD (2 for HDD)

# Logging
log_min_duration_statement = 1000  # Log queries > 1 second
log_line_prefix = '%t [%p]: '
log_checkpoints = on
log_connections = on
log_disconnections = on

# Autovacuum
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 60
```

### Connection Pooling

```ini
# PgBouncer configuration (pgbouncer.ini)
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_addr = *
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
```

---

## 2. Backup & Recovery

### pg_dump

```bash
# Full database backup
pg_dump -h localhost -U postgres -d mydb -F c -f backup.dump

# Schema only
pg_dump -h localhost -U postgres -d mydb --schema-only -f schema.sql

# Data only
pg_dump -h localhost -U postgres -d mydb --data-only -f data.sql

# Specific tables
pg_dump -h localhost -U postgres -d mydb -t users -t orders -f tables.dump

# Exclude tables
pg_dump -h localhost -U postgres -d mydb -T audit_log -f backup.dump

# Restore
pg_restore -h localhost -U postgres -d mydb backup.dump

# Restore with create
pg_restore -h localhost -U postgres -C -d postgres backup.dump
```

### Continuous Archiving (WAL)

```bash
# postgresql.conf
archive_mode = on
archive_command = 'cp %p /archive/%f'
wal_level = replica

# Base backup
pg_basebackup -h localhost -U replication -D /backup/base -Fp -Xs -P

# Point-in-time recovery (recovery.conf or postgresql.auto.conf)
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2024-01-15 14:30:00'
recovery_target_action = 'promote'
```

### Backup Script

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="mydb"

# Create backup
pg_dump -h localhost -U postgres -d $DB_NAME -F c \
  -f "$BACKUP_DIR/${DB_NAME}_${DATE}.dump"

# Compress
gzip "$BACKUP_DIR/${DB_NAME}_${DATE}.dump"

# Remove backups older than 7 days
find $BACKUP_DIR -name "*.dump.gz" -mtime +7 -delete

# Verify backup
pg_restore --list "$BACKUP_DIR/${DB_NAME}_${DATE}.dump.gz" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Backup verified successfully"
else
  echo "Backup verification failed!" >&2
  exit 1
fi
```

---

## 3. Maintenance

### Vacuum

```sql
-- Regular vacuum (non-blocking)
VACUUM VERBOSE users;

-- Vacuum with analyze
VACUUM ANALYZE users;

-- Full vacuum (locks table, rewrites)
VACUUM FULL users;

-- Vacuum all tables
VACUUM;

-- Check vacuum status
SELECT
  relname,
  last_vacuum,
  last_autovacuum,
  vacuum_count,
  autovacuum_count,
  n_dead_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### Reindex

```sql
-- Reindex single index
REINDEX INDEX users_email_idx;

-- Reindex table
REINDEX TABLE users;

-- Reindex database
REINDEX DATABASE mydb;

-- Concurrent reindex (no locks)
REINDEX INDEX CONCURRENTLY users_email_idx;
```

### Analyze

```sql
-- Update statistics
ANALYZE users;

-- All tables
ANALYZE;

-- Verbose output
ANALYZE VERBOSE users;

-- Check statistics
SELECT
  attname,
  n_distinct,
  most_common_vals,
  most_common_freqs
FROM pg_stats
WHERE tablename = 'users';
```

---

## 4. Monitoring

### Active Queries

```sql
-- Current activity
SELECT
  pid,
  usename,
  application_name,
  state,
  query_start,
  NOW() - query_start as duration,
  query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Long running queries (> 5 minutes)
SELECT
  pid,
  NOW() - query_start as duration,
  query
FROM pg_stat_activity
WHERE state = 'active'
  AND NOW() - query_start > interval '5 minutes';

-- Kill query
SELECT pg_cancel_backend(pid);     -- Graceful
SELECT pg_terminate_backend(pid);  -- Force
```

### Locks

```sql
-- View locks
SELECT
  l.pid,
  l.locktype,
  l.mode,
  l.granted,
  a.usename,
  a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.granted;

-- Lock conflicts
SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity
  ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### Database Size

```sql
-- Database size
SELECT pg_size_pretty(pg_database_size('mydb'));

-- Table sizes
SELECT
  relname as table,
  pg_size_pretty(pg_total_relation_size(relid)) as total,
  pg_size_pretty(pg_relation_size(relid)) as table,
  pg_size_pretty(pg_indexes_size(relid)) as indexes
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Index sizes
SELECT
  indexrelname as index,
  pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Cache Hit Ratio

```sql
-- Should be > 99% for good performance
SELECT
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit) as heap_hit,
  round(sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100, 2) as ratio
FROM pg_statio_user_tables;
```

---

## 5. Replication

### Streaming Replication

```bash
# Primary (postgresql.conf)
wal_level = replica
max_wal_senders = 3
wal_keep_size = 1GB

# Primary (pg_hba.conf)
host replication replicator replica_ip/32 scram-sha-256

# Create replication user
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'password';

# Replica setup
pg_basebackup -h primary_ip -U replicator -D /var/lib/postgresql/data -Fp -Xs -P

# Replica (postgresql.auto.conf)
primary_conninfo = 'host=primary_ip user=replicator password=password'
```

### Check Replication Status

```sql
-- On primary
SELECT
  client_addr,
  state,
  sent_lsn,
  write_lsn,
  flush_lsn,
  replay_lsn
FROM pg_stat_replication;

-- On replica
SELECT
  pg_is_in_recovery(),
  pg_last_wal_receive_lsn(),
  pg_last_wal_replay_lsn(),
  pg_last_xact_replay_timestamp();

-- Replication lag
SELECT
  EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::INT as lag_seconds;
```

---

## 6. Security

### User Management

```sql
-- Create user
CREATE USER appuser WITH PASSWORD 'secure_password';

-- Grant privileges
GRANT CONNECT ON DATABASE mydb TO appuser;
GRANT USAGE ON SCHEMA public TO appuser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO appuser;

-- Set default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;

-- Read-only user
CREATE USER readonly WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE mydb TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
```

### SSL Configuration

```ini
# postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ca_file = 'ca.crt'

# pg_hba.conf (require SSL)
hostssl all all 0.0.0.0/0 scram-sha-256
```

---

## Quick Reference

```bash
# Backup
pg_dump -F c dbname > backup.dump
pg_restore -d dbname backup.dump

# Maintenance
vacuumdb -z dbname
reindexdb dbname

# Connect
psql -h host -U user -d dbname

# Status
pg_isready -h localhost
```

```sql
-- Quick checks
SELECT version();
SELECT current_database();
SELECT current_user;
SHOW data_directory;
SHOW config_file;
```

## References

- [PostgreSQL Administration](https://www.postgresql.org/docs/current/admin.html)
- [Backup and Restore](https://www.postgresql.org/docs/current/backup.html)
- [High Availability](https://www.postgresql.org/docs/current/high-availability.html)
