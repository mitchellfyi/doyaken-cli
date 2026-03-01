# Code Quality

**Simplicity is the goal.** The best code is easiest to read, easiest to change, and easiest to delete. When choosing between approaches, pick the one a new team member would understand fastest.

## Core Principles

### KISS (Keep It Simple)
The simplest solution is usually the best. Complexity is the enemy of reliability.

- Prefer straightforward logic over clever tricks
- If code needs comments to explain what it does, simplify the code
- Break complex functions into smaller, focused ones
- Avoid premature abstraction
- Compare your solution's complexity to what an experienced developer would write by hand — if yours has more layers, more indirection, or more moving parts, simplify

### YAGNI (You Aren't Gonna Need It)
Don't build features or abstractions until you actually need them.

- No speculative features
- No "just in case" parameters
- No unused abstractions
- Delete dead code immediately

### DRY (Don't Repeat Yourself)
Every piece of knowledge should have a single, authoritative source.

- Extract repeated logic into functions
- Use constants for magic values
- Centralize configuration
- But: Don't over-DRY — some duplication is acceptable if it keeps code simpler

### SOLID Principles

| Principle | Meaning |
|-----------|---------|
| **S**ingle Responsibility | Each function/module does one thing |
| **O**pen/Closed | Extend behaviour without modifying existing code |
| **L**iskov Substitution | Subtypes honour base contracts |
| **I**nterface Segregation | Small, focused interfaces |
| **D**ependency Inversion | Depend on abstractions, not concrete implementations |

## Decomposition & Testability

Every unit of code — function, module, file, class — should have a **single, clear purpose that's obvious from its name**. If you can't name it clearly, it's doing too much.

**Functions:** Do one thing. If a function has "and" in its description, split it. Keep them short enough to read without scrolling. Prefer pure functions (input in, output out, no side effects) — they're trivially testable and easy to reason about.

**Modules and files:** Organize around a single responsibility or concept, not around a grab-bag of related utilities. When a module grows to handle multiple concerns, split it. Prefer many focused files over few sprawling ones.

**Testability is a design signal.** If something is hard to test, it's probably too coupled, too complex, or doing too many things. Difficulty writing a unit test means the code needs redesigning, not that the test needs more mocks.

**Decomposition checklist:**
- Can each piece be understood in isolation, without reading the rest of the file?
- Can each piece be tested with a simple setup (few mocks, minimal state)?
- Does each piece have a name that fully describes what it does?
- If a piece were deleted, would its absence be felt in exactly one place?

## Naming & Readability

- Names describe intent: functions are verbs (`calculateTotal`, `validateInput`), data is nouns (`activeUser`, `orderCount`)
- Booleans read as questions: `isValid`, `hasPermission`, `canRetry` — not `valid`, `flag`, `check`
- Collections indicate plurality: `users` not `userList`, `orderIds` not `orderIdArray`
- Use domain language consistently — if the business calls it an "enrollment", don't call it a "registration" in code
- Functions < 20 lines ideal, cognitive complexity < 15 per function, nesting depth ≤ 3 levels
- No hardcoded values, no magic numbers — use named constants
- Early returns over deep nesting; guard clauses for preconditions
- Prefer flat, linear control flow — extract nested logic into well-named helper functions rather than adding depth
- Consistent formatting matching the project's existing style

## Type Safety & Data Validation

- Use the language's type system to its full potential — prefer strict types, avoid `any`/`unknown`/`object` escape hatches
- Validate data at system boundaries: API inputs, file reads, environment variables, database results, third-party responses
- Parse, don't validate — transform untyped data into typed structures at the boundary, then use types internally
- Prefer immutable data structures
- Make invalid states unrepresentable through the type system where possible

## Resource Cleanup & Lifecycle

Every resource you acquire must be released — leaked resources cause slow degradation and eventual outages:

- **Close what you open**: database connections, file handles, network sockets, HTTP clients
- **Clear what you start**: intervals, timeouts, scheduled jobs, background tasks
- **Remove what you register**: event listeners, subscriptions, observers, callbacks
- **Delete what you create temporarily**: temp files, staging directories, lock files
- Use language-appropriate patterns: `try/finally`, `defer`, `using`/`with`, `useEffect` cleanup returns, destructors
- Verify cleanup happens in error paths too, not just the happy path
- In long-running processes, verify resources aren't accumulating over time (connection pool exhaustion, memory growth, file descriptor leaks)

