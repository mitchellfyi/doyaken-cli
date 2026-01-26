# Supabase API & Edge Functions

REST API, GraphQL, and Edge Functions on Supabase.

## When to Apply

Activate this guide when:
- Building APIs with Supabase
- Creating Edge Functions
- Integrating with external services
- Optimizing API performance

---

## 1. Auto-Generated REST API

### API Endpoints

```
Base URL: https://<project-ref>.supabase.co/rest/v1

GET    /tablename           - List all rows
GET    /tablename?id=eq.1   - Get specific row
POST   /tablename           - Insert row(s)
PATCH  /tablename?id=eq.1   - Update row(s)
DELETE /tablename?id=eq.1   - Delete row(s)
```

### Query Parameters

```typescript
// Filtering
.eq('column', 'value')     // =
.neq('column', 'value')    // !=
.gt('column', 'value')     // >
.gte('column', 'value')    // >=
.lt('column', 'value')     // <
.lte('column', 'value')    // <=
.like('column', '%value%') // LIKE
.ilike('column', '%value%')// ILIKE (case insensitive)
.is('column', null)        // IS NULL
.in('column', ['a', 'b'])  // IN
.contains('array_col', ['a'])
.containedBy('array_col', ['a', 'b'])

// Ordering
.order('created_at', { ascending: false })

// Pagination
.range(0, 9)  // First 10 rows
.limit(10)

// Counting
.select('*', { count: 'exact' })
```

### Complex Queries

```typescript
// Select with relations
const { data } = await supabase
  .from('posts')
  .select(`
    id,
    title,
    author:profiles(name, avatar_url),
    comments(
      id,
      content,
      user:profiles(name)
    )
  `)
  .eq('published', true)
  .order('created_at', { ascending: false })

// Or filter on relations
const { data } = await supabase
  .from('posts')
  .select('*, comments!inner(*)')
  .eq('comments.user_id', userId)

// Full-text search
const { data } = await supabase
  .from('posts')
  .select()
  .textSearch('title', 'search query', {
    type: 'websearch',
    config: 'english'
  })
```

---

## 2. Edge Functions

### Creating Functions

```bash
# Create new function
supabase functions new my-function

# Project structure
supabase/
└── functions/
    └── my-function/
        └── index.ts
```

### Basic Function

```typescript
// supabase/functions/my-function/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get auth user from request
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { data: { user } } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { name } = await req.json()

    // Do something
    const result = { message: `Hello ${name}!`, user_id: user.id }

    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

### Deploy Function

```bash
# Deploy single function
supabase functions deploy my-function

# Deploy all functions
supabase functions deploy

# Set secrets
supabase secrets set MY_API_KEY=value

# List secrets
supabase secrets list
```

### Invoke Function

```typescript
// From client
const { data, error } = await supabase.functions.invoke('my-function', {
  body: { name: 'World' }
})

// With custom headers
const { data, error } = await supabase.functions.invoke('my-function', {
  body: { name: 'World' },
  headers: { 'x-custom-header': 'value' }
})
```

---

## 3. Database Functions (RPC)

### Create Database Function

```sql
-- Simple function
create or replace function public.get_user_stats(user_id uuid)
returns json
language plpgsql
security definer
as $$
declare
  result json;
begin
  select json_build_object(
    'post_count', (select count(*) from posts where posts.user_id = $1),
    'comment_count', (select count(*) from comments where comments.user_id = $1),
    'total_likes', (select coalesce(sum(likes), 0) from posts where posts.user_id = $1)
  ) into result;

  return result;
end;
$$;
```

### Call via RPC

```typescript
const { data, error } = await supabase
  .rpc('get_user_stats', { user_id: userId })
```

### Function with Set-Returning

```sql
create or replace function public.search_posts(search_term text)
returns table (
  id uuid,
  title text,
  content text,
  rank real
)
language plpgsql
as $$
begin
  return query
  select
    p.id,
    p.title,
    p.content,
    ts_rank(
      to_tsvector('english', p.title || ' ' || p.content),
      plainto_tsquery('english', search_term)
    ) as rank
  from posts p
  where to_tsvector('english', p.title || ' ' || p.content)
    @@ plainto_tsquery('english', search_term)
  order by rank desc;
