# Supabase Authentication

Authentication patterns and best practices for Supabase Auth.

## When to Apply

Activate this guide when:
- Implementing user authentication
- Setting up OAuth providers
- Managing sessions
- Protecting routes and APIs

---

## 1. Basic Auth

### Email/Password

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password123',
  options: {
    data: {
      username: 'johndoe',
      full_name: 'John Doe'
    }
  }
})

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
})

// Sign out
await supabase.auth.signOut()

// Get current user
const { data: { user } } = await supabase.auth.getUser()

// Get session
const { data: { session } } = await supabase.auth.getSession()
```

### Magic Link

```typescript
// Send magic link
const { error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com',
  options: {
    emailRedirectTo: 'https://myapp.com/auth/callback'
  }
})

// User clicks link → handled by auth callback
```

### Phone/OTP

```typescript
// Send OTP
const { error } = await supabase.auth.signInWithOtp({
  phone: '+1234567890'
})

// Verify OTP
const { data, error } = await supabase.auth.verifyOtp({
  phone: '+1234567890',
  token: '123456',
  type: 'sms'
})
```

---

## 2. OAuth Providers

### Configure Provider

```typescript
// GitHub
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'github',
  options: {
    redirectTo: 'https://myapp.com/auth/callback',
    scopes: 'read:user user:email'
  }
})

// Google
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: 'https://myapp.com/auth/callback',
    queryParams: {
      access_type: 'offline',
      prompt: 'consent'
    }
  }
})

// Discord, Twitter, etc.
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'discord'  // 'twitter', 'facebook', 'apple', etc.
})
```

### Auth Callback Handler

```typescript
// pages/auth/callback.tsx (Next.js)
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')

  if (code) {
    const supabase = createServerClient(/* config */)
    await supabase.auth.exchangeCodeForSession(code)
  }

  return NextResponse.redirect(new URL('/dashboard', request.url))
}
```

---

## 3. Session Management

### Auth State Changes

```typescript
// Listen for auth changes
supabase.auth.onAuthStateChange((event, session) => {
  console.log('Auth event:', event)
  // Events: SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED, USER_UPDATED, PASSWORD_RECOVERY

  if (event === 'SIGNED_IN') {
    // Redirect to dashboard
  } else if (event === 'SIGNED_OUT') {
    // Clear local state, redirect to login
  }
})
```

### Server-Side Sessions (Next.js)

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export function createClient() {
  const cookieStore = cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Handle server component
          }
        },
      },
    }
  )
}
```

### Middleware Protection

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: { headers: request.headers },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          response = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  // Protect /dashboard routes
  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return response
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
}
```

---

## 4. User Management

### Update User

```typescript
// Update email
const { data, error } = await supabase.auth.updateUser({
  email: 'new@email.com'
})

// Update password
const { data, error } = await supabase.auth.updateUser({
  password: 'new-password'
})

// Update metadata
const { data, error } = await supabase.auth.updateUser({
  data: { full_name: 'New Name' }
})
```

### Password Reset

```typescript
// Request reset
const { error } = await supabase.auth.resetPasswordForEmail(
  'user@example.com',
  { redirectTo: 'https://myapp.com/reset-password' }
)

// Update password (after redirect)
const { data, error } = await supabase.auth.updateUser({
  password: 'new-password'
})
```

### Delete User

```typescript
// User deletes own account (if enabled)
// Or use Admin API server-side
import { createClient } from '@supabase/supabase-js'

const supabaseAdmin = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY
)

const { error } = await supabaseAdmin.auth.admin.deleteUser(userId)
```

---

## 5. Security Best Practices

### Key Management

```typescript
// Client-side: Use anon key only
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!  // Safe with RLS
)

// Server-side only: Service role key
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!  // NEVER expose to client
)
```

### JWT Verification

```typescript
// Verify JWT in API routes
import { createClient } from '@supabase/supabase-js'
import { jwtVerify } from 'jose'

export async function POST(request: Request) {
  const authHeader = request.headers.get('Authorization')
  const token = authHeader?.replace('Bearer ', '')

  if (!token) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const { payload } = await jwtVerify(
      token,
      new TextEncoder().encode(process.env.SUPABASE_JWT_SECRET!)
    )

    // payload.sub is the user ID
    const userId = payload.sub

    // Process request...
  } catch {
    return Response.json({ error: 'Invalid token' }, { status: 401 })
  }
}
```

### Rate Limiting

```typescript
// Enable in Supabase Dashboard: Authentication → Rate Limits
// Or implement server-side:

import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, '1 m'),
})

export async function POST(request: Request) {
  const ip = request.headers.get('x-forwarded-for') ?? 'anonymous'
  const { success } = await ratelimit.limit(ip)

  if (!success) {
    return Response.json({ error: 'Too many requests' }, { status: 429 })
  }

  // Process login...
}
```

---

## 6. Custom Claims

### Add Custom Claims

```sql
-- Create function to add custom claims
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
as $$
declare
  claims jsonb;
  user_role text;
begin
  -- Get user's role from profiles
  select role into user_role
  from public.profiles
  where id = (event->>'user_id')::uuid;

  claims := event->'claims';

  -- Add custom claims
  claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
  claims := jsonb_set(claims, '{user_level}', '"standard"');

  event := jsonb_set(event, '{claims}', claims);

  return event;
end;
$$;

-- Grant necessary permissions
grant usage on schema public to supabase_auth_admin;
grant execute on function public.custom_access_token_hook to supabase_auth_admin;
```

### Use Custom Claims in RLS

```sql
-- Access custom claims in policies
create policy "Admins can delete any post"
  on public.posts for delete
  to authenticated
  using (
    (current_setting('request.jwt.claims', true)::jsonb->>'user_role') = 'admin'
  );
```

---

## Auth Patterns by Framework

### React

```typescript
// AuthContext.tsx
import { createContext, useContext, useEffect, useState } from 'react'
import { User, Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

interface AuthContextType {
  user: User | null
  session: Session | null
  loading: boolean
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  session: null,
  loading: true
})

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setSession(session)
        setUser(session?.user ?? null)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  return (
    <AuthContext.Provider value={{ user, session, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
```

## References

- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Auth Helpers](https://supabase.com/docs/guides/auth/auth-helpers)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
