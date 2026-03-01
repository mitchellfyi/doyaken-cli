# Task: Review and improve error messages in lib/errors.sh

## Context
**Intent**: IMPROVE

`lib/errors.sh` provides a batch error collection framework with three fields per error: message, fix suggestion, and optional doc URL. It is currently used only by `cmd_validate()` in `lib/cli.sh` (8 `error_add` calls). The framework itself is well-designed, but the messages using it can be improved:

- No caller uses the `doc` parameter (missed opportunity)
- One message has a vague fix suggestion
- Some messages could be more specific about the exact file paths involved

## Acceptance Criteria
- [ ] AC-1: Every `error_add` call includes a clear "what went wrong" message with enough context (e.g. file path, value)
- [ ] AC-2: Every `error_add` call includes an actionable "how to fix it" suggestion with a concrete command or instruction
- [ ] AC-3: Error messages that relate to documented features include a `doc` URL parameter pointing to relevant docs/help
- [ ] AC-4: The `error_report()` output format clearly separates the problem from the fix
- [ ] AC-5: Quality gates pass (lint, test)
- [ ] AC-6: Changes committed with task reference

## Specification

### User Stories
N/A — see Acceptance Criteria (this is a small improvement task)

### Acceptance Scenarios
- SC-1 (AC-1, AC-2): Given a user runs `dk validate` in a project with a missing manifest, then they see both "manifest.yaml not found" AND "Run 'dk init' to create one" in the output
- SC-2 (AC-3): Given an error has a doc URL, then the output includes a "Docs:" line with the URL
- SC-3 (AC-4): Given multiple errors, then each error shows a numbered item with problem, fix, and optional docs on separate indented lines

### Success Metrics
**Functional:** All 8 `error_add` calls have non-empty message AND fix parameters; at least 3 include a doc URL
**Quality:** `npm run lint` passes, `npm run test:basic` passes
**Regression:** Existing bats tests pass unchanged

### Key Files
| File | Relevance | Pattern |
|------|-----------|---------|
| `lib/errors.sh` | Error framework (collect, report) | Parallel arrays, numbered output |
| `lib/cli.sh:820-918` | `cmd_validate()` — all 8 `error_add` callers | Validation checks with error collection |
| `test/unit/commands.bats` | Test coverage for CLI commands | bats test pattern |

### Current Error Message Audit

| # | Location | Message | Fix | Doc | Assessment |
|---|----------|---------|-----|-----|------------|
| 1 | cli.sh:835 | "manifest.yaml not found" | "Run 'dk init' to create one" | — | Good. Clear problem + fix. |
| 2 | cli.sh:842 | "manifest.yaml has invalid YAML syntax" | "Run 'yq .' .doyaken/manifest.yaml to see the parse error" | — | Good. Diagnostic command. |
| 3 | cli.sh:851 | "project.name is missing or empty" | "Add 'project.name' to .doyaken/manifest.yaml" | — | Good. Specific field + file. |
| 4 | cli.sh:867 | "quality.$field command not found: $base_cmd" | "Install '$base_cmd' or update the command in manifest.yaml" | — | Good. Specific command name. |
| 5 | cli.sh:887 | "Integration '$integration' requires env var: $var" | "export $var=<value> or run 'dk mcp setup $integration'" | — | Good. Two fix paths. |
| 6 | cli.sh:891 | "Integration '$integration' enabled but no server config found" | "Check config/mcp/servers/ for available servers" | — | **Vague fix.** Should tell user what to do concretely. |
| 7 | cli.sh:903 | "Skill hook '$skill_name' not found" | "Create skills/$skill_name.md or remove from manifest hooks" | — | Good. Two options. |
| 8 | cli.sh:908 | "yq not installed (required for full validation)" | "Install: brew install yq (macOS) or snap install yq (Ubuntu)" | — | Good. Platform-specific. |

### Scope
**In Scope:**
- Improving `error_add` messages in `lib/cli.sh` (the only consumer of `errors.sh`)
- Adding `doc` URLs where relevant documentation exists
- Improving message #6 (vague fix)

