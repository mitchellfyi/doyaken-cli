# Prompts

All prompt content for doyaken follows a **library-first architecture**.

```
prompts/
├── library/     # SOURCE OF TRUTH - reusable prompt modules
│   ├── code-quality.md
│   ├── security.md
│   ├── testing.md
│   └── ... (20+ modules)
├── phases/      # Workflow phases (compose from library)
│   ├── 0-expand.md
│   ├── 1-triage.md
│   └── ... (8 phases)
└── README.md
```

## Architecture

```
┌─────────────────────────────────────┐
│          prompts/library/           │
│       (Single Source of Truth)      │
│                                     │
│  • Self-contained methodology       │
│  • Copy-pastable into any AI        │
│  • No duplication allowed           │
└─────────────────────────────────────┘
                  │
       ┌──────────┴──────────┐
       ▼                     ▼
┌─────────────┐       ┌─────────────┐
│   phases/   │       │   skills/   │
│             │       │             │
│  Compose    │       │  Compose    │
│  from       │       │  from       │
│  library    │       │  library    │
└─────────────┘       └─────────────┘
```

## Golden Rule

> **Library prompts are the source of truth. Never duplicate methodology.**

When you need guidance on security, testing, code quality, etc.:
1. Check `library/` for existing content
2. Use `{{include:library/name.md}}` to compose
3. If missing, create in `library/` first, then include

## Directories

### [library/](library/)

The **single source of truth** for all reusable prompt content.

Each file is:
- **Copy-pastable**: Works directly in any AI assistant
- **Includable**: Use `{{include:library/name.md}}`
- **Self-contained**: No external dependencies

See [library/README.md](library/README.md) for the full list.

### [phases/](phases/)

The 8-phase workflow executed by `doyaken run`:

| Phase | File | Purpose |
|-------|------|---------|
| 0 | `0-expand.md` | Expand brief prompt into full spec |
| 1 | `1-triage.md` | Validate task, check dependencies |
| 2 | `2-plan.md` | Gap analysis, detailed planning |
| 3 | `3-implement.md` | Execute the plan, write code |
| 4 | `4-test.md` | Run tests, add coverage |
| 5 | `5-docs.md` | Sync documentation |
| 6 | `6-review.md` | Code review, create follow-ups |
| 7 | `7-verify.md` | Verify completion, commit |

Phases compose from library:
```markdown
# Phase 3: IMPLEMENT

{{include:library/code-quality.md}}
{{include:library/testing.md}}

[Phase-specific instructions...]
```

## Include System

### Syntax

```markdown
{{include:library/security.md}}
```

### Resolution Order

1. Project: `.doyaken/prompts/library/security.md`
2. Global: `$DOYAKEN_HOME/prompts/library/security.md`

### Nesting

Includes can nest (max depth 5):
```markdown
# library/full-review.md
{{include:library/code-quality.md}}
{{include:library/security.md}}
{{include:library/testing.md}}
```

### Variables

| Variable | Available In | Description |
|----------|--------------|-------------|
| `{{TASK_ID}}` | Phases | Current task ID |
| `{{TASK_FILE}}` | Phases | Path to task file |
| `{{TIMESTAMP}}` | Phases | Current timestamp |
| `{{AGENT_ID}}` | Phases | Worker agent ID |
| `{{DOYAKEN_PROJECT}}` | Skills | Project directory |
| `{{ARGS.name}}` | Skills | Skill argument |

## Development

### Adding to Library

1. Create `prompts/library/topic-name.md`
2. Follow the structure in [library/README.md](library/README.md)
3. Add to library README table
4. Add to `scripts/test.sh`

### Using in Skills

```markdown
---
name: my-skill
---

{{include:library/code-quality.md}}

Now apply these standards to {{DOYAKEN_PROJECT}}...
```

### Using in Phases

```markdown
# Phase N: NAME

{{include:library/relevant-content.md}}

## Phase-Specific Instructions
[...]
```

## See Also

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Full architecture documentation
- [skills/](../skills/) - Skills that compose from library
