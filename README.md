# Text2SQL

LLM-powered Text2SQL over a Postgres real-estate sales & collections database: hybrid retrieval (dense +
keyword) → schema linking → SQL generation → EXPLAIN validation → execution →
bounded self-repair, orchestrated as a LangGraph state machine. Served via a
FastAPI backend and a two-page React UI (Q&A, Evals).

See `IMPLEMENTATION_GUIDE.md` for the full phased design this implements, and
`seed/README.md` for the synthetic schema standing in for a real DB.

## Folder structure

```
text2sql/
├── docker-compose.yml          # local Postgres+pgvector, seeded on first `up`
├── docker/postgres/init/       # DDL + seed SQL run in order on first init
│   ├── 01_synthetic_schema.sql
│   ├── 02_seed_data.sql
│   └── 03_pgvector_ddl.sql
├── seed/                       # synthetic 50-table real-estate schema + starter eval set
│   ├── 00_synthetic_schema_ddl.sql
│   ├── 01_seed_data.sql
│   ├── eval_seed/eval_questions.json
│   └── README.md
├── backend/                    # FastAPI app + one-off scripts
│   ├── app/
│   │   ├── main.py             # FastAPI entrypoint
│   │   ├── config.py, deps.py
│   │   ├── api/                # routers, request/response schemas
│   │   ├── retrieval/          # dense + keyword retrieval, fusion, rerank, FK expand
│   │   ├── linking/            # schema linking
│   │   ├── generation/         # SQL generation, few-shot bank, SQL guard
│   │   ├── execution/          # EXPLAIN validation, execution, self-repair
│   │   ├── graph/              # LangGraph state machine (nodes, build_graph, state)
│   │   ├── eval/               # eval runner, scoring, result comparison
│   │   ├── llm/                # Anthropic + OpenAI embeddings clients
│   │   ├── db/                 # connection pool
│   │   └── logging_/           # run logger
│   ├── scripts/
│   │   ├── schema_extraction/  # 01 extract → 02 build index → 03 pgvector DDL
│   │   ├── load_embeddings.py
│   │   ├── load_golden_queries.py
│   │   ├── load_glossary.py
│   │   └── run_eval_cli.py
│   ├── tests/
│   └── pyproject.toml
├── frontend/                    # Vite + React + TS app
│   ├── src/
│   │   ├── pages/               # QAPage, EvalsPage, HistoryPage
│   │   ├── components/          # SQLDisplay, ResultTable, RepairTrace, MetricsDashboard, ...
│   │   ├── api/client.ts
│   │   ├── App.tsx, main.tsx, types.ts
│   │   └── index.css
│   └── package.json
└── IMPLEMENTATION_GUIDE.md      # full phased design this implements
```

## Day 0 — bring up the local database

```
docker compose up -d postgres
```

This runs, in order: the synthetic schema DDL, seed data, and the pgvector
retrieval-layer DDL (`schema_embeddings`, `column_embeddings`,
`schema_relationships`, `golden_queries`, `business_glossary`). Only runs on
first init against an empty volume.

## Day 1 Runbook (schema foundation)

1. `backend/scripts/schema_extraction/01_extract_schema.sql` — sanity-check
   directly against the DB (psql/DBeaver).
2. `backend/scripts/schema_extraction/02_build_schema_index.py` — reads DB
   connection config from `backend/.env` (copy from `backend/.env.example`).
   Run from `backend/`: `python scripts/schema_extraction/02_build_schema_index.py`
   Outputs `schema_metadata.json`, `fk_graph.json`, `schema_for_review.json` into
   that same directory.
3. **Human review pass** — `schema_metadata.json` / `fk_graph.json` / `schema_for_review.json`
   in that directory are still generated from the old insurance schema; run step 2 against the
   real-estate schema (see `seed/README.md`) to regenerate them, then review/tag before proceeding.
4. `backend/scripts/schema_extraction/03_pgvector_ddl.sql` — already applied via
   the docker-compose init; re-run by hand if pointing at a different DB.

## Backend setup

```
cd backend
pip install -e .
cp .env.example .env   # fill in ANTHROPIC_API_KEY and OPENAI_API_KEY
python -m scripts.load_embeddings       # Phase 2: embeds schema into pgvector
python -m scripts.load_golden_queries   # seeds the few-shot bank
python -m scripts.load_glossary         # seeds the business glossary
uvicorn app.main:app --reload
```

## Frontend setup

```
cd frontend
npm install
cp .env.example .env   # VITE_API_BASE_URL, defaults to http://localhost:8000
npm run dev
```

## Running evals

```
cd backend
python -m scripts.run_eval_cli   # against seed/eval_seed/eval_questions.json
```

Or trigger a run from the Evals page in the UI, which calls the same
`POST /api/evals/run` endpoint and shares the same scoring code as the CLI.

## What's NOT built yet

- Only a starter eval set (20 hand-verified questions) — grow toward the guide's
  50-100 target as real failure cases surface.
- No background-job pattern for eval runs — fine at 20 questions synchronously,
  will need one before scaling up.
- Not yet pointed at a real 150+ table DB — swapping in one is a `backend/.env`
  connection-string change plus re-running the Day 1 scripts against it.
