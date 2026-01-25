# Prompts

All prompt content for doyaken.

```
prompts/
├── phases/      # Workflow phase prompts (0-7)
├── library/     # Reusable prompt content (source of truth)
└── README.md
```

## Structure

### [phases/](phases/)
The 8-phase workflow executed by `doyaken run`. Each phase runs in sequence with fresh context.

### [library/](library/)
Single source of truth for reusable content. Used by phases, skills, and hooks via `{{include:library/...}}`.

## Include System

Prompts can include library content:
```markdown
{{include:library/testing.md}}
```

The include system:
- Checks project `.doyaken/prompts/` first
- Falls back to global `$DOYAKEN_HOME/prompts/`
- Supports nested includes (max depth 5)
