# GitHub Repository Management

Best practices for repository setup, configuration, and maintenance.

## When to Apply

Activate this guide when:
- Creating new repositories
- Setting up branch protection
- Configuring repository settings
- Managing team permissions

---

## 1. Repository Structure

### Standard Layout

```
repository/
├── .github/
│   ├── workflows/           # GitHub Actions
│   │   ├── ci.yml
│   │   ├── cd.yml
│   │   └── release.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── CODEOWNERS
│   ├── dependabot.yml
│   └── FUNDING.yml
├── docs/                    # Documentation
├── src/                     # Source code
├── tests/                   # Test files
├── scripts/                 # Build/utility scripts
├── .gitignore
├── .editorconfig
├── LICENSE
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── SECURITY.md
```

### Essential Files

**README.md:**
```markdown
# Project Name

Brief description of what this project does.

## Features

- Feature 1
- Feature 2

## Installation

```bash
npm install project-name
```

## Usage

```javascript
import { thing } from 'project-name';
```

## Documentation

[Link to full docs]

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

[MIT](LICENSE)
```

**CONTRIBUTING.md:**
```markdown
# Contributing

## Getting Started

1. Fork the repository
2. Clone your fork
3. Install dependencies: `npm install`
4. Create a branch: `git checkout -b feature/your-feature`

## Development

```bash
npm run dev    # Start development
npm run test   # Run tests
npm run lint   # Check code style
```

## Pull Request Process

1. Update documentation if needed
2. Add tests for new features
3. Ensure all tests pass
4. Update CHANGELOG.md
5. Request review from maintainers

## Code Style

- Use [style guide link]
- Run `npm run lint` before committing
```

---

## 2. Branch Protection

### Main Branch Settings

```yaml
# Recommended protection for main/master

Required reviews:
  - Require approvals: 1 (or 2 for critical repos)
  - Dismiss stale reviews: true
  - Require review from code owners: true
  - Restrict dismissals to: [maintainers]

Required status checks:
  - Require branches be up to date: true
  - Required checks:
    - build
    - test
    - lint
    - security-scan

Branch restrictions:
  - Restrict pushes: true
  - Allow specified actors: [maintainers, release-bot]

Rules:
  - Allow force pushes: false
  - Allow deletions: false
  - Require linear history: true (optional)
  - Require signed commits: false (optional)
```

### Development Branch Settings

```yaml
# Lighter protection for develop branch

Required reviews:
  - Require approvals: 1
  - Dismiss stale reviews: true

Required status checks:
  - build
  - test

Rules:
  - Allow force pushes: false
  - Allow deletions: false
```

---

## 3. CODEOWNERS

### Configuration

```
# .github/CODEOWNERS

# Default owners for everything
* @org/core-team

# Frontend ownership
/src/components/ @org/frontend-team
/src/styles/ @org/frontend-team
/src/hooks/ @org/frontend-team
*.css @org/frontend-team
*.tsx @org/frontend-team

# Backend ownership
/src/api/ @org/backend-team
/src/models/ @org/backend-team
/src/services/ @org/backend-team

# Infrastructure
/terraform/ @org/devops-team
/docker/ @org/devops-team
/.github/workflows/ @org/devops-team
Dockerfile @org/devops-team

# Database
/migrations/ @org/backend-team @db-admin
/prisma/ @org/backend-team

# Security-sensitive files
/src/auth/ @security-team
*.key @security-team
.env* @security-team

# Documentation
/docs/ @org/docs-team
*.md @org/docs-team

# Dependencies
package.json @org/core-team
package-lock.json @org/core-team
```

### Best Practices

- Keep ownership granular but not excessive
- Ensure owners are active and responsive
- Use team handles over individuals
- Review CODEOWNERS quarterly

---

## 4. Issue & PR Templates

### Bug Report Template

```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: Bug Report
description: File a bug report
title: "[Bug]: "
labels: ["bug", "triage"]
body:
  - type: markdown
    attributes:
      value: Thanks for taking the time to fill out this bug report!

  - type: textarea
    id: description
    attributes:
      label: Describe the bug
      description: Clear description of the bug
    validations:
      required: true

  - type: textarea
    id: reproduction
    attributes:
      label: Steps to reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Go to '...'
        2. Click on '...'
        3. See error
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
      description: What should happen

  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - Critical (app crashes)
        - High (major feature broken)
        - Medium (minor feature broken)
        - Low (cosmetic issue)
    validations:
      required: true

  - type: textarea
    id: environment
    attributes:
      label: Environment
      description: OS, browser, version, etc.
```

### PR Template

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->

## Summary
<!-- Brief description of changes -->

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Related Issues
<!-- Link to related issues: Closes #123 -->

## Changes
<!-- List main changes -->
-
-
-

## Testing
<!-- How was this tested? -->
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally
```

---

## 5. Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  # NPM dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "npm"
    commit-message:
      prefix: "chore(deps):"
    groups:
      dev-dependencies:
        dependency-type: "development"
      production-dependencies:
        dependency-type: "production"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "github-actions"
    commit-message:
      prefix: "chore(actions):"

  # Docker
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "docker"
```

---

## 6. Repository Settings

### General Settings

```yaml
Features:
  - Wikis: Disabled (use docs/ instead)
  - Issues: Enabled
  - Projects: Enabled
  - Discussions: Enabled (for community repos)
  - Preserve this repository: false

Pull Requests:
  - Allow merge commits: true
  - Allow squash merging: true (default)
  - Allow rebase merging: false
  - Always suggest updating PR branches: true
  - Automatically delete head branches: true

Archives:
  - Include Git LFS objects: true
```

### Security Settings

```yaml
Security:
  - Dependency graph: Enabled
  - Dependabot alerts: Enabled
  - Dependabot security updates: Enabled
  - Code scanning: Enabled
  - Secret scanning: Enabled
  - Push protection: Enabled

Access:
  - Base permissions: Read
  - Admin access: Restricted
  - Outside collaborators: Require approval
```

---

## 7. Secrets Management

### Secret Types

```
Repository Secrets:
  - API_KEY
  - DATABASE_URL
  - JWT_SECRET

Environment Secrets:
  - production/DEPLOY_KEY
  - staging/DEPLOY_KEY

Organization Secrets:
  - SHARED_NPM_TOKEN
  - SLACK_WEBHOOK
```

### Best Practices

- Never commit secrets to code
- Use environment-specific secrets
- Rotate secrets regularly
- Audit secret access
- Use OIDC for cloud providers

---

## 8. Release Management

### Release Workflow

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: npm run build

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
          files: |
            dist/*
```

### Semantic Versioning

```
MAJOR.MINOR.PATCH

- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

Examples:
1.0.0 → 2.0.0  # Breaking change
1.0.0 → 1.1.0  # New feature
1.0.0 → 1.0.1  # Bug fix
```

## CLI Quick Reference

```bash
# Repository setup
gh repo create org/repo --public --clone
gh repo edit --enable-issues --enable-wiki=false

# Branch protection
gh api repos/{owner}/{repo}/branches/main/protection \
  -X PUT -F required_status_checks='{"strict":true}'

# Secrets
gh secret set API_KEY --body "..."
gh secret list

# Labels
gh label create "priority: high" --color "b60205"
gh label list
```

## References

- [GitHub Repository Settings](https://docs.github.com/en/repositories)
- [Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
