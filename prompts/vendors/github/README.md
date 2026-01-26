# GitHub Prompts

Specialized prompts for GitHub platform - issues, pull requests, code review, and repository management.

## Prompt Library

| File | Description | Use When |
|------|-------------|----------|
| [issues-prs.md](issues-prs.md) | Issue and PR management patterns | Creating issues, reviewing PRs, managing workflows |
| [code-review.md](code-review.md) | GitHub-specific code review practices | PR reviews, suggesting changes, approval criteria |
| [repository.md](repository.md) | Repository management and configuration | Setting up repos, branch protection, CODEOWNERS |

## Usage

### In Skills

```markdown
---
name: my-github-skill
requires:
  - github
---

{{include:vendors/github/code-review.md}}

Now review this pull request...
```

## MCP Integration

Enable GitHub MCP for full platform access:

```yaml
# .doyaken/manifest.yaml
integrations:
  github:
    enabled: true
    repo: "owner/repo"  # Auto-detected from git remote
```

MCP Server: `https://api.githubcopilot.com/mcp/` (OAuth) or local via Docker.

## Skills

See [skills/vendors/github/](../../../skills/vendors/github/) for executable skills:

- `github:create-issue` - Create GitHub issues
- `github:review-pr` - Review pull requests
- `github:sync-issues` - Sync issues with local tasks

## References

- [GitHub MCP Server](https://github.com/github/github-mcp-server)
- [GitHub CLI](https://cli.github.com/)
- [GitHub Docs](https://docs.github.com/)
