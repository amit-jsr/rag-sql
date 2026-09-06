from functools import lru_cache

from sentence_transformers import CrossEncoder

from app.linking.schemas import RetrievedTable


@lru_cache
def _get_reranker(model_name: str) -> CrossEncoder:
    """Loaded once and cached — call this at FastAPI startup (see app/deps.py) so
    the first request doesn't pay the model-load cost."""
    return CrossEncoder(model_name)


def rerank(
    question: str, candidates: list[RetrievedTable], top_k: int, model_name: str
) -> list[RetrievedTable]:
    if not candidates:
        return candidates
    model = _get_reranker(model_name)
    pairs = [(question, f"{c.full_name}: {c.description}") for c in candidates]
    scores = model.predict(pairs)
    reranked = sorted(zip(candidates, scores), key=lambda pair: pair[1], reverse=True)
    return [c.model_copy(update={"score": float(s)}) for c, s in reranked[:top_k]]
