# Contributing to Doyaken

This document explains the architecture and development guidelines for doyaken. It's written for both human developers and AI agents working on this codebase.

## Architecture Overview

Doyaken follows a **library-first, composition-based** architecture for all prompt content:

```
                    ┌─────────────────────────────────────┐
                    │     prompts/library/                │
                    │     (Source of Truth)               │
                    │                                     │
                    │  Self-contained, reusable prompts   │
                    │  that work standalone or composed   │
                    └─────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌───────────┐   ┌───────────┐   ┌───────────┐
            │  Phases   │   │  Skills   │   │  Hooks    │
            │           │   │           │   │           │
            │ 0-expand  │   │ security- │   │ quality-  │
            │ 1-triage  │   │   audit   │   │   check   │
            │ 2-plan    │   │ tech-debt │   │           │
            │   ...     │   │   ...     │   │   ...     │
            └───────────┘   └───────────┘   └───────────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │
                                    ▼
                    ┌─────────────────────────────────────┐
                    │     AI Agent Execution              │
                    │                                     │
                    │  claude, cursor, codex, gemini, etc.│
                    └─────────────────────────────────────┘
```

## The Golden Rule

> **Library prompts are the source of truth. Never duplicate prompt content.**

When you need methodology, principles, or structured guidance:
1. Check if it exists in `prompts/library/`
2. If yes, use `{{include:library/name.md}}`
3. If no, create it in `prompts/library/` first, then include it

## Directory Structure

```
doyaken/
├── prompts/
│   ├── library/           # SOURCE OF TRUTH - reusable prompt modules
│   │   ├── code-quality.md
│   │   ├── security.md
│   │   ├── testing.md
│   │   └── ...
│   └── phases/            # Workflow phase prompts (compose from library)
│       ├── 0-expand.md
│       ├── 1-triage.md
│       └── ...
├── skills/                # Runnable skills (compose from library)
│   ├── security-audit.md
│   ├── tech-debt.md
│   └── ...
├── hooks/                 # Git/CLI hooks (may reference library)
│   ├── quality-check.sh
│   └── ...
├── lib/                   # Shell scripts for CLI
├── templates/             # Project templates
└── config/                # Global configuration
```

## Library Prompts (`prompts/library/`)

### Purpose

Library prompts are **self-contained, copy-pastable methodology documents** that:
- Work standalone (can be copied into any AI assistant)
- Can be composed into phases, skills, and hooks
- Are the single source of truth for any given topic

### Design Principles

1. **Self-Contained**: Each file works independently without context
2. **Copy-Pastable**: A user can literally copy the file and paste it into ChatGPT/Claude
3. **Universal**: Works across languages, frameworks, and AI agents
4. **Composable**: Can be included in other prompts via `{{include:}}`
5. **Single Source of Truth**: Update once, used everywhere

### Structure of a Library Prompt

```markdown
# [Topic Name]

## Mindset
[Mental model and principles for approaching this topic]

## [Main Content Sections]
[Checklists, methodology, patterns, examples]

## [Template/Output Format] (if applicable)
[How to structure findings or output]

## Quick Reference (optional)
[Code examples, common patterns]
```

### Example: Creating a New Library Prompt

If you need to add "API versioning" methodology:

```markdown
# prompts/library/api-versioning.md

# API Versioning

## Mindset
- Version for consumers, not implementers
- Breaking changes require major version bumps
- Support at least N-1 versions in production

## Versioning Strategies

### URL Path Versioning
- `/v1/users`, `/v2/users`
- Pros: Explicit, cacheable
- Cons: URL pollution

### Header Versioning
- `Accept: application/vnd.api+json; version=1`
- Pros: Clean URLs
- Cons: Less discoverable

[... etc]

## Checklist
- [ ] Version documented in API spec
- [ ] Breaking change policy defined
- [ ] Deprecation timeline communicated
```

## Phases (`prompts/phases/`)

Phases are the 8-step workflow executed by `doyaken run`. Each phase:
- Runs in sequence with fresh context
- Composes from library prompts
- Has a specific timeout and purpose

### Structure

```markdown
# Phase [N]: [NAME]

## Context
[What this phase receives]

## Instructions
[What the agent should do]

## Quality Standards
{{include:library/code-quality.md}}

## [Phase-Specific Sections]
[Unique to this phase]

## Output
[What this phase produces]
```

