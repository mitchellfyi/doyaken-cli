---
description: Set up quality gates, CI, and git hooks for the project
---

Run the doyaken skill: setup-quality

```bash
doyaken skill setup-quality $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# Setup Quality Gates

You are setting up quality gates to ensure high code quality in this project.

## Context

Project directory: {{DOYAKEN_PROJECT}}
CI platform: {{ARGS.ci}}
Install git hooks: {{ARGS.hooks}}

## Quality Principles

{{include:library/quality.md}}

## Instructions

### 1) Detect Project Type

Identify the project's language/framework:
- Check for `package.json` (Node.js/JavaScript/TypeScript)
- Check for `pyproject.toml` or `requirements.txt` (Python)
- Check for `go.mod` (Go)
- Check for `Cargo.toml` (Rust)
- Check for `Gemfile` (Ruby)

### 2) Audit Existing Setup

Check what already exists:
- [ ] Linter configured? (ESLint, Ruff, golint, etc.)
- [ ] Formatter configured? (Prettier, Black, gofmt, etc.)
- [ ] Type checker? (TypeScript, mypy, etc.)
- [ ] Test framework? (Jest, pytest, go test, etc.)
- [ ] CI pipeline? (.github/workflows, .gitlab-ci.yml)
- [ ] Git hooks? (.husky, .git/hooks, pre-commit)

### 3) Add Missing Quality Tools

For each missing tool, add configuration:

**Node.js/TypeScript:**
```bash
# ESLint + Prettier
npm install -D eslint prettier eslint-config-prettier
npx eslint --init

# TypeScript (if not present)
npm install -D typescript @types/node
npx tsc --init

# Testing
npm install -D vitest  # or jest
```

**Python:**
```bash
# Ruff (linter + formatter)
pip install ruff
# Add to pyproject.toml: [tool.ruff]

# Type checking
pip install mypy

# Testing
pip install pytest pytest-cov
```

**Go:**
```bash
# Built-in tools
go fmt ./...
go vet ./...
golangci-lint run

# Testing
go test ./...
```

### 4) Add Quality Scripts

Add to package.json (Node.js) or Makefile:

```json
{
  "scripts": {
    "lint": "eslint . --ext .ts,.tsx,.js,.jsx",
    "lint:fix": "eslint . --ext .ts,.tsx,.js,.jsx --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "audit": "npm audit --audit-level=high",
    "audit:fix": "npm audit fix",
    "quality": "npm run lint && npm run typecheck && npm run test && npm run audit"
  }
}
```

Or Makefile:
```makefile
.PHONY: lint format typecheck test audit quality

lint:
	ruff check .

format:
	ruff format .

typecheck:
	mypy .

test:
	pytest

audit:
	pip-audit

quality: lint typecheck test audit
```

### 5) Set Up CI Pipeline

**GitHub Actions** (.github/workflows/ci.yml):
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run typecheck

      - name: Test
        run: npm run test

      - name: Security audit
        run: npm audit --audit-level=high

      - name: Build
        run: npm run build
```

**GitLab CI** (.gitlab-ci.yml):
```yaml
stages:
  - quality

quality:
  stage: quality
  image: node:20
  script:
    - npm ci
    - npm run lint
    - npm run typecheck
    - npm run test
    - npm audit --audit-level=high
    - npm run build
```

### 6) Set Up Git Hooks

**Using Husky (Node.js):**
```bash
npm install -D husky lint-staged
npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

Add to package.json:
```json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yml,yaml}": ["prettier --write"]
  }
}
```

**Using pre-commit (Python/universal):**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.4
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
```

```bash
pip install pre-commit
pre-commit install
```

**Manual git hook** (.git/hooks/pre-commit):
```bash
#!/bin/bash
set -e
npm run lint
npm run typecheck
npm run test
```

### 7) Document Quality Standards

Add to CONTRIBUTING.md or README:
```markdown
## Code Quality

All code must pass quality gates before merging:

- **Lint**: `npm run lint` - Code style and potential errors
- **Format**: `npm run format` - Consistent formatting
- **Types**: `npm run typecheck` - Type safety
- **Tests**: `npm run test` - All tests passing

Pre-commit hooks run automatically. CI runs on all PRs.
```

## Output

```
Quality Gates Setup Complete
============================

Project type: [detected type]

Added/configured:
- [x] Linter: [tool]
- [x] Formatter: [tool]
- [x] Type checker: [tool]
- [x] Test framework: [tool]
- [x] CI pipeline: [platform]
- [x] Git hooks: [method]

Scripts available:
- npm run quality  # Run all checks
- npm run lint     # Lint code
- npm run test     # Run tests

Next steps:
1. Review generated configs
2. Run `npm run quality` to verify
3. Commit the changes
```

## Rules

- Do NOT break existing configurations
- Preserve existing scripts, add new ones
- Use project's existing package manager
- Keep configurations minimal and standard
- Add only what's missing
