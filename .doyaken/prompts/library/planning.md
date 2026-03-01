# Planning

## Before Planning

Understand the current state:

1. **Find ALL files** related to this domain
2. **Trace execution paths** for relevant functionality
3. **Understand architecture** and patterns in use
4. **Note conventions** (naming, structure, error handling)
5. **Check existing tests** — what's covered?
6. **Identify the tech stack**, frameworks, and their idiomatic patterns

**Context questions to answer before writing a single line:**
- What does the system currently do in this area?
- What patterns does the codebase already use for similar problems?
- What could break? What are the edge cases?
- What's the simplest change that solves this correctly?
- Are there existing abstractions, utilities, or components to reuse?

## Specify the Work

Turn the request into precise, testable requirements:

- **Classify intent**: BUILD (new), FIX (broken), IMPROVE (better), REVIEW (assess)
- **Write acceptance criteria** that are specific and measurable — ban vague terms like "works correctly" unless accompanied by a measurable threshold
- **Identify edge cases**: empty inputs, nulls, boundary values, concurrent access, large datasets, malformed data, missing permissions, network failures
- **Define scope boundaries**: what's in, what's explicitly out and why
- **Identify backward compatibility requirements**: will this break existing callers, APIs, configs, or data formats?

## Research Before Choosing an Approach

**Stop and research before choosing an approach.** Do not jump to the first implementation that comes to mind.

For every non-trivial implementation decision:

- Search for how others have solved this problem with the project's current tech stack and framework versions
- Find at least 2-3 different approaches and compare their trade-offs before picking one
- Check for well-known libraries, built-in APIs, or framework features that already solve the problem — don't reinvent what exists
- Read current official documentation for any APIs or libraries you plan to use — never rely on memory
- Search for common pitfalls, gotchas, and failure modes others have documented
- Prefer solutions that are widely adopted and battle-tested over novel or clever approaches

After researching, think critically about what you found. Don't just pick the most popular answer — reason about which approach fits best in *this* codebase, with *this* architecture, for *this* specific problem.

## Gap Analysis

For EACH requirement, assess honestly:

| Criterion | Status | Gap |
|-----------|--------|-----|
| [criterion] | full / partial / none | [what's missing] |

- **Full**: Code exists and completely satisfies
- **Partial**: Exists but needs modification
- **None**: Needs to be built

Be ruthlessly honest — "exists" is not the same as "done".

## Risk Assessment

### Technical Risks
- What existing functionality could this break?
- Edge cases needing special handling?
- Security or data privacy implications?
- Performance implications at expected scale?
- Hidden dependencies or ordering constraints?
- Are database/schema migrations needed? Are they reversible?
- Does this require backward-compatible deployment?

### Scope Risks
- Is the requirement clear?
- Hidden dependencies?
- Could this grow larger than expected?

### Mitigation
For each risk: how to detect early, what to do if it happens.

## Test Strategy

Decide what tests you need **before** you write code. This is your contract — tests define the behaviour you're building.

- What unit tests cover the core logic?
- What integration tests verify the full path?
- What edge cases and error paths need explicit tests?
- What existing tests should still pass (backward compatibility)?

## Creating the Plan

Each step should be:
- **Atomic**: Completed and verified independently
- **Ordered**: Dependencies are clear
- **Specific**: Exact file, exact change, how to verify

### Step Format
```
Step N: [Brief Description]
  - File: path/to/file
  - Change: [specific modification]
  - Verify: [how to confirm]
```

## Checkpoints

Define verification points:

| After Step | Verify |
|------------|--------|
| Step N | [what to check] |

## Anti-Patterns

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| **Analysis paralysis** | Timebox planning |
| **Vague steps** | Specific file + change |
| **No verification** | Define done for each step |
| **Big bang** | Smaller, verifiable steps |
| **Over-engineering** | Simplest solution |
| **First idea wins** | Research 2-3 approaches, compare trade-offs |
| **Assuming APIs exist** | Verify every import, function, and method is real |