### Using Library Includes in Phases

```markdown
# Phase 3: IMPLEMENT

## Code Quality Standards
{{include:library/code-quality.md}}

## Testing Requirements
{{include:library/testing.md}}

## Security Considerations
{{include:library/security.md}}
```

## Skills (`skills/`)

Skills are runnable prompt templates invoked via `doyaken skill <name>`.

### Structure

```yaml
---
name: skill-name
description: What this skill does
args:
  - name: scope
    description: Scope of analysis
    default: "full"
requires:
  - github  # Optional: MCP servers needed
---

# Skill Title

## Context
Project: {{DOYAKEN_PROJECT}}
Scope: {{ARGS.scope}}

## Methodology
{{include:library/relevant-methodology.md}}

## Instructions
[Skill-specific instructions]

## Output
[Expected output format]
```

### Creating a New Skill

1. **Check for existing library prompt**: Does the methodology exist?
2. **Create library prompt if needed**: Add to `prompts/library/`
3. **Create skill that composes**: Use `{{include:}}` for methodology
4. **Add skill-specific context**: Args, output format, instructions

**Example:**

```markdown
---
name: api-audit
description: Audit API design and versioning
args:
  - name: path
    description: API path to audit
    default: "."
---

# API Audit

## Context
Project: {{DOYAKEN_PROJECT}}
Path: {{ARGS.path}}

## API Design Standards
{{include:library/api-design.md}}

## API Versioning
{{include:library/api-versioning.md}}

## Instructions
1. Find all API endpoints
2. Check against design standards
3. Verify versioning strategy
4. Document findings

## Output
[Structured report format]
```

## Include System

### Syntax

```markdown
{{include:library/code-quality.md}}
```

### Resolution Order

1. Project: `.doyaken/prompts/library/code-quality.md`
2. Global: `$DOYAKEN_HOME/prompts/library/code-quality.md`

### Nesting

Includes can be nested (max depth 5):

```markdown
# prompts/library/full-review.md
{{include:library/code-quality.md}}
{{include:library/security.md}}
{{include:library/testing.md}}
```

## Development Guidelines for AI Agents

When developing on this codebase, follow these rules:

### 1. Library First

Before writing any methodology or checklist:
- Check if it exists in `prompts/library/`
- If similar content exists, extend it rather than duplicate
- If it doesn't exist, create it there first

### 2. No Inline Methodology

**Bad** (methodology in skill):
```markdown
---
name: security-check
---

## OWASP Top 10
- A01: Broken Access Control
- A02: Cryptographic Failures
[... duplicated content]
```

**Good** (include from library):
```markdown
---
name: security-check
---

{{include:library/security.md}}
```

### 3. Make It Copy-Pastable

