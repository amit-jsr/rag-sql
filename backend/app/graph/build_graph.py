from functools import partial

from langgraph.graph import END, StateGraph

from app.graph.nodes import (
    GraphDeps,
    execute_node,
    generate_node,
    link_node,
    make_router,
    repair_node,
    retrieve_node,
    route_after_link,
    validate_node,
)
from app.graph.state import GraphState


def build_graph(deps: GraphDeps):
    """Wires the Phase 5 state machine:
    retrieve -> link -> generate -> validate -> execute -> (on error) repair -> re-validate
    with the repair loop bounded by settings.max_repair_retries."""
    route_after_validate, route_after_execute = make_router(deps)

    graph = StateGraph(GraphState)
    graph.add_node("retrieve", partial(retrieve_node, deps=deps))
    graph.add_node("link", partial(link_node, deps=deps))
    graph.add_node("generate", partial(generate_node, deps=deps))
    graph.add_node("validate", partial(validate_node, deps=deps))
    graph.add_node("execute", partial(execute_node, deps=deps))
    graph.add_node("repair", partial(repair_node, deps=deps))

    graph.set_entry_point("retrieve")
    graph.add_edge("retrieve", "link")
    graph.add_conditional_edges("link", route_after_link, {"generate": "generate", "end": END})
    graph.add_edge("generate", "validate")
    graph.add_conditional_edges(
        "validate", route_after_validate, {"execute": "execute", "repair": "repair", "end": END}
    )
    graph.add_conditional_edges(
        "execute", route_after_execute, {"end": END, "repair": "repair"}
    )
    graph.add_edge("repair", "validate")

    return graph.compile()
