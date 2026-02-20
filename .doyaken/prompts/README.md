# Prompts

All prompt content for doyaken follows a **library-first architecture**.

```
prompts/
├── library/     # SOURCE OF TRUTH - reusable prompt modules
│   ├── code-quality.md
│   ├── security.md
│   ├── testing.md
│   └── ... (20+ modules)
├── vendors/     # Vendor-specific prompt libraries
│   ├── vercel/  # Vercel, Next.js, React optimization
│   │   ├── react-best-practices.md
│   │   ├── web-design-guidelines.md
│   │   └── deployment.md
│   └── ...      # Future vendors (aws, gcp, etc.)
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

The 8-phase pipeline executed by `dk run "<prompt>"`:

| Phase | File | Purpose |
|-------|------|---------|
| 0 | `0-expand.md` | Expand brief prompt into full spec |
| 1 | `1-triage.md` | Validate feasibility, check dependencies |
| 2 | `2-plan.md` | Gap analysis, detailed planning |
| 3 | `3-implement.md` | Write code (with verification gates) |
| 4 | `4-test.md` | Run tests, add coverage (with verification gates) |
| 5 | `5-docs.md` | Sync documentation |
| 6 | `6-review.md` | Code review, quality check (with verification gates) |
| 7 | `7-verify.md` | Final verification, commit |

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
# Core library
{{include:library/security.md}}

# Vendor library
{{include:vendors/vercel/react-best-practices.md}}
```

### Resolution Order

1. Project: `.doyaken/prompts/library/security.md`
2. Global: `$DOYAKEN_HOME/prompts/library/security.md`

For vendor prompts:
1. Project: `.doyaken/prompts/vendors/vercel/react-best-practices.md`
2. Global: `$DOYAKEN_HOME/prompts/vendors/vercel/react-best-practices.md`

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
| `{{TASK_ID}}` | Phases | Generated task ID |
| `{{TASK_PROMPT}}` | Phases | The original prompt text |
| `{{ACCUMULATED_CONTEXT}}` | Phases | Context from prior phases and retries |
| `{{VERIFICATION_CONTEXT}}` | All phases | Gate failure output for retries |
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

## Vendor Prompts

Vendor-specific libraries extend doyaken with specialized knowledge:

| Vendor | Description | MCP Required |
|--------|-------------|--------------|
| [vercel](vendors/vercel/) | Next.js, React, deployment patterns | Optional |

### Using Vendor Prompts

```markdown
# In a skill
{{include:vendors/vercel/react-best-practices.md}}

# In a phase
{{include:vendors/vercel/web-design-guidelines.md}}
```

See [vendors/README.md](vendors/README.md) for full documentation.

## See Also

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Full architecture documentation
- [skills/](../skills/) - Skills that compose from library
- [vendors/](vendors/) - Vendor-specific prompt libraries
