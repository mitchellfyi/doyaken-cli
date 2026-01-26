---
name: github:pr-review
description: Review a pull request with comprehensive feedback
requires:
  - github
args:
  - name: pr
    description: Pull request number
    default: ""
  - name: repo
    description: Repository (owner/repo format)
    default: ""
---

# Pull Request Review

You are reviewing a pull request using GitHub MCP tools.

## Context

Project: {{DOYAKEN_PROJECT}}
Pull Request: {{ARGS.pr}}
Repository: {{ARGS.repo}}

## Review Process

### 1. Fetch PR Information

Use GitHub MCP tools to:

1. **Get PR details**
   - Title, description, author
   - Base and head branches
   - Changed files list

2. **Get PR diff**
   - Review all changed files
   - Note additions and deletions

3. **Check PR status**
   - CI/CD check results
   - Review status
   - Merge conflicts

### 2. Code Review

Apply code review best practices:

{{include:vendors/github/code-review.md}}

### 3. Review Criteria

Evaluate the PR against:

**Code Quality**
- [ ] Code follows project conventions
- [ ] No unnecessary complexity
- [ ] Clear naming and structure
- [ ] Appropriate error handling

**Testing**
- [ ] Tests added for new functionality
- [ ] Existing tests pass
- [ ] Edge cases considered

**Security**
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No obvious vulnerabilities

**Documentation**
- [ ] Code is self-documenting
- [ ] Complex logic is commented
- [ ] API changes documented

### 4. Submit Review

Use GitHub MCP to submit the review:

- **Approve**: All criteria met, no blocking issues
- **Request Changes**: Issues that must be fixed before merge
- **Comment**: Feedback without blocking

## Output

Provide a structured review summary:

```markdown
## PR Review: #{{ARGS.pr}}

**Verdict**: Approve / Request Changes / Comment

### Summary
[1-2 sentence summary of the changes]

### Strengths
- [What's done well]

### Issues
- **[Severity]**: [Description] ([file:line])

### Suggestions
- [Optional improvements]

### Checklist
- [ ] Code quality
- [ ] Tests
- [ ] Security
- [ ] Documentation
```
