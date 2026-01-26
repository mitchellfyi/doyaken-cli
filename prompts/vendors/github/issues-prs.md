# GitHub Issues & Pull Requests

Best practices for managing issues and pull requests on GitHub.

## When to Apply

Activate this guide when:
- Creating or managing GitHub issues
- Opening or reviewing pull requests
- Setting up issue templates
- Configuring PR workflows

---

## 1. Issue Management

### Creating Effective Issues

```markdown
## Bug Report

### Description
[Clear, concise description of the bug]

### Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happens]

### Environment
- OS: [e.g., macOS 14.0]
- Browser: [e.g., Chrome 120]
- Version: [e.g., 1.2.3]

### Screenshots
[If applicable]

### Additional Context
[Any other relevant information]
```

### Feature Request Template

```markdown
## Feature Request

### Problem Statement
[What problem does this solve?]

### Proposed Solution
[How should it work?]

### Alternatives Considered
[Other approaches you've thought about]

### Additional Context
[Mockups, examples, or references]
```

### Issue Labels

| Label | Purpose | Color |
|-------|---------|-------|
| `bug` | Something isn't working | `#d73a4a` |
| `feature` | New feature request | `#a2eeef` |
| `enhancement` | Improvement to existing feature | `#84b6eb` |
| `documentation` | Documentation updates | `#0075ca` |
| `good first issue` | Good for newcomers | `#7057ff` |
| `help wanted` | Extra attention needed | `#008672` |
| `priority: high` | High priority | `#b60205` |
| `priority: medium` | Medium priority | `#fbca04` |
| `priority: low` | Low priority | `#0e8a16` |

### Issue Triage Checklist

- [ ] Issue has clear title and description
- [ ] Reproduction steps provided (for bugs)
- [ ] Labels applied appropriately
- [ ] Milestone assigned (if applicable)
- [ ] Assignee designated
- [ ] Related issues linked
- [ ] Duplicate check completed

---

## 2. Pull Request Workflow

### PR Title Conventions

```
type(scope): description

# Examples:
feat(auth): add OAuth2 login support
fix(api): resolve null pointer in user endpoint
docs(readme): update installation instructions
refactor(core): simplify error handling logic
test(auth): add unit tests for login flow
chore(deps): update dependencies
```

### PR Description Template

```markdown
## Summary
[Brief description of changes]

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Related Issues
Closes #123
Related to #456

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots
[If applicable]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### Branch Naming

```bash
# Feature branches
feature/add-user-authentication
feature/123-oauth-integration  # With issue number

# Bug fixes
fix/null-pointer-exception
fix/456-login-redirect-loop

# Hotfixes
hotfix/critical-security-patch

# Documentation
docs/api-reference-update

# Chores
chore/update-dependencies
```

---

## 3. Code Review Guidelines

### Reviewer Checklist

**Functionality:**
- [ ] Code accomplishes stated goal
- [ ] Edge cases handled
- [ ] Error handling appropriate
- [ ] No obvious bugs

**Code Quality:**
- [ ] Follows project conventions
- [ ] DRY - no unnecessary duplication
- [ ] KISS - not over-engineered
- [ ] Readable and maintainable

**Testing:**
- [ ] Adequate test coverage
- [ ] Tests are meaningful
- [ ] CI passes

**Security:**
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities

**Documentation:**
- [ ] Code is self-documenting
- [ ] Complex logic commented
- [ ] API changes documented

### Review Comments

```markdown
# Suggestion (optional improvement)
**Suggestion:** Consider using `const` here since the value isn't reassigned.

# Request (required change)
**Request:** This needs null checking to prevent runtime errors.

# Question (seeking clarification)
**Question:** What's the reasoning behind this approach vs using X?

# Praise (positive feedback)
**Nice!** Clean implementation of the factory pattern here.

# Nitpick (minor style issue)
**Nit:** Missing trailing comma (project convention).
```

### Approval Criteria

**Approve when:**
- All tests pass
- No blocking issues found
- Code meets quality standards
- Documentation updated

**Request changes when:**
- Tests failing
- Security vulnerabilities present
- Breaking changes without migration
- Missing error handling

**Comment only when:**
- Minor suggestions
- Questions need answering
- Non-blocking feedback

---

## 4. Branch Protection

### Recommended Settings

```yaml
# Branch protection for main/master
protection:
  required_reviews: 1
  dismiss_stale_reviews: true
  require_code_owner_reviews: true
  required_status_checks:
    - "build"
    - "test"
    - "lint"
  require_branches_up_to_date: true
  restrictions:
    users: []
    teams: ["maintainers"]
  enforce_admins: false
  allow_force_pushes: false
  allow_deletions: false
```

### CODEOWNERS File

```
# .github/CODEOWNERS

# Default owners
* @team-lead

# Frontend
/src/components/ @frontend-team
/src/styles/ @frontend-team

# Backend
/src/api/ @backend-team
/src/models/ @backend-team

# Infrastructure
/terraform/ @devops-team
/.github/workflows/ @devops-team

# Documentation
/docs/ @docs-team
*.md @docs-team
```

---

## 5. Automation

### Auto-labeling

```yaml
# .github/labeler.yml
documentation:
  - 'docs/**'
  - '*.md'

frontend:
  - 'src/components/**'
  - 'src/styles/**'

backend:
  - 'src/api/**'
  - 'src/models/**'

tests:
  - 'tests/**'
  - '**/*.test.ts'
```

### Stale Issue Management

```yaml
# .github/workflows/stale.yml
name: Stale Issues
on:
  schedule:
    - cron: '0 0 * * *'

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          stale-issue-message: 'This issue has been inactive for 60 days.'
          stale-pr-message: 'This PR has been inactive for 30 days.'
          days-before-issue-stale: 60
          days-before-pr-stale: 30
          days-before-close: 7
          stale-issue-label: 'stale'
          stale-pr-label: 'stale'
```

---

## CLI Quick Reference

```bash
# Issues
gh issue create --title "Bug: ..." --body "..."
gh issue list --state open --label "bug"
gh issue close 123 --reason completed
gh issue edit 123 --add-label "priority: high"

# Pull Requests
gh pr create --title "feat: ..." --body "..."
gh pr list --state open
gh pr checkout 123
gh pr review 123 --approve
gh pr review 123 --request-changes --body "..."
gh pr merge 123 --squash --delete-branch

# Code Review
gh pr diff 123
gh pr checks 123
gh pr comment 123 --body "..."
```

## References

- [GitHub Issues](https://docs.github.com/en/issues)
- [Pull Requests](https://docs.github.com/en/pull-requests)
- [GitHub CLI](https://cli.github.com/manual/)