## Concurrency & State Management

- **Avoid shared mutable state** — it's the root cause of most concurrency bugs
- Prefer immutable data and pure functions; isolate side effects at the edges
- When shared state is necessary, use proper synchronization (locks, mutexes, atomic operations, transactions)
- Watch for race conditions: check-then-act patterns, read-modify-write without locking, concurrent access to collections
- Database operations that must be atomic should use transactions with appropriate isolation levels
- Use optimistic concurrency (version fields, ETags) rather than pessimistic locking where possible

## Observability & Logging

Code that can't be observed in production can't be debugged in production:

- **Structured logging** — use key-value pairs or JSON, not unstructured strings. Include: timestamp, level, correlation ID, operation, relevant context
- **Log levels matter**: ERROR (requires attention), WARN (unexpected but handled), INFO (significant business events), DEBUG (diagnostic detail, off in production)
- **What to log**: request/response at boundaries, state transitions, errors with context, security events, slow operations
- **What NOT to log**: sensitive data (passwords, tokens, PII, secrets), high-frequency noise, successful health checks
- **Correlation IDs**: propagate a request/trace ID through the entire call chain

## Architecture

- Clear separation of concerns — business logic belongs in services/domain layer, not in controllers, handlers, or UI components
- Dependencies flow in one direction; no circular dependencies
- Modules can be changed and tested independently (loose coupling)
- Related code is grouped together (high cohesion) — but a module that groups too many things becomes a dumping ground
- External dependencies (databases, APIs, file system) are abstracted behind interfaces
- New modules should follow existing architectural patterns unless there's a documented reason to diverge

## Backward Compatibility

- **Classify every change** as breaking or non-breaking before shipping
- **Breaking changes**: removing/renaming fields, changing types, tightening validation, changing semantics, removing endpoints
- **Non-breaking changes**: adding endpoints, adding optional fields with defaults, adding new enum values, loosening validation
- **Additive-only by default** — add new fields/endpoints rather than modifying existing ones
- For database migrations: make them reversible, test rollback, deploy in phases
- Run existing integration tests and contract tests to catch unintended breakage

## Dependency Management

- **Evaluate before adding**: does this dependency solve a problem worth the maintenance cost? Could it be done in a few lines of code instead?
- **Minimize surface area**: fewer dependencies = fewer security vulnerabilities, fewer breaking upgrades, smaller bundles
- Pin versions explicitly — avoid floating ranges in production dependencies
- Audit dependencies for known CVEs regularly
- Check license compatibility before adding any dependency
- Prefer well-maintained dependencies with active communities over abandoned ones

## Codebase Stewardship

**Leave every file better than you found it.** When you touch a file, also:

- Remove dead code, unused imports, and unreachable branches
- Fix stale comments that no longer match the code
- Replace magic numbers with named constants
- Simplify overly complex expressions you encounter
- Delete commented-out code — version control is the history
- Fix minor bugs you discover, as long as the fix is obvious and safe

Put stewardship improvements in separate commits from feature work so they can be reviewed and reverted independently.

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **God Object** | One class does everything | Split into focused units |
| **Spaghetti Code** | Tangled control flow | Clear structure, early returns |
| **Copy-Paste** | Duplicated code | Extract shared logic |
| **Premature Optimization** | Complexity without need | Make it work, then profile |
| **Gold Plating** | Features nobody asked for | Stick to requirements |
| **Shared Mutable State** | Concurrency bugs | Prefer immutable data; isolate mutation |
| **Leaking Resources** | Slow degradation, outages | Close, clear, and release everything you acquire |
| **Introducing New Patterns** | Architectural drift | Reuse the project's established approach |
| **Over-Abstracting** | Unnecessary complexity | Don't add layers that don't exist elsewhere |

## Quality Gates

Every change should pass the project's quality checks:

- **Lint** — catch style and potential errors
- **Type check** — catch type errors (if applicable)
- **Test** — verify behaviour
- **Build** — ensure it compiles (if applicable)

Run quality gates **after every file change**, not just at the end. Don't accumulate broken state.

Discover specific commands during triage by checking project configuration.
