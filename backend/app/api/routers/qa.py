from fastapi import APIRouter, Depends

from app.api.schemas import AskRequest, AskResponse, RetrievedTableOut
from app.deps import get_graph_deps
from app.graph.build_graph import build_graph
from app.graph.nodes import GraphDeps
from app.logging_.run_logger import log_run

router = APIRouter(prefix="/api/qa", tags=["qa"])

MAX_HISTORY_TURNS = 5


@router.post("/ask", response_model=AskResponse)
async def ask(request: AskRequest, deps: GraphDeps = Depends(get_graph_deps)) -> AskResponse:
    compiled_graph = build_graph(deps)
    history = [turn.model_dump() for turn in request.history[-MAX_HISTORY_TURNS:]]
    final_state = await compiled_graph.ainvoke(
        {"question": request.question, "history": history, "retry_count": 0, "repair_trace": []}
    )
    run_id = log_run(final_state)

    linked = final_state.get("linked")

    return AskResponse(
        question=request.question,
        run_id=run_id,
        out_of_scope=final_state.get("out_of_scope", False),
        out_of_scope_reason=final_state.get("out_of_scope_reason"),
        retrieved_tables=[
            RetrievedTableOut(
                table=t.full_name, description=t.description, domain_cluster=t.domain_cluster, score=t.score
            )
            for t in final_state.get("retrieved", [])
        ],
        linked_schema=linked.model_dump() if linked else None,
        sql=final_state.get("sql"),
        error=final_state.get("error"),
        columns=final_state.get("columns", []),
        rows=final_state.get("rows", []),
        retry_count=final_state.get("retry_count", 0),
        repair_trace=final_state.get("repair_trace", []),
    )
