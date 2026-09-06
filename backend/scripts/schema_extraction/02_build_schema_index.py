"""
Day 1 Step 2: Build a structured schema index from a live Postgres DB.

Produces:
  - schema_metadata.json   -> full table/column/PK/FK inventory
  - fk_graph.json          -> adjacency list of table relationships
  - schema_for_review.json -> per-table draft description (LLM-assisted, human review needed)

Requires: psycopg2-binary
    pip install psycopg2-binary --break-system-packages

Connection config and table scope are read from environment variables so the same
script runs unmodified against the synthetic docker-compose DB or a real DB later —
see backend/.env.example for the full list.
"""

import json
import os
import psycopg2
from collections import defaultdict

# ---- CONFIG: read from environment (see backend/.env.example) ----
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", "5432")),
    "dbname": os.environ.get("DB_NAME", "text2sql"),
    "user": os.environ.get("DB_USER", "text2sql"),
    "password": os.environ.get("DB_PASSWORD", "text2sql"),
}
SCHEMAS_TO_INCLUDE = os.environ.get("SCHEMAS_TO_INCLUDE", "public").split(",")
SAMPLE_ROWS_PER_TABLE = int(os.environ.get("SAMPLE_ROWS_PER_TABLE", "3"))

# Scope to a starter subset instead of all tables.
# Leave both empty to extract everything (fine for the ~18-table synthetic schema).
# TABLE_ALLOWLIST: exact "schema.table" names to include (your chosen domain cluster core tables)
# AUTO_EXPAND_FK_NEIGHBORS: after filtering to the allowlist, also pull in directly FK-connected
#   tables so you don't cut a relationship in half.
_allowlist_env = os.environ.get("TABLE_ALLOWLIST", "").strip()
TABLE_ALLOWLIST = [t.strip() for t in _allowlist_env.split(",") if t.strip()] if _allowlist_env else []
AUTO_EXPAND_FK_NEIGHBORS = os.environ.get("AUTO_EXPAND_FK_NEIGHBORS", "true").lower() != "false"
# ---------------------------------------------------


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def fetch_all(cur, query, params=None):
    cur.execute(query, params or ())
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def extract_columns(cur):
    query = """
        SELECT
            c.table_schema, c.table_name, c.column_name,
            c.data_type, c.is_nullable, c.column_default,
            col_description(
                (quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass::oid,
                c.ordinal_position
            ) AS column_comment
        FROM information_schema.columns c
        WHERE c.table_schema = ANY(%s)
        ORDER BY c.table_schema, c.table_name, c.ordinal_position;
    """
    return fetch_all(cur, query, (SCHEMAS_TO_INCLUDE,))


def extract_primary_keys(cur):
    query = """
        SELECT tc.table_schema, tc.table_name, kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'PRIMARY KEY'
            AND tc.table_schema = ANY(%s);
    """
    return fetch_all(cur, query, (SCHEMAS_TO_INCLUDE,))


def extract_foreign_keys(cur):
    query = """
        SELECT
            tc.table_schema AS fk_schema, tc.table_name AS fk_table, kcu.column_name AS fk_column,
            ccu.table_schema AS ref_schema, ccu.table_name AS ref_table, ccu.column_name AS ref_column
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = ANY(%s);
    """
    return fetch_all(cur, query, (SCHEMAS_TO_INCLUDE,))


def extract_table_comments(cur):
    query = """
        SELECT n.nspname AS table_schema, c.relname AS table_name, obj_description(c.oid) AS table_comment
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r' AND n.nspname = ANY(%s);
    """
    return fetch_all(cur, query, (SCHEMAS_TO_INCLUDE,))


def get_sample_values(cur, schema, table, limit=SAMPLE_ROWS_PER_TABLE):
    try:
        cur.execute(f'SELECT * FROM "{schema}"."{table}" LIMIT %s;', (limit,))
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        return {"columns": cols, "rows": [list(map(str, r)) for r in rows]}
    except Exception as e:
        return {"error": str(e)}


