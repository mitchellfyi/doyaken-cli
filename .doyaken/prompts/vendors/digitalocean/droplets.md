# DigitalOcean Droplets

Virtual machine management on DigitalOcean.

## When to Apply

Activate this guide when:
- Creating new Droplets
- Configuring server infrastructure
- Managing compute resources
- Setting up development/production servers

---

## 1. Droplet Creation

### Recommended Specs

| Use Case | Size | vCPUs | Memory | Storage |
|----------|------|-------|--------|---------|
| Development | s-1vcpu-1gb | 1 | 1GB | 25GB |
| Small App | s-1vcpu-2gb | 1 | 2GB | 50GB |
| Medium App | s-2vcpu-4gb | 2 | 4GB | 80GB |
| Production | s-4vcpu-8gb | 4 | 8GB | 160GB |
| High Memory | m-2vcpu-16gb | 2 | 16GB | 50GB |

### CLI Creation

```bash
# Create Droplet
doctl compute droplet create myserver \
  --size s-2vcpu-4gb \
  --image ubuntu-24-04-x64 \
  --region nyc1 \
  --ssh-keys $(doctl compute ssh-key list --format ID --no-header | tr '\n' ',') \
  --enable-monitoring \
  --enable-backups \
  --tag-names "production,web"

# With user data script
doctl compute droplet create myserver \
  --size s-2vcpu-4gb \
  --image ubuntu-24-04-x64 \
  --region nyc1 \
  --ssh-keys <key-id> \
  --user-data-file init.sh
```

### User Data Script

```bash
#!/bin/bash
# init.sh - Droplet initialization

# Update system
apt-get update && apt-get upgrade -y

# Install essentials
apt-get install -y \
  curl \
  git \
  ufw \
  fail2ban \
  htop \
  unzip

# Setup firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

# Create deploy user
adduser --disabled-password --gecos "" deploy
usermod -aG sudo deploy
mkdir -p /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Disable root SSH
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

echo "Setup complete!"
```

---

## 2. Droplet Sizing

### Resize Operations

```bash
# Power off first (for disk resize)
doctl compute droplet-action power-off <droplet-id>

# Resize (CPU/RAM only - reversible)
doctl compute droplet-action resize <droplet-id> \
  --size s-4vcpu-8gb

# Resize with disk (irreversible)
doctl compute droplet-action resize <droplet-id> \
  --size s-4vcpu-8gb \
  --resize-disk

# Power on
doctl compute droplet-action power-on <droplet-id>
```

### Vertical vs Horizontal Scaling

```
Vertical (resize):
- Quick for sudden traffic
- Has limits (max 192GB RAM)
- Requires brief downtime

Horizontal (more droplets):
- Better for sustained growth
- Requires load balancer
- No single point of failure
```

---

## 3. Networking

### VPC (Virtual Private Cloud)

```bash
# Create VPC
doctl vpcs create \
  --name production-vpc \
  --region nyc1 \
  --ip-range 10.10.10.0/24

# Create Droplet in VPC
doctl compute droplet create myserver \
  --size s-2vcpu-4gb \
  --image ubuntu-24-04-x64 \
  --region nyc1 \
  --vpc-uuid <vpc-id>
```

### Reserved IPs

```bash
# Create reserved IP
doctl compute reserved-ip create --region nyc1

# Assign to Droplet
doctl compute reserved-ip-action assign <ip> <droplet-id>

# Unassign
doctl compute reserved-ip-action unassign <ip>
```

### Load Balancers

```bash
# Create load balancer
doctl compute load-balancer create \
  --name my-lb \
  --region nyc1 \
  --forwarding-rules "entry_protocol:https,entry_port:443,target_protocol:http,target_port:80,certificate_id:<cert-id>,tls_passthrough:false" \
  --health-check "protocol:http,port:80,path:/health,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:3,unhealthy_threshold:3" \
  --droplet-ids <id1>,<id2>
```

---

## 4. Storage

### Volumes

