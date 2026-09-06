import json
import time
import uuid
from pathlib import Path

from app.graph.state import GraphState

RUN_LOG_DIR = Path(__file__).parent.parent.parent / "run_logs"


def log_run(state: GraphState) -> str:
    """Persists the full run trace (question, retrieved tables, linked JSON, SQL,
    result, retry count) as required by IMPLEMENTATION_GUIDE.md Phase 5 — this is
    the debugging/eval data source going forward."""
    RUN_LOG_DIR.mkdir(exist_ok=True)
    run_id = str(uuid.uuid4())

    linked = state.get("linked")
    rows = state.get("rows", [])
    record = {
        "run_id": run_id,
        "timestamp": time.time(),
        "question": state.get("question"),
        "retrieved_tables": [
            {
                "table": t.full_name,
                "description": t.description,
                "domain_cluster": t.domain_cluster,
                "score": t.score,
            }
            for t in state.get("retrieved", [])
        ],
        "linked_schema": linked.model_dump() if linked else None,
        "out_of_scope": state.get("out_of_scope", False),
        "out_of_scope_reason": state.get("out_of_scope_reason"),
        "sql": state.get("sql"),
        "error": state.get("error"),
        "columns": state.get("columns", []),
        "rows": rows,
        "row_count": len(rows),
        "retry_count": state.get("retry_count", 0),
        "repair_trace": state.get("repair_trace", []),
    }
    with open(RUN_LOG_DIR / f"{run_id}.json", "w") as f:
        json.dump(record, f, indent=2, default=str)
    return run_id
