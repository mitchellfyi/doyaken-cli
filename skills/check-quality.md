---
name: check-quality
description: Run all quality checks and report issues
args:
  - name: fix
    description: Attempt to auto-fix issues
    default: "false"
  - name: path
    description: Path to check (default: entire project)
    default: "."
---

# Check Quality

You are running quality checks on the codebase.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Check path: {{ARGS.path}}
Auto-fix: {{ARGS.fix}}

## Quality Standards

{{include:library/code-quality.md}}

## Instructions

### 1) Identify Project Type

Detect the project's language and tooling:
- Node.js: `package.json`
- Python: `pyproject.toml`, `requirements.txt`
- Go: `go.mod`
- Rust: `Cargo.toml`

### 2) Run Available Quality Checks

Run all quality commands that exist in the project:

**Lint**
```bash
# Node.js
npm run lint
# With fix:
npm run lint -- --fix

# Python
ruff check {{ARGS.path}}
# With fix:
ruff check {{ARGS.path}} --fix

# Go
golangci-lint run {{ARGS.path}}
```

**Type Check**
```bash
# Node.js (TypeScript)
npm run typecheck
# or
npx tsc --noEmit

# Python
mypy {{ARGS.path}}

# Go
go vet {{ARGS.path}}
```

**Format Check**
```bash
# Node.js
npm run format:check
# With fix:
npm run format

# Python
ruff format --check {{ARGS.path}}
# With fix:
ruff format {{ARGS.path}}

# Go
gofmt -l {{ARGS.path}}
# With fix:
gofmt -w {{ARGS.path}}
```

**Tests**
```bash
# Node.js
npm test

# Python
pytest {{ARGS.path}}

# Go
go test {{ARGS.path}}/...
```

### 3) Analyze Results

For each check, categorize issues by severity:

| Severity | Examples |
|----------|----------|
| **Error** | Type errors, syntax errors, failing tests |
| **Warning** | Unused variables, missing docs, complexity |
| **Info** | Style suggestions, minor optimizations |

### 4) Report Summary

## Output

```
Quality Check Report
====================

Project: {{DOYAKEN_PROJECT}}
Path: {{ARGS.path}}
Auto-fix: {{ARGS.fix}}

Results:
| Check      | Status | Issues |
|------------|--------|--------|
| Lint       | [PASS/FAIL] | [count] |
| Types      | [PASS/FAIL] | [count] |
| Format     | [PASS/FAIL] | [count] |
| Tests      | [PASS/FAIL] | [count] |

Overall: [PASS/FAIL]

[If issues found:]
Top Issues:
1. [file:line] - [issue description]
2. [file:line] - [issue description]
3. [file:line] - [issue description]

[If auto-fix was enabled:]
Fixed:
- [count] lint issues auto-fixed
- [count] format issues auto-fixed

Remaining (manual fix needed):
- [list of issues that couldn't be auto-fixed]

Recommendations:
- [specific suggestions for improvement]
```

## Rules

- Run ALL available quality checks
- Report issues clearly with file and line numbers
- If auto-fix is enabled, run fix commands where available
- Don't modify code unless fix=true
- Provide actionable recommendations
