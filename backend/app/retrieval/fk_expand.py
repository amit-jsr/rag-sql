import asyncpg

from app.linking.schemas import RetrievedTable


async def expand_with_fk_neighbors(
    conn: asyncpg.Connection, tables: list[RetrievedTable]
) -> list[RetrievedTable]:
    """Add 1-hop FK-connected tables so join paths are present even if the
    neighbor wasn't directly retrieved (IMPLEMENTATION_GUIDE.md Phase 3, step 5)."""
    if not tables:
        return tables

    present = {t.full_name for t in tables}
    names = list(present)

    rows = await conn.fetch(
        """
        SELECT DISTINCT referenced_table AS neighbor FROM schema_relationships WHERE fk_table = ANY($1)
        UNION
        SELECT DISTINCT fk_table AS neighbor FROM schema_relationships WHERE referenced_table = ANY($1);
        """,
        names,
    )
    neighbor_names = [r["neighbor"] for r in rows if r["neighbor"] not in present]
    if not neighbor_names:
        return tables

    neighbor_rows = await conn.fetch(
        """
        SELECT table_schema, table_name, description, columns_json, domain_cluster
        FROM schema_embeddings
        WHERE (table_schema || '.' || table_name) = ANY($1);
        """,
        neighbor_names,
    )
    expanded = list(tables)
    for r in neighbor_rows:
        expanded.append(
            RetrievedTable(
                table_schema=r["table_schema"],
                table_name=r["table_name"],
                description=r["description"],
                columns_json=r["columns_json"],
                domain_cluster=r["domain_cluster"],
                score=0.0,  # added via FK expansion, not ranked by retrieval
            )
        )
    return expanded
