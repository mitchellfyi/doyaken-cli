---
name: supabase:setup-auth
description: Configure Supabase authentication
requires:
  - supabase
args:
  - name: provider
    description: Auth provider (email, google, github, apple)
    default: "email"
---

# Supabase Auth Setup

You are configuring authentication for a Supabase project.

## Context

Project: {{DOYAKEN_PROJECT}}
Provider: {{ARGS.provider}}

## Setup Process

### 1. Review Current Auth Config

Use Supabase MCP to check:
- Current auth providers
- Existing settings
- URL configuration

### 2. Configure Provider

{{include:vendors/supabase/auth.md}}

{{#if provider == "email"}}
**Email/Password Auth**

Already enabled by default. Configure settings:
- Enable email confirmations
- Set password requirements
- Configure email templates

{{else if provider == "google"}}
**Google OAuth**

1. Create OAuth credentials in Google Cloud Console
2. Configure in Supabase:
   - Client ID
   - Client Secret
   - Authorized redirect URIs

{{else if provider == "github"}}
**GitHub OAuth**

1. Create OAuth App in GitHub Settings
2. Configure in Supabase:
   - Client ID
   - Client Secret
   - Callback URL: `https://[project].supabase.co/auth/v1/callback`

{{else if provider == "apple"}}
**Apple Sign In**

1. Configure in Apple Developer Portal
2. Generate Service ID and Key
3. Configure in Supabase

{{/if}}

### 3. Client Integration

**JavaScript/TypeScript**:
```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

{{#if provider == "email"}}
// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password'
})

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password'
})
{{else}}
// OAuth sign in
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: '{{ARGS.provider}}'
})
{{/if}}
```

### 4. Configure Redirects

Set up redirect URLs:
- Site URL: `https://your-app.com`
- Redirect URLs: `https://your-app.com/auth/callback`

### 5. Test Authentication

1. Test sign up flow
2. Test sign in flow
3. Verify session handling
4. Test sign out

## Output

```markdown
## Auth Configuration

**Provider**: {{ARGS.provider}}
**Status**: Configured

### Settings
| Setting | Value |
|---------|-------|
| Provider | {{ARGS.provider}} |
| Email Confirmation | [enabled/disabled] |
| Auto-confirm | [enabled/disabled] |

### Callback URLs
- `https://[project].supabase.co/auth/v1/callback`

### Client Code
```typescript
// Sign in with {{ARGS.provider}}
const { data, error } = await supabase.auth.signInWith{{#if provider == "email"}}Password({
  email, password
}){{else}}OAuth({
  provider: '{{ARGS.provider}}'
}){{/if}}
```

### Next Steps
- [ ] Test authentication flow
- [ ] Configure email templates (if email)
- [ ] Set up RLS policies for authenticated users
- [ ] Add auth state handling in app
```
