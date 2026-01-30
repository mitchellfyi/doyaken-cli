# Fix Incomplete Registry YAML Fallback

## Category
Periodic Review Finding - debt

## Severity
high

## Description
The registry module (lib/registry.sh) uses `yq` for YAML manipulation when available, but the fallback to manual `awk` parsing is incomplete. The fallback only handles empty projects list, not existing entries.

If `yq` is unavailable and a user tries to modify an existing registry, data loss can occur.

## Location
lib/registry.sh:77-99

## Recommended Fix
Options (pick one):
1. **Require yq**: Add yq to required dependencies, fail fast if missing
2. **Complete fallback**: Implement full YAML read/write with awk/sed
3. **Use JSON**: Switch registry to JSON format (bash has better native support)

Recommendation: Option 1 (require yq) - it's already used elsewhere and is a reasonable dependency.

## Impact
- Potential data loss if yq unavailable
- Silent corruption of registry

## Acceptance Criteria
- [ ] Registry operations never corrupt data
- [ ] Clear error message if yq missing
- [ ] Doctor command checks for yq
- [ ] Document yq as requirement
