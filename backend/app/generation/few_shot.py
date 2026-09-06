import asyncpg

from app.llm.openai_embeddings import OpenAIEmbeddingClient


async def get_few_shot_examples(
    conn: asyncpg.Connection, embedder: OpenAIEmbeddingClient, question: str, top_k: int = 3
) -> list[dict]:
    """Top-k most similar *verified* prior questions from golden_queries, used as
    few-shot examples in the generation prompt (IMPLEMENTATION_GUIDE.md Phase 4)."""
    query_embedding = embedder.embed_one(question)
    rows = await conn.fetch(
        """
        SELECT question, sql_query, tables_used
        FROM golden_queries
        WHERE verified = true
        ORDER BY embedding <=> $1
        LIMIT $2;
        """,
        query_embedding,
        top_k,
    )
    return [{"question": r["question"], "sql": r["sql_query"]} for r in rows]
