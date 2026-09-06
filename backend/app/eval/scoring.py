from pydantic import BaseModel

from app.eval.result_compare import result_sets_match


class EvalCaseResult(BaseModel):
    case_id: str
    question: str
    difficulty: str
    question_type: str
    domain_cluster: str | None = None
    gold_sql: str
    generated_sql: str | None = None
    gold_tables: list[str]
    linked_tables: list[str] = []
    valid_sql: bool
    execution_match: bool
    retry_count: int = 0
    error: str | None = None
    gold_columns: list[str] = []
    gold_rows: list[list] = []
    generated_columns: list[str] = []
    generated_rows: list[list] = []


class EvalMetrics(BaseModel):
    schema_linking_precision: float
    schema_linking_recall: float
    execution_accuracy: float
    valid_sql_rate: float
    repair_loop_usage_rate: float
    total_cases: int


def score_case(
    case_id: str,
    question: str,
    difficulty: str,
    question_type: str,
    domain_cluster: str | None,
    gold_sql: str,
    gold_tables: list[str],
    generated_sql: str | None,
    linked_tables: list[str],
    retry_count: int,
    error: str | None,
    gold_columns: list[str],
    gold_rows: list[list],
    generated_columns: list[str],
    generated_rows: list[list],
) -> EvalCaseResult:
    valid_sql = generated_sql is not None and error is None
    execution_match = valid_sql and result_sets_match(gold_rows, generated_rows)

    return EvalCaseResult(
        case_id=case_id,
        question=question,
        difficulty=difficulty,
        question_type=question_type,
        domain_cluster=domain_cluster,
        gold_sql=gold_sql,
        generated_sql=generated_sql,
        gold_tables=gold_tables,
        linked_tables=linked_tables,
        valid_sql=valid_sql,
        execution_match=execution_match,
        retry_count=retry_count,
        error=error,
        gold_columns=gold_columns,
        gold_rows=gold_rows,
        generated_columns=generated_columns,
        generated_rows=generated_rows,
    )


def _linking_precision_recall(case: EvalCaseResult) -> tuple[float, float]:
    linked = set(case.linked_tables)
    gold = set(case.gold_tables)
    if not linked and not gold:
        return 1.0, 1.0
    if not linked:
        return 0.0, 0.0
    if not gold:
        return 0.0, 1.0
    precision = len(linked & gold) / len(linked)
    recall = len(linked & gold) / len(gold)
    return precision, recall


def aggregate_metrics(cases: list[EvalCaseResult]) -> EvalMetrics:
    """Tracks the 4 metrics separately per IMPLEMENTATION_GUIDE.md Phase 6.4 —
    deliberately not collapsed into one "accuracy" number."""
    if not cases:
        return EvalMetrics(
            schema_linking_precision=0.0,
            schema_linking_recall=0.0,
            execution_accuracy=0.0,
            valid_sql_rate=0.0,
            repair_loop_usage_rate=0.0,
            total_cases=0,
        )

    precisions, recalls = zip(*(_linking_precision_recall(c) for c in cases))

    return EvalMetrics(
        schema_linking_precision=sum(precisions) / len(cases),
        schema_linking_recall=sum(recalls) / len(cases),
        execution_accuracy=sum(1 for c in cases if c.execution_match) / len(cases),
        valid_sql_rate=sum(1 for c in cases if c.valid_sql) / len(cases),
        repair_loop_usage_rate=sum(1 for c in cases if c.retry_count > 0) / len(cases),
        total_cases=len(cases),
    )
