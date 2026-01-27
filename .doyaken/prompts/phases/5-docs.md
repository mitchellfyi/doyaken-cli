# Phase 5: DOCS

You are synchronizing documentation for task **{{TASK_ID}}**.

## Methodology

{{include:library/docs.md}}

## Phase Instructions

1. **Identify** what needs documentation based on changes made
2. **Update** docs in priority order: API → README → Architecture → Inline
3. **Verify consistency** - Code and docs tell the same story
4. **Update task file** - Add notes, observations, trade-offs

## What to Document

| Change Type | Documentation Needed |
|-------------|---------------------|
| New API endpoint | API docs, possibly README |
| New feature | README if user-facing |
| Changed behaviour | Update existing docs |
| Complex logic | Inline code comments |

## Output

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Documentation Sync

Docs updated:
- `path/to/doc` - [change]

Inline comments:
- `path/to/file:line` - [what]

Consistency: [verified/issues found]
```

## Rules

- Do NOT add new code features
- Do NOT change functionality
- ONLY update documentation and comments
- Keep docs concise - don't over-document
- Remove outdated content

Task file: {{TASK_FILE}}
