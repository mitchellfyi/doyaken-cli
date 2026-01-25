# Git Workflow & Best Practices

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

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `docs`: Documentation only
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (deps, configs)
- `perf`: Performance improvement

**Good messages:**
```
feat: Add user email validation

- Validate format before save
- Return specific error for invalid emails
- Add unit tests for edge cases

Closes #123
```

**Bad messages:**
```
fix stuff
WIP
asdf
```

### Commit Frequency

- Commit early and often
- Don't batch unrelated changes
- Commit when tests pass, not at end of day
- Each commit should be deployable (not break the build)

## Branching Strategy

### Branch Naming
```
feature/user-authentication
bugfix/login-timeout
hotfix/security-patch
refactor/database-queries
```

### Branch Hygiene
- Keep branches short-lived (< 1 week ideal)
- Rebase on main before merging
- Delete branches after merge
- Don't commit directly to main/master

## Pull Requests

### PR Size
- Aim for < 400 lines changed
- Split large changes into stacked PRs
- One concern per PR

### PR Description Template
```markdown
## Summary
[1-3 bullet points of what this PR does]

## Changes
- [specific change 1]
- [specific change 2]

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing performed
- [ ] Edge cases covered

## Screenshots (if UI)
[before/after if applicable]
```

### Before Merging
- [ ] All CI checks pass
- [ ] Code reviewed and approved
- [ ] Conflicts resolved
- [ ] Branch is up to date with base
- [ ] PR description is complete

## Common Operations

### Updating Branch with Main
```bash
# Preferred: Rebase (cleaner history)
git fetch origin
git rebase origin/main

# Alternative: Merge (preserves history)
git fetch origin
git merge origin/main
```

### Fixing Last Commit
```bash
# Amend message
git commit --amend -m "New message"

# Add forgotten files (don't change message)
git add forgotten-file.js
git commit --amend --no-edit
```

### Undoing Changes
```bash
# Undo last commit, keep changes staged
git reset --soft HEAD~1

# Undo last commit, keep changes unstaged
git reset HEAD~1

# Discard all uncommitted changes (DANGEROUS)
git reset --hard HEAD
```

### Interactive Rebase (Cleaning History)
```bash
# Squash last 3 commits
git rebase -i HEAD~3
```

## What NOT to Commit

- `.env` files with real credentials
- API keys, passwords, secrets
- Large binary files
- Build artifacts (`node_modules/`, `dist/`, `__pycache__/`)
- IDE-specific files (`.idea/`, `.vscode/settings.json`)
- OS files (`.DS_Store`, `Thumbs.db`)

### .gitignore Essentials
```gitignore
# Dependencies
node_modules/
vendor/
venv/

# Build outputs
dist/
build/
*.pyc

# Environment
.env
.env.local
*.pem
*.key

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db
```

## Handling Conflicts

1. **Understand both changes** before resolving
2. **Talk to the other author** if unclear
3. **Test after resolving** - conflicts often hide bugs
4. **Don't just accept one side** - merge logic carefully

### Conflict Markers
```
<<<<<<< HEAD
your changes
=======
their changes
>>>>>>> branch-name
```

## Emergency Procedures

### Accidentally Committed Secrets
```bash
# Remove from history (requires force push)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret' \
  --prune-empty -- --all

# Rotate the compromised credentials immediately!
```

### Recover Deleted Branch
```bash
# Find the commit
git reflog

# Recreate branch
git checkout -b recovered-branch <commit-hash>
```

## Checklist Before Push

- [ ] All tests pass locally
- [ ] No debug code or console.logs
- [ ] No hardcoded values that should be config
- [ ] Commit messages are clear
- [ ] No unintended files included
- [ ] Branch is rebased on latest main
