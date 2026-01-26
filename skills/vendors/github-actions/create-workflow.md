---
name: github-actions:create-workflow
description: Create a GitHub Actions workflow from patterns
args:
  - name: type
    description: Workflow type (ci, cd, release, scheduled)
    default: "ci"
  - name: language
    description: Primary language/framework
    default: ""
---

# Create GitHub Actions Workflow

You are creating a GitHub Actions workflow following best practices.

## Context

Project: {{DOYAKEN_PROJECT}}
Workflow Type: {{ARGS.type}}
Language: {{ARGS.language}}

## Workflow Creation

### 1. Analyze Project

Determine project requirements:

- **Language/Runtime**: Node.js, Python, Go, Rust, etc.
- **Package Manager**: npm, yarn, pnpm, pip, cargo
- **Build System**: If applicable
- **Test Framework**: Jest, pytest, go test, etc.
- **Deployment Target**: Vercel, AWS, Docker, etc.

### 2. Select Workflow Pattern

{{#if type == "ci"}}
**Continuous Integration Workflow**

Create `.github/workflows/ci.yml`:

{{include:vendors/github-actions/workflows.md}}

Key elements:
- Trigger on push and pull_request
- Matrix testing for multiple versions
- Caching for dependencies
- Parallel jobs where possible

{{else if type == "cd"}}
**Continuous Deployment Workflow**

Create `.github/workflows/deploy.yml`:

Key elements:
- Trigger on push to main/release branches
- Environment protection rules
- Deployment to staging then production
- Rollback capability

{{else if type == "release"}}
**Release Workflow**

Create `.github/workflows/release.yml`:

Key elements:
- Trigger on tag push or release creation
- Build artifacts
- Generate changelog
- Publish to registries

{{else if type == "scheduled"}}
**Scheduled Workflow**

Create `.github/workflows/scheduled.yml`:

Key elements:
- Cron trigger
- Maintenance tasks
- Dependency updates
- Health checks
{{/if}}

### 3. Apply Security Best Practices

{{include:vendors/github-actions/security.md}}

### 4. Optimize Performance

{{include:vendors/github-actions/optimization.md}}

## Output

Provide the workflow file and summary:

```markdown
## Workflow Created

**File**: `.github/workflows/{{ARGS.type}}.yml`
**Type**: {{ARGS.type}}

### Triggers
- [List of triggers]

### Jobs
| Job | Purpose | Runs On |
|-----|---------|---------|
| [name] | [description] | [runner] |

### Features
- [ ] Caching enabled
- [ ] Matrix testing
- [ ] Security hardened
- [ ] Optimized for speed

### Next Steps
1. Review and customize the workflow
2. Add repository secrets if needed
3. Push to enable the workflow
```
