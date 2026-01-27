---
description: Check MCP integration status and configure
---

Run the doyaken skill: mcp-status

```bash
doyaken skill mcp-status $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# MCP Integration

Manage Model Context Protocol (MCP) integrations.

## Context

Action: {{ARGS.action}}
Project: {{DOYAKEN_PROJECT}}

## CLI Usage

```bash
# Check integration status
doyaken mcp status

# Generate MCP configuration
doyaken mcp configure

# List available integrations
doyaken mcp list
```

## Available Integrations

| Integration | Description | Required Env Var |
|-------------|-------------|------------------|
| GitHub | Issues, PRs, repos | `GITHUB_TOKEN` |
| Linear | Issues, projects | `LINEAR_API_KEY` |
| Slack | Messages, channels | `SLACK_BOT_TOKEN` |
| Jira | Issues, sprints | `JIRA_API_TOKEN` |

## Configuration

Enable integrations in `.doyaken/manifest.yaml`:

```yaml
integrations:
  github:
    enabled: true
  linear:
    enabled: false
  slack:
    enabled: false
  jira:
    enabled: false
```

## MCP Server Setup

### GitHub

1. Create a GitHub Personal Access Token:
   - Go to GitHub Settings → Developer Settings → Personal Access Tokens
   - Create token with `repo` and `issues` scopes

2. Set environment variable:
   ```bash
   export GITHUB_TOKEN="ghp_..."
   ```

3. Enable in manifest and run:
   ```bash
   doyaken mcp configure
   ```

### Linear

1. Create a Linear API key:
   - Go to Linear Settings → API → Personal API Keys

2. Set environment variable:
   ```bash
   export LINEAR_API_KEY="lin_api_..."
   ```

### Slack

1. Create a Slack App:
   - Go to api.slack.com/apps
   - Create app with `chat:write` scope

2. Set environment variable:
   ```bash
   export SLACK_BOT_TOKEN="xoxb-..."
   ```

## Skills Using MCP

These skills require MCP integrations:

| Skill | Requires |
|-------|----------|
| `github-import` | GitHub |
| `github-sync` | GitHub |
| `create-pr` | GitHub |
| `notify-slack` | Slack |

## Skill Hooks

Auto-run skills at workflow points:

```yaml
# In .doyaken/manifest.yaml
skills:
  hooks:
    before-triage:
      - github-import    # Sync issues before starting
    after-verify:
      - github-sync      # Update issues after completion
      - notify-slack     # Notify on completion
```

## Troubleshooting

### Check Environment Variables

```bash
# Verify tokens are set
echo $GITHUB_TOKEN
echo $LINEAR_API_KEY
echo $SLACK_BOT_TOKEN
```

### Test Connection

```bash
# Test GitHub
gh auth status

# Test with doyaken
doyaken mcp status
```

### Common Issues

1. **Token not set**: Export the required environment variable
2. **Token expired**: Generate a new token
3. **Insufficient permissions**: Check token scopes
4. **Integration not enabled**: Enable in manifest.yaml
