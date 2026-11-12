---
description: "Use when adding or changing schema-backed HR forms, persistence payloads, migrations, SQL, or data fields."
applyTo: "HR/**/*.sql"
---

# Schema Alignment

- Treat `HR/HR_Schema_final-v4.sql` as the authoritative HR schema unless the task explicitly identifies a newer source.
- Verify columns, types, enums, keys, and relationships in the schema before adding fields or changing payloads.
- Do not create UI fields or persistence attributes that have no schema or documented business backing.
- Keep schema changes narrowly scoped and explain any required migration or compatibility impact.
- For form and child-record presentation, also follow the relevant creation UX and dynamic-relations instructions.
