# DigitalOcean App Platform

Managed PaaS for deploying applications.

## When to Apply

Activate this guide when:
- Deploying applications to App Platform
- Setting up CI/CD with App Platform
- Configuring app components
- Managing environments

---

## 1. App Types

### Supported Components

| Type | Description | Use Case |
|------|-------------|----------|
| Service | Long-running HTTP service | Web apps, APIs |
| Worker | Background process | Queue processors, schedulers |
| Static Site | Static files served via CDN | Marketing sites, SPAs |
| Job | One-time or scheduled task | Migrations, cron jobs |
| Database | Managed database | Data storage |

### Supported Languages

- Node.js
- Python
- Go
- Ruby
- PHP
- Rust
- Docker (any language)

---

## 2. App Specification

### Basic App Spec

```yaml
# .do/app.yaml
name: myapp
region: nyc

services:
  - name: api
    github:
      repo: myorg/myapp
      branch: main
      deploy_on_push: true
    source_dir: /api
    build_command: npm run build
    run_command: npm start
    http_port: 3000
    instance_size_slug: professional-xs
    instance_count: 2
    health_check:
      http_path: /health
    envs:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        type: SECRET
        value: ${db.DATABASE_URL}

  - name: web
    github:
      repo: myorg/myapp
      branch: main
    source_dir: /web
    build_command: npm run build
    environment_slug: node-js
    http_port: 3000

workers:
  - name: queue-worker
    github:
      repo: myorg/myapp
      branch: main
    source_dir: /worker
    run_command: npm run worker
    instance_count: 1

static_sites:
  - name: landing
    github:
      repo: myorg/landing
      branch: main
    build_command: npm run build
    output_dir: dist

jobs:
  - name: migrate
    github:
      repo: myorg/myapp
      branch: main
    source_dir: /api
    run_command: npm run migrate
    kind: PRE_DEPLOY

databases:
  - name: db
    engine: PG
    version: "15"
    size: db-s-1vcpu-1gb
    num_nodes: 1
```

### Environment Variables

```yaml
envs:
  # Plain value
  - key: NODE_ENV
    value: production

  # Secret (hidden in UI)
  - key: API_KEY
    type: SECRET
    value: sk-xxxxx

  # From database
  - key: DATABASE_URL
    type: SECRET
    value: ${db.DATABASE_URL}

  # Component-scoped
  - key: REDIS_URL
    scope: RUN_AND_BUILD_TIME
    value: redis://...
```

### Instance Sizing

```yaml
# Slug format: [basic|professional]-[xs|s|m|l|xl|xxl]
instance_size_slug: professional-xs

# Options:
# basic-xxs     - $5/mo   (512MB, 1 vCPU)
# basic-xs      - $10/mo  (1GB, 1 vCPU)
# basic-s       - $20/mo  (2GB, 1 vCPU)
# professional-xs - $25/mo (1GB, 1 vCPU)
# professional-s  - $50/mo (2GB, 1 vCPU)
# professional-m  - $100/mo (4GB, 2 vCPU)
```

---

## 3. Deployment

### CLI Deployment

```bash
# Create app from spec
doctl apps create --spec .do/app.yaml

# Update existing app
doctl apps update <app-id> --spec .do/app.yaml

# List apps
doctl apps list

# Get app info
doctl apps get <app-id>

# Trigger deployment
doctl apps create-deployment <app-id>

# View logs
doctl apps logs <app-id> --type=RUN
doctl apps logs <app-id> --type=BUILD
```

### Deployment Strategies

```yaml
# Rolling deployment (default)
# New instances start before old ones stop

# Zero-downtime guaranteed with:
services:
  - name: api
    instance_count: 2  # At least 2 instances
    health_check:
      http_path: /health
      initial_delay_seconds: 10
```

### Build & Deploy Hooks

```yaml
services:
  - name: api
    # Build phase
    build_command: npm ci && npm run build

    # Run phase
    run_command: npm start

jobs:
  # Pre-deploy (runs before new version)
  - name: migrate
    kind: PRE_DEPLOY
    run_command: npm run migrate

  # Post-deploy
  - name: notify
    kind: POST_DEPLOY
    run_command: ./notify-slack.sh
```

