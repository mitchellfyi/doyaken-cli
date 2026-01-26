# Dokku Plugins

Database and service plugins for Dokku.

## When to Apply

Activate this guide when:
- Setting up databases
- Configuring Redis/caching
- Managing backing services
- Connecting services to apps

---

## 1. Plugin Management

### Installing Plugins

```bash
# Official plugins
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git
sudo dokku plugin:install https://github.com/dokku/dokku-mysql.git
sudo dokku plugin:install https://github.com/dokku/dokku-mongo.git
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# List installed plugins
dokku plugin:list

# Update plugins
sudo dokku plugin:update

# Uninstall
sudo dokku plugin:uninstall postgres
```

---

## 2. PostgreSQL

### Setup

```bash
# Install plugin
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git

# Create service
dokku postgres:create mydb

# Link to app (sets DATABASE_URL)
dokku postgres:link mydb myapp

# View connection info
dokku postgres:info mydb
```

### Management

```bash
# Access psql
dokku postgres:connect mydb

# Run SQL file
dokku postgres:connect mydb < backup.sql

# Export database
dokku postgres:export mydb > backup.sql

# Import database
dokku postgres:import mydb < backup.sql

# View logs
dokku postgres:logs mydb -t
```

### Backup & Restore

```bash
# Manual backup
dokku postgres:export mydb > $(date +%Y%m%d)-mydb.sql

# Scheduled backups (cron)
# /etc/cron.daily/dokku-postgres-backup
#!/bin/bash
dokku postgres:export mydb | gzip > /backups/mydb-$(date +%Y%m%d).sql.gz

# Restore
gunzip -c backup.sql.gz | dokku postgres:import mydb
```

### PostGIS Extension

```bash
# Use PostGIS image
dokku postgres:create mydb --image "postgis/postgis" --image-version "15-3.3"

# Enable extension in database
dokku postgres:connect mydb
# CREATE EXTENSION postgis;
```

### pgvector Extension

```bash
# Use pgvector image
dokku postgres:create vectordb --image "pgvector/pgvector" --image-version "pg16"
```

---

## 3. Redis

### Setup

```bash
# Install plugin
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git

# Create service
dokku redis:create myredis

# Link to app (sets REDIS_URL)
dokku redis:link myredis myapp

# View info
dokku redis:info myredis
```

### Management

```bash
# Access redis-cli
dokku redis:connect myredis

# Export/Import
dokku redis:export myredis > redis-backup.rdb
dokku redis:import myredis < redis-backup.rdb

# View logs
dokku redis:logs myredis -t
```

### Configuration

```bash
# Set max memory
dokku redis:set myredis maxmemory 256mb
dokku redis:set myredis maxmemory-policy allkeys-lru
```

---

## 4. MySQL/MariaDB

### Setup

```bash
# Install plugin
sudo dokku plugin:install https://github.com/dokku/dokku-mysql.git

# Create service
dokku mysql:create mydb

# Link to app (sets DATABASE_URL)
dokku mysql:link mydb myapp
```

### Management

```bash
# Access mysql client
dokku mysql:connect mydb

# Export/Import
dokku mysql:export mydb > backup.sql
dokku mysql:import mydb < backup.sql
```

---

## 5. MongoDB

### Setup

```bash
# Install plugin
sudo dokku plugin:install https://github.com/dokku/dokku-mongo.git

# Create service
dokku mongo:create mydb

# Link to app (sets MONGO_URL)
dokku mongo:link mydb myapp
```

---

## 6. Service Patterns

### Linking Services

```bash
# Link creates environment variable automatically
dokku postgres:link mydb myapp
# Creates: DATABASE_URL=postgres://user:pass@dokku-postgres-mydb:5432/mydb

# Custom environment variable name
dokku postgres:link mydb myapp --alias POSTGRES_URL

# Multiple apps can share a service
dokku postgres:link mydb app1
dokku postgres:link mydb app2
```

### Unlinking Services

```bash
# Unlink (removes environment variable)
dokku postgres:unlink mydb myapp

# Destroy service (removes data!)
dokku postgres:destroy mydb
```

### Service Networking

```bash
# Services are on internal network
# Access from app by service name:
# postgres://dokku-postgres-mydb:5432/mydb
# redis://dokku-redis-myredis:6379

# For external access (not recommended for production):
dokku postgres:expose mydb 5432
dokku postgres:unexpose mydb
```

---

## 7. Custom Images

### Using Custom Docker Images

```bash
# Create with custom image
dokku postgres:create mydb \
  --image "postgres" \
  --image-version "15-alpine"

# Custom environment
export POSTGRES_CUSTOM_ENV="shared_preload_libraries=pg_stat_statements"
dokku postgres:create mydb
```

### Supported Image Options

```bash
# PostgreSQL
--image "postgres" | "postgis/postgis" | "pgvector/pgvector"
--image-version "15" | "16-alpine" | etc.

# Redis
--image "redis" | "valkey/valkey"
--image-version "7-alpine"

# MySQL
--image "mysql" | "mariadb"
--image-version "8.0" | "10.11"
```

---

## 8. Production Patterns

### High Availability Notes

Dokku is single-host by design. For HA:

- Use managed databases (RDS, Cloud SQL)
- Use external Redis (ElastiCache, Redis Cloud)
- Dokku handles app HA via process scaling

### External Database

```bash
# Just set the URL directly
dokku config:set myapp DATABASE_URL=postgres://user:pass@rds-host:5432/db

# No need for dokku-postgres plugin for external DBs
```

### Backup Strategy

```bash
#!/bin/bash
# /etc/cron.daily/dokku-backup

BACKUP_DIR=/backups
DATE=$(date +%Y%m%d)

# Postgres
for db in $(dokku postgres:list | tail -n +2); do
  dokku postgres:export $db | gzip > $BACKUP_DIR/postgres-$db-$DATE.sql.gz
done

# Redis
for redis in $(dokku redis:list | tail -n +2); do
  dokku redis:export $redis > $BACKUP_DIR/redis-$redis-$DATE.rdb
done

# Cleanup old backups (keep 7 days)
find $BACKUP_DIR -type f -mtime +7 -delete

# Optional: sync to S3
aws s3 sync $BACKUP_DIR s3://mybucket/backups/
```

---

## Quick Reference

```bash
# PostgreSQL
dokku postgres:create <name>
dokku postgres:link <name> <app>
dokku postgres:connect <name>
dokku postgres:export <name> > backup.sql
dokku postgres:import <name> < backup.sql

# Redis
dokku redis:create <name>
dokku redis:link <name> <app>
dokku redis:connect <name>

# MySQL
dokku mysql:create <name>
dokku mysql:link <name> <app>

# Common operations
dokku <plugin>:info <name>
dokku <plugin>:logs <name> -t
dokku <plugin>:unlink <name> <app>
dokku <plugin>:destroy <name>
```

## References

- [Dokku Postgres](https://github.com/dokku/dokku-postgres)
- [Dokku Redis](https://github.com/dokku/dokku-redis)
- [Dokku MySQL](https://github.com/dokku/dokku-mysql)
- [Community Plugins](https://dokku.com/docs/community/plugins/)
