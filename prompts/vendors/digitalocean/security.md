# DigitalOcean Security

Security best practices for DigitalOcean infrastructure.

## When to Apply

Activate this guide when:
- Setting up new infrastructure
- Hardening existing servers
- Auditing security posture
- Configuring firewalls

---

## 1. Cloud Firewalls

### Creating Firewalls

```bash
# Create firewall with basic rules
doctl compute firewall create \
  --name production-firewall \
  --inbound-rules "protocol:tcp,ports:22,address:0.0.0.0/0 protocol:tcp,ports:80,address:0.0.0.0/0 protocol:tcp,ports:443,address:0.0.0.0/0" \
  --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0" \
  --droplet-ids <droplet-id>
```

### Recommended Rules

```yaml
# Web Server
Inbound:
  - Protocol: TCP, Port: 22, Source: Your IP (or VPN)
  - Protocol: TCP, Port: 80, Source: 0.0.0.0/0
  - Protocol: TCP, Port: 443, Source: 0.0.0.0/0
Outbound:
  - Protocol: TCP, Ports: all, Destination: 0.0.0.0/0
  - Protocol: UDP, Port: 53, Destination: 0.0.0.0/0 (DNS)

# Database Server
Inbound:
  - Protocol: TCP, Port: 22, Source: Your IP
  - Protocol: TCP, Port: 5432, Source: App Server IPs
Outbound:
  - Protocol: TCP, Ports: all, Destination: 0.0.0.0/0

# Internal Service (VPC only)
Inbound:
  - Protocol: TCP, Port: all, Source: 10.10.10.0/24 (VPC range)
```

### Managing Firewalls

```bash
# List firewalls
doctl compute firewall list

# Add Droplet to firewall
doctl compute firewall add-droplets <firewall-id> --droplet-ids <droplet-id>

# Add rules
doctl compute firewall add-rules <firewall-id> \
  --inbound-rules "protocol:tcp,ports:8080,address:0.0.0.0/0"

# Remove rules
doctl compute firewall remove-rules <firewall-id> \
  --inbound-rules "protocol:tcp,ports:8080,address:0.0.0.0/0"
```

---

## 2. SSH Security

### SSH Key Best Practices

```bash
# Use ED25519 keys (more secure than RSA)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to DigitalOcean
doctl compute ssh-key create mykey --public-key "$(cat ~/.ssh/id_ed25519.pub)"
```

### SSH Hardening on Droplets

```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no

# Restart SSH
sudo systemctl restart sshd
```

### SSH Jump Host

```bash
# ~/.ssh/config
Host bastion
  HostName bastion.example.com
  User admin
  IdentityFile ~/.ssh/bastion_key

Host internal-*
  ProxyJump bastion
  User deploy

Host internal-web
  HostName 10.10.10.5

# SSH through bastion
ssh internal-web
```

---

## 3. VPC Security

### Network Isolation

```bash
# Create isolated VPC
doctl vpcs create \
  --name production-vpc \
  --region nyc1 \
  --ip-range 10.10.10.0/24

# Create Droplets in VPC
doctl compute droplet create web-server \
  --vpc-uuid <vpc-id> \
  --private-networking
```

### VPC Design

```
┌─────────────────────────────────────────┐
│              production-vpc              │
│              10.10.10.0/24               │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │   Web    │  │   API    │  │   DB   │ │
│  │10.10.10.2│  │10.10.10.3│  │10.10.10.4│
│  └────┬─────┘  └────┬─────┘  └────────┘ │
│       │             │              ▲     │
│       └─────────────┴──────────────┘     │
│              Internal only               │
└─────────────────────────────────────────┘
         │
         │ Public (Firewall controlled)
         ▼
    ┌─────────┐
    │ Internet│
    └─────────┘
```

---

## 4. Account Security

### Two-Factor Authentication

1. Enable 2FA in Account Settings
2. Use authenticator app (not SMS)
3. Save backup codes securely
4. Require 2FA for team members

### API Token Security

