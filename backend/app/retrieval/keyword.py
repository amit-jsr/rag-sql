import asyncpg

from app.linking.schemas import RetrievedTable


async def keyword_search(conn: asyncpg.Connection, question: str, top_k: int) -> list[RetrievedTable]:
    """Keyword retrieval combining Postgres full-text search (ts_rank_cd over the
    description) with pg_trgm similarity on the table name — catches exact-match
    identifier terms dense/semantic search can miss (see IMPLEMENTATION_GUIDE.md
    Phase 3). Both run in one query so there's no separate index to keep in sync
    with schema_embeddings on every reload."""
    rows = await conn.fetch(
        """
        SELECT table_schema, table_name, description, columns_json, domain_cluster,
               GREATEST(
                   ts_rank_cd(to_tsvector('english', description), plainto_tsquery('english', $1)),
                   similarity(full_table_name, $1)
               ) AS score
        FROM schema_embeddings
        WHERE to_tsvector('english', description) @@ plainto_tsquery('english', $1)
           OR similarity(full_table_name, $1) > 0.1
        ORDER BY score DESC
        LIMIT $2;
        """,
        question,
        top_k,
    )
    return [
        RetrievedTable(
            table_schema=r["table_schema"],
            table_name=r["table_name"],
            description=r["description"],
            columns_json=r["columns_json"],
            domain_cluster=r["domain_cluster"],
            score=float(r["score"]),
        )
        for r in rows
    ]
