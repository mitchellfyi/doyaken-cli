---
name: github:release
description: Create a GitHub release with changelog
requires:
  - github
args:
  - name: version
    description: Version tag (e.g., v1.0.0)
    default: ""
  - name: draft
    description: Create as draft release
    default: "false"
  - name: prerelease
    description: Mark as pre-release
    default: "false"
---

# GitHub Release

You are creating a GitHub release using GitHub MCP tools.

## Context

Project: {{DOYAKEN_PROJECT}}
Version: {{ARGS.version}}
Draft: {{ARGS.draft}}
Pre-release: {{ARGS.prerelease}}

## Release Process

### 1. Determine Version

{{#if version}}
Using specified version: {{ARGS.version}}
{{else}}
Determine version from:
- `package.json` version field
- Latest git tag + conventional commits
- CHANGELOG.md latest entry
{{/if}}

### 2. Generate Changelog

Analyze commits since last release:

```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Categorize changes:

**Breaking Changes** (BREAKING CHANGE or !)
- Major API changes
- Removed features
- Migration required

**Features** (feat:)
- New functionality
- New commands/options

**Bug Fixes** (fix:)
- Error corrections
- Performance fixes

**Other**
- Documentation (docs:)
- Refactoring (refactor:)
- Dependencies (chore:)

### 3. Create Release

Use GitHub MCP to create the release:

**Release Title**: {{ARGS.version}}

**Release Body**:
```markdown
## What's Changed

### Breaking Changes
- Description (#PR)

### Features
- Description (#PR)

### Bug Fixes
- Description (#PR)

### Other Changes
- Description (#PR)

**Full Changelog**: https://github.com/owner/repo/compare/v0.9.0...{{ARGS.version}}
```

### 4. Post-Release

After creating the release:

1. **Verify release page**
   - Check release is visible
   - Verify assets if applicable

2. **Announce** (optional)
   - Update documentation
   - Notify stakeholders

## Output

```markdown
## Release Created

**Version**: {{ARGS.version}}
**Type**: {{#if prerelease == "true"}}Pre-release{{else}}Stable{{/if}}
**Status**: {{#if draft == "true"}}Draft{{else}}Published{{/if}}

### Changelog Summary
- **Breaking**: [count] changes
- **Features**: [count] additions
- **Fixes**: [count] bug fixes

### Links
- Release: [URL]
- Compare: [URL]

### Next Steps
{{#if draft == "true"}}
- [ ] Review release notes
- [ ] Publish when ready
{{else}}
- [ ] Verify release assets
- [ ] Update documentation
- [ ] Announce release
{{/if}}
```
