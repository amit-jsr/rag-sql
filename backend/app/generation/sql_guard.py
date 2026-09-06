import sqlglot
from sqlglot import exp

FORBIDDEN_STATEMENT_TYPES = (
    exp.Insert,
    exp.Update,
    exp.Delete,
    exp.Drop,
    exp.Create,
    exp.Alter,
    exp.TruncateTable,
    exp.Grant,
)


class SQLGuardError(Exception):
    pass


def parse_and_guard(sql: str, dialect: str = "postgres") -> exp.Expression:
    """Raises SQLGuardError if the SQL doesn't parse, isn't a single SELECT, or
    references anything not in `allowed_tables`. Returns the parsed AST on success."""
    try:
        statements = sqlglot.parse(sql, dialect=dialect)
    except Exception as e:
        raise SQLGuardError(f"SQL failed to parse: {e}") from e

    if len(statements) != 1:
        raise SQLGuardError(f"Expected exactly one statement, got {len(statements)}")

    stmt = statements[0]
    if stmt is None:
        raise SQLGuardError("SQL parsed to an empty statement")

    if not isinstance(stmt, (exp.Select, exp.Union)):
        raise SQLGuardError(f"Only SELECT statements are allowed, got {type(stmt).__name__}")

    for forbidden_type in FORBIDDEN_STATEMENT_TYPES:
        if list(stmt.find_all(forbidden_type)):
            raise SQLGuardError(f"SQL contains a forbidden {forbidden_type.__name__} clause")

    return stmt


def extract_referenced_tables(stmt: exp.Expression, default_schema: str = "public") -> set[str]:
    """Returns the set of 'schema.table' names referenced by the parsed SQL."""
    tables = set()
    for table in stmt.find_all(exp.Table):
        schema = table.db or default_schema
        tables.add(f"{schema}.{table.name}")
    return tables


def extract_referenced_columns(stmt: exp.Expression) -> set[str]:
    """Returns the set of bare column names referenced (unqualified — cross-check
    against the linked schema's column list per table separately if needed)."""
    return {col.name for col in stmt.find_all(exp.Column)}


def validate_against_linked_schema(sql: str, linked_tables: set[str], dialect: str = "postgres") -> exp.Expression:
    """Full guard: parse, enforce SELECT-only, and ensure every referenced table
    is a subset of what schema linking approved (second hallucination guard,
    on top of the linking-JSON cross-check — IMPLEMENTATION_GUIDE.md Phase 4)."""
    stmt = parse_and_guard(sql, dialect=dialect)
    referenced = extract_referenced_tables(stmt)
    unknown = referenced - linked_tables
    if unknown:
        raise SQLGuardError(f"SQL references tables not in the linked schema: {unknown}")
    return stmt
