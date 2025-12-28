# Implementation Review Criteria

Evaluate every changed file against the passes below. The `/dkreview` skill drives how these passes are applied — this prompt defines the criteria only. These criteria complement the implementation discipline described in `prompts/guardrails.md`.

For each finding, report: `file:line | pass | severity | confidence | issue | suggested fix`.

Severity levels: **high** (correctness, security, data loss), **medium** (performance, missing tests, design), **low** (style, naming, minor conventions).

### Confidence Scoring

Every finding MUST include a confidence score from 0-100:

| Score | Meaning | Action |
|-------|---------|--------|
| 90-100 | Certain — verifiable bug, missing guard, failing test | Always report |
| 75-89 | Highly confident — real issue with clear evidence | Always report |
| 50-74 | Moderately confident — likely issue but needs judgement | Report with caveat |
| 25-49 | Low confidence — might be intentional or context-dependent | Filter out |
| 0-24 | Noise — stylistic nitpick, pre-existing pattern, linter territory | Filter out |

**Threshold: 50.** Only report findings with confidence >= 50.

**Scoring guidelines:**
- Pre-existing code patterns (not introduced in this PR) → confidence 0. However, if new code _extends_ a pre-existing bad pattern (e.g., adds a new instance of a known anti-pattern), score the new instance at 50-60 with a note that it follows an existing pattern — the new code should not perpetuate known issues.
- Issues that linters/formatters will catch → confidence 0
- Code that looks odd but follows a nearby pattern → confidence 10-30
- Missing error handling in a new code path → confidence 80-95
- Security gap (missing auth, hardcoded secret) → confidence 95-100
- Failing test or type error → confidence 100
- Convention violation in new code → confidence 60-80
- Potential performance issue → confidence 50-70 (depends on evidence)

---

## Pass A: Correctness

**Adversarial stance:** Your goal is to BREAK the code, not confirm it works. For each function, actively construct inputs that would cause failure, states that would produce wrong results, and timing that would create races. Only mark a code path as correct if you cannot construct a breaking scenario.

Trace the code path end-to-end:

- **Happy path** — does the expected input produce the expected output?
- **Failure paths** — what happens when a dependency is down, the API returns an error, the input is malformed?
- **Edge cases** — empty collections, null/nil/undefined, zero, negative numbers, MAX_INT, concurrent access, Unicode, very long strings, special characters
- **State transitions** — are all state changes atomic? Can partial failures leave inconsistent state?
- **Resource cleanup** — are all opened resources (connections, handles, subscriptions, timers) closed on both success and failure paths?
- **Return values** — are all branches returning the correct type? Any implicit undefined/null?
- **Boundary conditions** — off-by-one in loops/slices, empty vs. missing vs. null, first/last element handling

## Pass B: Design

- Is this the simplest solution that meets the requirements?
- Would a new developer understand this in 5 minutes?
- Does it follow existing patterns in nearby files and the project's documented conventions?
- Are there unnecessary layers of abstraction or indirection?
- Does it use existing utilities rather than creating new ones?
- Could a simpler data structure or algorithm achieve the same result?
- Are naming conventions consistent with surrounding code?

## Pass C: Security

- All endpoints/routes have appropriate authentication and authorization
- No hardcoded secrets, credentials, or API keys
- No sensitive data in logs, error messages, or API responses
- Input validated at system boundaries (request handlers, external API inputs)
- Database queries use parameterized queries — no string interpolation
- Auth context checked at the appropriate layer
- Secure defaults — features are off/restricted by default, not permissive
- Defense in depth — no single control is the only protection; if one layer fails, another catches it
- CORS, rate limiting, and security headers where applicable

## Pass D: Performance

- No N+1 queries — use joins, batch loading, or eager loading
- Pagination on list operations — no unbounded queries
- Indexes for new query patterns — check migrations add appropriate indexes
- Timeouts on external service calls
- No unbounded loops over user-controlled data
- Select only needed columns/fields, not entire records
- Caching considered for expensive read-heavy operations
- Bulk operations preferred over row-by-row processing
- Algorithm complexity appropriate — no O(n²) or worse where O(n log n) or O(n) is achievable
- Connection pooling and resource reuse where applicable

