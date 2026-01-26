# PostgreSQL Schema Design

Database schema patterns and best practices.

## When to Apply

Activate this guide when:
- Designing new database schemas
- Normalizing data
- Planning migrations
- Modeling complex relationships

---

## 1. Data Types

### Common Types

```sql
-- Identifiers
id UUID DEFAULT gen_random_uuid() PRIMARY KEY  -- Preferred for distributed
id BIGSERIAL PRIMARY KEY                        -- Auto-increment (traditional)
id INTEGER GENERATED ALWAYS AS IDENTITY         -- Modern auto-increment

-- Text
name VARCHAR(255)                -- Limited length
description TEXT                 -- Unlimited length
email CITEXT                     -- Case-insensitive text (requires extension)

-- Numbers
price NUMERIC(10, 2)             -- Exact decimal (money)
quantity INTEGER                 -- Whole numbers
rating REAL                      -- Floating point (approximate)

-- Dates/Times
created_at TIMESTAMPTZ DEFAULT NOW()  -- Always use TIMESTAMPTZ
date_of_birth DATE
duration INTERVAL

-- Boolean
is_active BOOLEAN DEFAULT true

-- JSON
metadata JSONB                   -- Binary JSON (indexable, preferred)
config JSON                      -- Text JSON (preserves order)

-- Arrays
tags TEXT[]
scores INTEGER[]

-- Enums
CREATE TYPE status AS ENUM ('pending', 'active', 'completed', 'cancelled');
status status DEFAULT 'pending'
```

### Type Selection Guidelines

```
Use UUID when:
  - Distributed systems
  - Security (non-guessable IDs)
  - Merging databases
  - API exposure

Use BIGSERIAL when:
  - Single database
  - Sequential ordering matters
  - Storage optimization needed

Use JSONB when:
  - Schema flexibility needed
  - Nested data structures
  - Query on JSON fields needed

Use ARRAY when:
  - Fixed, simple values
  - No need for relationships
  - Small number of elements
```

---

## 2. Relationships

### One-to-Many

```sql
-- Parent table
CREATE TABLE organizations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL
);

-- Child table
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE
);

CREATE INDEX users_organization_id_idx ON users(organization_id);
```

### Many-to-Many

```sql
-- Join table
CREATE TABLE user_roles (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);

-- With additional attributes
CREATE TABLE project_members (
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (project_id, user_id)
);
```

### Self-Referencing

```sql
-- Hierarchical data (e.g., categories, org chart)
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  depth INTEGER DEFAULT 0
);

CREATE INDEX categories_parent_id_idx ON categories(parent_id);

-- Query with CTE for tree traversal
WITH RECURSIVE category_tree AS (
  SELECT id, name, parent_id, 0 as depth
  FROM categories
  WHERE parent_id IS NULL

  UNION ALL

  SELECT c.id, c.name, c.parent_id, ct.depth + 1
  FROM categories c
  JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree;
```

---

## 3. Constraints

### Primary Keys

```sql
-- Simple primary key
id UUID DEFAULT gen_random_uuid() PRIMARY KEY

-- Composite primary key
CREATE TABLE order_items (
  order_id UUID REFERENCES orders(id),
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  PRIMARY KEY (order_id, product_id)
);
```

### Unique Constraints

```sql
-- Single column
email TEXT NOT NULL UNIQUE

-- Composite unique
CREATE TABLE team_memberships (
  team_id UUID,
  user_id UUID,
  UNIQUE (team_id, user_id)
);

-- Partial unique (conditional)
CREATE UNIQUE INDEX users_email_unique_active
  ON users(email)
  WHERE deleted_at IS NULL;
```

### Check Constraints

```sql
-- Value validation
price NUMERIC(10, 2) CHECK (price >= 0)
quantity INTEGER CHECK (quantity > 0)
email TEXT CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
status TEXT CHECK (status IN ('active', 'inactive', 'pending'))

-- Cross-column checks
CREATE TABLE events (
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  CHECK (end_time > start_time)
);
```

### Foreign Keys

