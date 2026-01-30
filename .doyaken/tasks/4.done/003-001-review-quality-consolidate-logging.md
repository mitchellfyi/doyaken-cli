# Consolidate Duplicate Logging Functions

## Category
Periodic Review Finding - quality

## Severity
medium

## Description
Logging functions (log_info, log_error, log_warn, log_success) and color definitions (RED, GREEN, YELLOW, BLUE, NC) are duplicated across 10+ files instead of being centralized. Different files use different prefixes ([doyaken], [upgrade], [review], [registry]).

Files with duplicates:
- lib/utils.sh
- lib/upgrade.sh
- lib/core.sh
- lib/hooks.sh
- lib/taskboard.sh
- lib/run-periodic-review.sh
- lib/registry.sh
- scripts/*.sh
- install.sh

## Location
Multiple files - see description

## Recommended Fix
1. Create `lib/logging.sh` with all logging functions and color definitions
2. Export functions for use across scripts
3. Update all files to source lib/logging.sh
4. Remove duplicate definitions
5. Standardize logging prefix (recommend `[doyaken]` everywhere)

## Impact
- Maintenance burden when changing logging format
- Inconsistent output across different commands
- Code bloat

## Acceptance Criteria
- [ ] lib/logging.sh created with all logging functions
- [ ] All duplicate definitions removed from other files
- [ ] Consistent logging prefix across all commands
- [ ] All tests pass
