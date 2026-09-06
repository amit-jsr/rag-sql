from app.llm.anthropic_client import AnthropicClient

SYSTEM_PROMPT = """You are a SQL repair assistant for a Postgres insurance \
database. You are given a SQL query that failed (either at EXPLAIN time or at \
execution time) along with the database error message. Fix the SQL so it runs \
correctly, using ONLY the tables/columns already present in the original query \
or the allowed-tables list provided — do not introduce a new table.

Output ONLY the corrected SQL statement, no markdown fences, no explanation."""


def repair_sql(
    client: AnthropicClient,
    question: str,
    failed_sql: str,
    error_message: str,
    allowed_tables: set[str],
) -> str:
    user_message = (
        f"Question: {question}\n\n"
        f"Failed SQL:\n{failed_sql}\n\n"
        f"Database error:\n{error_message}\n\n"
        f"Allowed tables: {', '.join(sorted(allowed_tables))}"
    )
    raw = client.complete(system=SYSTEM_PROMPT, user_message=user_message, effort="medium")
    return raw.strip().removeprefix("```sql").removeprefix("```").removesuffix("```").strip()