Library prompts should work when literally copied and pasted into any AI assistant:
- No dependencies on variables
- Self-contained explanations
- Universal (not language-specific unless that's the topic)

### 4. Update the Source

When improving methodology:
- Update the library prompt
- All skills/phases using it automatically get the improvement

### 5. Test Coverage

When adding:
- New library prompt: Add to `scripts/test.sh` library prompt checks
- New skill: Add to `scripts/test.sh` skill checks
- New phase: Ensure phase prompt exists check

## Quick Reference

### When to Create a Library Prompt

Create a new `prompts/library/` file when:
- You're writing methodology that could be reused
- You're duplicating content from another prompt
- You want something copy-pastable for standalone use
- Multiple skills/phases need the same guidance

### When to Create a Skill

Create a new `skills/` file when:
- You want a runnable, parameterized prompt
- You need to compose multiple library prompts
- You want CLI integration via `doyaken skill`

### File Naming

| Type | Location | Format | Example |
|------|----------|--------|---------|
| Library | `prompts/library/` | `kebab-case.md` | `code-quality.md` |
| Phase | `prompts/phases/` | `N-name.md` | `3-implement.md` |
| Skill | `skills/` | `kebab-case.md` | `security-audit.md` |

### Template Variables

| Variable | Context | Description |
|----------|---------|-------------|
| `{{DOYAKEN_PROJECT}}` | Skills | Project directory path |
| `{{ARGS.name}}` | Skills | Skill argument value |
| `{{TASK_PROMPT}}` | Phases | The original prompt text |
| `{{ACCUMULATED_CONTEXT}}` | Phases | Context from prior phases |
| `{{VERIFICATION_CONTEXT}}` | Phases | Gate failure output for retries |
| `{{TIMESTAMP}}` | Phases | Current timestamp |
| `{{RECENT_COMMITS}}` | Phase 6 | Recent git commit log |
| `{{include:path}}` | Any | Include another prompt |

## Checklist for New Contributions

### Adding a Library Prompt

- [ ] File is self-contained (works copy-pasted)
- [ ] Has clear structure (Mindset, Content, Template)
- [ ] Uses universal language (not tied to specific tech unless that's the topic)
- [ ] Added to `prompts/library/README.md`
- [ ] Added to `scripts/test.sh` checks

### Adding a Skill

- [ ] Uses `{{include:}}` for methodology (no duplication)
- [ ] Has YAML frontmatter (name, description, args)
- [ ] Has clear output format
- [ ] Added to `scripts/test.sh` checks

### Adding a Phase

- [ ] Composes from library prompts
- [ ] Has clear input/output contract
- [ ] Fits in the 8-phase workflow
- [ ] Added to `scripts/test.sh` checks

## Security & Credential Handling

Security is critical for any tool that runs with elevated permissions or handles credentials.

### Credential Safety

- **Never commit secrets** - API keys, tokens, and passwords must never appear in code or git history
- **Use `.env` for local secrets** - The `.env` file is gitignored; store local credentials there
- **Use `.env.example` for templates** - Show required variables with placeholder values only
- **CI/CD uses GitHub Secrets** - Production credentials live in GitHub Secrets, never in code

### Before Committing

- [ ] No hardcoded credentials in your changes
- [ ] No secrets in log statements or error messages
- [ ] `.env` file is not staged (`git status` to verify)
- [ ] Any new environment variables are documented in `.env.example`

### If You Accidentally Expose a Credential

1. **Revoke it immediately** - assume it's compromised
2. Generate a new credential
3. If committed to git, the credential is permanently compromised (git history persists even after deletion)
4. Report the incident to maintainers

For full security guidelines, see [SECURITY.md](./SECURITY.md).

## Examples

### See How It's Done

- **Library prompt**: `prompts/library/security.md`
- **Skill using library**: `skills/security-audit.md`
- **Phase using library**: `prompts/phases/3-implement.md`

### Common Patterns

**Skill with multiple library includes:**
```markdown
---
name: full-audit
---

{{include:library/code-quality.md}}
{{include:library/security.md}}
{{include:library/performance.md}}

Now audit the codebase...
```

**Library prompt with checklist:**
```markdown
# Topic

## Checklist
- [ ] Item 1
- [ ] Item 2

## Detailed Guidance
[Explanations for each item]
```

## CI/CD

### Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **CI** | `ci.yml` | Push/PR to `main` | Lint, validate, test, package, install-test |
| **Release** | `release.yml` | Tag push, `package.json` change on `main`, or manual | Publish to npm and create GitHub release |
| **Rollback** | `rollback.yml` | Manual dispatch | Re-publish a previous version tag to npm |

### Running Checks Locally

```bash
# Run all checks (lint + validate + test)
./scripts/check-all.sh

# Individual checks
./scripts/lint.sh            # ShellCheck linting
./scripts/validate-yaml.sh   # YAML validation
./scripts/test.sh            # Basic tests
./test/run-bats.sh           # Bats unit + integration tests

# Or via npm
npm test                     # All tests (basic + bats)
npm run lint                 # Linting
npm run validate             # YAML validation
npm run check                # All checks
```

### How Deploys Work

1. **Automatic**: When `package.json` version changes on `main`, the Release workflow creates a git tag and publishes to npm.
2. **Tag-based**: Pushing a `v*` tag (e.g., `v0.2.0`) triggers a release directly.
3. **Manual**: Use the "Run workflow" button on the Release workflow in GitHub Actions.

Deploys use a concurrency group (`deploy-production`) so only one deploy runs at a time. New pushes cancel in-progress deploys.

### Rollback

If a bad version is deployed:

1. Go to **Actions → Rollback → Run workflow**
2. Enter the version tag to rollback to (e.g., `v0.1.15`)
3. The workflow checks out that tag and re-publishes to npm

### Branch Protection (Recommended)

Configure these settings on `main`:
- Require status checks to pass (CI workflow)
- Require at least one approval on PRs
- Disable force pushes
- Require linear history (squash or rebase merges)
