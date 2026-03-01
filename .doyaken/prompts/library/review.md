# Code Review

## Mindset

- Review like you will own this code for 2 years
- Prefer boring code — minimize cleverness
- Assume edge cases exist until disproven

## Findings Ledger

Track issues systematically by severity:
- **blocker**: Bugs, data loss, auth bypass, crashes
- **high**: Security issues, significant correctness problems
- **medium**: Performance, maintainability concerns
- **low**: Style, minor improvements

## Multi-Pass Review

### Pass A: Correctness
- Trace the happy path end-to-end
- Trace every failure and edge path
- Check for: silent failures, wrong defaults, missing error handling, off-by-one errors, null/undefined handling, empty collection handling, type coercion bugs
- Verify every import resolves, every API/function called exists, every property accessed is real

### Pass B: Design & Simplicity
- Does it fit existing patterns? Would a new developer understand it?
- Could this be simpler? Is there unnecessary abstraction or indirection?
- Is every function, module, and file focused on a single clear purpose?
- Any dead code, duplicated logic, magic numbers, unused imports?
- Is it backward compatible? Will existing callers, configs, or data formats still work?
- Does the implementation match the structure, style, and approach of adjacent code in this codebase?

### Pass C: Security & Privacy
- Input validation on all external data?
- Authorization on sensitive operations?
- No hardcoded secrets, no sensitive data in logs or error messages?
- PII handled correctly (minimized, not logged)?

### Pass D: Performance & Resilience
- N+1 queries or expensive loops?
- Timeouts on all external calls?
- Missing pagination on list endpoints?
- Race conditions in concurrent scenarios?
- Graceful degradation if dependencies fail?
- Resources cleaned up in both success and error paths?

### Pass E: Observability
- Errors logged with sufficient context to diagnose?
- Correlation IDs propagated?
- Appropriate log levels used?
- No sensitive data in logs?

### Pass F: Tests & Docs
- Tests cover behaviour, edge cases, and error paths?
- Tests actually verify meaningful behaviour, not just mirror the implementation's structure?
- Error-case tests exist for every happy-path test?
- Docs match implementation?
- No stale comments referring to old code?
- Configuration options documented?

## Loose Ends Sweep

- [ ] No unused imports or variables
- [ ] No console.log/print/debugger statements
- [ ] No commented-out code
- [ ] No broken imports from refactoring
- [ ] No TODOs without issue references
- [ ] All error paths handled, no silent catches
- [ ] All new files have appropriate file structure and naming
- [ ] Dead code, stale comments, and unnecessary complexity removed from files touched
- [ ] Resources (connections, handles, listeners, timers) properly cleaned up in all code paths

## Checklist

- [ ] All passes completed (A through F)
- [ ] No blocker/high issues remaining
- [ ] Tests exist and pass
- [ ] Code is understandable
- [ ] Changes match stated intent
- [ ] Backward compatibility verified
