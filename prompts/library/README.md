# Prompt Library

Single source of truth for reusable prompt content. Used by phases, skills, and hooks.

Each file can be:
1. **Copy/pasted** into any AI coding assistant
2. **Included** in prompts via `{{include:library/name.md}}`
3. **Referenced** by skills and hooks

## Available Prompts

### Principles

| File | Description |
|------|-------------|
| [code-quality.md](code-quality.md) | SOLID, DRY, KISS, YAGNI - core quality principles |
| [testing.md](testing.md) | Testing methodology, test pyramid, AAA pattern |
| [code-review.md](code-review.md) | Multi-pass review process, findings ledger |
| [planning.md](planning.md) | Gap analysis, implementation planning |
| [debugging.md](debugging.md) | Systematic debugging methodology |
| [security.md](security.md) | OWASP Top 10, security checklist |

### Patterns

| File | Description |
|------|-------------|
| [error-handling.md](error-handling.md) | Error handling patterns, retry, circuit breaker |
| [api-design.md](api-design.md) | REST API design principles |
| [performance.md](performance.md) | Performance optimization, profiling |
| [git-workflow.md](git-workflow.md) | Commits, branches, PRs |
| [documentation.md](documentation.md) | Documentation standards |

### Complete Prompts

| File | Description |
|------|-------------|
| [base.md](base.md) | Core principles and mindset |
| [diagnose.md](diagnose.md) | Bug diagnosis (includes debugging.md) |
| [security-review.md](security-review.md) | Security audit (includes security.md) |
| [refactor.md](refactor.md) | Code refactoring guidelines |

## Usage

### In phase prompts
```markdown
{{include:library/testing.md}}
```

### In skills
```markdown
---
name: security-audit
---

{{include:library/security.md}}

Now audit the following code...
```

### Copy/paste
Each file is self-contained and works standalone.

## Design Principles

- **Self-contained**: Each file works independently
- **Composable**: Can be included in other prompts
- **Single source of truth**: Update once, used everywhere
- **Universal**: Works across languages and frameworks
