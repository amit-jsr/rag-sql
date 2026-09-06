import asyncpg


class ExplainError(Exception):
    pass


async def explain_dry_run(conn: asyncpg.Connection, sql: str) -> str:
    """Runs EXPLAIN (no ANALYZE — no side effects, no actual execution) to catch
    reference/syntax errors cheaply before spending an execution attempt."""
    try:
        rows = await conn.fetch(f"EXPLAIN {sql}")
    except asyncpg.PostgresError as e:
        raise ExplainError(str(e)) from e
    return "\n".join(r["QUERY PLAN"] for r in rows)
