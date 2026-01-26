# Dokku Operations

Production operations, SSL, domains, and maintenance.

## When to Apply

Activate this guide when:
- Setting up SSL certificates
- Managing domains
- Server maintenance
- Monitoring applications

---

## 1. SSL Certificates

### Let's Encrypt (Recommended)

```bash
# Install letsencrypt plugin
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# Set email for Let's Encrypt
dokku letsencrypt:set myapp email admin@example.com

# Enable SSL
dokku letsencrypt:enable myapp

# Enable auto-renewal
dokku letsencrypt:cron-job --add
```

### Manual Certificates

```bash
# Import existing certificate
dokku certs:add myapp server.crt server.key

# View certificate info
dokku certs:report myapp

# Remove certificate
dokku certs:remove myapp
```

### Wildcard Certificates

```bash
# For wildcard, use DNS challenge
dokku letsencrypt:set myapp dns-provider cloudflare
dokku letsencrypt:set myapp dns-provider-credentials /path/to/cloudflare.ini
dokku letsencrypt:enable myapp
```

---

## 2. Domain Management

### Adding Domains

```bash
# Set app domain
dokku domains:set myapp app.example.com

# Add additional domain
dokku domains:add myapp www.example.com

# View domains
dokku domains:report myapp

# Remove domain
dokku domains:remove myapp old.example.com
```

### Global Domain

```bash
# Set global domain (*.dokku.example.com)
dokku domains:set-global dokku.example.com

# Apps get subdomains automatically:
# myapp -> myapp.dokku.example.com
```

### DNS Configuration

```
# For app.example.com, add:
A     app     <server-ip>
# or
CNAME app     server.example.com.

# For wildcard (*.dokku.example.com):
A     *.dokku <server-ip>
```

---

## 3. Nginx Configuration

### Custom Nginx Config

```bash
# View current config
dokku nginx:show-config myapp

# Custom nginx template
mkdir -p /home/dokku/myapp
cat > /home/dokku/myapp/nginx.conf.sigil << 'EOF'
server {
  listen      [::]:{{ $.PORT }};
  listen      {{ $.PORT }};
  server_name {{ $.NOSSL_SERVER_NAME }};

  location / {
    proxy_pass  http://{{ $.APP }}-{{ $.PROCESS_TYPE }}-{{ $.CONTAINER_INDEX }}.web:5000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

  # Custom location
  location /api {
    proxy_pass http://{{ $.APP }}-{{ $.PROCESS_TYPE }}-{{ $.CONTAINER_INDEX }}.web:5000;
    proxy_read_timeout 300s;
  }
}
EOF

# Rebuild nginx config
dokku proxy:build-config myapp
```

### Common Nginx Settings

```bash
# Client max body size
dokku nginx:set myapp client-max-body-size 50m

# Proxy timeouts
dokku nginx:set myapp proxy-read-timeout 120s
dokku nginx:set myapp proxy-send-timeout 120s

# HSTS
dokku nginx:set myapp hsts true
dokku nginx:set myapp hsts-max-age 31536000

# Gzip
dokku nginx:set myapp gzip on
```

---

## 4. Maintenance

### App Maintenance Mode

```bash
# Enable maintenance mode
dokku maintenance:enable myapp

# Custom maintenance page
dokku maintenance:set myapp page /path/to/maintenance.html

# Disable
dokku maintenance:disable myapp
```

### Cleanup

```bash
# Clean old containers
dokku cleanup

# Clean app containers
dokku cleanup myapp

# Remove dangling images
docker system prune -f

# Clean build cache
dokku buildpacks:clear myapp
```

### Updates

```bash
# Update Dokku
sudo dokku upgrade

# Update all plugins
sudo dokku plugin:update

# Update specific plugin
sudo dokku plugin:update postgres
```

---

## 5. Monitoring

### Logs

```bash
# View logs
dokku logs myapp
dokku logs myapp -t  # tail
dokku logs myapp -n 100  # last 100 lines

# Service logs
dokku postgres:logs mydb -t
dokku redis:logs myredis -t

# Nginx access logs
dokku nginx:access-logs myapp
dokku nginx:error-logs myapp
```

