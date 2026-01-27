# Prompt Library

**The single source of truth for all reusable prompt content.**

Every file in this directory is designed to be:
1. **Copy/pasted** directly into any AI assistant (ChatGPT, Claude, etc.)
2. **Included** in skills, phases, and hooks via `{{include:library/name.md}}`
3. **The only place** this methodology exists (no duplication)

## Architecture

```
prompts/library/     ← YOU ARE HERE (Source of Truth)
       │
       ├──→ phases/          (compose from library)
       ├──→ skills/          (compose from library)
       └──→ hooks/           (may reference library)
```

**Golden Rule:** If methodology exists here, use `{{include:}}`. Never duplicate.

## Available Prompts

### Core Principles

| File | Description | Use When |
|------|-------------|----------|
| [base.md](base.md) | Core AI agent principles | Starting any development work |
| [code-quality.md](code-quality.md) | SOLID, DRY, KISS, YAGNI | Writing or reviewing code |
| [testing.md](testing.md) | Test pyramid, AAA pattern, TDD | Writing or reviewing tests |
| [planning.md](planning.md) | Gap analysis, implementation planning | Planning features |

### Review & Audit

| File | Description | Use When |
|------|-------------|----------|
| [code-review.md](code-review.md) | Multi-pass review, findings ledger | Reviewing code changes |
| [security.md](security.md) | OWASP Top 10, security checklist | Security audits |
| [performance.md](performance.md) | Performance patterns, profiling | Performance analysis |
| [architecture-review.md](architecture-review.md) | Structure, coupling, scalability | Architecture assessment |
| [technical-debt.md](technical-debt.md) | Debt identification, priority matrix | Tech debt assessment |

### Discovery & Research

| File | Description | Use When |
|------|-------------|----------|
| [competitor-analysis.md](competitor-analysis.md) | Competitive research framework | Researching alternatives |
| [feature-discovery.md](feature-discovery.md) | RICE scoring, feature specs | Planning roadmap |
| [ux-review.md](ux-review.md) | CLI/UX audit methodology | Improving user experience |

### Specialized Topics

| File | Description | Use When |
|------|-------------|----------|
| [debugging.md](debugging.md) | Systematic debugging approach | Investigating bugs |
| [error-handling.md](error-handling.md) | Error patterns, retry, circuit breaker | Implementing error handling |
| [api-design.md](api-design.md) | REST API design principles | Designing APIs |
| [git-workflow.md](git-workflow.md) | Commits, branches, PRs | Git operations |
| [documentation.md](documentation.md) | Documentation standards | Writing docs |
| [refactor.md](refactor.md) | Refactoring guidelines | Refactoring code |

### Composed Prompts

These include other library prompts for comprehensive coverage:

| File | Includes | Use When |
|------|----------|----------|
| [diagnose.md](diagnose.md) | debugging.md | Bug diagnosis |
| [security-review.md](security-review.md) | security.md | Full security audit |

## Usage

### Copy/Paste (Any AI Assistant)

Open any file and copy the entire content into ChatGPT, Claude, or any other AI assistant. Each file is self-contained and works standalone.

### Include in Skills

```markdown
---
name: my-skill
---

# My Skill

{{include:library/code-quality.md}}
{{include:library/testing.md}}

Now apply these standards to...
```

### Include in Phases

```markdown
# Phase 3: IMPLEMENT

## Quality Standards
{{include:library/code-quality.md}}

## Security Requirements
{{include:library/security.md}}
```

### Resolution Order

1. Project-specific: `.doyaken/prompts/library/`
2. Global: `$DOYAKEN_HOME/prompts/library/`

## Design Principles

### Self-Contained

Each file works independently:
- No external dependencies
- All context provided
- Works when copy-pasted directly

### Universal

Files work across:
- Any programming language
- Any framework
- Any AI assistant (Claude, ChatGPT, Gemini, etc.)

### Structured

Each file follows a consistent structure:
- **Mindset**: Mental model and principles
- **Content**: Checklists, methodology, patterns
- **Template**: Output format (if applicable)
- **Examples**: Code samples and quick reference

### Single Source of Truth

- Each topic has ONE file
- Update here, improvements propagate everywhere
- No duplicated methodology across the codebase

## Creating New Library Prompts

### When to Create

Create a new library prompt when:
- Methodology will be reused across skills/phases
- You're about to duplicate content
- You want something copy-pastable for standalone use

### Template

```markdown
# [Topic Name]

## Mindset

- [Key principle 1]
- [Key principle 2]
- [Key principle 3]

## [Main Section 1]

### [Subsection]

- [ ] Checklist item 1
- [ ] Checklist item 2

### [Another Subsection]

[Detailed guidance...]

## [Main Section 2]

[Continue with content...]

## Template (if applicable)

\`\`\`
[Output format template]
\`\`\`

## Quick Reference

[Code examples, common patterns]
```

### Checklist

- [ ] File is self-contained (works copy-pasted)
- [ ] Has clear structure (Mindset → Content → Template)
- [ ] Uses universal language
- [ ] Added to this README's table
- [ ] Added to `scripts/test.sh`

## See Also

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Full development guidelines
- [prompts/README.md](../README.md) - Prompts system overview
- [skills/](../../skills/) - Skills that compose from library
