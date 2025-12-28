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
