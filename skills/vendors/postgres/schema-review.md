---
name: postgres:schema-review
description: Review PostgreSQL schema design
args:
  - name: table
    description: Specific table to review (optional)
    default: ""
---

# PostgreSQL Schema Review

You are reviewing PostgreSQL database schema design.

## Context

Project: {{DOYAKEN_PROJECT}}
Table: {{ARGS.table}}

## Review Process

### 1. Schema Analysis

{{include:vendors/postgres/schema.md}}

{{#if table}}
Review specific table: {{ARGS.table}}
{{else}}
Review all tables in the database schema.
{{/if}}

### 2. Check Table Design

For each table, evaluate:

**Primary Keys**
- Has a primary key?
- Using appropriate type (UUID vs serial)?
- Composite key appropriate?

**Data Types**
- Appropriate types for data?
- Using TEXT vs VARCHAR appropriately?
- Numeric precision correct?
- Timestamp with/without timezone?

**Constraints**
- NOT NULL where required?
- CHECK constraints for validation?
- UNIQUE constraints for business rules?

**Foreign Keys**
- Relationships properly defined?
- ON DELETE/UPDATE actions set?
- Cascades appropriate?

### 3. Index Review

```sql
-- Missing foreign key indexes
SELECT
  c.conrelid::regclass AS table_name,
  c.conname AS constraint_name,
  a.attname AS column_name
FROM pg_constraint c
JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
WHERE c.contype = 'f'
AND NOT EXISTS (
  SELECT 1 FROM pg_index i
  WHERE i.indrelid = c.conrelid
  AND a.attnum = ANY(i.indkey)
);
```

### 4. Naming Conventions

Check adherence to conventions:
- snake_case for tables and columns
- Singular table names (user vs users)
- Descriptive column names
- Consistent naming patterns

### 5. Normalization

Evaluate normalization level:
- First Normal Form (1NF)
- Second Normal Form (2NF)
- Third Normal Form (3NF)
- Denormalization where appropriate for performance

## Output

```markdown
## Schema Review Report

{{#if table}}
**Table**: {{ARGS.table}}
{{else}}
**Database**: [name]
**Tables Reviewed**: [count]
{{/if}}

### Summary
- **Issues Found**: [count]
- **Warnings**: [count]
- **Suggestions**: [count]

### Issues

#### Critical
- [ ] [Table]: [Issue description]

#### Warnings
- [ ] [Table]: [Warning description]

### Table Analysis

| Table | PK | FK | Indexes | Issues |
|-------|----|----|---------|--------|
| users | OK | OK | OK | None |
| orders | OK | Missing | Missing | 2 |

### Recommendations

1. **Add Foreign Key Index**
   ```sql
   CREATE INDEX idx_orders_user_id ON orders (user_id);
   ```

2. **Add NOT NULL Constraint**
   ```sql
   ALTER TABLE users ALTER COLUMN email SET NOT NULL;
   ```

3. **Fix Data Type**
   ```sql
   ALTER TABLE products ALTER COLUMN price TYPE numeric(10,2);
   ```

### Best Practices Checklist
- [ ] All tables have primary keys
- [ ] Foreign keys have indexes
- [ ] Appropriate NOT NULL constraints
- [ ] Consistent naming conventions
- [ ] Timestamps use timestamptz
```
