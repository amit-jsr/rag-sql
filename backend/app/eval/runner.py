import json

from pydantic import BaseModel

from app.eval.scoring import EvalCaseResult, EvalMetrics, aggregate_metrics, score_case
from app.execution.executor import ExecutionError, execute_readonly
from app.graph.nodes import GraphDeps
from app.graph.build_graph import build_graph


class EvalRunResult(BaseModel):
    run_id: str
    metrics: EvalMetrics
    cases: list[EvalCaseResult]


async def _run_gold_sql(deps: GraphDeps, gold_sql: str) -> tuple[list[str], list[list]]:
    async with deps.db_pool.acquire() as conn:
        return await execute_readonly(
            conn, gold_sql, deps.settings.execution_row_limit, deps.settings.execution_statement_timeout_ms
        )


async def run_eval(eval_file_path: str, deps: GraphDeps, run_id: str) -> EvalRunResult:
    """Shared by both the CLI (scripts/run_eval_cli.py) and the FastAPI evals
    router — no duplicated scoring logic between the two entrypoints."""
    with open(eval_file_path) as f:
        eval_cases = json.load(f)

    compiled_graph = build_graph(deps)
    results: list[EvalCaseResult] = []

    for case in eval_cases:
        case_id = case["id"]
        question = case["question"]
        gold_sql = case["gold_sql"]
        gold_tables = case["gold_tables"]

        try:
            gold_columns, gold_rows = await _run_gold_sql(deps, gold_sql)
        except ExecutionError as e:
            gold_columns, gold_rows = [], []
            print(f"WARNING: gold_sql failed for case {case_id}: {e}")

        final_state = await compiled_graph.ainvoke({"question": question, "retry_count": 0, "repair_trace": []})

        linked = final_state.get("linked")
        linked_tables = [t.table for t in linked.tables] if linked else []
        generated_sql = final_state.get("sql")
        error = final_state.get("error")
        generated_columns = final_state.get("columns", [])
        generated_rows = final_state.get("rows", [])

        results.append(
            score_case(
                case_id=case_id,
                question=question,
                difficulty=case.get("difficulty", "unknown"),
                question_type=case.get("question_type", "unknown"),
                domain_cluster=case.get("domain_cluster"),
                gold_sql=gold_sql,
                gold_tables=gold_tables,
                generated_sql=generated_sql,
                linked_tables=linked_tables,
                retry_count=final_state.get("retry_count", 0),
                error=error,
                gold_columns=gold_columns,
                gold_rows=gold_rows,
                generated_columns=generated_columns,
                generated_rows=generated_rows,
            )
        )

    metrics = aggregate_metrics(results)
    return EvalRunResult(run_id=run_id, metrics=metrics, cases=results)