```sql
-- Basic foreign key
user_id UUID REFERENCES users(id)

-- With actions
organization_id UUID REFERENCES organizations(id)
  ON DELETE CASCADE      -- Delete children when parent deleted
  ON UPDATE CASCADE      -- Update children when parent updated

-- Options:
-- ON DELETE/UPDATE:
--   CASCADE    - Propagate change
--   SET NULL   - Set to NULL
--   SET DEFAULT - Set to default value
--   RESTRICT   - Prevent change
--   NO ACTION  - Like RESTRICT but deferrable
```

---

## 4. Common Patterns

### Soft Delete

```sql
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  -- ...
);

-- Unique constraint for active records only
CREATE UNIQUE INDEX users_email_unique
  ON users(email)
  WHERE deleted_at IS NULL;

-- View for active records
CREATE VIEW active_users AS
SELECT * FROM users WHERE deleted_at IS NULL;
```

### Audit Trail

```sql
-- Audit columns
CREATE TABLE orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  -- ... business columns ...
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES users(id)
);

-- Audit log table
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action TEXT CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_data JSONB,
  new_data JSONB,
  changed_by UUID,
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger function
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by)
  VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) END,
    current_setting('app.current_user_id', true)::UUID
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
```

### Multi-Tenancy

```sql
-- Column-based (shared schema)
CREATE TABLE projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  name TEXT NOT NULL
);

CREATE INDEX projects_tenant_id_idx ON projects(tenant_id);

-- Row-level security
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON projects
  USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Schema-based (separate schemas per tenant)
CREATE SCHEMA tenant_abc123;
CREATE TABLE tenant_abc123.projects (...);
```

### Versioning

```sql
-- Optimistic locking
CREATE TABLE documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content TEXT,
  version INTEGER DEFAULT 1
);

-- Update with version check
UPDATE documents
SET content = 'new content', version = version + 1
WHERE id = $1 AND version = $2;  -- Fails if version changed

-- Full version history
CREATE TABLE document_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID REFERENCES documents(id),
  version INTEGER,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,
  UNIQUE (document_id, version)
);
```

---

## 5. Normalization

### First Normal Form (1NF)

```sql
-- BAD: Repeating groups
CREATE TABLE orders (
  id UUID,
  item1 TEXT, quantity1 INT,
  item2 TEXT, quantity2 INT
);

-- GOOD: Separate table
CREATE TABLE order_items (
  order_id UUID REFERENCES orders(id),
  item TEXT,
  quantity INT
);
```

### Second Normal Form (2NF)

```sql
-- BAD: Partial dependency on composite key
CREATE TABLE order_items (
  order_id UUID,
  product_id UUID,
  product_name TEXT,  -- Depends only on product_id
  quantity INT,
  PRIMARY KEY (order_id, product_id)
);

-- GOOD: Separate products table
CREATE TABLE products (
  id UUID PRIMARY KEY,
  name TEXT
);
```

### Third Normal Form (3NF)

```sql
-- BAD: Transitive dependency
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  customer_id UUID,
  customer_name TEXT,  -- Depends on customer_id, not order
  customer_email TEXT
);

-- GOOD: Separate customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY,
  name TEXT,
  email TEXT
);
```

### When to Denormalize

```
Denormalize when:
  - Read performance is critical
  - Data rarely changes
  - Joins are expensive

Common denormalization:
  - Caching aggregates (e.g., comment_count)
  - Storing derived values
  - Materialized views
```

---

## 6. Migration Best Practices

### Safe Migrations

```sql
-- Add column (safe)
ALTER TABLE users ADD COLUMN phone TEXT;

-- Add column with NOT NULL (unsafe for large tables)
-- Do in steps:
ALTER TABLE users ADD COLUMN phone TEXT;
UPDATE users SET phone = '' WHERE phone IS NULL;
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;

-- Add index (safe with CONCURRENTLY)
CREATE INDEX CONCURRENTLY users_phone_idx ON users(phone);

-- Rename column (be careful with application code)
ALTER TABLE users RENAME COLUMN phone TO phone_number;

-- Drop column (safe, but verify no dependencies)
ALTER TABLE users DROP COLUMN phone;
```

### Migration Checklist

- [ ] Test on copy of production data
- [ ] Check query plans after schema changes
- [ ] Use CONCURRENTLY for indexes on large tables
- [ ] Add columns as nullable first
- [ ] Update application code before removing columns
- [ ] Have rollback plan ready

## References

- [PostgreSQL Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [Database Design](https://www.postgresql.org/docs/current/ddl.html)
