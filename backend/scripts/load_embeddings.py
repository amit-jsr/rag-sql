"""
Phase 2: load reviewed schema metadata into the pgvector retrieval tables.

Reads (from backend/scripts/schema_extraction/, produced by 02_build_schema_index.py
and the human review pass):
  - schema_metadata.json   -> full column/PK/FK/sample-value inventory
  - schema_for_review.json -> human-reviewed description + domain_cluster per table
  - fk_graph.json          -> adjacency list, loaded into schema_relationships

Writes: schema_embeddings, column_embeddings, schema_relationships
(embeds "description + column names + sample values" per table via OpenAI
text-embedding-3-small; also embeds each column individually).

Run from backend/: python -m scripts.load_embeddings
"""

import json
from pathlib import Path

import psycopg2
from pgvector.psycopg2 import register_vector

from app.config import get_settings
from app.llm.openai_embeddings import OpenAIEmbeddingClient

EXTRACTION_DIR = Path(__file__).parent / "schema_extraction"


def load_json(name: str) -> dict:
    with open(EXTRACTION_DIR / name) as f:
        return json.load(f)


def build_table_embedding_text(full_name: str, review: dict, meta: dict) -> str:
    col_names = ", ".join(review["columns"])
    sample = meta.get("sample_values", {})
    sample_cols = sample.get("columns", [])
    sample_rows = sample.get("rows", [])[:2]
    sample_text = ""
    if sample_cols and sample_rows:
        sample_text = " Sample rows: " + "; ".join(
            ", ".join(f"{c}={v}" for c, v in zip(sample_cols, row)) for row in sample_rows
        )
    return f"Table {full_name}: {review['draft_description']} Columns: {col_names}.{sample_text}"


def build_column_embedding_text(table_name: str, column: dict) -> str:
    comment = f" — {column['comment']}" if column.get("comment") else ""
    return f"Column {table_name}.{column['name']} ({column['type']}){comment}"


def main():
    settings = get_settings()
    if not settings.openai_api_key:
        raise SystemExit("OPENAI_API_KEY is not set in backend/.env — cannot embed.")

    schema_metadata = load_json("schema_metadata.json")
    schema_for_review = load_json("schema_for_review.json")
    fk_graph = load_json("fk_graph.json")

    embedder = OpenAIEmbeddingClient(settings)

    conn = psycopg2.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname=settings.db_name,
        user=settings.db_user,
        password=settings.db_password,
    )
    register_vector(conn)
    cur = conn.cursor()

    print(f"Embedding {len(schema_for_review)} tables...")
    table_texts = []
    table_rows = []
    for full_name, review in schema_for_review.items():
        if review.get("needs_review"):
            print(f"  SKIP {full_name}: still needs_review=true")
            continue
        schema, table = full_name.split(".", 1)
        meta = schema_metadata[full_name]
        table_texts.append(build_table_embedding_text(full_name, review, meta))
        table_rows.append((schema, table, review, meta))

    table_embeddings = embedder.embed(table_texts)

    for (schema, table, review, meta), embedding in zip(table_rows, table_embeddings):
        cur.execute(
            """
            INSERT INTO schema_embeddings
                (table_schema, table_name, description, columns_json, sample_values_json,
                 domain_cluster, embedding)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (table_schema, table_name) DO UPDATE SET
                description = EXCLUDED.description,
                columns_json = EXCLUDED.columns_json,
                sample_values_json = EXCLUDED.sample_values_json,
                domain_cluster = EXCLUDED.domain_cluster,
                embedding = EXCLUDED.embedding,
                updated_at = now();
            """,
            (
                schema,
                table,
                review["draft_description"],
                json.dumps(meta["columns"]),
                json.dumps(meta.get("sample_values", {})),
                review.get("domain_cluster"),
                embedding,
            ),
        )
    print(f"  Inserted/updated {len(table_rows)} rows in schema_embeddings.")

    print("Embedding columns...")
    col_texts = []
    col_rows = []
    for full_name, review in schema_for_review.items():
        if review.get("needs_review"):
            continue
        schema, table = full_name.split(".", 1)
        meta = schema_metadata[full_name]
        for column in meta["columns"]:
            col_texts.append(build_column_embedding_text(table, column))
            col_rows.append((schema, table, column))

    # Batch to stay well under the embeddings API's per-request input limits.
    BATCH = 100
    col_embeddings: list[list[float]] = []
    for i in range(0, len(col_texts), BATCH):
        col_embeddings.extend(embedder.embed(col_texts[i : i + BATCH]))

    for (schema, table, column), embedding in zip(col_rows, col_embeddings):
        cur.execute(
            """
            INSERT INTO column_embeddings
                (table_schema, table_name, column_name, data_type, description, embedding)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (table_schema, table_name, column_name) DO UPDATE SET
                data_type = EXCLUDED.data_type,
                description = EXCLUDED.description,
                embedding = EXCLUDED.embedding;
            """,
            (schema, table, column["name"], column["type"], column.get("comment"), embedding),
        )
    print(f"  Inserted/updated {len(col_rows)} rows in column_embeddings.")

    print("Loading FK graph into schema_relationships...")
    cur.execute("DELETE FROM schema_relationships;")
    fk_count = 0
    for full_name, review in schema_for_review.items():
        if review.get("needs_review"):
            continue
        meta = schema_metadata[full_name]
        for fk in meta.get("foreign_keys", []):
            cur.execute(
                """
                INSERT INTO schema_relationships
                    (fk_table, fk_column, referenced_table, referenced_column)
                VALUES (%s, %s, %s, %s);
                """,
                (full_name, fk["column"], fk["references_table"], fk["references_column"]),
            )
            fk_count += 1
    print(f"  Inserted {fk_count} rows in schema_relationships (from schema_metadata FKs).")

    conn.commit()
    cur.close()
    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
