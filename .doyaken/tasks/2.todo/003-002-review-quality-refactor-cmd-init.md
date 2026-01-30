# Refactor cmd_init() Function (254 lines)

## Category
Periodic Review Finding - quality

## Severity
medium

## Description
The `cmd_init()` function in lib/cli.sh is 254 lines long, handling multiple responsibilities:
- Directory creation
- Git detection
- Manifest creation
- Task template setup
- Agent file sync
- Slash command generation
- Project registration

This violates single-responsibility principle and makes the code hard to test and maintain.

## Location
lib/cli.sh:356-610

## Recommended Fix
Extract into smaller functions:
1. `init_directories()` - Create .doyaken structure
2. `init_manifest()` - Create and configure manifest.yaml
3. `init_task_template()` - Set up task templates
4. `init_agent_files()` - Sync agent configuration files
5. `init_slash_commands()` - Generate .claude/commands/

Keep `cmd_init()` as orchestrator calling these functions.

## Impact
- Hard to understand initialization flow
- Difficult to test individual parts
- Changes risk breaking unrelated functionality

## Acceptance Criteria
- [ ] cmd_init() reduced to <50 lines
- [ ] Each extracted function is independently testable
- [ ] Behavior unchanged (all tests pass)
- [ ] Each function has clear single responsibility
