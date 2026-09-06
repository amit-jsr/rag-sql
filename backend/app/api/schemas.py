from pydantic import BaseModel

from app.eval.scoring import EvalCaseResult, EvalMetrics


class RepairTraceEntry(BaseModel):
    attempt: int
    failed_sql: str
    error: str
    fixed_sql: str


class RetrievedTableOut(BaseModel):
    table: str
    description: str
    domain_cluster: str | None
    score: float


class ConversationTurn(BaseModel):
    question: str
    sql: str | None = None


class AskRequest(BaseModel):
    question: str
    history: list[ConversationTurn] = []


class RunResultFields(BaseModel):
    out_of_scope: bool
    out_of_scope_reason: str | None = None
    retrieved_tables: list[RetrievedTableOut]
    linked_schema: dict | None
    sql: str | None
    error: str | None
    columns: list[str]
    rows: list[list]
    retry_count: int
    repair_trace: list[RepairTraceEntry]


class AskResponse(RunResultFields):
    question: str
    run_id: str


class HistorySummary(BaseModel):
    run_id: str
    timestamp: float
    question: str
    out_of_scope: bool
    sql: str | None
    error: str | None
    row_count: int
    retry_count: int


class HistoryDetailResponse(RunResultFields):
    question: str
    run_id: str
    timestamp: float


class EvalRunRequest(BaseModel):
    eval_file: str = "seed/eval_seed/eval_questions.json"


class EvalRunResponse(BaseModel):
    run_id: str
    metrics: EvalMetrics
    cases: list[EvalCaseResult]
