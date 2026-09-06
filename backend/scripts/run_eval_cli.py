"""
CLI entrypoint for the eval harness — shares app/eval/runner.py::run_eval with the
FastAPI /api/evals/run endpoint, so scoring logic isn't duplicated between the two.

Writes a timestamped results JSON to eval_runs/ for regression tracking (diff
against the previous run to catch regressions after a pipeline change, per
IMPLEMENTATION_GUIDE.md Phase 6.5).

Usage (from backend/): python -m scripts.run_eval_cli [path/to/eval_questions.json]
"""

import asyncio
import sys
import time
import uuid
from pathlib import Path

from app.config import get_settings
from app.db.pool import close_pool, init_pool
from app.eval.runner import run_eval
from app.graph.nodes import GraphDeps
from app.llm.anthropic_client import AnthropicClient
from app.llm.openai_embeddings import OpenAIEmbeddingClient

REPO_ROOT = Path(__file__).parents[2]
DEFAULT_EVAL_FILE = REPO_ROOT / "seed" / "eval_seed" / "eval_questions.json"
RUNS_DIR = Path(__file__).parent.parent / "eval_runs"


def print_report(metrics) -> None:
    print("\n=== Eval results ===")
    print(f"Total cases:              {metrics.total_cases}")
    print(f"Schema-linking precision:  {metrics.schema_linking_precision:.1%}")
    print(f"Schema-linking recall:     {metrics.schema_linking_recall:.1%}")
    print(f"Execution accuracy:        {metrics.execution_accuracy:.1%}")
    print(f"Valid-SQL rate:            {metrics.valid_sql_rate:.1%}")
    print(f"Repair-loop usage rate:    {metrics.repair_loop_usage_rate:.1%}")


async def main() -> None:
    eval_file = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_EVAL_FILE
    if not eval_file.exists():
        raise SystemExit(f"Eval file not found: {eval_file}")

    settings = get_settings()
    pool = await init_pool(settings)
    deps = GraphDeps(
        db_pool=pool,
        anthropic_client=AnthropicClient(settings),
        embedder=OpenAIEmbeddingClient(settings),
        settings=settings,
    )

    run_id = str(uuid.uuid4())
    result = await run_eval(str(eval_file), deps, run_id)
    print_report(result.metrics)

    RUNS_DIR.mkdir(exist_ok=True)
    out_path = RUNS_DIR / f"{int(time.time())}_{run_id}.json"
    with open(out_path, "w") as f:
        f.write(result.model_dump_json(indent=2))
    print(f"\nFull results written to {out_path}")

    await close_pool()


if __name__ == "__main__":
    asyncio.run(main())
