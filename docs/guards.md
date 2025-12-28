# Guards

Doyaken uses markdown-based guard rules to block or warn about dangerous patterns before they happen. Guards are evaluated by `hooks/guard-handler.py` on PreToolUse (before Bash/Edit/Write). Post-commit validation (after git commit) is handled by `hooks/post-commit-guard.sh`, which checks conventional commit format and then delegates to `guard-handler.py` for markdown-based guard evaluation of committed files.

These are Claude Code hooks — see [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks) for how hooks integrate with the tool lifecycle.

## How It Works

1. Claude invokes a tool (Bash, Edit, Write)
2. The hook passes the tool input to `guard-handler.py`
3. The handler loads all enabled guard `.md` files
4. Each guard's regex pattern is checked against the input
5. Matching guards trigger a **warn** (message shown, tool proceeds) or **block** (tool prevented, exit code 2)

## Guard File Format

Guards are markdown files with YAML frontmatter, stored in:
- `hooks/guards/*.md` — built-in guards (ship with Doyaken)
- `.doyaken/guards/*.md` — project-specific guards (per-repo)

```markdown
---
name: guard-name
enabled: true
event: bash|file|commit|all
pattern: regex-pattern
action: warn|block
---

Message shown when the guard triggers.
Supports **markdown** formatting.
```

### Fields

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `name` | yes | string | Unique identifier for the guard |
| `enabled` | yes | true/false/yes/no | Toggle without deleting the file |
| `event` | yes | bash, file, commit, all | When to evaluate this guard |
| `pattern` | yes | Python regex | Pattern to match against tool input |
| `action` | yes | warn, block | Warn shows a message; block prevents the action |
| `case_sensitive` | no | true/false/yes/no | If true, pattern matching is case-sensitive (default: false) |

### Event Types

| Event | Triggers On | Input Checked |
|-------|------------|---------------|
| `bash` | PreToolUse for Bash commands | The command string |
| `file` | PreToolUse for Edit/Write/MultiEdit | The file content being written |
| `commit` | PostToolUse after `git commit` | Committed file paths + commit message |
| `all` | All of the above | Varies by context |

## Built-in Guards

| Guard | Event | Action | What It Catches |
|-------|-------|--------|----------------|
| `block-destructive-commands` | bash | block | `rm -rf /`, `rm -rf ~`, `rm -rf .`, `rm -rf ./`, `rm -rf *` (but NOT `rm -rf /tmp` or `rm -rf ./build`), `dd if=`, `mkfs`, `format` |
| `warn-sensitive-files` | commit | warn | `.env`, credentials, keys, certs in commits |
| `warn-hardcoded-secrets` | file | warn | `API_KEY = "..."`, `ACCESS_KEY`, `JWT_SECRET`, and other credential patterns in code |

Note: Conventional commit format validation is handled by `hooks/post-commit-guard.sh` directly (not via guards) because commit events combine file paths and the message into a single text, making it impossible to write a guard pattern that targets only the commit message.

Project-specific guards (e.g., framework-specific endpoint checks, worktree config protection) are generated during `dk init` in `.doyaken/guards/` within the repo.

## Adding Project-Specific Guards

Create a `.md` file in `.doyaken/guards/`:

```bash
# Example: block force-push in this repo
cat > .doyaken/guards/no-force-push.md << 'EOF'
---
name: no-force-push
enabled: true
event: bash
pattern: git\s+push\s+.*--force
action: block
---

BLOCKED: Force-push is not allowed in this repository.

Use `git push --force-with-lease` instead for safer force-pushing.
EOF
```

Guards in `.doyaken/guards/` are repo-specific and take effect immediately — no restart needed.

## Disabling a Guard

Edit the guard file and set `enabled: false`:

```yaml
---
name: guard-name
enabled: false
...
---
```

## Pattern Syntax

Guards use Python regex (`re.search` with `re.MULTILINE`). Matching is case-insensitive by default; add `case_sensitive: true` to the frontmatter for exact-case matching:

| Pattern | Matches |
|---------|---------|
| `rm\s+-[a-z]*rf[a-z]*\s+/\s` | `rm -rf / ` (slash then space — anchors to path boundary, won't match `rm -rf /tmp`) |
| `\.env$` | Files ending in `.env` |
| `console\.log\(` | `console.log(...)` |
| `(eval|exec)\(` | `eval(...)` or `exec(...)` |
| `API_KEY\s*[=:]\s*['"]` | `API_KEY = "..."` or `API_KEY: '...'` |

## Testing Guards

```bash
# Test a bash guard
DOYAKEN_GUARD_EVENT=bash CLAUDE_TOOL_USE_INPUT="rm -rf /" python3 hooks/guard-handler.py
echo "Exit: $?"

# Test a file guard
DOYAKEN_GUARD_EVENT=file CLAUDE_TOOL_USE_INPUT='API_KEY = "secret123"' python3 hooks/guard-handler.py
echo "Exit: $?"

# Test a commit guard
DOYAKEN_GUARD_EVENT=commit CLAUDE_TOOL_USE_INPUT=$'config.toml\nfeat: add api' python3 hooks/guard-handler.py
echo "Exit: $?"
```

Exit code 0 = no block, exit code 2 = blocked.
