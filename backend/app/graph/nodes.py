from dataclasses import dataclass

import asyncpg

from app.config import Settings
from app.execution.executor import ExecutionError, execute_readonly
from app.execution.explain_validator import ExplainError, explain_dry_run
from app.execution.repair import repair_sql
from app.generation.few_shot import get_few_shot_examples
from app.generation.sql_generator import generate_sql
from app.generation.sql_guard import SQLGuardError, validate_against_linked_schema
from app.linking.schema_linker import SchemaLinkingError, link_schema
from app.linking.schemas import LinkedSchema
from app.llm.anthropic_client import AnthropicClient
from app.llm.openai_embeddings import OpenAIEmbeddingClient
from app.retrieval.dense import dense_search
from app.retrieval.fk_expand import expand_with_fk_neighbors
from app.retrieval.fusion import reciprocal_rank_fusion
from app.retrieval.keyword import keyword_search
from app.retrieval.rerank import rerank
from app.graph.state import GraphState


@dataclass
class GraphDeps:
    db_pool: asyncpg.Pool
    anthropic_client: AnthropicClient
    embedder: OpenAIEmbeddingClient
    settings: Settings


def _contextual_query(state: GraphState, max_prior_turns: int = 2) -> str:
    """Prepends the last few conversation turns to the question so a follow-up
    like "and what about last month?" retrieves against something more specific
    than that bare fragment. Only used for retrieval — linking/generation get the
    raw question plus structured history separately (see below)."""
    history = state.get("history") or []
    prior_questions = [turn["question"] for turn in history[-max_prior_turns:]]
    return "\n".join([*prior_questions, state["question"]])


async def retrieve_node(state: GraphState, deps: GraphDeps) -> dict:
    question = state["question"]
    contextual_query = _contextual_query(state)
    query_embedding = deps.embedder.embed_one(contextual_query)

    async with deps.db_pool.acquire() as conn:
        dense = await dense_search(conn, query_embedding, deps.settings.retrieval_dense_top_k)
        keyword = await keyword_search(conn, contextual_query, deps.settings.retrieval_keyword_top_k)
        fused = reciprocal_rank_fusion(dense, keyword, top_k=30)
        reranked = rerank(
            question, fused, deps.settings.retrieval_rerank_top_k, deps.settings.reranker_model
        )
        expanded = await expand_with_fk_neighbors(conn, reranked)

    return {"retrieved": expanded}


async def link_node(state: GraphState, deps: GraphDeps) -> dict:
    try:
        linked = link_schema(
            deps.anthropic_client, state["question"], state["retrieved"], history=state.get("history")
        )
    except SchemaLinkingError as e:
        return {"linked": LinkedSchema(tables=[], columns=[], joins=[], filters=[]),
                "out_of_scope": True, "out_of_scope_reason": str(e)}

    return {
        "linked": linked,
        "out_of_scope": linked.out_of_scope,
        "out_of_scope_reason": linked.out_of_scope_reason,
    }


async def generate_node(state: GraphState, deps: GraphDeps) -> dict:
    async with deps.db_pool.acquire() as conn:
        examples = await get_few_shot_examples(conn, deps.embedder, state["question"])
    sql = generate_sql(
        deps.anthropic_client, state["question"], state["linked"], examples, history=state.get("history")
    )
    return {"sql": sql, "error": None, "retry_count": state.get("retry_count", 0)}


async def validate_node(state: GraphState, deps: GraphDeps) -> dict:
    linked_tables = {t.table for t in state["linked"].tables}
    try:
        validate_against_linked_schema(state["sql"], linked_tables)
    except SQLGuardError as e:
        return {"error": str(e)}

    async with deps.db_pool.acquire() as conn:
        try:
            await explain_dry_run(conn, state["sql"])
        except ExplainError as e:
            return {"error": str(e)}

    return {"error": None}


async def execute_node(state: GraphState, deps: GraphDeps) -> dict:
    async with deps.db_pool.acquire() as conn:
        try:
            columns, rows = await execute_readonly(
                conn,
                state["sql"],
                deps.settings.execution_row_limit,
                deps.settings.execution_statement_timeout_ms,
            )
        except ExecutionError as e:
            return {"error": str(e)}

    return {"columns": columns, "rows": rows, "error": None}


async def repair_node(state: GraphState, deps: GraphDeps) -> dict:
    linked_tables = {t.table for t in state["linked"].tables}
    failed_sql = state["sql"]
    error = state["error"] or "unknown error"
    fixed_sql = repair_sql(deps.anthropic_client, state["question"], failed_sql, error, linked_tables)
    retry_count = state.get("retry_count", 0) + 1

    return {
        "sql": fixed_sql,
        "retry_count": retry_count,
        "repair_trace": [
            {"attempt": retry_count, "failed_sql": failed_sql, "error": error, "fixed_sql": fixed_sql}
        ],
    }


def route_after_link(state: GraphState) -> str:
    return "end" if state.get("out_of_scope") else "generate"


def _route_on_error(state: GraphState, deps: GraphDeps, success_route: str) -> str:
    if not state.get("error"):
        return success_route
    if state.get("retry_count", 0) >= deps.settings.max_repair_retries:
        return "end"
    return "repair"


def make_router(deps: GraphDeps):
    def route_after_validate(state: GraphState) -> str:
        return _route_on_error(state, deps, success_route="execute")

    def route_after_execute(state: GraphState) -> str:
        return _route_on_error(state, deps, success_route="end")

    return route_after_validate, route_after_execute