def build_table_dict(columns, pks, fks, comments):
    tables = defaultdict(lambda: {"columns": [], "primary_keys": [], "foreign_keys": [], "comment": None})

    for c in columns:
        key = f'{c["table_schema"]}.{c["table_name"]}'
        tables[key]["columns"].append({
            "name": c["column_name"],
            "type": c["data_type"],
            "nullable": c["is_nullable"],
            "default": c["column_default"],
            "comment": c["column_comment"],
        })

    for pk in pks:
        key = f'{pk["table_schema"]}.{pk["table_name"]}'
        tables[key]["primary_keys"].append(pk["column_name"])

    for fk in fks:
        key = f'{fk["fk_schema"]}.{fk["fk_table"]}'
        tables[key]["foreign_keys"].append({
            "column": fk["fk_column"],
            "references_table": f'{fk["ref_schema"]}.{fk["ref_table"]}',
            "references_column": fk["ref_column"],
        })

    for tc in comments:
        key = f'{tc["table_schema"]}.{tc["table_name"]}'
        if key in tables:
            tables[key]["comment"] = tc["table_comment"]

    return tables


def build_fk_graph(fks):
    """Adjacency list: table -> list of connected tables via FK, both directions."""
    graph = defaultdict(set)
    for fk in fks:
        src = f'{fk["fk_schema"]}.{fk["fk_table"]}'
        dst = f'{fk["ref_schema"]}.{fk["ref_table"]}'
        graph[src].add(dst)
        graph[dst].add(src)
    return {k: sorted(v) for k, v in graph.items()}


def draft_description(table_name, table_data):
    """
    Placeholder rule-based draft description.
    Replace with an LLM call for better first-pass descriptions,
    then have a human review before embedding.
    """
    col_names = ", ".join(c["name"] for c in table_data["columns"][:8])
    return f"Table '{table_name}' with columns including: {col_names}. (DRAFT - needs human review)"


def expand_allowlist_with_fk_neighbors(allowlist, fks):
    """Add tables directly FK-connected to the allowlist so we don't cut a join in half."""
    expanded = set(allowlist)
    for fk in fks:
        src = f'{fk["fk_schema"]}.{fk["fk_table"]}'
        dst = f'{fk["ref_schema"]}.{fk["ref_table"]}'
        if src in allowlist:
            expanded.add(dst)
        if dst in allowlist:
            expanded.add(src)
    return expanded


def filter_to_scope(columns, pks, fks, comments, scope):
    """Keep only rows belonging to tables in `scope` (a set of 'schema.table' strings)."""
    if not scope:
        return columns, pks, fks, comments

    columns = [c for c in columns if f'{c["table_schema"]}.{c["table_name"]}' in scope]
    pks = [p for p in pks if f'{p["table_schema"]}.{p["table_name"]}' in scope]
    fks = [
        f for f in fks
        if f'{f["fk_schema"]}.{f["fk_table"]}' in scope
        and f'{f["ref_schema"]}.{f["ref_table"]}' in scope
    ]
    comments = [c for c in comments if f'{c["table_schema"]}.{c["table_name"]}' in scope]
    return columns, pks, fks, comments


def main():
    conn = get_connection()
    cur = conn.cursor()

    print("Extracting columns...")
    columns = extract_columns(cur)
    print("Extracting primary keys...")
    pks = extract_primary_keys(cur)
    print("Extracting foreign keys...")
    fks = extract_foreign_keys(cur)
    print("Extracting table comments...")
    comments = extract_table_comments(cur)

    scope = set()
    if TABLE_ALLOWLIST:
        scope = set(TABLE_ALLOWLIST)
        if AUTO_EXPAND_FK_NEIGHBORS:
            scope = expand_allowlist_with_fk_neighbors(scope, fks)
        print(f"Scoping to {len(scope)} tables (allowlist + FK neighbors): {sorted(scope)}")
        columns, pks, fks, comments = filter_to_scope(columns, pks, fks, comments, scope)

    tables = build_table_dict(columns, pks, fks, comments)
    print(f"Found {len(tables)} tables.")

    print("Pulling sample values per table...")
    for key in tables:
        schema, table = key.split(".", 1)
        tables[key]["sample_values"] = get_sample_values(cur, schema, table)

    fk_graph = build_fk_graph(fks)

    schema_for_review = {}
    for key, data in tables.items():
        schema_for_review[key] = {
            "draft_description": data["comment"] or draft_description(key, data),
            "columns": [c["name"] for c in data["columns"]],
            "needs_review": True,
        }

    with open("schema_metadata.json", "w") as f:
        json.dump(tables, f, indent=2, default=str)

    with open("fk_graph.json", "w") as f:
        json.dump(fk_graph, f, indent=2)

    with open("schema_for_review.json", "w") as f:
        json.dump(schema_for_review, f, indent=2)

    cur.close()
    conn.close()

    print("Done. Wrote schema_metadata.json, fk_graph.json, schema_for_review.json")
    print("NEXT: human-review schema_for_review.json descriptions before embedding.")


if __name__ == "__main__":
    main()