```bash
# Create scoped token (read-only)
# In DO Console: API → Generate New Token
# Select: Read scope only

# Use environment variables
export DIGITALOCEAN_TOKEN=dop_v1_xxxxx

# Never commit tokens
echo "DIGITALOCEAN_TOKEN" >> .gitignore
```

### Team Permissions

```yaml
# Role-based access
Roles:
  - Admin: Full access
  - Billing: Billing only
  - Engineer: Create/manage resources
  - Viewer: Read-only

# Project-based access
Projects:
  - production: Admin, Senior Engineers
  - staging: All Engineers
  - development: All team members
```

---

## 5. Droplet Security

### Initial Hardening

```bash
#!/bin/bash
# secure-droplet.sh

# Update system
apt-get update && apt-get upgrade -y

# Install security tools
apt-get install -y fail2ban ufw unattended-upgrades

# Configure fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
systemctl enable fail2ban
systemctl start fail2ban

# Configure automatic updates
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

# Enable UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

echo "Security hardening complete!"
```

### Regular Maintenance

```bash
# Security updates
sudo apt-get update
sudo apt-get upgrade -y

# Check for rootkits
sudo apt-get install rkhunter
sudo rkhunter --check

# Audit open ports
sudo ss -tlnp
sudo netstat -tlnp

# Check failed logins
sudo lastb | head -20
sudo grep "Failed password" /var/log/auth.log
```

---

## 6. Monitoring & Auditing

### Security Monitoring

```bash
# Enable DO Monitoring
doctl compute droplet create myserver \
  --enable-monitoring

# Set up alerts
doctl monitoring alert create \
  --type "v1/insights/droplet/cpu" \
  --compare "GreaterThan" \
  --value 90 \
  --window "5m" \
  --emails "security@example.com"
```

### Audit Logging

- Account Activity: Settings → Security → Security History
- API Activity: API → Activity
- Team Activity: Settings → Team → Activity

### Log Management

```bash
# Centralized logging with rsyslog
# /etc/rsyslog.d/50-remote.conf
*.* @@logs.example.com:514

# Or use DO's log forwarding
# In App Platform, logs are automatically collected
```

---

## 7. Backup Security

### Encrypted Backups

```bash
# Enable automated backups (encrypted at rest)
doctl compute droplet create myserver \
  --enable-backups

# Encrypted volume snapshots
doctl compute volume-action snapshot <vol-id> \
  --snapshot-name "encrypted-$(date +%Y%m%d)"
```

### Backup Strategy

```yaml
Backups:
  - Type: Automated Droplet Backups
    Frequency: Weekly
    Retention: 4 weeks

  - Type: Volume Snapshots
    Frequency: Daily
    Retention: 7 days

  - Type: Database Backups
    Frequency: Daily
    Retention: 7 days
    Point-in-time: 7 days

  - Type: Off-site Backups
    Destination: Spaces (different region)
    Frequency: Daily
    Encryption: Client-side
```

---

## Security Checklist

### Account Level

- [ ] 2FA enabled for all team members
- [ ] API tokens scoped appropriately
- [ ] Inactive tokens revoked
- [ ] Team permissions reviewed quarterly
- [ ] Security history monitored

### Network Level

- [ ] Cloud Firewalls configured
- [ ] VPC for internal communication
- [ ] No unnecessary public IPs
- [ ] Load balancer with SSL termination
- [ ] DDoS protection enabled

### Server Level

- [ ] SSH key authentication only
- [ ] Root login disabled
- [ ] Fail2ban installed
- [ ] Automatic updates enabled
- [ ] UFW/iptables configured
- [ ] Unnecessary services disabled

### Application Level

- [ ] Secrets in environment variables
- [ ] No credentials in code
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] Regular dependency updates

## References

- [Security Best Practices](https://www.digitalocean.com/security/security-best-practices-guide-droplet)
- [Cloud Firewalls](https://docs.digitalocean.com/products/networking/firewalls/)
- [VPC](https://docs.digitalocean.com/products/networking/vpc/)
