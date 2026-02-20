# Task: Unit Tests for Workflows Module

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-019-workflows-unit-tests`                         |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-10 18:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | `003-012`, `003-013`, `003-014`, `003-015`, `003-016`, `003-017` |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

All doyaken modules have corresponding bats test files. The workflows module needs the same coverage to ensure template processing, install/remove, and the CLI subcommand work correctly.

## Objective

Create `test/unit/workflows_test.bats` with comprehensive tests for `lib/workflows.sh` and the workflow template processing.

## Requirements

### Test Coverage

1. **Template listing** — `doyaken workflows` lists all templates with tier and description
2. **Variable substitution** — all `{{VAR}}` placeholders replaced correctly
3. **Install** — creates file in `.github/workflows/` with `doyaken-` prefix and substituted variables
4. **Install --all** — installs all available templates
5. **Remove** — deletes the correct file from `.github/workflows/`
6. **Check** — detects outdated installed workflows (template changed since install)
7. **Duplicate install** — handles reinstalling an already-installed workflow (overwrite or warn)
8. **Missing template** — graceful error when trying to install nonexistent template
9. **Config loading** — verifies manifest > global.yaml > defaults priority for workflow settings

### Template Validation

1. Each workflow template produces valid YAML after variable substitution
2. Required fields present (name, on, jobs)
3. No unsubstituted `{{VAR}}` placeholders remain after processing

### Test Setup

- Use temp directories for `.github/workflows/` and `templates/workflows/`
- Create minimal test templates for testing (don't depend on real templates existing)
- Follow existing test patterns from `test/test_helper.bash`

## Technical Notes

- Use `yq` or simple grep checks for YAML validation (don't need full YAML parser)
- Consider testing with `actionlint` if available (optional, nice-to-have)
- Follow the bats test patterns used in existing tests (`test/unit/`)

## Success Criteria

- [ ] `test/unit/workflows_test.bats` exists with comprehensive tests
- [ ] All list/install/remove/check operations tested
- [ ] Variable substitution edge cases covered
- [ ] Config priority chain tested
- [ ] Tests pass: `npx bats test/unit/workflows_test.bats`
