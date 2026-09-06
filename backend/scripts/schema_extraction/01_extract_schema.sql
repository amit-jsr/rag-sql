-- ============================================================
-- Day 1 Step 1: Extract schema metadata for all tables
-- Run against your target Postgres DB (adjust schema_name filter)
-- Output: export each query result to CSV/JSON for downstream processing
-- ============================================================

-- 1. Table + column inventory
SELECT
    c.table_schema,
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    col_description(
        (quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass::oid,
        c.ordinal_position
    ) AS column_comment
FROM information_schema.columns c
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY c.table_schema, c.table_name, c.ordinal_position;

-- 2. Primary keys
SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
    AND tc.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY tc.table_schema, tc.table_name;

-- 3. Foreign keys (this is your join-graph source of truth)
SELECT
    tc.table_schema AS fk_schema,
    tc.table_name AS fk_table,
    kcu.column_name AS fk_column,
    ccu.table_schema AS referenced_schema,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY tc.table_schema, tc.table_name;

-- 4. Table-level comments (if any exist already — good source for descriptions)
SELECT
    n.nspname AS table_schema,
    c.relname AS table_name,
    obj_description(c.oid) AS table_comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname;

-- 5. Row counts + sample values helper (run per table in the Python script instead —
--    doing 150+ tables here individually is impractical in raw SQL)
