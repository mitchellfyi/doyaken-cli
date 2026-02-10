# Task: Workflows CLI Command and Template Engine

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-012-workflows-cli-and-template-engine`            |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-10 18:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      | `003-013`, `003-014`, `003-015`, `003-016`, `003-017`, `003-018`, `003-019` |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken has skills for reviews and audits but they only run when manually invoked. We want to ship GitHub Actions workflow templates that automate these. This task builds the core infrastructure: the `lib/workflows.sh` module and the `doyaken workflows` CLI command.

## Objective

Create `lib/workflows.sh` with template variable substitution, and wire up the `doyaken workflows` subcommand for listing, installing, removing, and checking workflow templates.

## Requirements

### CLI Subcommand: `doyaken workflows`

```
doyaken workflows                  # List available workflow templates
doyaken workflows install [name]   # Install one or all (--all)
doyaken workflows remove <name>    # Remove an installed workflow
doyaken workflows check            # Show if installed workflows are outdated
```

Follows existing subcommand pattern (`doyaken tasks`, `doyaken skills`, `doyaken mcp`).

### Template Variable Substitution

Templates use `{{VAR}}` placeholders. The engine reads values from manifest > global config > detected defaults:

| Variable | Source | Default |
|----------|--------|---------|
| `{{DEFAULT_BRANCH}}` | git/manifest | `main` |
| `{{CI_WORKFLOW_NAME}}` | detected/manifest | `CI` |
| `{{SCHEDULE_REVIEW}}` | manifest | `0 6 * * 1` (Monday 6am) |
| `{{SCHEDULE_SECURITY}}` | manifest | `0 6 1 * *` (1st of month) |
| `{{SCHEDULE_DEPS}}` | manifest | `0 6 * * 1` |
| `{{NODE_VERSION}}` | detected | `20` |
| `{{TEST_COMMAND}}` | manifest | `npm test` |
| `{{LINT_COMMAND}}` | manifest | `npm run lint` |
| `{{AGENT_STRATEGY}}` | manifest | `copilot` |

### Manifest Extension

Add `workflows:` section to `config/global.yaml`:

```yaml
workflows:
  agent_strategy: "copilot"   # copilot | claude-api | issue-only
  schedules:
    review: "0 6 * * 1"
    security: "0 6 1 * *"
    deps: "0 6 * * 1"
```

### Install/Remove Behavior

- `install` reads from `templates/workflows/`, substitutes variables, writes to `.github/workflows/doyaken-<name>.yml`
- `doyaken-` prefix on installed files avoids collisions with user workflows
- `remove` deletes the corresponding file from `.github/workflows/`
- `check` compares installed files against current templates (after variable substitution) and reports outdated ones

### Files to Create/Modify

| File | Action |
|------|--------|
| `lib/workflows.sh` | **Create** — core logic |
| `lib/cli.sh` | **Modify** — add `workflows` command dispatch |
| `lib/help.sh` | **Modify** — add workflows help text |
| `config/global.yaml` | **Modify** — add `workflows:` defaults |
| `templates/workflows/` | **Create** — empty dir (templates come in later tasks) |

### Reuse

- `sync-agent-files.sh` pattern for `{{VAR}}` substitution (sed-based)
- `lib/skills.sh` pattern for subcommand dispatch
- `_load_config` from `lib/config.sh` for reading workflow settings

## Success Criteria

- [ ] `doyaken workflows` lists available templates with tier/description
- [ ] `doyaken workflows install <name>` substitutes variables and writes to `.github/workflows/`
- [ ] `doyaken workflows install --all` installs all templates
- [ ] `doyaken workflows remove <name>` deletes installed workflow
- [ ] `doyaken workflows check` reports outdated installed workflows
- [ ] Template variable substitution works for all defined variables
- [ ] Config loaded from manifest > global.yaml > defaults
