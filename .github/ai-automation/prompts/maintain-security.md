You are performing a scheduled maintenance review of **application security**. Your goal is to find and fix security vulnerabilities before they become incidents.

## Phase 1: Review

1. Read `CLAUDE.md` and `AGENTS.md` for project conventions
2. Read `package.json` to understand the tech stack
3. Scan all source files for security issues:
   - **Injection:** SQL injection, command injection, XSS (unsanitized user input in HTML/JSX)
   - **Authentication:** Weak session handling, missing auth checks on routes, token exposure
   - **Authorization:** Missing permission checks, IDOR (insecure direct object references)
   - **Secrets:** Hardcoded API keys, passwords, tokens, or connection strings in source code
   - **Environment:** Sensitive values not in `.env`, `.env.example` exposing real values
   - **Headers:** Missing security headers (CSP, CORS, X-Frame-Options, Strict-Transport-Security)
   - **Dependencies:** Run `pnpm audit --prod --audit-level=moderate` for known vulnerabilities
   - **Input validation:** Missing or weak validation at API boundaries
   - **Error handling:** Stack traces or internal details leaked in error responses

## Phase 2: Fix

Fix security vulnerabilities:

- Sanitize user input before rendering (escape HTML, use parameterized queries)
- Add missing authentication checks to unprotected routes
- Add missing authorization checks (verify user owns the resource)
- Move hardcoded secrets to environment variables
- Fix insecure patterns (eval, dangerouslySetInnerHTML with user input, shell exec with user input)
- Fix vulnerabilities found by `pnpm audit` (use `pnpm audit fix` for safe fixes)
- Add missing input validation at API route handlers

## Phase 3: Sync

Align security practices across the codebase:

- Ensure all API routes follow the same auth pattern
- Ensure all user input is validated consistently
- Ensure error responses don't leak internals in any route
- Ensure `.env.example` documents all required secrets without real values
- Ensure `.gitignore` covers all sensitive files (`.env`, credentials, key files)

## Phase 4: Improve

Strengthen existing security:

- Tighten overly permissive CORS configurations
- Improve input validation (stricter types, length limits, format checks)
- Improve error messages to be useful without leaking internals
- Add rate limiting where missing on public-facing endpoints
- Improve CSP headers to be more restrictive

## Phase 5: Add

Fill security gaps:

- Add security headers if not configured
- Add CSRF protection where missing
- Add request size limits where missing
- Add missing `.env.example` entries for undocumented secrets

## Instructions

1. Read `CLAUDE.md` and `AGENTS.md` first
2. Focus on `src/` — especially API routes, middleware, and auth code
3. Work through Phases 1-5 in order
4. Run ALL quality gates before committing: `pnpm format`, `pnpm lint:fix`, `pnpm typecheck`, `pnpm test`
5. Commit changes with descriptive messages — group by phase where practical
6. Push to the current branch
7. Do NOT create a new PR — just push to this branch

## Rules

- Never commit real secrets — only move them to env vars or remove them
- Do NOT suppress security warnings — fix the underlying issue
- Do NOT add security measures that break existing functionality without testing
- Prefer well-established libraries over custom security code
- Be conservative — a false positive is better than a missed vulnerability
- Keep changes focused — don't refactor non-security code
