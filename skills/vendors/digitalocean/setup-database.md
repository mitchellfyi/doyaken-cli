---
name: digitalocean:setup-database
description: Setup DigitalOcean Managed Database
requires:
  - digitalocean-databases
args:
  - name: engine
    description: Database engine (postgres, mysql, redis, mongodb)
    default: "postgres"
  - name: name
    description: Database cluster name
    default: ""
  - name: size
    description: Database size slug
    default: "db-s-1vcpu-1gb"
  - name: region
    description: Region slug
    default: "nyc1"
---

# DigitalOcean Managed Database Setup

You are setting up a DigitalOcean Managed Database using MCP tools.

## Context

Project: {{DOYAKEN_PROJECT}}
Engine: {{ARGS.engine}}
Cluster Name: {{ARGS.name}}
Size: {{ARGS.size}}
Region: {{ARGS.region}}

## Setup Process

### 1. Create Database Cluster

Use DigitalOcean MCP to create the cluster:

**Configuration**:
- Engine: {{ARGS.engine}}
- Version: Latest stable
- Name: {{ARGS.name}}
- Size: {{ARGS.size}}
- Region: {{ARGS.region}}
- Nodes: 1 (standby nodes for HA optional)

### 2. Configure Security

{{include:vendors/digitalocean/security.md}}

**Trusted Sources**:
- Add your application's IP/Droplet
- Configure VPC access if applicable
- Restrict public access

**SSL Mode**: Require SSL connections

### 3. Create Database and User

After cluster is ready:

{{#if engine == "postgres"}}
```sql
-- Create application database
CREATE DATABASE appdb;

-- Create application user
CREATE USER appuser WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
```
{{else if engine == "mysql"}}
```sql
CREATE DATABASE appdb;
CREATE USER 'appuser'@'%' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
```
{{else if engine == "redis"}}
Redis doesn't require database/user setup.
Use the provided connection string.
{{/if}}

### 4. Get Connection Details

Retrieve from MCP:
- Host
- Port
- Database name
- Username
- Password
- SSL CA certificate

### 5. Connection String

{{#if engine == "postgres"}}
```
postgresql://appuser:password@host:port/appdb?sslmode=require
```
{{else if engine == "mysql"}}
```
mysql://appuser:password@host:port/appdb?ssl-mode=REQUIRED
```
{{else if engine == "redis"}}
```
rediss://default:password@host:port
```
{{/if}}

## Output

```markdown
## Managed Database Created

**Engine**: {{ARGS.engine}}
**Cluster**: {{ARGS.name}}
**Status**: Creating / Online

### Connection Details
| Property | Value |
|----------|-------|
| Host | [hostname] |
| Port | [port] |
| Database | appdb |
| Username | appuser |
| SSL | Required |

### Connection String
```
[connection string - do not expose password]
```

### Security
- Trusted sources: [IPs/Droplets]
- SSL: Required
- Public access: Disabled

### Environment Variable
```bash
DATABASE_URL="[connection string]"
```

### Next Steps
- [ ] Add connection string to app config
- [ ] Test database connection
- [ ] Set up backups schedule
- [ ] Configure monitoring alerts
```
