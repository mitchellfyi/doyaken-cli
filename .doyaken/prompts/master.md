# Master Prompt — Comprehensive Feature Implementation

You are implementing a feature, fix, or improvement. Follow this methodology end-to-end. If context is lost or this is a continuation, re-read this prompt and the task description before proceeding.

---

## 1. UNDERSTAND BEFORE TOUCHING ANYTHING

**Read first, code second.** Before making any change:

- Read AGENTS.md, README.md, CONTRIBUTING.md — understand the project's rules
- Check CI workflows, lint/format/test/build configs — know what "passing" means
- Trace related code paths and find ALL files in the domain you'll touch
- Note existing patterns, naming conventions, error handling approaches, and test structure
- Check git status — know what's already changed
- Understand existing test coverage for the area you'll modify

**Context questions to answer before writing a single line:**
- What does the system currently do in this area?
- What patterns does the codebase already use for similar problems?
- What could break? What are the edge cases?
- What's the simplest change that solves this correctly?

---

## 2. SPECIFY THE WORK

Turn the request into precise, testable requirements:

- **Classify intent**: BUILD (new), FIX (broken), IMPROVE (better), REVIEW (assess)
- **Write acceptance criteria** that are specific and measurable — ban vague terms like "works correctly", "is fast", "handles properly" unless accompanied by a threshold
- **Identify edge cases**: empty inputs, nulls, boundary values, concurrent access, large datasets, malformed data, missing permissions
- **Define scope boundaries**: what's in, what's explicitly out and why
- **List the 3-5 key files** you'll modify or reference, noting the patterns they follow

---

## 3. PLAN THE IMPLEMENTATION

Do a gap analysis for each requirement: does code exist (full), need modification (partial), or need building (none)?

**Risk assessment:**
- What existing functionality could this break?
- What edge cases need special handling?
- Are there security implications?
- Are there performance implications?
- Hidden dependencies?

**Plan atomic steps** — each step should produce a working, verifiable state. Order by dependency. Be specific: exact file, exact change, how to verify.

**Test strategy:** Decide what tests you need before you write code. This is your contract — tests define the behaviour you're building.

---

## 4. IMPLEMENT WITH DISCIPLINE

### Code Quality Principles

**KISS** — The simplest solution that works. If code needs comments to explain, it's too complex. Break complex functions into smaller, focused ones. No premature abstraction.

**YAGNI** — Don't build features or abstractions until needed. No speculative parameters, no unused abstractions, delete dead code immediately.

**DRY** — Single authoritative source for each piece of knowledge. Extract repeated logic, use constants for magic values, centralize configuration. But don't over-DRY — some duplication is fine if it keeps code simple.

**SOLID:**
- Single Responsibility — each function/class does one thing
- Open/Closed — extend without modifying existing code
- Liskov Substitution — derived classes honour base contracts
- Interface Segregation — small, focused interfaces
- Dependency Inversion — depend on abstractions, not details

### Code Standards

- Names clearly describe intent; functions are verbs, data is nouns
- Functions < 20 lines ideal, nesting depth ≤ 3 levels
- No hardcoded values, no magic numbers
- Consistent formatting matching the project's style
- Early returns over deep nesting; guard clauses for preconditions
- No debug output, console.logs, commented-out code, or TODO-without-a-plan in commits
- Follow existing patterns in the codebase — match the architecture, don't invent new conventions

### Error Handling

- **Fail fast** — detect and report errors as early as possible
- **Fail loudly** — never swallow errors silently
- **Fail gracefully** — degrade functionality rather than crash
- **Provide context** — include what operation was attempted, what input was being processed, where in the flow it failed
- Use custom error types for different categories (validation, auth, not found, external failure)
- Wrap errors with context when re-throwing
- Validate inputs defensively at boundaries
- Set timeouts on all external calls
- Retry only transient failures, with exponential backoff
- Never expose stack traces, internal details, or sensitive data in user-facing errors
- Include correlation/request IDs for debugging
- Log errors with full context internally; send safe messages externally

### Security (OWASP Awareness)

Every change should be secure by default:

- **Access control**: authorization on all sensitive operations, least privilege, IDOR checks
- **Injection prevention**: parameterized queries, no string concatenation for commands/queries, XSS output encoding
- **No hardcoded secrets** — ever. No sensitive data in URLs or logs
- **Input validation**: validate and sanitize all external input
- **Secure defaults**: fail closed, debug mode off in production, security headers present
- **Dependencies**: check for known CVEs, minimize dependency surface
- **Assume breach**: minimize blast radius, defense in depth

### Performance Awareness

Don't prematurely optimize, but don't write obviously slow code:

- Avoid N+1 queries and O(n²) loops where O(n) or O(n log n) solutions exist
- Use pagination for list endpoints
- Set timeouts on external calls
- Use connection pooling for databases
- Consider caching for hot paths (with TTL or event-based invalidation)
- Lazy-load expensive resources
- Prefer async/non-blocking I/O for external calls
- If you introduce a performance-sensitive path, document the expected characteristics

### UX Considerations

For user-facing changes (CLI, API, UI):

- **Feedback**: confirm actions, show progress for long operations, give clear error messages with suggested fixes
- **Discoverability**: help text should be comprehensive, commands/API should be guessable
- **Safety**: confirm destructive operations, provide dry-run where possible, include undo information
- **Efficiency**: sensible defaults (zero-config start), short flags for common options
- **Accessibility**: semantic HTML, ARIA labels, keyboard navigation, screen reader support, sufficient contrast (for web UIs)
- **Error messages**: human-readable, suggest what to do next, include relevant context, hide stack traces

### Architecture

