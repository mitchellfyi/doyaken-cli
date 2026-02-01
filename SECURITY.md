# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in Doyaken, please report it responsibly:

1. **Do NOT open a public issue** for security vulnerabilities
2. Email the maintainer directly or use GitHub's private vulnerability reporting
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We aim to respond to security reports within 48 hours and will work with you to understand and address the issue.

## Credential Handling

### For Users

- **Never commit credentials** to version control
- Store sensitive values in `.env` files (already in `.gitignore`)
- Use environment variables or secret managers for production
- Rotate credentials immediately if exposed

### For Contributors

- **Never hardcode** API keys, tokens, or passwords in code
- Use placeholder values in `.env.example` (e.g., `NPM_TOKEN=`)
- CI/CD credentials must be stored in GitHub Secrets
- Review diffs before committing to avoid accidental exposure

### What to Do If You Expose a Credential

1. **Revoke the credential immediately** - don't wait
2. Generate a new credential
3. Update any systems using the old credential
4. Check logs for unauthorized usage
5. If the credential was committed to git, consider it permanently compromised (git history persists)

## Security Best Practices

This project follows these security practices:

- `.env` files are gitignored to prevent credential exposure
- CI/CD uses GitHub Secrets for sensitive values
- Dependencies are regularly audited (`npm audit`)
- Shell scripts are linted with ShellCheck

## Scope

This security policy covers the Doyaken CLI tool and its official distribution channels (npm, GitHub releases).
