import asyncpg


class ExecutionError(Exception):
    pass


async def execute_readonly(
    conn: asyncpg.Connection, sql: str, row_limit: int, statement_timeout_ms: int
) -> tuple[list[str], list[list]]:
    """Executes generated SQL read-only, bounded by row_limit and a statement
    timeout. Wraps the query as a subquery so the row limit applies regardless of
    whether the generated SQL already has its own LIMIT/ORDER BY."""
    bounded_sql = f"SELECT * FROM ({sql.rstrip(';')}) AS _bounded LIMIT {row_limit}"

    async with conn.transaction(readonly=True):
        try:
            await conn.execute(f"SET LOCAL statement_timeout = {statement_timeout_ms}")
            rows = await conn.fetch(bounded_sql)
        except asyncpg.PostgresError as e:
            raise ExecutionError(str(e)) from e

    columns = list(rows[0].keys()) if rows else []
    values = [list(r.values()) for r in rows]
    return columns, values