**Out of Scope:**
- `log_error`/`log_warn` calls in core.sh, agents.sh, project.sh — these don't use the errors.sh framework and are a separate concern
- Adding new error checks to cmd_validate — this task is about improving existing messages
- Changing the errors.sh framework itself — it already supports message + fix + doc well

### Gap Analysis
| Criterion | Status | Gap |
|-----------|--------|-----|
| AC-1: Clear "what went wrong" | full | All 8 messages describe the problem clearly |
| AC-2: Actionable fix | partial | Message #6 has vague fix ("Check config/mcp/servers/") |
| AC-3: Doc URLs | none | No error_add call uses the doc parameter |
| AC-4: Output format | full | error_report() already separates problem/fix/docs well |
| AC-5: Quality gates | full | Currently passing |

### Risks
- [ ] Low risk: Adding doc URLs to non-existent pages would be worse than no URL — verify URLs exist or use relative references to repo paths

### Implementation Steps

1. **Improve message #6 fix suggestion**
   - File: `lib/cli.sh:891`
   - Change: Replace vague "Check config/mcp/servers/ for available servers" with actionable suggestion: "Run 'dk mcp status' to see available integrations, or add a server config at config/mcp/servers/$integration.yaml"
   - Verify: `npm run lint` passes

2. **Add doc URLs to error_add calls where relevant**
   - File: `lib/cli.sh:835,842,851,867,908`
   - Change: Add third parameter to `error_add` for errors that have relevant docs:
     - #1 (manifest not found): `"https://github.com/mitchellfyi/doyaken-cli#quick-start"`
     - #4 (quality command not found): `"See .doyaken/manifest.yaml quality section"`
     - #8 (yq not installed): `"https://github.com/mikefarah/yq#install"`
   - Verify: `npm run lint` passes

3. **Add unit tests for error_add message quality**
   - File: `test/unit/commands.bats` (or new `test/unit/errors.bats`)
   - Change: Add tests that source errors.sh, call error_add, and verify error_report output includes message, fix, and doc lines
   - Verify: `npm run test:basic` passes

### Test Plan
- [ ] Unit: Test `error_add` with all 3 parameters and verify `error_report` output format
- [ ] Unit: Test `error_add` with empty doc parameter (backwards compat)
- [ ] Unit: Test `error_has_errors` returns correctly before/after `error_add`
- [ ] Regression: Existing bats tests pass (`npm run test:basic`)

### Docs to Update
- [ ] None — error messages are self-documenting through the Fix/Docs lines

## Quality Gates (MANDATORY)

```
QUALITY_GATES:
lint:npm run lint
format:
test:npm run test:basic
build:
```

## Work Log

### 2026-03-01 — Plan Complete
- Intent: IMPROVE
- Quality gates discovered: lint (npm run lint), test (npm run test:basic), format (none), build (none)
- Steps: 3
- Complexity: small
- Findings: errors.sh framework is solid; 8 error_add calls exist, 7/8 have good messages, 1 has a vague fix, 0/8 use the doc URL parameter

### 2026-03-01 08:17 - Testing and Docs Complete

Tests written:
- `test/unit/errors.bats` - 17 tests (unit)
  - error_init: resets arrays
  - error_add: stores message+fix, all 3 params, empty doc, message-only, accumulates multiple
  - error_has_errors: returns correctly before/after add, after init reset
  - error_report: empty case, numbered output, Fix lines, Docs lines, omits Docs when empty, separates problem/fix/docs on different lines
  - error_report_and_exit: exits 1 with errors, succeeds silently without
  - Mixed doc URL rendering regression test

Docs updated:
- None needed — error messages are self-documenting via Fix/Docs lines

Quality gates:
- Lint: pass (0 errors, 6 pre-existing warnings)
- Format: n/a
- Tests: pass (571 unit total, 17 new + 97 basic)
- Build: n/a

CI ready: yes
