# Commit Message Format

Follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.

## Format

```
<type>(<scope>): <short description>
```

**Types**: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`

## Multi-line Messages

Use a HEREDOC for commits with a body:

```bash
git commit -m "$(cat <<'EOF'
feat(inventory): add batch allocation endpoint

Implements the allocation algorithm with optimistic locking
to prevent race conditions on concurrent requests.

Co-Authored-By: Doyaken <noreply@doyaken.ai>
EOF
)"
```

## Grouping

Each commit should be a single logical unit. Group related changes together:

- Schema/migration + corresponding model/entity/type changes
- Service/business logic + its tests
- API endpoint + request/response types
- UI component + tests
- Configuration changes

## Rules

- Never commit broken code or failing tests.
- Never skip hooks (`--no-verify`).
- Never amend commits that have already been pushed.
- Never use `git add -A` or `git add .` — stage specific files.
- If unsure whether to split into multiple commits, prefer more granular commits.

## Forbidden Files

Never commit:
- `.env`, credentials, secrets, or key files
- Files modified by the worktree setup script (check `.env` at repo root, any files marked with `git update-index --assume-unchanged`)