end;
$$;
```

---

## 4. Webhooks

### Database Webhooks

```sql
-- Create webhook trigger
create trigger on_post_created
after insert on public.posts
for each row
execute function supabase_functions.http_request(
  'https://<project-ref>.supabase.co/functions/v1/on-post-created',
  'POST',
  '{"Content-Type": "application/json"}',
  '{}',
  '1000'
);
```

### Webhook Handler

```typescript
// supabase/functions/on-post-created/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const payload = await req.json()

  // payload.type: INSERT, UPDATE, DELETE
  // payload.table: table name
  // payload.record: new row data
  // payload.old_record: old row data (for UPDATE/DELETE)

  const { type, table, record } = payload

  if (type === 'INSERT' && table === 'posts') {
    // Send notification, update cache, etc.
    console.log('New post created:', record.title)
  }

  return new Response('OK')
})
```

---

## 5. Storage API

### Upload Files

```typescript
// Upload file
const { data, error } = await supabase.storage
  .from('avatars')
  .upload(`${userId}/avatar.png`, file, {
    cacheControl: '3600',
    upsert: true
  })

// Get public URL
const { data } = supabase.storage
  .from('avatars')
  .getPublicUrl(`${userId}/avatar.png`)

// Get signed URL (for private buckets)
const { data, error } = await supabase.storage
  .from('private-files')
  .createSignedUrl(`${userId}/document.pdf`, 3600)
```

### Storage Policies

```sql
-- Allow users to upload to their own folder
create policy "Users can upload own avatar"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read of avatars
create policy "Avatars are publicly accessible"
on storage.objects for select
to public
using (bucket_id = 'avatars');
```

---

## 6. API Security

### Rate Limiting

```typescript
// In Edge Function
import { Ratelimit } from 'https://esm.sh/@upstash/ratelimit'
import { Redis } from 'https://esm.sh/@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
})

serve(async (req) => {
  const ip = req.headers.get('x-forwarded-for') ?? 'anonymous'
  const { success, limit, remaining } = await ratelimit.limit(ip)

  if (!success) {
    return new Response('Rate limit exceeded', {
      status: 429,
      headers: {
        'X-RateLimit-Limit': limit.toString(),
        'X-RateLimit-Remaining': remaining.toString(),
      },
    })
  }

  // Process request...
})
```

### Input Validation

```typescript
import { z } from 'https://esm.sh/zod@3'

const CreatePostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(10000),
  published: z.boolean().optional().default(false),
})

serve(async (req) => {
  const body = await req.json()

  const result = CreatePostSchema.safeParse(body)
  if (!result.success) {
    return new Response(
      JSON.stringify({ error: 'Validation failed', details: result.error }),
      { status: 400 }
    )
  }

  const { title, content, published } = result.data
  // Process validated data...
})
```

### API Keys

```typescript
// Verify API key for external services
serve(async (req) => {
  const apiKey = req.headers.get('x-api-key')

  if (apiKey !== Deno.env.get('EXPECTED_API_KEY')) {
    return new Response('Unauthorized', { status: 401 })
  }

  // Process request...
})
```

---

## Quick Reference

```typescript
// REST API
supabase.from('table').select()
supabase.from('table').insert({})
supabase.from('table').update({}).eq('id', 1)
supabase.from('table').delete().eq('id', 1)

// RPC
supabase.rpc('function_name', { arg: 'value' })

// Edge Functions
supabase.functions.invoke('function-name', { body: {} })

// Storage
supabase.storage.from('bucket').upload(path, file)
supabase.storage.from('bucket').download(path)
supabase.storage.from('bucket').getPublicUrl(path)

// Realtime
supabase.channel('name').on('postgres_changes', {}, callback)
```

## References

- [Supabase API](https://supabase.com/docs/guides/api)
- [Edge Functions](https://supabase.com/docs/guides/functions)
- [Database Functions](https://supabase.com/docs/guides/database/functions)
- [Storage](https://supabase.com/docs/guides/storage)
