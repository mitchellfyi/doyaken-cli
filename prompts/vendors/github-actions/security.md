# GitHub Actions Security

Security best practices for GitHub Actions workflows.

## When to Apply

Activate this guide when:
- Auditing workflow security
- Hardening CI/CD pipelines
- Reviewing third-party actions
- Setting up secrets management

---

## 1. Action Pinning

### Pin to Commit SHA

```yaml
# BAD: Using branch/tag (mutable)
- uses: actions/checkout@main
- uses: actions/checkout@v4

# GOOD: Pinned to commit SHA (immutable)
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1

# BEST: Pinned with comment for version
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

### Automated Pin Updates

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(actions):"
```

### Finding SHA for Version

```bash
# Get SHA for a tag
gh api repos/actions/checkout/git/refs/tags/v4.1.1 --jq '.object.sha'

# Or via git
git ls-remote --tags https://github.com/actions/checkout.git | grep v4.1.1
```

---

## 2. Permissions

### Principle of Least Privilege

```yaml
# Set restrictive defaults at workflow level
permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

  release:
    runs-on: ubuntu-latest
    # Override only where needed
    permissions:
      contents: write
      packages: write
    steps:
      - uses: actions/checkout@v4
      - run: ./release.sh
```

### Permission Reference

```yaml
permissions:
  actions: read|write|none
  attestations: read|write|none
  checks: read|write|none
  contents: read|write|none
  deployments: read|write|none
  discussions: read|write|none
  id-token: write|none          # OIDC token
  issues: read|write|none
  packages: read|write|none
  pages: read|write|none
  pull-requests: read|write|none
  repository-projects: read|write|none
  security-events: read|write|none
  statuses: read|write|none
```

### Default Permissions

```yaml
# Organization/repo setting recommendation:
# Settings → Actions → General → Workflow permissions
# Select: "Read repository contents and packages permissions"
# Uncheck: "Allow GitHub Actions to create and approve pull requests"
```

---

## 3. Secrets Management

### Using Secrets Safely

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # GOOD: Pass as environment variable
      - name: Deploy
        run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}

      # BAD: Inline in command (may leak in logs)
      - run: curl -H "Authorization: ${{ secrets.API_KEY }}" https://api.example.com
```

### Secret Masking

```yaml
steps:
  - name: Generate token
    id: token
    run: |
      TOKEN=$(generate-token)
      echo "::add-mask::$TOKEN"
      echo "token=$TOKEN" >> $GITHUB_OUTPUT

  - name: Use token
    run: ./deploy.sh
    env:
      TOKEN: ${{ steps.token.outputs.token }}
```

### Environment Secrets

```yaml
jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment: production  # Requires approval
    steps:
      - run: ./deploy.sh
        env:
          # Only accessible in production environment
          PROD_API_KEY: ${{ secrets.PROD_API_KEY }}
```

---

## 4. Input Validation

### Sanitize Inputs

```yaml
jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
      # BAD: Direct interpolation (injection risk)
      - run: echo "Hello ${{ github.event.issue.title }}"

      # GOOD: Use environment variable
      - run: echo "Hello $TITLE"
        env:
          TITLE: ${{ github.event.issue.title }}
```

### Dangerous Contexts

```yaml
# These can contain attacker-controlled content:
github.event.issue.title
github.event.issue.body
github.event.pull_request.title
github.event.pull_request.body
github.event.comment.body
github.event.review.body
github.event.head_commit.message
github.event.commits[*].message
github.head_ref  # PR branch name

# NEVER interpolate directly in run: commands
# ALWAYS pass via env: or use actions/github-script
```

### Safe Pattern

```yaml
steps:
  # Using actions/github-script for safe API calls
  - uses: actions/github-script@v7
    with:
      script: |
        const title = context.payload.issue.title;
        // title is properly escaped
        await github.rest.issues.createComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          issue_number: context.issue.number,
          body: `Processing: ${title}`
        });
```

---

## 5. Workflow Triggers

### Restrict Workflow Triggers

```yaml
on:
  # Limit to specific branches
  push:
    branches: [main]
  pull_request:
    branches: [main]

  # Be careful with these (can expose secrets):
  # pull_request_target - Runs with repo write access
  # workflow_run - Can access secrets from triggering workflow
```

### pull_request_target Safety

```yaml
# DANGEROUS: Running untrusted code with write access
on:
  pull_request_target:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # Attacker code!
      - run: npm install  # Runs attacker's package.json!

# SAFER: Only checkout trusted code, use separate job for untrusted
on:
  pull_request_target:

jobs:
  # Job 1: Run on trusted base
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4  # Trusted base branch
      - run: ./add-labels.sh

  # Job 2: Build untrusted (no secrets)
  build:
    runs-on: ubuntu-latest
    permissions: {}  # No permissions
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
```

---

## 6. Third-Party Actions

### Vetting Actions

Before using a third-party action:

1. **Check source repository**
   - Is it actively maintained?
   - Does it have security policy?
   - Are issues addressed?

2. **Review the code**
   - What permissions does it need?
   - Does it phone home?
   - Are dependencies pinned?

3. **Check for vulnerabilities**
   - Search for CVEs
   - Check npm audit
   - Review GitHub security advisories

### Alternatives to Third-Party Actions

```yaml
# Instead of untrusted action:
- uses: random-org/deploy-action@v1

# Use official actions or scripts:
- uses: actions/github-script@v7
  with:
    script: |
      // Your deployment logic
```

### Fork Critical Actions

```yaml
# For critical workflows, fork and audit:
- uses: your-org/forked-action@audited-sha
```

---

## 7. Self-Hosted Runners

### Security Considerations

```yaml
# NEVER use self-hosted runners for public repos
# Attackers can run arbitrary code via PRs

# For private repos, isolate runners:
jobs:
  build:
    runs-on: [self-hosted, linux, production]
    # Use labels to separate environments
```

### Runner Hardening

- Use ephemeral runners (destroy after each job)
- Run in containers or VMs
- Limit network access
- Don't store credentials on runner
- Regular security updates
- Monitor runner activity

---

## 8. Security Checklist

### Workflow Review

- [ ] All actions pinned to SHA
- [ ] Permissions set to minimum required
- [ ] No direct interpolation of user input
- [ ] Secrets not logged or exposed
- [ ] Third-party actions vetted
- [ ] Appropriate trigger restrictions
- [ ] OIDC used for cloud auth (no static credentials)

### Repository Settings

- [ ] Branch protection enabled
- [ ] Required reviews for workflows
- [ ] Restrict who can approve workflow runs
- [ ] Secret scanning enabled
- [ ] Dependabot enabled for actions

### Monitoring

- [ ] Audit logs reviewed regularly
- [ ] Failed workflow alerts configured
- [ ] Unusual activity monitoring
- [ ] Secret rotation schedule

---

## 9. Security Tools

### Built-in Security

```yaml
# Enable CodeQL scanning
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1'

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
```

### Dependency Review

```yaml
name: Dependency Review

on: pull_request

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: moderate
          deny-licenses: GPL-3.0, AGPL-3.0
```

## References

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OIDC for Cloud Providers](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments)
- [StepSecurity](https://www.stepsecurity.io/)
