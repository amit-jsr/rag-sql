from app.linking.schemas import LinkedSchema
from app.llm.anthropic_client import AnthropicClient

SYSTEM_PROMPT = """You are a SQL generation assistant for a Postgres insurance \
database. You are given a linked-schema JSON (the exact tables, columns, joins, \
and filters approved by the schema-linking step) and must generate a single \
Postgres SELECT statement that implements it.

Rules:
- Generate SQL only from the tables/columns/joins/filters in the linked schema — \
do not reference anything else.
- Output ONLY the SQL statement, no markdown fences, no explanation.
- Use explicit JOIN ... ON syntax, not comma joins.
- Prefer readable aliases matching the table name's first letters."""


def _format_few_shot(examples: list[dict]) -> str:
    if not examples:
        return ""
    blocks = [f"Q: {ex['question']}\nSQL: {ex['sql']}" for ex in examples]
    return "\n\nSimilar verified examples:\n" + "\n\n".join(blocks)


def _format_history(history: list[dict] | None) -> str:
    """The linked schema already fully resolves any follow-up reference, so this
    is purely a style hint — e.g. so "same but for claims" reuses the previous
    query's alias/structure conventions rather than generating something unrelated
    in shape."""
    prior_sql_turns = [turn for turn in (history or []) if turn.get("sql")]
    if not prior_sql_turns:
        return ""
    last = prior_sql_turns[-1]
    return f"\n\nMost recent prior query in this conversation (for style/structure reference only):\nQ: {last['question']}\nSQL: {last['sql']}"


def generate_sql(
    client: AnthropicClient,
    question: str,
    linked: LinkedSchema,
    few_shot_examples: list[dict] | None = None,
    history: list[dict] | None = None,
) -> str:
    user_message = (
        f"Question: {question}\n\n"
        f"Linked schema JSON:\n{linked.model_dump_json(indent=2)}"
        f"{_format_few_shot(few_shot_examples or [])}"
        f"{_format_history(history)}"
    )
    raw = client.complete(system=SYSTEM_PROMPT, user_message=user_message, effort="medium")
    return raw.strip().removeprefix("```sql").removeprefix("```").removesuffix("```").strip()