## Pass E: Testing

- Tests cover **behaviour** (inputs → outputs), not implementation details
- Factory functions or fixtures for test data with sensible defaults
- Real schemas/types imported, not redefined in tests
- Edge cases and failure paths tested — not just the happy path
- No mocking of internals — mock at boundaries only (external services, databases)
- Test names describe the scenario and expected outcome
- Each test is independent — no shared mutable state between tests
- Tests can actually fail — if the implementation were broken, the test would catch it (not just asserting on mocked data or tautologies)
- Acceptance criteria from the ticket each have at least one corresponding test

## Pass F: Style & Conventions

Follow the project's established conventions (check CLAUDE.md, AGENTS.md, linter configs, and surrounding code):

- No dead code, debug logging, commented-out code, or debug artifacts
- Type safety: avoid escape hatches (language-specific: `any`, `as`, `@ts-ignore`, `unsafe`, `# type: ignore`, etc.)
- Comments explain "why", never "what" — no redundant comments
- No TODO comments without a linked ticket
- DRY applied to _knowledge_, not just code that looks similar
- YAGNI — no speculative features, no unused abstractions

## Pass G: Dependency Consistency

Cross-file contract adherence — verify changes propagate consistently:

When files that define contracts change (types, schemas, API definitions, database models, interfaces), verify:
- All consumers/callers are updated to handle the new shape
- Serialization/deserialization code maps the new fields
- Tests reflect the updated contracts
- Generated code is refreshed if applicable

**How to check — multi-hop tracing:**

1. **Hop 1:** `Grep` for imports of the changed file → verify each direct consumer is consistent
2. **Hop 2:** For each direct consumer that re-exports or wraps the changed entity, `Grep` for ITS consumers → verify consistency
3. **Hop 3:** Continue one more level if hop 2 revealed re-exports, or stop at leaf consumers

Track the chain: `[Changed] X → [Hop 1] Y ✓ → [Hop 2] Z ✓`. Stop at 3 hops or leaf consumers (non-exported code), whichever comes first.

## Pass H: Acceptance Criteria

If ticket context is available (plan file, task list, or ticket tracker):

For each acceptance criterion:
1. **Implementation**: trace to a specific `file:line` in production code that implements it
2. **Test**: trace to a specific test case that validates it

| Criterion | Implemented | Tested |
|-----------|------------|--------|
| _criterion text_ | `file:line` or **NOT FOUND** | `test-file:line` or **NOT FOUND** |

Flag **NOT FOUND** entries as high-severity findings.

## Pass I: Documentation Quality

Code should be self-documenting, but non-obvious logic needs explanation:

- Functions/methods with complex control flow (nested conditionals, state machines, multi-step transformations) must have a comment explaining **why**, not what
- New public APIs (exported functions, HTTP endpoints, CLI commands) need doc comments with parameter/return descriptions
- Complex regular expressions must have a comment explaining what they match and why that pattern was chosen
- Magic numbers and magic strings must be extracted to named constants, or have an inline comment explaining the value
- Non-trivial algorithms should cite the algorithm name or link to the source/reference (e.g., "// Fisher-Yates shuffle" or "// See RFC 5322 §3.4")
- If a code block implements a workaround for a known issue, it must link to the issue/ticket

## Pass J: Holistic Consistency

Review ALL changed files together as a set (not individually). Check for cross-file consistency:

- **Naming** — are the same concepts named the same way across all changed files? (e.g., not `userId` in one file and `user_id` in another, not `getUser` in one and `fetchUser` in another)
- **Error handling** — does every file follow the same error handling pattern? (e.g., if one function returns errors, all similar functions should too; if one uses try/catch, don't mix with error codes)
- **Logging** — are log levels, formats, and structured fields consistent across all changed files?
- **Patterns** — if a pattern is established in one changed file (e.g., input validation style, response formatting), it must be followed in all changed files
- **Imports** — are utility/helper imports consistent? (e.g., not importing the same function from different paths)

---

## Output

For each finding:
```
| file:line | Pass | Severity | Confidence | Issue | Suggested fix |
```

Only include findings with confidence >= 50. If all passes are clean or all findings are below threshold: **"No issues found."**
