import json

from app.linking.schemas import LinkedSchema, RetrievedTable
from app.llm.anthropic_client import AnthropicClient

SYSTEM_PROMPT = """You are a schema-linking assistant for a Text2SQL system over a \
Postgres insurance database. Given a natural-language question and a list of \
candidate tables (with their columns), decide exactly which tables, columns, \
joins, and filters are needed to answer the question.

If prior turns from this conversation are provided, use them only to resolve \
references in the current question (e.g. "that", "the same but for claims", \
"last month" referring to a filter mentioned earlier) — the linked JSON must still \
describe a complete, standalone query for the CURRENT question, not a diff against \
the previous one.

Rules:
- Only reference tables and columns that appear in the provided candidate list. \
Never invent a table or column name.
- If the question cannot be answered from the candidate tables (out of scope, or \
ambiguous with no reasonable resolution — including an unresolvable follow-up \
reference), set out_of_scope=true and explain why in out_of_scope_reason instead \
of guessing.
- Respond with ONLY a JSON object matching this shape, no other text:
{
  "tables": [{"table": "schema.table", "reason": "..."}],
  "columns": [{"table": "schema.table", "column": "col_name"}],
  "joins": [{"left_table": "schema.a", "left_column": "x", "right_table": "schema.b", "right_column": "y"}],
  "filters": [{"table": "schema.a", "column": "col", "op": "=", "value": "..."}],
  "aggregation": "COUNT" or null,
  "out_of_scope": false,
  "out_of_scope_reason": null
}"""


class SchemaLinkingError(Exception):
    pass


def _format_candidates(tables: list[RetrievedTable]) -> str:
    parts = []
    for t in tables:
        col_names = [c["name"] for c in t.columns_json] if t.columns_json else []
        parts.append(f"- {t.full_name}: {t.description} | columns: {', '.join(col_names)}")
    return "\n".join(parts)


def _format_history(history: list[dict] | None) -> str:
    if not history:
        return ""
    lines = [f"{i + 1}. {turn['question']}" for i, turn in enumerate(history)]
    return "\n\nPrior turns in this conversation (most recent last):\n" + "\n".join(lines)


def _validate_subset(linked: LinkedSchema, retrieved: list[RetrievedTable]) -> None:
    """Reject/re-prompt trigger: every referenced table/column must be in the
    retrieved candidate set — catches hallucination before generation ever runs."""
    if linked.out_of_scope:
        return
    valid_tables = {t.full_name for t in retrieved}
    valid_columns: dict[str, set[str]] = {
        t.full_name: {c["name"] for c in t.columns_json} for t in retrieved
    }

    for ref in linked.tables:
        if ref.table not in valid_tables:
            raise SchemaLinkingError(f"Linked table '{ref.table}' not in retrieved candidates")
    for col in linked.columns:
        if col.table not in valid_tables:
            raise SchemaLinkingError(f"Linked column references unknown table '{col.table}'")
        if col.column not in valid_columns.get(col.table, set()):
            raise SchemaLinkingError(f"Linked column '{col.table}.{col.column}' not in retrieved schema")


def link_schema(
    client: AnthropicClient,
    question: str,
    retrieved: list[RetrievedTable],
    max_attempts: int = 2,
    history: list[dict] | None = None,
) -> LinkedSchema:
    """Calls Claude to produce the linked-schema JSON, validates it against the
    retrieved candidate set, and re-prompts once with the validation error if it
    hallucinated a table/column (IMPLEMENTATION_GUIDE.md Phase 4). `history` is the
    last few turns of this conversation, used only to resolve follow-up references."""
    user_message = (
        f"Question: {question}\n\nCandidate tables:\n{_format_candidates(retrieved)}"
        f"{_format_history(history)}"
    )
    last_error: Exception | None = None

    for attempt in range(max_attempts):
        if last_error is not None:
            user_message += f"\n\nYour previous answer was invalid: {last_error}. Try again, using ONLY the candidate tables/columns listed above."

        raw = client.complete(system=SYSTEM_PROMPT, user_message=user_message, effort="medium")
        try:
            data = json.loads(raw)
            linked = LinkedSchema.model_validate(data)
            _validate_subset(linked, retrieved)
            return linked
        except Exception as e:  # noqa: BLE001 - broad: JSON/validation/subset errors all trigger retry
            last_error = e

    raise SchemaLinkingError(f"Schema linking failed after {max_attempts} attempts: {last_error}")
