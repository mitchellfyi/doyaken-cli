---
description: Apply git methodology
---

# Git Workflow

## Commit Discipline

### Atomic Commits
Each commit should be:
- **Focused**: One logical change per commit
- **Complete**: Doesn't leave code in broken state
- **Reversible**: Can be reverted independently

### Commit Message Format

```
<type>: <short description>

[optional body]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change (no feature/fix)
- `docs`: Documentation only
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

### Commit Frequency
- Commit early and often
- Don't batch unrelated changes
- Commit when tests pass
- Each commit should not break the build

## Branching

### Branch Naming
```
feature/user-authentication
bugfix/login-timeout
hotfix/security-patch
```

### Branch Hygiene
- Keep branches short-lived
- Rebase on main before merging
- Delete branches after merge
- Don't commit directly to main

## Pull Requests

### PR Size
- Aim for < 400 lines changed
- One concern per PR

### Before Merging
- [ ] All CI checks pass
- [ ] Code reviewed
- [ ] Conflicts resolved
- [ ] Branch up to date with base

## What NOT to Commit

- `.env` files with real credentials
- API keys, passwords, secrets
- Large binary files
- Build artifacts
- IDE-specific files

## Pre-Push Checklist

- [ ] All tests pass locally
- [ ] No debug code
- [ ] No hardcoded values
- [ ] Commit messages are clear
- [ ] No unintended files included

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
