# Task: Optimize Manifest Loading (Reduce yq Calls)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-003-perf-optimize-manifest-loading`               |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:10`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 22:13` |

---

## Context

Performance analysis identified that `load_manifest()` in `lib/core.sh:157-221` calls yq 8-12 times on the same manifest file. Each call parses the entire YAML, causing 500ms-2s delay per agent startup. Additionally, the env var loop calls yq once per variable (N+1 problem).

**Location**: `lib/core.sh:157-221`
**Category**: Performance
**Severity**: HIGH (impacts every agent run)

---

## Acceptance Criteria

- [ ] Reduce yq calls from 8-12 to 1-2 per manifest load
- [ ] Eliminate N+1 pattern for environment variable loading
- [ ] Maintain backward compatibility with existing manifest format
- [ ] Measure and document performance improvement

---

## Plan

1. Use single yq call to extract all values as JSON or tab-separated
2. Parse result with bash string operations
3. For env vars, extract entire env object in one call
4. Benchmark before/after

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review performance findings

---

## Notes

Example optimization:
```bash
# Instead of:
manifest_agent=$(yq '.agent.name' "$MANIFEST_FILE")
manifest_model=$(yq '.agent.model' "$MANIFEST_FILE")

# Use:
eval $(yq -o=shell '.agent | to_entries | .[] | "\(.key)=\(.value)"' "$MANIFEST_FILE")
```

Or cache entire manifest in a variable.

---

## Links

- Performance review finding: yq overhead
