from functools import lru_cache

from fastapi import Request

from app.config import Settings, get_settings
from app.graph.nodes import GraphDeps
from app.llm.anthropic_client import AnthropicClient
from app.llm.openai_embeddings import OpenAIEmbeddingClient


@lru_cache
def get_anthropic_client() -> AnthropicClient:
    return AnthropicClient(get_settings())


@lru_cache
def get_embedder() -> OpenAIEmbeddingClient:
    return OpenAIEmbeddingClient(get_settings())


def get_graph_deps(request: Request) -> GraphDeps:
    """db_pool lives on app.state (created at startup, see main.py) since asyncpg
    pools must be created inside a running event loop."""
    return GraphDeps(
        db_pool=request.app.state.db_pool,
        anthropic_client=get_anthropic_client(),
        embedder=get_embedder(),
        settings=get_settings(),
    )
