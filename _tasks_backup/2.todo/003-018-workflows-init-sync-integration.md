# Task: Integrate Workflow Templates with Init/Sync

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-018-workflows-init-sync-integration`              |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-10 18:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | `003-012`                                              |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken already has a template distribution pattern: `templates/` dir at install root, synced to projects via `doyaken init`/`doyaken sync` (handled by `scripts/sync-agent-files.sh`). Workflow templates should plug into this same distribution mechanism.

## Objective

Extend `doyaken init` and `doyaken sync` to copy workflow templates into the project's `.doyaken/workflows/` directory, making them available for `doyaken workflows install`.

## Requirements

### Init Behavior

- `doyaken init` copies all files from `templates/workflows/` to `.doyaken/workflows/` in the target project
- Templates are copied as-is (no variable substitution at this stage — substitution happens at `install` time)
- Don't overwrite if the user has customized a template (check modification time or content hash)

### Sync Behavior

- `doyaken sync` refreshes templates in `.doyaken/workflows/`
- Report which templates were updated/added
- Warn if a local template has been customized and would be overwritten (offer to skip)

### Important Distinction

- `.doyaken/workflows/` = local reference copies (raw templates, not installed)
- `.github/workflows/` = installed, active workflows (with variables substituted)
- Installing to `.github/workflows/` always requires explicit `doyaken workflows install`

### Files to Modify

| File | Action |
|------|--------|
| `scripts/sync-agent-files.sh` | **Modify** — add workflow template copying |

## Technical Notes

- Follow the existing pattern in `sync-agent-files.sh` for copying template files
- The `.doyaken/workflows/` directory should be created during init if it doesn't exist
- Consider adding `.doyaken/workflows/` to the project's `.gitignore` since these are derived files (or not — user may want to version customizations)

## Success Criteria

- [ ] `doyaken init` copies workflow templates to `.doyaken/workflows/`
- [ ] `doyaken sync` refreshes workflow templates
- [ ] User customizations not silently overwritten
- [ ] Clear separation between `.doyaken/workflows/` (templates) and `.github/workflows/` (installed)
