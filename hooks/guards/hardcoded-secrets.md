---
name: warn-hardcoded-secrets
enabled: true
event: file
pattern: (API_KEY|SECRET_KEY|PRIVATE_KEY|ACCESS_KEY|ENCRYPTION_KEY|AUTH_TOKEN|JWT_SECRET|PASSWORD|TOKEN)\s*[=:]\s*['"][^'"]{8,}
action: warn
---

WARNING: Possible hardcoded credential detected.

Use environment variables instead of hardcoded secrets.
Store sensitive values in `.env` files (which should be in `.gitignore`).

Caught patterns: `API_KEY`, `SECRET_KEY`, `PRIVATE_KEY`, `ACCESS_KEY` (AWS), `ENCRYPTION_KEY`, `AUTH_TOKEN`, `JWT_SECRET`, `PASSWORD`, `TOKEN` — followed by `=` or `:` and a quoted value of 8+ characters.