```bash
# Create volume
doctl compute volume create myvolume \
  --region nyc1 \
  --size 100GiB \
  --desc "Data volume"

# Attach to Droplet
doctl compute volume-action attach <volume-id> <droplet-id>

# On the Droplet, mount the volume
sudo mkdir -p /mnt/data
sudo mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_myvolume /mnt/data

# Add to fstab for persistence
echo '/dev/disk/by-id/scsi-0DO_Volume_myvolume /mnt/data ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab
```

### Snapshots

```bash
# Create snapshot
doctl compute droplet-action snapshot <droplet-id> \
  --snapshot-name "myserver-$(date +%Y%m%d)"

# List snapshots
doctl compute snapshot list

# Create Droplet from snapshot
doctl compute droplet create myserver-new \
  --size s-2vcpu-4gb \
  --image <snapshot-id> \
  --region nyc1
```

### Backups

```bash
# Enable backups (additional cost)
doctl compute droplet-action enable-backups <droplet-id>

# List backups
doctl compute droplet backups <droplet-id>

# Restore from backup
doctl compute droplet-action restore <droplet-id> --image-id <backup-id>
```

---

## 5. Monitoring

### Built-in Monitoring

```bash
# Enable monitoring (free)
doctl compute droplet create myserver \
  --enable-monitoring \
  ...

# Or enable on existing
# Requires agent installation on Droplet
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash
```

### Metrics Available

- CPU utilization
- Memory usage (with agent)
- Disk I/O
- Bandwidth (public/private)
- Load average

### Alerts

```bash
# Create alert policy
doctl monitoring alert create \
  --type "v1/insights/droplet/cpu" \
  --compare "GreaterThan" \
  --value 80 \
  --window "5m" \
  --emails "admin@example.com" \
  --entities <droplet-id>
```

---

## 6. Management

### Common Operations

```bash
# List Droplets
doctl compute droplet list

# Get Droplet details
doctl compute droplet get <droplet-id>

# Power operations
doctl compute droplet-action power-off <droplet-id>
doctl compute droplet-action power-on <droplet-id>
doctl compute droplet-action reboot <droplet-id>

# Delete Droplet
doctl compute droplet delete <droplet-id> --force

# SSH into Droplet
doctl compute ssh <droplet-name>
```

### Tags

```bash
# Create tag
doctl compute tag create production

# Tag Droplet
doctl compute droplet tag <droplet-id> --tag-name production

# List by tag
doctl compute droplet list --tag-name production
```

### SSH Keys

```bash
# Add SSH key
doctl compute ssh-key create mykey --public-key "$(cat ~/.ssh/id_rsa.pub)"

# List keys
doctl compute ssh-key list

# Delete key
doctl compute ssh-key delete <key-id>
```

---

## 7. Automation

### Terraform

```hcl
# main.tf
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "web" {
  image    = "ubuntu-24-04-x64"
  name     = "web-server"
  region   = "nyc1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  tags = ["production", "web"]

  monitoring = true
  backups    = true

  vpc_uuid = digitalocean_vpc.production.id
}

resource "digitalocean_firewall" "web" {
  name = "web-firewall"
  droplet_ids = [digitalocean_droplet.web.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }
}
```

---

## Quick Reference

```bash
# Droplets
doctl compute droplet create <name> --size <size> --image <image> --region <region>
doctl compute droplet list
doctl compute droplet delete <id>
doctl compute ssh <name>

# Power
doctl compute droplet-action power-off <id>
doctl compute droplet-action power-on <id>
doctl compute droplet-action reboot <id>

# Snapshots
doctl compute droplet-action snapshot <id> --snapshot-name <name>
doctl compute snapshot list

# Volumes
doctl compute volume create <name> --region <region> --size <size>
doctl compute volume-action attach <vol-id> <droplet-id>

# Networking
doctl compute reserved-ip create --region <region>
doctl vpcs create --name <name> --region <region>
```

## References

- [Droplets Documentation](https://docs.digitalocean.com/products/droplets/)
- [doctl CLI](https://docs.digitalocean.com/reference/doctl/)
- [Terraform Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/)
