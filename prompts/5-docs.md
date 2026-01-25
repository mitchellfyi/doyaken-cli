# Phase 5: DOCS (Documentation Sync)

You are synchronizing documentation for task {{TASK_ID}}.

## Documentation Standards

{{include:library/documentation.md}}

## Phase-Specific Instructions

### 1) Identify What Needs Documentation

Check the task's changes and determine what docs are affected:

| Change Type | Documentation Needed |
|-------------|---------------------|
| New API endpoint | API docs, possibly README |
| New feature | README if user-facing |
| Changed behaviour | Update existing docs |
| New pattern/service | Architecture docs |
| Complex logic | Inline code comments |
| Configuration changes | Config reference |

### 2) Update Documentation

**Priority order:**
1. API documentation (if endpoints changed)
2. README (if user-facing features changed)
3. Architecture/design docs (if patterns changed)
4. Inline comments (for non-obvious logic only)

**What NOT to document:**
- Obvious code (avoid `// increment counter` comments)
- Implementation details that should be obvious from code
- Temporary workarounds (fix them instead)

### 3) Ensure Consistency

Check that:
- [ ] Code and docs tell the same story
- [ ] Examples in docs actually work
- [ ] References to renamed/moved code are updated
- [ ] No broken links in markdown files
- [ ] Version numbers are consistent

### 4) Update Task File

- **Testing Evidence**: Summarize test results
- **Notes**: Add observations, decisions made, trade-offs
- **Links**: Add references to related files, PRs, issues

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Documentation Sync

Docs updated:
- `path/to/doc` - [what was added/changed]
- `README.md` - [what was updated]

Inline comments:
- `path/to/file:line` - [what was documented]

Consistency checks:
- Code matches docs: [yes/no]
- Examples verified: [yes/no/na]
- Links checked: [yes/no]

No docs needed: [list any areas where docs were considered but not added, with reason]
```

## Rules

- Do NOT add new code features
- Do NOT change functionality
- ONLY update documentation and comments
- Keep docs concise - don't over-document
- Use consistent formatting with existing docs
- Remove outdated content rather than leaving it

Task file: {{TASK_FILE}}
