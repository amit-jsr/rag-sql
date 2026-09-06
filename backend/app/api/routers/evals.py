import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException

from app.api.schemas import EvalRunRequest, EvalRunResponse
from app.deps import get_graph_deps
from app.eval.runner import EvalRunResult, run_eval
from app.graph.nodes import GraphDeps

router = APIRouter(prefix="/api/evals", tags=["evals"])

REPO_ROOT = Path(__file__).parents[4]

_run_store: dict[str, EvalRunResult] = {}


@router.post("/run", response_model=EvalRunResponse)
async def run(request: EvalRunRequest, deps: GraphDeps = Depends(get_graph_deps)) -> EvalRunResponse:
    eval_file_path = REPO_ROOT / request.eval_file
    if not eval_file_path.exists():
        raise HTTPException(status_code=404, detail=f"Eval file not found: {eval_file_path}")

    run_id = str(uuid.uuid4())
    result = await run_eval(str(eval_file_path), deps, run_id)
    _run_store[run_id] = result

    return EvalRunResponse(run_id=result.run_id, metrics=result.metrics, cases=result.cases)


@router.get("/{run_id}", response_model=EvalRunResponse)
async def get_run(run_id: str) -> EvalRunResponse:
    result = _run_store.get(run_id)
    if result is None:
        raise HTTPException(status_code=404, detail=f"No eval run found for run_id={run_id}")
    return EvalRunResponse(run_id=result.run_id, metrics=result.metrics, cases=result.cases)
