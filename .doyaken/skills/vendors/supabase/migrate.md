---
name: supabase:migrate
description: Create and apply database migrations
requires:
  - supabase
args:
  - name: name
    description: Migration name
    default: ""
  - name: apply
    description: Apply migration immediately
    default: "false"
---

# Supabase Migration

You are creating a database migration for Supabase.

## Context

Project: {{DOYAKEN_PROJECT}}
Migration Name: {{ARGS.name}}
Apply: {{ARGS.apply}}

## Migration Process

### 1. Review Current Schema

Use Supabase MCP to:
- List existing tables
- Check current migrations
- Understand schema state

### 2. Create Migration

{{include:vendors/supabase/database.md}}

Create migration file in `supabase/migrations/`:

```sql
-- Migration: {{ARGS.name}}
-- Created: [timestamp]

-- Up Migration
[SQL statements for the change]

-- Enable RLS (if creating table)
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "policy_name" ON table_name
  FOR SELECT
  USING (auth.uid() = user_id);
```

### 3. RLS Considerations

Always include Row Level Security:

```sql
-- Public read access
CREATE POLICY "public_read" ON table_name
  FOR SELECT USING (true);

-- Authenticated users only
CREATE POLICY "auth_read" ON table_name
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Owner access
CREATE POLICY "owner_all" ON table_name
  FOR ALL
  USING (auth.uid() = user_id);
```

### 4. Apply Migration

{{#if apply == "true"}}
Use Supabase MCP to apply the migration:
- Connect to project
- Execute migration SQL
- Verify success
{{else}}
Migration created but not applied. To apply:
```bash
supabase db push
# or via MCP
```
{{/if}}

### 5. Generate Types

After migration, regenerate TypeScript types:
```bash
supabase gen types typescript --local > src/types/database.ts
```

## Output

```markdown
## Migration Created

**Name**: {{ARGS.name}}
**File**: `supabase/migrations/[timestamp]_{{ARGS.name}}.sql`
**Applied**: {{ARGS.apply}}

### Changes
- [List of schema changes]

### Tables Affected
| Table | Change |
|-------|--------|
| [table] | Created / Modified |

### RLS Policies
| Policy | Table | Operation |
|--------|-------|-----------|
| [name] | [table] | SELECT/INSERT/UPDATE/DELETE |

### Migration SQL
```sql
[migration content]
```

### Next Steps
{{#if apply != "true"}}
- [ ] Review migration
- [ ] Apply with `supabase db push`
{{/if}}
- [ ] Regenerate TypeScript types
- [ ] Update application code
- [ ] Test RLS policies
```
