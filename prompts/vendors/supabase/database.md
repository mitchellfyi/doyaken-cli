# Supabase Database

PostgreSQL database design and Row Level Security on Supabase.

## When to Apply

Activate this guide when:
- Designing database schema
- Implementing Row Level Security
- Writing database migrations
- Optimizing queries

---

## 1. Schema Design

### Table Structure

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Users profile (extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  full_name text,
  avatar_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Posts table
create table public.posts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  content text,
  published boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Comments table
create table public.comments (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamptz default now()
);

-- Create indexes
create index posts_user_id_idx on public.posts(user_id);
create index posts_created_at_idx on public.posts(created_at desc);
create index comments_post_id_idx on public.comments(post_id);
```

### Timestamps Trigger

```sql
-- Auto-update updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to tables
create trigger set_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

create trigger set_updated_at
  before update on public.posts
  for each row execute function public.handle_updated_at();
```

### Profile Auto-Creation

```sql
-- Create profile when user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

---

## 2. Row Level Security (RLS)

### Enable RLS

```sql
-- ALWAYS enable RLS on public tables
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
```

### Policy Patterns

#### User's Own Data

```sql
-- Users can read their own profile
create policy "Users can view own profile"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);
```

#### Public Read, Owner Write

```sql
-- Anyone can read published posts
create policy "Published posts are viewable by everyone"
  on public.posts for select
  using (published = true);

-- Users can read their own unpublished posts
create policy "Users can view own posts"
  on public.posts for select
  to authenticated
  using (auth.uid() = user_id);

-- Only owner can insert
create policy "Users can create posts"
  on public.posts for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Only owner can update
create policy "Users can update own posts"
  on public.posts for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Only owner can delete
create policy "Users can delete own posts"
  on public.posts for delete
  to authenticated
  using (auth.uid() = user_id);
```

#### Multi-Tenant

```sql
-- Organization-based access
create table public.organizations (
  id uuid default uuid_generate_v4() primary key,
  name text not null
);

create table public.org_members (
  org_id uuid references public.organizations(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text check (role in ('owner', 'admin', 'member')),
  primary key (org_id, user_id)
);

create table public.org_documents (
  id uuid default uuid_generate_v4() primary key,
  org_id uuid references public.organizations(id) on delete cascade not null,
  title text not null,
  content text
);

alter table public.org_documents enable row level security;

-- Members can view org documents
create policy "Org members can view documents"
  on public.org_documents for select
  to authenticated
  using (
    exists (
      select 1 from public.org_members
      where org_members.org_id = org_documents.org_id
      and org_members.user_id = auth.uid()
    )
  );
```

### RLS Best Practices

```sql
-- 1. Use TO clause for role targeting
create policy "..."
  on table for select
  to authenticated  -- Only runs for authenticated users
  using (...);

-- 2. Separate policies by operation
-- DON'T use FOR ALL
-- DO create separate policies for select, insert, update, delete

-- 3. Optimize with function caching
create or replace function auth.uid()
returns uuid
language sql stable
as $$
  select nullif(
    current_setting('request.jwt.claim.sub', true),
    ''
  )::uuid
$$;

-- 4. Index columns used in policies
create index org_members_user_id_idx on public.org_members(user_id);
create index org_documents_org_id_idx on public.org_documents(org_id);
```

---

## 3. Migrations

### Migration Files

```sql
-- supabase/migrations/20240101000000_initial_schema.sql

-- Create tables
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Create policies
create policy "Users can view own profile"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);
```

### Migration Commands

```bash
# Create new migration
supabase migration new add_posts_table

# Apply migrations locally
supabase db reset

# Push to remote
supabase db push

# Pull remote schema
supabase db pull

# Show migration status
supabase migration list
```

### Safe Migrations

```sql
-- Add column with default (safe)
alter table public.posts
  add column if not exists view_count integer default 0;

-- Rename column (use transaction)
begin;
  alter table public.posts rename column title to post_title;
commit;

-- Add NOT NULL safely
-- 1. Add column nullable
alter table public.posts add column slug text;
-- 2. Backfill data
update public.posts set slug = lower(replace(title, ' ', '-'));
-- 3. Add constraint
alter table public.posts alter column slug set not null;
```

---

## 4. Querying

### Client Queries

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Select with relations
const { data: posts, error } = await supabase
  .from('posts')
  .select(`
    id,
    title,
    content,
    created_at,
    profiles (
      username,
      avatar_url
    ),
    comments (
      id,
      content,
      profiles (username)
    )
  `)
  .eq('published', true)
  .order('created_at', { ascending: false })
  .limit(10)

// Insert
const { data, error } = await supabase
  .from('posts')
  .insert({
    user_id: userId,
    title: 'My Post',
    content: 'Content here'
  })
  .select()
  .single()

// Update
const { data, error } = await supabase
  .from('posts')
  .update({ title: 'Updated Title' })
  .eq('id', postId)
  .eq('user_id', userId)  // RLS will also enforce this
  .select()
  .single()

// Delete
const { error } = await supabase
  .from('posts')
  .delete()
  .eq('id', postId)
```

### Database Functions

```sql
-- Create function for complex operations
create or replace function public.get_user_feed(user_id uuid, limit_count int default 20)
returns table (
  id uuid,
  title text,
  content text,
  author_name text,
  created_at timestamptz
) as $$
begin
  return query
  select
    p.id,
    p.title,
    p.content,
    pr.full_name as author_name,
    p.created_at
  from public.posts p
  join public.profiles pr on p.user_id = pr.id
  where p.published = true
  order by p.created_at desc
  limit limit_count;
end;
$$ language plpgsql security definer;

-- Call from client
const { data, error } = await supabase
  .rpc('get_user_feed', { user_id: userId, limit_count: 10 })
```

---

## 5. Real-time

### Enable Real-time

```sql
-- In Supabase Dashboard: Database → Replication
-- Or via SQL:
alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.comments;
```

### Subscribe to Changes

```typescript
// Subscribe to all changes
const channel = supabase
  .channel('posts-changes')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('Change:', payload)
    }
  )
  .subscribe()

// Subscribe to specific rows
const channel = supabase
  .channel('post-detail')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'posts',
      filter: `id=eq.${postId}`
    },
    (payload) => {
      console.log('Post updated:', payload.new)
    }
  )
  .subscribe()

// Cleanup
supabase.removeChannel(channel)
```

---

## Security Checklist

- [ ] RLS enabled on all public tables
- [ ] Separate policies per operation (no FOR ALL)
- [ ] Policies use `to authenticated` or `to anon` appropriately
- [ ] No use of `user_metadata` in RLS (user-modifiable)
- [ ] Indexes on columns used in RLS policies
- [ ] Service role key only used server-side
- [ ] Anon key safe for client-side with RLS

## References

- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Database Functions](https://supabase.com/docs/guides/database/functions)
- [Migrations](https://supabase.com/docs/guides/cli/local-development#database-migrations)
