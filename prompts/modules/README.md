# Prompt Modules

Standalone, reusable prompt modules containing specialist knowledge and best practices. Each module is self-contained and can be:

1. **Copy/pasted** into any AI coding assistant
2. **Included** in doyaken phase prompts via `{{include:modules/name.md}}`
3. **Referenced** by skills and hooks

## Available Modules

### Core Development

| Module | Description | Best for |
|--------|-------------|----------|
| [testing.md](testing.md) | Testing methodology, test pyramid, AAA pattern | Writing tests, TDD |
| [code-review.md](code-review.md) | Multi-pass review process, findings ledger | Code reviews, PR reviews |
| [planning.md](planning.md) | Gap analysis, implementation planning | Starting new features |
| [debugging.md](debugging.md) | Systematic debugging methodology | Fixing bugs, diagnosis |

### Quality & Security

| Module | Description | Best for |
|--------|-------------|----------|
| [security.md](security.md) | OWASP Top 10, security checklist | Security reviews, audits |
| [error-handling.md](error-handling.md) | Error handling patterns, resilience | Writing robust code |
| [performance.md](performance.md) | Performance optimization, profiling | Optimizing code |

### Documentation & Workflow

| Module | Description | Best for |
|--------|-------------|----------|
| [documentation.md](documentation.md) | Documentation standards, what to document | Writing docs |
| [git-workflow.md](git-workflow.md) | Commits, branches, PRs, merge strategies | Git operations |
| [api-design.md](api-design.md) | REST API design principles | Designing APIs |

## Usage

### Standalone (copy/paste)

Copy the content of any module and paste it into your AI assistant's context or system prompt.

### In Doyaken Phase Prompts

```markdown
# My Phase

Some workflow instructions...

{{include:modules/testing.md}}

More instructions...
```

### In Skills

```markdown
---
name: security-audit
description: Run a security audit
---

{{include:modules/security.md}}

Now audit the following code...
```

## Contributing

Each module should be:
- **Self-contained**: No dependencies on other modules
- **Actionable**: Provides concrete steps, not just theory
- **Balanced**: Thorough but not overwhelming
- **Universal**: Works across languages and frameworks
