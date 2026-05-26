# Error Handling

Status: active

Always wrap external API calls in `tryOrLog(fn)` from `src/safe-call.js`.

Reason: external profile lookups used to fail silently and return partial responses without an audit trail.

Recheck this entry when adding or changing calls to external service adapters.
