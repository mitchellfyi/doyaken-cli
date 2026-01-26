# Dokku Deployment

Complete guide to deploying applications with Dokku.

## When to Apply

Activate this guide when:
- Deploying applications to Dokku
- Setting up new Dokku apps
- Configuring buildpacks
- Managing environment variables

---

## 1. Initial Setup

### Server Installation

```bash
# Ubuntu 22.04/24.04 or Debian 11+
wget -NP . https://dokku.com/install/v0.37.5/bootstrap.sh
sudo DOKKU_TAG=v0.37.5 bash bootstrap.sh

# Add your SSH key
cat ~/.ssh/id_rsa.pub | sudo dokku ssh-keys:add admin

# Set global domain
dokku domains:set-global yourdomain.com
```

### Creating an Application

```bash
# On the Dokku server
dokku apps:create myapp

# Set environment variables
dokku config:set myapp NODE_ENV=production
dokku config:set myapp DATABASE_URL=postgres://...
```

---

## 2. Deployment Workflow

### Git Push Deployment

```bash
# On your local machine
cd myproject

# Add Dokku remote
git remote add dokku dokku@yourdomain.com:myapp

# Deploy
git push dokku main
```

### Deployment Process

```
git push dokku main
       │
       ▼
┌──────────────────┐
│  Receive Code    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Detect Language │  ← Buildpack selection
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Build Container │  ← Install deps, compile
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Run Checks      │  ← Health checks
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Deploy          │  ← Zero-downtime swap
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Retire Old      │  ← Grace period
└──────────────────┘
```

### Procfile

```procfile
# Procfile
web: npm start
worker: npm run worker
release: npm run migrate
```

### app.json (Optional)

```json
{
  "name": "myapp",
  "scripts": {
    "dokku": {
      "predeploy": "npm run migrate",
      "postdeploy": "npm run seed"
    }
  },
  "healthchecks": {
    "web": [
      {
        "type": "startup",
        "name": "web check",
        "path": "/health"
      }
    ]
  }
}
```

---

## 3. Buildpacks

### Language Detection

Dokku auto-detects languages:

| Language | Detection File | Buildpack |
|----------|----------------|-----------|
| Node.js | `package.json` | heroku/nodejs |
| Python | `requirements.txt`, `setup.py` | heroku/python |
| Ruby | `Gemfile` | heroku/ruby |
| Go | `go.mod` | heroku/go |
| PHP | `composer.json` | heroku/php |
| Java | `pom.xml`, `build.gradle` | heroku/java |

### Custom Buildpack

```bash
# Set specific buildpack
dokku buildpacks:set myapp https://github.com/heroku/heroku-buildpack-nodejs

# Multiple buildpacks
dokku buildpacks:add myapp --index 1 https://github.com/heroku/heroku-buildpack-nodejs
dokku buildpacks:add myapp --index 2 https://github.com/custom/buildpack

# Clear and reset
dokku buildpacks:clear myapp
```

### .buildpacks File

```
# .buildpacks
https://github.com/heroku/heroku-buildpack-nodejs
https://github.com/heroku/heroku-buildpack-python
```

---

## 4. Environment Configuration

### Setting Variables

```bash
# Set single variable
dokku config:set myapp API_KEY=secret123

# Set multiple
dokku config:set myapp \
  NODE_ENV=production \
  PORT=5000 \
  DATABASE_URL=postgres://user:pass@host/db

# From file
dokku config:set myapp < .env.production

# View config
dokku config:show myapp

# Unset
dokku config:unset myapp DEBUG
```

### Sensitive Variables

```bash
# Variables are encrypted at rest
# Never commit to git

# Use dokku config:set for:
- API keys
- Database URLs
- JWT secrets
- Third-party credentials
```

---

## 5. Docker Deployment

### Dockerfile Deployment

```dockerfile
# Dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

EXPOSE 5000
CMD ["npm", "start"]
```

```bash
# Enable dockerfile deploys
dokku builder:set myapp selected dockerfile

# Or use docker-options
dokku docker-options:add myapp build '--build-arg NODE_ENV=production'
```

### Docker Image Deployment

```bash
# Deploy from Docker Hub
dokku git:from-image myapp myorg/myapp:latest

# Deploy from archive
dokku git:from-archive myapp https://example.com/app.tar.gz
```

---

## 6. Zero-Downtime Deploys

### Health Checks

```bash
# Create CHECKS file in repo root
# CHECKS
WAIT=10
TIMEOUT=60
ATTEMPTS=5

/health Ready
/api/status {"status":"ok"}
```

### Check Configuration

```bash
# Environment variables
dokku config:set myapp \
  DOKKU_CHECKS_WAIT=10 \
  DOKKU_CHECKS_TIMEOUT=60 \
  DOKKU_CHECKS_ATTEMPTS=5 \
  DOKKU_WAIT_TO_RETIRE=60
```

### Deployment Lifecycle

```bash
# Before new containers start
predeploy: npm run migrate

# After new containers start, before old retire
postdeploy: npm run notify-deploy

# Grace period before killing old containers
DOKKU_WAIT_TO_RETIRE=60  # seconds
```

---

## 7. Scaling

### Process Scaling

```bash
# Scale web processes
dokku ps:scale myapp web=2

# Scale workers
dokku ps:scale myapp web=2 worker=3

# View current scale
dokku ps:report myapp
```

### Resource Limits

```bash
# Memory limits
dokku resource:limit myapp --memory 512m
dokku resource:limit myapp --memory-swap 1g

# CPU limits
dokku resource:limit myapp --cpu 1

# View limits
dokku resource:report myapp
```

---

## 8. Networking

### Ports

```bash
# View port mappings
dokku ports:report myapp

# Set port mapping
dokku ports:set myapp http:80:5000 https:443:5000

# Remove mapping
dokku ports:remove myapp http:80:5000
```

### Network Configuration

```bash
# Create network
dokku network:create mynetwork

# Attach app to network
dokku network:set myapp attach-post-create mynetwork
dokku network:set myapp attach-post-deploy mynetwork

# Apps on same network can communicate by app name
# e.g., http://api:5000 from web app
```

---

## 9. Troubleshooting

### Common Commands

```bash
# View logs
dokku logs myapp
dokku logs myapp -t  # tail

# View running processes
dokku ps:report myapp

# Enter container
dokku enter myapp web

# Run one-off command
dokku run myapp npm run migrate

# Restart app
dokku ps:restart myapp

# Rebuild
dokku ps:rebuild myapp
```

### Debug Deployment

```bash
# View build output
dokku trace:on
git push dokku main
dokku trace:off

# Check nginx config
dokku nginx:show-config myapp

# View recent deploys
dokku events:list
```

---

## Quick Reference

```bash
# App lifecycle
dokku apps:create myapp
dokku apps:destroy myapp
dokku apps:list

# Config
dokku config:set myapp KEY=value
dokku config:show myapp

# Deploy
git push dokku main
dokku ps:rebuild myapp

# Logs & debug
dokku logs myapp -t
dokku enter myapp web
dokku run myapp <command>

# Scaling
dokku ps:scale myapp web=2
dokku ps:report myapp
```

## References

- [Dokku Deployment](https://dokku.com/docs/deployment/application-deployment/)
- [Zero-Downtime Deploys](https://dokku.com/docs/deployment/zero-downtime-deploys/)
- [Docker Deploys](https://dokku.com/docs/deployment/methods/dockerfiles/)
