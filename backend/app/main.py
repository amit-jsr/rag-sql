from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routers import evals, history, qa
from app.config import get_settings
from app.db.pool import close_pool, init_pool
from app.retrieval.rerank import _get_reranker


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.db_pool = await init_pool(settings)
    _get_reranker(settings.reranker_model)  # load once at startup, not on first request
    yield
    await close_pool()


app = FastAPI(title="Text2SQL API", lifespan=lifespan)

settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(qa.router)
app.include_router(evals.router)
app.include_router(history.router)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}