### Health Checks

```bash
# View health check status
dokku checks:report myapp

# Skip checks (emergency)
dokku checks:skip myapp

# Re-enable checks
dokku checks:enable myapp
```

### Resource Monitoring

```bash
# View running processes
dokku ps:report myapp

# Docker stats
docker stats $(docker ps --filter "label=com.dokku.app-name=myapp" -q)

# System resources
htop
df -h
free -m
```

---

## 6. Backups

### Full Backup Script

```bash
#!/bin/bash
# /usr/local/bin/dokku-backup.sh

BACKUP_DIR="/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

echo "Starting backup..."

# Backup app configs
for app in $(dokku apps:list | tail -n +2); do
  echo "Backing up config for $app"
  dokku config:export $app > $BACKUP_DIR/$app.env
done

# Backup databases
for db in $(dokku postgres:list 2>/dev/null | tail -n +2); do
  echo "Backing up postgres $db"
  dokku postgres:export $db | gzip > $BACKUP_DIR/postgres-$db.sql.gz
done

for db in $(dokku mysql:list 2>/dev/null | tail -n +2); do
  echo "Backing up mysql $db"
  dokku mysql:export $db | gzip > $BACKUP_DIR/mysql-$db.sql.gz
done

# Backup Dokku configs
echo "Backing up Dokku configs"
cp -r /home/dokku/*/nginx.conf.sigil $BACKUP_DIR/ 2>/dev/null || true
cp -r /home/dokku/*/CHECKS $BACKUP_DIR/ 2>/dev/null || true

# Compress
tar -czf /backups/dokku-backup-$(date +%Y%m%d).tar.gz $BACKUP_DIR

# Cleanup old backups (keep 7 days)
find /backups -name "*.tar.gz" -mtime +7 -delete
find /backups -type d -empty -delete

echo "Backup complete!"
```

### Restore

```bash
# Restore app config
dokku config:set myapp < backup/myapp.env

# Restore database
gunzip -c backup/postgres-mydb.sql.gz | dokku postgres:import mydb
```

---

## 7. Security

### SSH Access

```bash
# Add SSH key
cat ~/.ssh/id_rsa.pub | dokku ssh-keys:add user-name

# List keys
dokku ssh-keys:list

# Remove key
dokku ssh-keys:remove user-name
```

### Firewall

```bash
# Use UFW
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable

# Check status
sudo ufw status
```

### Security Headers

```bash
# Add security headers via nginx
dokku nginx:set myapp x-content-type-options nosniff
dokku nginx:set myapp x-frame-options "DENY"
dokku nginx:set myapp x-xss-protection "1; mode=block"
```

---

## 8. Troubleshooting

### Common Issues

```bash
# App not starting
dokku logs myapp -t
dokku ps:report myapp

# Deployment failed
dokku trace:on
git push dokku main
dokku trace:off

# SSL not working
dokku nginx:show-config myapp
dokku letsencrypt:ls

# Database connection failed
dokku postgres:info mydb
dokku config:show myapp | grep DATABASE_URL
```

### Recovery

```bash
# Force restart
dokku ps:restart myapp

# Rebuild app
dokku ps:rebuild myapp

# Rebuild from git
dokku git:sync myapp https://github.com/org/repo main --build
```

---

## Quick Reference

```bash
# SSL
dokku letsencrypt:enable myapp
dokku certs:add myapp cert.crt cert.key

# Domains
dokku domains:set myapp example.com
dokku domains:add myapp www.example.com

# Nginx
dokku nginx:set myapp client-max-body-size 50m
dokku nginx:show-config myapp

# Maintenance
dokku maintenance:enable myapp
dokku cleanup

# Logs
dokku logs myapp -t
dokku nginx:access-logs myapp

# SSH keys
dokku ssh-keys:add keyname
dokku ssh-keys:list
```

## References

- [Dokku SSL](https://dokku.com/docs/configuration/ssl/)
- [Dokku Domains](https://dokku.com/docs/configuration/domains/)
- [Dokku Nginx](https://dokku.com/docs/configuration/nginx/)
