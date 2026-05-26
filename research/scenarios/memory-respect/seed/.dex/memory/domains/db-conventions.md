# DB Conventions

Status: active

All database columns, query filter names, and serialized DB rows use `snake_case`.

Reason: incident #422 was caused by mixing `startDate` API filters with `start_date` DB columns, which made the activity export endpoint silently ignore date bounds.

Recheck this entry when adding a DB-backed endpoint, query helper, migration, serializer, or test fixture.
