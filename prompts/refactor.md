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

```bash
# Check coverage on the code you'll change
npm test -- --coverage --collectCoverageFrom="path/to/file.ts"
```

**If coverage is low:**
1. Write characterization tests (tests that document current behaviour)
2. Cover the main paths and edge cases
3. Only then proceed with refactoring

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
2. Run tests: `npm test`
3. If tests pass, commit
4. If tests fail, revert and reconsider

```bash
# After each step
npm test && git commit -am "refactor: [description]"
```

**Do NOT combine multiple steps into one commit.**

## 5) Common Refactoring Patterns

### Extract Function
```
// Before
function processOrder(order) {
  // ... validation logic ...
  // ... calculation logic ...
  // ... notification logic ...
}

// After
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order);
  notifyCustomer(order, total);
}
```

### Rename for Clarity
```
// Before
const d = new Date();
const t = d.getTime();

// After
const currentDate = new Date();
const timestampMs = currentDate.getTime();
```

### Remove Duplication (DRY)
```
// Before
function getUserName(user) { return user?.name || 'Anonymous'; }
function getAuthorName(author) { return author?.name || 'Anonymous'; }

// After
function getName(entity, fallback = 'Anonymous') {
  return entity?.name || fallback;
}
```

### Simplify Conditionals
```
// Before
if (user !== null && user !== undefined && user.isActive === true) { ... }

// After
if (user?.isActive) { ... }
```

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

## Rules

- Run tests after EVERY change
- Commit after EVERY successful step
- If tests fail, revert immediately
- Never combine refactoring with feature work
- If coverage is low, add tests BEFORE refactoring