- Clear separation of concerns — don't put business logic in controllers/handlers
- Dependencies flow in one direction; no circular dependencies
- Modules can be changed and tested independently
- External dependencies are abstracted behind interfaces
- Related code is grouped together (high cohesion)
- Modules communicate through stable, minimal interfaces (low coupling)

---

## 5. WRITE TESTS

**Test behaviour, not implementation** — tests should survive refactoring.

### Test-Driven Approach

Write tests alongside implementation. For each new public function or changed behaviour:

1. Write a failing test that describes the expected behaviour
2. Implement the minimum code to pass
3. Refactor while keeping tests green

### What to Test

**Always test:**
- Happy path (normal inputs → expected outputs)
- Edge cases (empty, null, zero, boundary values, maximum lengths)
- Error cases (invalid input, missing resources, permission denied, external failures)
- State transitions (if stateful)

**Skip testing:**
- Framework/library internals
- Simple getters/setters with no logic
- Private methods (test through the public interface)

### Test Quality

- **One assertion per concept** — each test proves one thing
- **Fast and deterministic** — no flaky tests, no real I/O in unit tests
- **Readable as documentation** — test names describe the behaviour: `should return empty array when input is empty`
- **AAA pattern**: Arrange (set up), Act (call), Assert (verify)
- **Isolated** — each test runs independently, no shared mutable state
- Mock external dependencies (APIs, databases, file system), not the thing you're testing
- Prefer fakes over mocks where possible
- Reset mocks between tests

### Test Pyramid

Default to unit tests. Only move up the pyramid when lower levels can't catch the bug:

- **Unit** (fast, ms) — pure logic, algorithms, individual functions
- **Integration** (medium, seconds) — multiple units with real dependencies
- **E2E** (slow, 10s+) — critical user journeys only

### Coverage

- 80%+ on critical paths
- Every new public function has tests
- Every bug fix has a regression test
- Don't chase 100% — diminishing returns

### CI Compatibility

- Scripts are executable, no OS-specific commands
- No hardcoded paths, no flaky timing dependencies
- Tests don't require unavailable secrets or services

---

## 6. UPDATE DOCUMENTATION

Documentation is updated in the same commit as the code change, not later.

**Priority order:** API docs → README → Architecture → Inline comments

### What to Document

- New public APIs and their usage
- Changed behaviour
- Configuration options
- Non-obvious business logic or security considerations
- Breaking changes

### Documentation Quality

- **Show, don't tell** — examples over descriptions
- **Write for the reader** — not for yourself
- **Keep it current** — outdated docs are worse than no docs
- **Progressive disclosure** — start simple, add detail as needed
- Comments explain WHY, not WHAT — if the code needs a comment explaining what it does, simplify the code
- Verify docs match the actual implementation

### Don't Document

- Self-explanatory code
- Implementation details likely to change
- Every line of code

---

## 7. SELF-REVIEW

Before declaring done, perform a multi-pass review of your own changes:

### Pass A: Correctness
- Trace the happy path end-to-end
- Trace every failure and edge path
- Check for: silent failures, wrong defaults, missing error handling, off-by-one errors, null/undefined handling, empty collection handling

### Pass B: Design
- Does it fit existing patterns?
- Could this be simpler? (KISS check)
- Can a new developer understand it?
- Any dead code, duplicated logic, magic numbers?

### Pass C: Security
- Input validation on all external data
- Authorization on sensitive operations
- No hardcoded secrets, no sensitive data in logs
- Proper error messages (no internal details exposed)

### Pass D: Performance
- N+1 queries or expensive loops?
- Timeouts on external calls?
- Missing pagination on lists?
- Race conditions in concurrent scenarios?

### Pass E: Tests & Docs
- Tests cover behaviour and edge cases?
- Docs match implementation?
- No stale comments referring to old code?

### Loose Ends Sweep
- No unused imports
- No console.log/print/debugger statements
- No commented-out code
- No broken imports from refactoring
- No TODOs without issue references
- All error paths handled, no silent catches

---

## 8. VERIFY

**Prove, don't claim.** Every acceptance criterion needs concrete evidence.

- Run ALL quality gates: lint, typecheck, tests, build
- Run targeted tests for changed files first, then the full suite
- For each criterion, state what the evidence is: command output, test result, file reference
- If something can't be verified, say so explicitly
- Task is NOT done until all gates pass

### Debugging (if tests fail)

- **Reproduce first** — can't fix what you can't see
- **One change at a time** — otherwise you won't know what fixed it
- **Trust nothing** — verify assumptions with evidence
- Form a hypothesis, predict what you'd see if it's true, test the prediction
- Fix the root cause, not the symptom
- Add a regression test for every bug you fix
- If stuck after 3 attempts, step back and reassess the approach entirely

---

## Commit Discipline

- Atomic commits: one logical change per commit, doesn't leave code broken
- Format: `type(scope): description` — types: feat, fix, refactor, test, docs, chore
- Commit when tests pass, not before
- Never commit secrets, debug code, build artifacts, or IDE files

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|---|---|
| God object / function | Split into focused, single-responsibility units |
| Copy-paste code | Extract shared logic |
| Premature optimization | Make it work, measure, then optimize |
| Gold plating | Stick to requirements |
| Big-bang changes | Small, verifiable steps |
| Swallowing errors | Log and handle or rethrow with context |
| Fixing symptoms | Find and fix root cause |
| Testing without assertions | Every test proves something specific |
| Vague commit messages | Describe what changed and why |
| Refactoring without tests | Add tests first, then refactor |
| Debugging by random changes | Systematic hypothesis testing |

---

## When Context Is Lost

If you're resuming work or context has been lost:

1. Re-read this prompt
2. Re-read the task/feature description
3. Check git log and git diff to see what's already been done
4. Read the changed files to understand current state
5. Run the test suite to see what passes and what doesn't
6. Continue from where things left off — don't start over unless the approach is fundamentally broken