---

## 4. Databases

### Managed Databases

```yaml
databases:
  # PostgreSQL
  - name: db
    engine: PG
    version: "15"
    size: db-s-1vcpu-1gb
    num_nodes: 1

  # MySQL
  - name: mysql
    engine: MYSQL
    version: "8"
    size: db-s-1vcpu-1gb

  # Redis
  - name: cache
    engine: REDIS
    version: "7"
    size: db-s-1vcpu-1gb

  # MongoDB
  - name: mongo
    engine: MONGODB
    version: "6"
    size: db-s-1vcpu-1gb
```

### Database Connection

```yaml
services:
  - name: api
    envs:
      # Automatic connection string
      - key: DATABASE_URL
        value: ${db.DATABASE_URL}

      # Individual components
      - key: DB_HOST
        value: ${db.HOSTNAME}
      - key: DB_PORT
        value: ${db.PORT}
      - key: DB_USER
        value: ${db.USERNAME}
      - key: DB_PASS
        type: SECRET
        value: ${db.PASSWORD}
      - key: DB_NAME
        value: ${db.DATABASE}
```

---

## 5. Networking

### Custom Domains

```yaml
domains:
  - domain: myapp.com
    type: PRIMARY
  - domain: www.myapp.com
    type: ALIAS
```

### Routes

```yaml
services:
  - name: api
    http_port: 3000
    routes:
      - path: /api

  - name: web
    http_port: 3000
    routes:
      - path: /

static_sites:
  - name: docs
    routes:
      - path: /docs
```

### Internal Networking

```yaml
# Services can communicate internally
# Use service name as hostname
services:
  - name: api
    envs:
      - key: INTERNAL_API_URL
        value: http://api:3000
```

---

## 6. Auto-Scaling

### Horizontal Scaling

```yaml
services:
  - name: api
    instance_count: 2
    autoscaling:
      min_instance_count: 2
      max_instance_count: 10
      metrics:
        cpu:
          percent: 70
```

### Alert Rules

```yaml
alerts:
  - rule: CPU_UTILIZATION
    value: 80
    operator: GREATER_THAN
    window: FIVE_MINUTES

  - rule: DEPLOYMENT_FAILED

  - rule: DOMAIN_FAILED
```

---

## 7. CI/CD Integration

### GitHub Integration

```yaml
services:
  - name: api
    github:
      repo: myorg/myapp
      branch: main
      deploy_on_push: true  # Auto-deploy on push
```

### GitLab Integration

```yaml
services:
  - name: api
    gitlab:
      repo: myorg/myapp
      branch: main
      deploy_on_push: true
```

### Docker Registry

```yaml
services:
  - name: api
    image:
      registry_type: DOCR  # DigitalOcean Container Registry
      repository: myapp
      tag: latest
    # Or external registry
    image:
      registry_type: DOCKER_HUB
      registry: myorg
      repository: myapp
      tag: v1.0.0
```

---

## 8. Monitoring

### Logs

```bash
# View logs
doctl apps logs <app-id>

# Build logs
doctl apps logs <app-id> --type=BUILD

# Runtime logs
doctl apps logs <app-id> --type=RUN

# Follow logs
doctl apps logs <app-id> --follow

# Specific component
doctl apps logs <app-id> --component=api
```

### Metrics

Available in dashboard:
- CPU utilization
- Memory usage
- Restart count
- Response times
- Request count

---

## Quick Reference

```bash
# Apps
doctl apps create --spec app.yaml
doctl apps update <id> --spec app.yaml
doctl apps list
doctl apps get <id>
doctl apps delete <id>

# Deployments
doctl apps create-deployment <id>
doctl apps list-deployments <id>

# Logs
doctl apps logs <id>
doctl apps logs <id> --type=BUILD
doctl apps logs <id> --follow

# Console
doctl apps console <id> <component>
```

## References

- [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [App Spec Reference](https://docs.digitalocean.com/products/app-platform/reference/app-spec/)
- [doctl apps](https://docs.digitalocean.com/reference/doctl/reference/apps/)
