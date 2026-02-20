# Phase 5: DOCS

You are synchronizing documentation with the implementation.

## Methodology

{{include:library/docs.md}}

## Phase Instructions

1. **Identify** what needs documentation based on changes made
2. **Update** docs in priority order: API → README → Architecture → Inline
3. **Verify consistency** - Code and docs tell the same story

## What to Document

| Change Type | Documentation Needed |
|-------------|---------------------|
| New API endpoint | API docs, possibly README |
| New feature | README if user-facing |
| Changed behaviour | Update existing docs |
| Complex logic | Inline code comments |

## Output

Summarize:
- Docs updated (file and what changed)
- Inline comments added (file:line and what)
- Consistency check result

## Rules

- Do NOT add new code features
- Do NOT change functionality
- ONLY update documentation and comments
- Keep docs concise - don't over-document
- Remove outdated content
