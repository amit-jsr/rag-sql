"""
Seeds the golden_queries few-shot bank (IMPLEMENTATION_GUIDE.md Phase 4: "retrieve
top-3 similar verified questions ... include as examples in the generation
prompt"). Each entry here has been hand-verified against the synthetic schema.

Run from backend/: python -m scripts.load_golden_queries
"""

import psycopg2
from pgvector.psycopg2 import register_vector

from app.config import get_settings
from app.llm.openai_embeddings import OpenAIEmbeddingClient

GOLDEN_QUERIES = [
    {
        "question": "Which policies have lapsed?",
        "sql": "SELECT policy_number, status FROM public.policy WHERE status = 'lapsed';",
        "tables_used": ["public.policy"],
        "domain_cluster": "policy",
    },
    {
        "question": "Show all open claims and the policy they were filed against.",
        "sql": (
            "SELECT c.claim_number, c.status, c.claim_amount, p.policy_number "
            "FROM public.claim c JOIN public.policy p ON c.policy_id = p.policy_id "
            "WHERE c.status = 'open';"
        ),
        "tables_used": ["public.claim", "public.policy"],
        "domain_cluster": "claims",
    },
    {
        "question": "Which agent has written the most policies?",
        "sql": (
            "SELECT a.first_name, a.last_name, COUNT(p.policy_id) AS policy_count "
            "FROM public.agent a JOIN public.policy p ON p.agent_id = a.agent_id "
            "GROUP BY a.agent_id, a.first_name, a.last_name "
            "ORDER BY policy_count DESC LIMIT 1;"
        ),
        "tables_used": ["public.agent", "public.policy"],
        "domain_cluster": "agent",
    },
    {
        "question": "What is the total paid amount across all closed claims?",
        "sql": "SELECT SUM(paid_amount) FROM public.claim WHERE status = 'closed';",
        "tables_used": ["public.claim"],
        "domain_cluster": "claims",
    },
    {
        "question": "List customers who have a missed premium payment.",
        "sql": (
            "SELECT DISTINCT cu.first_name, cu.last_name, cu.email "
            "FROM public.customer cu "
            "JOIN public.policy_holder ph ON ph.customer_id = cu.customer_id "
            "JOIN public.policy p ON p.policy_holder_id = ph.policy_holder_id "
            "JOIN public.premium_payment pp ON pp.policy_id = p.policy_id "
            "WHERE pp.status = 'missed';"
        ),
        "tables_used": ["public.customer", "public.policy_holder", "public.policy", "public.premium_payment"],
        "domain_cluster": "finance",
    },
    {
        "question": "How many Auto policies are currently active?",
        "sql": (
            "SELECT COUNT(*) FROM public.policy p "
            "JOIN public.policy_type pt ON p.policy_type_id = pt.policy_type_id "
            "WHERE pt.name = 'Auto' AND p.status = 'active';"
        ),
        "tables_used": ["public.policy", "public.policy_type"],
        "domain_cluster": "policy",
    },
]


def main():
    settings = get_settings()
    if not settings.openai_api_key:
        raise SystemExit("OPENAI_API_KEY is not set in backend/.env — cannot embed.")

    embedder = OpenAIEmbeddingClient(settings)
    conn = psycopg2.connect(
        host=settings.db_host, port=settings.db_port, dbname=settings.db_name,
        user=settings.db_user, password=settings.db_password,
    )
    register_vector(conn)
    cur = conn.cursor()

    questions = [gq["question"] for gq in GOLDEN_QUERIES]
    embeddings = embedder.embed(questions)

    for gq, embedding in zip(GOLDEN_QUERIES, embeddings):
        cur.execute(
            """
            INSERT INTO golden_queries (question, sql_query, tables_used, domain_cluster, verified, embedding)
            VALUES (%s, %s, %s, %s, true, %s);
            """,
            (gq["question"], gq["sql"], gq["tables_used"], gq["domain_cluster"], embedding),
        )

    conn.commit()
    cur.close()
    conn.close()
    print(f"Inserted {len(GOLDEN_QUERIES)} golden queries.")


if __name__ == "__main__":
    main()
