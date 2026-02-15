## CI Fix

{{#if HAS_CHANGES}}
Automated fix for CI failures on `main`.
{{else}}
Automated fix attempt for CI failures on `main`. No changes made yet — awaiting retry.
{{/if}}

### Original Failure
- **Failed Run:** {{RUN_URL}}
- **Failed Jobs:** {{FAILED_JOBS}}
- **Failed Steps:** {{FAILED_STEPS}}

### Error Logs

<details>
<summary>Click to expand full error output</summary>

```
{{ERROR_LOGS}}
```

</details>

{{#if HAS_CHANGES}}
### Changes
- **Commits:** {{COMMIT_COUNT}}
```
{{CHANGED_FILES}}
```
{{/if}}

Fixes #{{ISSUE_NUM}}

---
_Generated with [Claude Code](https://claude.ai/code)_
