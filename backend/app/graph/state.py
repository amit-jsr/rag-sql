import operator
from typing import Annotated, TypedDict

from app.linking.schemas import LinkedSchema, RetrievedTable


class RepairAttempt(TypedDict):
    attempt: int
    failed_sql: str
    error: str
    fixed_sql: str


class ConversationTurn(TypedDict):
    question: str
    sql: str | None


class GraphState(TypedDict, total=False):
    question: str
    history: list[ConversationTurn]
    retrieved: list[RetrievedTable]
    linked: LinkedSchema
    out_of_scope: bool
    out_of_scope_reason: str | None
    sql: str
    error: str | None
    columns: list[str]
    rows: list[list]
    retry_count: int
    repair_trace: Annotated[list[RepairAttempt], operator.add]
