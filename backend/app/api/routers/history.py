import json
from pathlib import Path

from fastapi import APIRouter, HTTPException

from app.api.schemas import HistoryDetailResponse, HistorySummary, RetrievedTableOut

router = APIRouter(prefix="/api/history", tags=["history"])

RUN_LOG_DIR = Path(__file__).parents[3] / "run_logs"


@router.get("", response_model=list[HistorySummary])
async def list_runs() -> list[HistorySummary]:
    if not RUN_LOG_DIR.exists():
        return []

    summaries = []
    for path in RUN_LOG_DIR.glob("*.json"):
        with open(path) as f:
            data = json.load(f)
        summaries.append(
            HistorySummary(
                run_id=data["run_id"],
                timestamp=data["timestamp"],
                question=data["question"],
                out_of_scope=data.get("out_of_scope", False),
                sql=data.get("sql"),
                error=data.get("error"),
                row_count=data.get("row_count", 0),
                retry_count=data.get("retry_count", 0),
            )
        )
    summaries.sort(key=lambda s: s.timestamp, reverse=True)
    return summaries


@router.get("/{run_id}", response_model=HistoryDetailResponse)
async def get_run(run_id: str) -> HistoryDetailResponse:
    path = RUN_LOG_DIR / f"{run_id}.json"
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"No run found for run_id={run_id}")

    with open(path) as f:
        data = json.load(f)

    return HistoryDetailResponse(
        question=data["question"],
        run_id=data["run_id"],
        timestamp=data["timestamp"],
        out_of_scope=data.get("out_of_scope", False),
        out_of_scope_reason=data.get("out_of_scope_reason"),
        retrieved_tables=[RetrievedTableOut(**t) for t in data.get("retrieved_tables", [])],
        linked_schema=data.get("linked_schema"),
        sql=data.get("sql"),
        error=data.get("error"),
        columns=data.get("columns") or [],
        rows=data.get("rows") or [],
        retry_count=data.get("retry_count", 0),
        repair_trace=data.get("repair_trace", []),
    )
