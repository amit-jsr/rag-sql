"""
Phase 7: business glossary — maps ambiguous business terms to concrete
table/column mappings, checked at retrieval/linking time alongside schema
embeddings. Seeded here with the terms this synthetic dataset was built to test
(see seed/README.md "Deliberate test cases").

Run from backend/: python -m scripts.load_glossary
"""

import psycopg2
from pgvector.psycopg2 import register_vector

from app.config import get_settings
from app.llm.openai_embeddings import OpenAIEmbeddingClient

GLOSSARY_TERMS = [
    {
        "term": "lapsed policy",
        "maps_to_table": "public.policy",
        "maps_to_column": "status",
        "definition": "A policy where status = 'lapsed' — premium went unpaid past the grace period. Not the same as 'cancelled' (customer/company terminated it) or 'expired' (term ended, not renewed).",
    },
    {
        "term": "written premium",
        "maps_to_table": "public.premium_payment",
        "maps_to_column": "amount",
        "definition": "The scheduled premium payment amount for a policy; annual_premium on public.policy is the yearly total.",
    },
    {
        "term": "churn",
        "maps_to_table": "public.policy",
        "maps_to_column": "status",
        "definition": "A policy moving to status IN ('lapsed', 'cancelled') — i.e. no longer active, whether from non-payment or voluntary cancellation.",
    },
    {
        "term": "open claim",
        "maps_to_table": "public.claim",
        "maps_to_column": "status",
        "definition": "A claim with status IN ('open', 'under_review') — not yet resolved (approved/denied/closed).",
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

    terms = [g["term"] for g in GLOSSARY_TERMS]
    embeddings = embedder.embed(terms)

    for g, embedding in zip(GLOSSARY_TERMS, embeddings):
        cur.execute(
            """
            INSERT INTO business_glossary (term, maps_to_table, maps_to_column, definition, embedding)
            VALUES (%s, %s, %s, %s, %s);
            """,
            (g["term"], g["maps_to_table"], g["maps_to_column"], g["definition"], embedding),
        )

    conn.commit()
    cur.close()
    conn.close()
    print(f"Inserted {len(GLOSSARY_TERMS)} glossary terms.")


if __name__ == "__main__":
    main()
