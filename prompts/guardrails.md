# Implementation Guardrails

Reference document for doyaken skills. Read when referenced by `/dkplan`, `/dkimplement`, or `/dkloop`.

## AI Discipline

### Verify, Don't Assume

- Before claiming something works: run the test, read the output, check the file.
- Before claiming something exists: grep for it, read it. Don't rely on memory.
- Before using a function or API: read the source or official docs to confirm the signature and behavior.
- If you are uncertain about behavior, a schema, or a business rule: write a small test or read the code. Do not fill gaps with plausible guesses.

### Research Before Implementing

- Before writing code that uses an unfamiliar API or library: read the official docs or source.
- Before choosing an approach for a non-trivial problem: search the codebase for prior art and similar patterns.
- Before implementing a non-trivial algorithm or integration: search for known pitfalls, common mistakes, and edge cases others have documented.
- Prefer solutions that are widely adopted and battle-tested over novel or clever ones.

### Understanding Verification

Before writing any implementation code, answer these five questions (briefly, to yourself):

1. What is the exact input and output of this change?
2. What existing code will this interact with?
3. What are the failure modes?
4. What is explicitly out of scope?
5. What would a reviewer challenge about this approach?

If you cannot answer all five confidently, gather more context first.

## Implementation Principles

### Fail Fast, Fail Loud

- Validate preconditions at function entry. Return early or throw on invalid state.
- Include context in error messages: what was expected, what was received, what the caller should do.
- Never swallow errors silently. If you catch an exception, log it with context or re-throw with added information.
- Set timeouts on all external calls — network, database, file system. No unbounded waits.

### Type Safety at Boundaries

- Validate all data entering the system: API inputs, file reads, environment variables, database results, third-party responses.
- Do not trust data shape from external sources. Parse and validate before using.
- Use the language's type system to enforce contracts internally (generics, branded types, sum types, enums).

### Production API Defaults

When building HTTP APIs (REST, GraphQL, RPC), always include these unless explicitly scoped out:

- **CORS**: Enable cross-origin requests via middleware (e.g., `cors` package) or manual `Access-Control-Allow-*` headers.
- **Request size limits**: Set explicit body size limits (e.g., `express.json({ limit: '10kb' })`).
- **UUIDs for resource IDs**: Use `crypto.randomUUID()` or a uuid library — never sequential integers (they leak information and are guessable).
- **Graceful shutdown**: Handle `SIGTERM` and `SIGINT` to close the server and release resources cleanly.
- **Module structure**: Separate route definitions from the app/server setup. Each resource gets its own route file (e.g., `routes/books.js`), imported by the main app.
- **JSON error bodies**: Every error response must be JSON with a descriptive `error` or `message` field. Never return raw strings or stack traces.
- **Status code discipline**: Use the correct code for each outcome — `201` for creation, `204` for deletion, `400` for validation failure, `404` for missing resources, `409` for conflicts.

These are implied requirements for any production-quality API, even when the spec does not list them.

### Library & Package Deliverables

When creating a standalone library, package, or module:

- **Standard importability**: The module must be loadable via the language's standard mechanism (`require()`, `import`, `go get`) without requiring the consumer to run a separate build step. For TypeScript projects: set `"main"` in package.json to the compiled JS output (e.g., `"dist/index.js"`), add a `"build": "tsc"` script, and add `"prepare": "npm run build"` so that `npm install` automatically compiles TypeScript to JavaScript.
- **README.md**: Include a README documenting what the library does, installation, usage with code examples, and rationale behind non-obvious design decisions.

### Resource Cleanup

- Close what you open: database connections, file handles, HTTP clients, sockets.
- Clear what you start: intervals, timeouts, event listeners, subscriptions, temporary files.
- Use the language's cleanup idiom: try-finally, defer, using/with, RAII, useEffect cleanup.
- Verify cleanup happens in error paths too — errors during processing must not leak resources acquired before the error.

### Backward Compatibility

- Classify every change: additive (safe), modification (potentially breaking), removal (breaking).
- For breaking changes: document the migration path in the PR description.
- For API or schema changes: consider versioning or deprecation periods before removal.
- For database migrations: ensure they are reversible and test rollback.

### Codebase Stewardship

When modifying a file for your task, also:

- Remove dead code, unused imports, and unreachable branches you encounter.
- Fix stale comments that no longer match the code.
- Replace magic numbers with named constants.
- Delete commented-out code — version control is the history.

Do not expand scope to files outside the plan. Stewardship improvements in your working files should be in separate commits from feature work.

### Test Integrity

- After writing a test, verify it can fail: temporarily break the code under test and confirm the test catches it.
- If a test passes with the implementation removed or broken, the test is not testing anything — rewrite it.
- Test behavior, not implementation details. Tests should survive refactoring.
- Error-case tests are mandatory, not optional. For every happy-path test, write at least one error-case test.
- Name tests to describe the specific behavior they verify. For bug fixes, name each test after the bug it prevents — include the symptom and the fix (e.g., "should reject negative prices", "removeItem should filter items not reassign array", "discount should subtract percentage not add"). Test names must be grep-searchable for the behavior they guard.

### Edge Case Coverage

For any non-trivial feature, systematically test these categories (where applicable):

- **Concurrency / parallel access**: Multiple simultaneous callers sharing state. Use keywords like `concurrent`, `parallel`, `simultaneous` in test names so intent is searchable.
- **State expiry / reset**: Time-based state (windows, TTLs, caches) must have tests that verify cleanup, expiry, and window boundaries.
- **Multi-tenant / client isolation**: If state is keyed per client, user, or tenant, test that one key's state does not affect another.
- **Burst / stress**: Rapid successive calls beyond normal limits — verify the system degrades correctly, not silently.
- **Boundary values**: Zero, one, max, max+1, empty, null, undefined for every input.

Aim for **>10 focused test cases** per feature. Prefer many small tests over few large ones.

### Refactoring Quality

When extracting shared utilities or reducing duplication:

- **Declarative over imperative**: Prefer validation schemas/rule objects over chains of if-else. The shared module should express *what* to validate, not *how* to walk through fields.
- **Parameterize**: Shared helpers must accept configuration (max lengths, required fields, patterns) — not hardcode values from one caller.
- **Clean exports**: Use named exports (`module.exports = { fn1, fn2 }` or `export { fn1, fn2 }`), not default exports of anonymous objects.
- **Modern idioms**: Use `const`/`let` (never `var`). Remove `console.log` from production code — use a proper logger or remove debug output entirely.
- **Minimal callers**: After extraction, caller files should be thin — route handlers should delegate to the shared utility and be short.
