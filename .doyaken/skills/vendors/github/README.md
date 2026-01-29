# GitHub Skills

Skills for GitHub operations using the GitHub MCP server.

## Available Skills

| Skill | Description |
|-------|-------------|
| `github:pr-review` | Review a pull request with comprehensive feedback |
| `github:issue-triage` | Triage and label issues |
| `github:release` | Create a release with changelog |

## MCP Setup

```bash
# Remote (OAuth)
claude mcp add github https://api.githubcopilot.com/mcp/

# Local (PAT)
claude mcp add github --command 'docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server'
```

## Usage

```bash
# Review a pull request
doyaken skill github:pr-review --pr=123

# Triage issues
doyaken skill github:issue-triage

# Create a release
doyaken skill github:release --version=v1.0.0
```

## See Also

- [GitHub Prompts](../../../prompts/vendors/github/)
- [GitHub MCP Config](../../../templates/mcp/github.json)
