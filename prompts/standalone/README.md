# Standalone Prompts

These are utility prompts that can be used independently, not as part of the phase workflow.

## Available Prompts

| Prompt | Description | Use Case |
|--------|-------------|----------|
| [base.md](base.md) | Core principles and mindset | Injected into skills, general guidance |
| [diagnose.md](diagnose.md) | Debugging methodology | Troubleshooting bugs |
| [security-review.md](security-review.md) | OWASP security audit | Security-focused code review |
| [refactor.md](refactor.md) | Code refactoring guidelines | Improving existing code |

## Usage

### Direct use
Copy and paste any prompt into your AI assistant's context.

### In skills
Reference via include:
```markdown
{{include:standalone/security-review.md}}
```

### In hooks
Reference via file path in hook scripts (see `hooks/security-check.sh` for example).

## vs Phase Prompts

**Phase prompts** (numbered 0-7) are part of the structured workflow and run in sequence.

**Standalone prompts** are utilities that can be invoked on-demand for specific tasks.
