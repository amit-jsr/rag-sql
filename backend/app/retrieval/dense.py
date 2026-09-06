import asyncpg

from app.linking.schemas import RetrievedTable


async def dense_search(conn: asyncpg.Connection, query_embedding: list[float], top_k: int) -> list[RetrievedTable]:
    """Cosine-similarity search over schema_embeddings. embedding <=> is cosine
    *distance* (hnsw vector_cosine_ops index) — convert to a similarity score."""
    rows = await conn.fetch(
        """
        SELECT table_schema, table_name, description, columns_json, domain_cluster,
               1 - (embedding <=> $1) AS score
        FROM schema_embeddings
        ORDER BY embedding <=> $1
        LIMIT $2;
        """,
        query_embedding,
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
