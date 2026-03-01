# Phase 1: PLAN

You are planning task **{{TASK_ID}}** — expanding the brief into a full specification and implementation plan in a single pass.

## Methodology

{{include:library/planning.md}}

## Phase Instructions

1. **Classify** the intent (BUILD/FIX/IMPROVE/REVIEW)
2. **Understand** the request — what's the smallest change that solves the problem?
3. **Analyze** the codebase — find related files, patterns, existing tests
4. **Discover quality gates** — see "Quality Gate Discovery" below. This is MANDATORY.
5. **Write user stories** (for non-trivial tasks) — `As a <role>, I want <feature> so that <benefit>` (US-1, US-2, ...). For trivial tasks (typo fixes, small bug fixes), skip user stories and write acceptance criteria directly.
6. **Write acceptance criteria** — Map each AC to its user story: `- [ ] AC-1 (US-1): [Specific testable criterion]`. For trivial tasks, omit the `(US-N)` mapping.
7. **Write acceptance scenarios** (for non-trivial tasks) — `SC-1 (AC-1): Given <precondition>, When <action>, Then <expected result>`
8. **Define success metrics** — Functional, Quality, Regression, Performance (if relevant). Every metric must have a pass/fail threshold.
9. **Set scope boundaries** — Explicit in-scope and out-of-scope lists. Every out-of-scope item must have an exclusion reason.
10. **Gap analysis** — For each acceptance criterion: full/partial/none
11. **Risk assessment** — What could go wrong? How to mitigate?
12. **Implementation steps** — Ordered, atomic, with verification for each. Use format: `Step N: [Description] - File: path - Change: [specific] - Verify: [how]`
13. **Test strategy** — What tests are needed?
14. **Docs to update** — What docs need updating?

**Scaling guidance** — Match spec depth to task complexity:
- **Trivial** (typo, config change): AC list + success metrics + quality gates. No user stories, no scenarios.
- **Small** (single-file bug fix): ACs + success metrics + scope + quality gates. User stories optional.
- **Medium** (multi-file feature): Full spec — user stories, ACs with traceability, scenarios, all metric categories, key files, quality gates.
- **Large** (new subsystem): Full spec + clarifications + dependency analysis + risk assessment + quality gates.

**Anti-vagueness** — BANNED unless measurable: "works correctly", "is fast", "handles properly", "is robust", etc.

---

## Quality Gate Discovery (MANDATORY)

You MUST scan the repository and discover ALL available quality check commands. The engine will use these for deterministic verification after each phase. List them in your output using the EXACT format below.

### Where to Look

Check each of these in order:

1. **package.json** — `scripts` section (lint, test, build, format, typecheck, type-check, check, validate)
2. **Makefile** — targets like lint, test, build, format, check
3. **CI config** — `.github/workflows/*.yml`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `.circleci/config.yml`, `Jenkinsfile`
4. **Pre-commit hooks** — `.husky/`, `.pre-commit-config.yaml`
5. **Project manifest** — `.doyaken/manifest.yaml` (quality.test_command, quality.lint_command, quality.format_command, quality.build_command)
6. **Other convention files** — `pyproject.toml` (tool.ruff, pytest), `Cargo.toml`, `mix.exs`, `go.mod` + Makefile

### Output Format (EXACT)

At the end of your plan, include this block. Use the gate names exactly: `lint`, `format`, `test`, `build`. Leave a gate empty if no command exists. One command per line. The engine parses this.

```
QUALITY_GATES:
lint:<command>
format:<command>
test:<command>
build:<command>
```

Example for npm project:
```
QUALITY_GATES:
lint:npm run lint
format:npm run format
test:npm run test:basic
build:
```

Example when format has no dedicated command:
```
QUALITY_GATES:
lint:npm run lint
format:
test:npm run test:basic
build:npm run build
```

**Rules:**
- Commands must be runnable from the project root as-is
- Prefer the project's canonical commands (from package.json, Makefile) over CI-specific invocations
- If you find multiple candidates (e.g. `npm run lint` and `eslint .`), use the one the project docs or CI use
- Test that each command exists (e.g. `npm run lint` must be defined in package.json) — do NOT guess

---

## Output

Update the task file (or produce a plan document) with these sections:

```markdown
## Context
**Intent**: BUILD / FIX / IMPROVE / REVIEW
[Clear explanation of what and why]

## Acceptance Criteria
- [ ] AC-1 (US-1): [Specific testable criterion]
- [ ] AC-N: Quality gates pass (discovered below)
- [ ] AC-N: Changes committed with task reference

## Specification
### User Stories
(For trivial: "N/A — see Acceptance Criteria")

### Acceptance Scenarios
(For trivial: "N/A")

### Success Metrics
**Functional:** [specific behaviour with threshold]
**Quality:** All tests pass, no lint errors
**Regression:** Existing test suite passes

### Key Files
| File | Relevance | Pattern |
|------|-----------|---------|
| path | why | what to follow |

### Scope
**In Scope:** [what]
**Out of Scope:** [item] -- [why]

### Gap Analysis
| Criterion | Status | Gap |
|-----------|--------|-----|
| AC-N | full/partial/none | [what's missing] |

### Risks
- [ ] [Risk]: [mitigation]

### Implementation Steps
1. **[Description]**
   - File: path/to/file
   - Change: [specific]
   - Verify: [how]

### Test Plan
- [ ] Unit: [description]
- [ ] Integration: [description]

### Docs to Update
- [ ] path - [change]

## Quality Gates (MANDATORY)
(Include the QUALITY_GATES block exactly as specified above)
```

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Plan Complete
- Intent: [BUILD/FIX/IMPROVE/REVIEW]
- Quality gates discovered: lint, format, test, build (or "missing" for empty)
- Steps: [count]
- Complexity: [trivial/small/medium/large]
```

## Rules

- Do NOT write implementation code — only the plan
- Be SPECIFIC — vague plans lead to vague implementations
- QUALITY_GATES block is REQUIRED — the engine will not proceed correctly without it
- If something already exists and is complete, note it and move on
- Mark unknowns with `[NEEDS CLARIFICATION]: [question] -- [why it matters]`

{{VERIFICATION_CONTEXT}}

{{ACCUMULATED_CONTEXT}}

Task prompt: {{TASK_PROMPT}}
