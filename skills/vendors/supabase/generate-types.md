---
name: supabase:generate-types
description: Generate TypeScript types from Supabase schema
requires:
  - supabase
args:
  - name: output
    description: Output file path
    default: "src/types/database.ts"
---

# Generate Supabase TypeScript Types

You are generating TypeScript types from a Supabase database schema.

## Context

Project: {{DOYAKEN_PROJECT}}
Output: {{ARGS.output}}

## Generation Process

### 1. Fetch Schema

Use Supabase MCP to:
- Get project information
- Retrieve database schema
- List all tables and columns

### 2. Generate Types

Use Supabase MCP's `generate_typescript_types` tool:
- Generates types for all tables
- Includes enums and custom types
- Creates proper nullable types

### 3. Type Structure

Generated types follow this pattern:

```typescript
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          email: string
          created_at: string
        }
        Insert: {
          id?: string
          email: string
          created_at?: string
        }
        Update: {
          id?: string
          email?: string
          created_at?: string
        }
      }
      // ... other tables
    }
    Views: {
      // ... views
    }
    Functions: {
      // ... functions
    }
    Enums: {
      // ... enums
    }
  }
}
```

### 4. Client Configuration

Update Supabase client to use types:

```typescript
import { createClient } from '@supabase/supabase-js'
import type { Database } from '{{ARGS.output}}'

export const supabase = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
)

// Now fully typed!
const { data } = await supabase
  .from('users')  // autocomplete works
  .select('*')
// data is typed as Database['public']['Tables']['users']['Row'][]
```

### 5. Helper Types

Create convenience types:

```typescript
import type { Database } from '{{ARGS.output}}'

// Table row types
export type User = Database['public']['Tables']['users']['Row']
export type Post = Database['public']['Tables']['posts']['Row']

// Insert types
export type NewUser = Database['public']['Tables']['users']['Insert']

// Update types
export type UserUpdate = Database['public']['Tables']['users']['Update']
```

## Output

```markdown
## TypeScript Types Generated

**Output**: {{ARGS.output}}
**Tables**: [count]

### Generated Types
| Table | Row Type | Insert Type | Update Type |
|-------|----------|-------------|-------------|
| users | User | NewUser | UserUpdate |
| posts | Post | NewPost | PostUpdate |

### Usage
```typescript
import type { Database } from '{{ARGS.output}}'

const supabase = createClient<Database>(url, key)
```

### Files Updated
- {{ARGS.output}}

### Next Steps
- [ ] Import types in your code
- [ ] Update client initialization
- [ ] Add helper type exports
- [ ] Re-run when schema changes
```
