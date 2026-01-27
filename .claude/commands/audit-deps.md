---
description: Audit dependencies for security vulnerabilities
---

Run the doyaken skill: audit-deps

```bash
doyaken skill audit-deps $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# Audit Dependencies

You are auditing project dependencies for security vulnerabilities.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Auto-fix: {{ARGS.fix}}
Minimum severity: {{ARGS.severity}}

## Instructions

### 1) Identify Package Manager

Detect the project's package manager:
- `package-lock.json` or `yarn.lock` → npm/yarn
- `pnpm-lock.yaml` → pnpm
- `requirements.txt` or `poetry.lock` → pip/poetry
- `go.sum` → Go modules
- `Cargo.lock` → Cargo (Rust)
- `Gemfile.lock` → Bundler (Ruby)

### 2) Run Security Audit

**Node.js (npm)**
```bash
npm audit --audit-level={{ARGS.severity}}

# With fix:
npm audit fix
# For breaking changes:
npm audit fix --force
```

**Node.js (yarn)**
```bash
yarn audit --level {{ARGS.severity}}

# With fix (yarn 2+):
yarn npm audit --fix
```

**Node.js (pnpm)**
```bash
pnpm audit --audit-level={{ARGS.severity}}

# With fix:
pnpm audit --fix
```

**Python (pip-audit)**
```bash
# Install if needed: pip install pip-audit
pip-audit

# With fix:
pip-audit --fix
```

**Python (safety)**
```bash
# Install if needed: pip install safety
safety check
```

**Go**
```bash
# Install if needed: go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
```

**Rust**
```bash
# Install if needed: cargo install cargo-audit
cargo audit

# With fix:
cargo audit fix
```

**Ruby**
```bash
# Install if needed: gem install bundler-audit
bundle audit check --update

# With fix:
bundle audit fix
```

### 3) Analyze Results

Categorize vulnerabilities by severity:

| Severity | Action Required |
|----------|-----------------|
| **Critical** | Fix immediately - active exploits exist |
| **High** | Fix ASAP - significant security risk |
| **Moderate** | Fix soon - potential security risk |
| **Low** | Fix when convenient - minimal risk |

### 4) Generate Fix Plan

For each vulnerability:
1. Identify the vulnerable package and version
2. Check if a patched version exists
3. Assess breaking change risk
4. Document upgrade path

### 5) Apply Fixes (if enabled)

If `fix=true`:
1. Run auto-fix commands
2. Verify fixes don't break the build
3. Run tests to check for regressions
4. Document what was changed

## Output

```
Dependency Audit Report
=======================

Project: {{DOYAKEN_PROJECT}}
Package manager: [detected]
Total dependencies: [count]
Scan date: {{TIMESTAMP}}

Vulnerabilities Found:
| Severity | Count |
|----------|-------|
| Critical | [n]   |
| High     | [n]   |
| Moderate | [n]   |
| Low      | [n]   |

Critical/High Issues:
1. [package@version] - [vulnerability title]
   - CVE: [CVE-ID]
   - Severity: [level]
   - Fix: Upgrade to [version]
   - Breaking: [yes/no]

2. [package@version] - [vulnerability title]
   ...

[If fix=true:]
Fixes Applied:
- [package]: [old version] → [new version]
- [package]: [old version] → [new version]

Remaining Issues (manual fix needed):
- [package]: [reason can't auto-fix]

[If fix=false:]
Recommended Actions:
1. Run `npm audit fix` to auto-fix [n] issues
2. Manually update [package] to [version] (breaking change)
3. Review [package] - no patch available yet

Next Steps:
- [ ] Review and apply fixes
- [ ] Run tests after fixes
- [ ] Update lockfile
- [ ] Commit changes
```

## CI Integration

Add to your CI pipeline:

**GitHub Actions:**
```yaml
- name: Security audit
  run: npm audit --audit-level=high
```

**Pre-commit hook:**
```bash
npm audit --audit-level=high || echo "Security vulnerabilities found!"
```

## References

- [npm audit docs](https://docs.npmjs.com/cli/v10/commands/npm-audit)
- [Snyk vulnerability database](https://snyk.io/vuln/)
- [GitHub Advisory Database](https://github.com/advisories)
- [NVD - National Vulnerability Database](https://nvd.nist.gov/)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)

## Rules

- Always report critical and high vulnerabilities
- Don't auto-fix if fix=false
- Warn about breaking changes before applying
- Run tests after applying fixes
- Document all changes made
