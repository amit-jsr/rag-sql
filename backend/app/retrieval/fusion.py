from app.linking.schemas import RetrievedTable

RRF_K = 60  # standard reciprocal-rank-fusion constant


def reciprocal_rank_fusion(
    dense_results: list[RetrievedTable],
    keyword_results: list[RetrievedTable],
    top_k: int,
) -> list[RetrievedTable]:
    """Merge two ranked lists via RRF: score(d) = sum(1 / (RRF_K + rank_in_list))."""
    fused_scores: dict[str, float] = {}
    by_name: dict[str, RetrievedTable] = {}

    for results in (dense_results, keyword_results):
        for rank, table in enumerate(results):
            fused_scores[table.full_name] = fused_scores.get(table.full_name, 0.0) + 1.0 / (
                RRF_K + rank + 1
            )
            by_name[table.full_name] = table

    ranked_names = sorted(fused_scores, key=lambda name: fused_scores[name], reverse=True)
    merged = []
    for name in ranked_names[:top_k]:
        table = by_name[name]
        merged.append(table.model_copy(update={"score": fused_scores[name]}))
    return merged
