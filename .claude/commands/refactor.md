---
description: Apply refactor methodology
---

# Refactor (Safe Code Restructuring)

You are refactoring code without changing its external behaviour.

## Mindset

- **Behaviour preservation** - External behaviour must not change
- **Small steps** - Many small changes, not one big rewrite
- **Test coverage first** - If no tests exist, add them before refactoring
- **Verify after each step** - Run tests after every change

## The Golden Rule

> Before refactoring, ensure the code has adequate test coverage.
> If it doesn't, add tests first. Refactoring without tests is just editing.

## 1) Assess Test Coverage

Before any refactoring:

1. Check coverage on the code you'll change
2. If coverage is low, write characterization tests first
3. Cover the main paths and edge cases
4. Only then proceed with refactoring

## 2) Identify the Refactoring Type

| Type | Description | Risk |
|------|-------------|------|
| **Rename** | Change names for clarity | Low |
| **Extract** | Pull code into function/class/module | Low |
| **Inline** | Replace function call with its body | Low |
| **Move** | Relocate code to better location | Medium |
| **Simplify** | Reduce complexity, remove duplication | Medium |
| **Restructure** | Change organization or architecture | High |

Start with lower-risk refactorings.

## 3) Plan the Refactoring

Break into atomic steps. Each step should:

- Make ONE type of change
- Be independently verifiable
- Not break tests

```
Step 1: [description]
- Before: [current state]
- After: [desired state]
- Verify: [how to check]

Step 2: ...
```

## 4) Execute Step by Step

For EACH step:

1. Make the change
2. Run tests
3. If tests pass, commit
4. If tests fail, revert and reconsider

**Do NOT combine multiple steps into one commit.**

## 5) Common Refactoring Patterns

### Extract Function
Pull related code into a named function:
- Identify cohesive code block
- Extract to function with descriptive name
- Replace original with function call

### Rename for Clarity
Replace cryptic names with descriptive ones:
- Single-letter variables → meaningful names
- Abbreviations → full words
- Verbs for functions, nouns for data

### Remove Duplication (DRY)
Extract duplicated logic:
- Find similar code blocks
- Parameterize differences
- Extract shared logic

### Simplify Conditionals
Make conditionals easier to read:
- Early returns instead of deep nesting
- Guard clauses
- Extract complex conditions to named functions

## 6) What NOT to Do

- **Don't change behaviour** - If tests fail, you've changed behaviour
- **Don't add features** - Refactoring is not the time for new functionality
- **Don't fix bugs** - Fix bugs separately (it's a different type of change)
- **Don't refactor without tests** - Add tests first
- **Don't make big leaps** - Many small steps, not one big rewrite

## 7) Output

```
### Refactoring Summary

Goal:
- [what was the refactoring objective]

Steps taken:
1. [step 1] - commit [hash]
2. [step 2] - commit [hash]

Tests:
- Existing tests: [all pass]
- New tests added: [list if any]

Behaviour changes:
- [none - this is refactoring]

Code improvements:
- [what's better now]
```

## Quality Principles for Refactoring

Apply these principles when deciding what to refactor:

- **KISS** - Simplify complex code; remove unnecessary abstraction
- **YAGNI** - Remove unused code; don't add "just in case" features
- **DRY** - Extract duplicated logic; single source of truth
- **SOLID** - Improve separation of concerns; reduce coupling

**After refactoring, code should be:**
- Easier to understand
- Easier to test
- Easier to modify
- No more complex than necessary

## Rules

- Run tests after EVERY change
- Commit after EVERY successful step
- If tests fail, revert immediately
- Never combine refactoring with feature work
- If coverage is low, add tests BEFORE refactoring
- All quality gates must pass

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
