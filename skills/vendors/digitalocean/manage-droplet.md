---
name: digitalocean:manage-droplet
description: Create and manage DigitalOcean Droplets
requires:
  - digitalocean-droplets
args:
  - name: action
    description: Action (create, list, delete, snapshot, resize)
    default: "list"
  - name: name
    description: Droplet name (for create)
    default: ""
  - name: size
    description: Droplet size slug
    default: "s-1vcpu-1gb"
  - name: region
    description: Region slug
    default: "nyc1"
---

# DigitalOcean Droplet Management

You are managing DigitalOcean Droplets using MCP tools.

## Context

Project: {{DOYAKEN_PROJECT}}
Action: {{ARGS.action}}
Name: {{ARGS.name}}
Size: {{ARGS.size}}
Region: {{ARGS.region}}

## Actions

{{#if action == "create"}}
### Create Droplet

{{include:vendors/digitalocean/droplets.md}}

Use MCP to create a new Droplet:

**Configuration**:
- Name: {{ARGS.name}}
- Size: {{ARGS.size}} (1 vCPU, 1GB RAM)
- Region: {{ARGS.region}}
- Image: ubuntu-24-04-x64 (or appropriate for workload)
- SSH Keys: Include existing keys
- Monitoring: Enable
- VPC: Use default or specify

**Post-Creation Setup**:
1. Note the public IP address
2. Update DNS if needed
3. Run initial configuration

{{else if action == "list"}}
### List Droplets

Use MCP to list all Droplets:
- Show name, IP, size, status
- Include resource usage if available

{{else if action == "delete"}}
### Delete Droplet

**Warning**: This is destructive!

1. Confirm Droplet to delete
2. Check for attached volumes
3. Create snapshot if needed (optional)
4. Delete the Droplet

{{else if action == "snapshot"}}
### Create Snapshot

1. Power off Droplet (for consistent snapshot)
2. Create snapshot via MCP
3. Power on Droplet
4. Note snapshot ID

{{else if action == "resize"}}
### Resize Droplet

1. Power off Droplet
2. Resize to new size: {{ARGS.size}}
3. Power on Droplet
4. Verify resize completed

{{/if}}

## Security Best Practices

{{include:vendors/digitalocean/security.md}}

## Output

```markdown
## Droplet Management

**Action**: {{ARGS.action}}
**Status**: Success / Failed

{{#if action == "create"}}
### New Droplet
| Property | Value |
|----------|-------|
| Name | {{ARGS.name}} |
| IP | [IP address] |
| Size | {{ARGS.size}} |
| Region | {{ARGS.region}} |
| Status | active |

### SSH Access
```bash
ssh root@[IP]
```
{{else if action == "list"}}
### Droplets
| Name | IP | Size | Region | Status |
|------|----|----- |--------|--------|
| [name] | [ip] | [size] | [region] | [status] |
{{/if}}

### Next Steps
- [Context-appropriate next steps]
```
