# Text2SQL RAG Implementation Guide
### Enterprise-scale (starting scope: ~50 tables, expanding to 150+)

---

## Phase 0 — Prerequisites
- [ ] Postgres with `pgvector` extension enabled
- [ ] Read-replica or sandboxed DB connection for safe query execution/testing
- [ ] Embedding model chosen (Bedrock Titan v2, or OpenAI text-embedding-3-small) — confirm vector dimension
- [ ] LLM for generation (Bedrock-hosted Claude/other) and a lighter model for reranking if self-hosting bge-reranker
- [ ] LangGraph environment set up (matches your existing stack)

---

## Phase 1 — Schema Foundation (Day 1)

**Goal:** structured, human-reviewed schema metadata for the scoped table set.

1. Run `01_extract_schema.sql` manually first to confirm DB access and output shape.
2. Run `02_build_schema_index.py` with `TABLE_ALLOWLIST` set to your ~50-table domain cluster (auto-expands via FK neighbors).
3. Outputs: `schema_metadata.json`, `fk_graph.json`, `schema_for_review.json`.
4. **Human review pass**: rewrite draft descriptions into clear 1-2 line business descriptions. Tag each table with a `domain_cluster`.
5. Run `03_pgvector_ddl.sql` to create `schema_embeddings`, `column_embeddings`, `schema_relationships`, `golden_queries`, `business_glossary`.

**Exit criteria:** every scoped table has a reviewed description; FK graph is loaded into `schema_relationships`.

---

## Phase 2 — Embedding & Load (Day 2)

1. Write an embedding script that reads `schema_for_review.json` (post-review) and:
   - Embeds `description + column names + sample values` per table → insert into `schema_embeddings`.
   - Optionally embeds each column individually (name + type + comment) → insert into `column_embeddings`.
2. Load `fk_graph.json` into `schema_relationships`.
3. Sanity check: run a raw cosine-similarity query for 5 known questions and manually verify the top-5 retrieved tables make sense.

**Exit criteria:** retrieval returns sensible tables for obvious questions before any reranking is added.

---

## Phase 3 — Hybrid Retrieval Pipeline (Day 3)

1. Implement dense retrieval (pgvector cosine, top-30).
2. Implement keyword/BM25 retrieval (Postgres `pg_trgm` or a lightweight BM25 lib) over table/column names — catches exact-match terms dense search misses.
3. Combine both via reciprocal rank fusion (RRF) to produce a merged top-30 candidate list.
4. Add a reranker (cross-encoder) on the merged list → final top 8-15 tables.
5. Expand result with 1-hop FK neighbors from `schema_relationships` so join paths are present even if not directly retrieved.

**Exit criteria:** measure retrieval precision/recall against 15-20 manually labeled questions (see Phase 6 eval set) before moving on.

---

## Phase 4 — Schema Linking & Generation (Day 4-5)

1. **Linking node**: LLM call that takes (question + retrieved schema) and outputs strict JSON: `{tables, columns, joins, filters}`. Validate every table/column against actual retrieved schema — reject/re-prompt if it references anything not present (catches hallucination early).
2. **Generation node**: SQL generated from the *linked JSON*, not raw retrieval text — this decoupling is what cuts join errors.
3. **Few-shot injection**: retrieve top-3 similar verified questions from `golden_queries` (once populated) and include as examples in the generation prompt.
4. **Dry-run validation**: `EXPLAIN` the generated SQL before execution to catch reference/syntax errors cheaply.

**Exit criteria:** SQL generates without syntax errors on your eval set; join structure matches expected FK paths.

---

## Phase 5 — Execution & Self-Correction (Day 6-7, LangGraph)

State machine: `retrieve → link → generate → validate(EXPLAIN) → execute → (on error) repair → re-execute`

1. Execute against read-replica with a row-limit and timeout guard.
2. On DB error, feed the actual error message back into a bounded repair prompt (max 2-3 retries).
3. Optionally: generate 2-3 SQL candidates via sampling, execute all, pick by majority-vote/result-shape agreement (self-consistency) for higher-stakes queries.
4. Log every run (question, retrieved tables, linked JSON, generated SQL, execution result, retry count) — this log is your debugging and eval data source going forward.

**Exit criteria:** pipeline runs end-to-end on 10 sample questions without manual intervention.

---

## Phase 6 — Evaluation Set (build in parallel with Phase 3 onward)

This is the part most teams under-invest in. Build it *before* you start tuning retrieval, not after.

### 6.1 — Structure
Store as a JSON/CSV with these fields per row:

| Field | Description |
|---|---|
| `id` | unique identifier |
| `question` | natural language question |
| `gold_sql` | verified correct SQL |
| `gold_tables` | list of tables the correct query touches (for linking-accuracy scoring) |
| `domain_cluster` | which cluster this question belongs to |
| `difficulty` | `simple` / `moderate` / `complex` (by join count — see below) |
| `question_type` | `lookup`, `aggregation`, `multi-hop-join`, `filter-heavy`, `temporal` |

### 6.2 — Difficulty tiers (mirrors Spider/BIRD convention)
- **Simple**: single table, basic filter/select.
- **Moderate**: 2-3 table join, single aggregation.
- **Complex**: 4+ table join, nested subquery, or multi-step aggregation/window function.

Aim for a rough split: 40% simple, 40% moderate, 20% complex — reflects real usage better than an even split.

### 6.3 — Building the set (target: 50-100 questions for the 50-table slice)
1. Pull 15-20 questions from actual business users/analysts if available (real phrasing > invented phrasing).
2. Draft the remaining questions yourself across each `domain_cluster`, deliberately covering:
   - Ambiguous business terms (tests your glossary layer)
   - Cryptic column names (tests description quality)
   - Multi-hop joins following your FK graph
   - Questions with no valid answer / out-of-scope tables (tests the system says "I don't have that data" instead of hallucinating)
3. Hand-write and manually verify the `gold_sql` for each — execute it yourself against the DB to confirm it's correct, don't just eyeball it.

### 6.4 — Metrics to track separately
Don't collapse these into one "accuracy" number — they tell you different things:

- **Schema-linking accuracy**: did retrieved/linked tables match `gold_tables`? (precision + recall)
- **Execution accuracy**: does generated SQL, when run, return the same result set as `gold_sql`? (not exact string match — compare result sets)
- **Valid-SQL rate**: % of generations that execute without error at all
- **Repair-loop usage rate**: % of queries needing 1+ repair attempt (signals generation quality trend over time)

### 6.5 — Cadence
- Run the full eval set after every pipeline change (retrieval tuning, prompt change, reranker swap).
- Track results over time in a simple spreadsheet/log — regression here is easy to miss without a running record.
- Grow the eval set as you find real failure cases in production — add them back as regression tests.

**Exit criteria:** 50-100 verified questions with gold SQL and gold tables, categorized by difficulty and type, runnable as an automated scoring script.

---

## Phase 7 — Semantic Layer / Glossary (parallel track, ongoing)

1. Populate `business_glossary` with business terms → table/column mappings as ambiguity surfaces during eval (e.g. "churn" → `customer.status = 'cancelled'`).
2. Embed glossary terms; check them at retrieval time alongside schema embeddings.
3. Revisit after each eval run — glossary gaps usually show up as schema-linking failures on ambiguous questions.

---

## Rollout Sequence Summary

1. Phase 1-2: Foundation + embeddings for 50-table slice → **today/tomorrow**
2. Phase 6.1-6.3: Start drafting eval questions **in parallel**, don't wait for Phase 5
3. Phase 3-5: Retrieval → linking → generation → execution, each validated against the growing eval set
4. Phase 7: Glossary refinement, ongoing based on eval failures
5. Once execution accuracy on the 50-table slice is stable (target: track your own bar, e.g. 80%+ execution accuracy on moderate/simple, lower expected on complex), expand `TABLE_ALLOWLIST` to the next domain cluster and repeat Phases 1-2 for the new tables only — retrieval/linking/generation logic doesn't need to be rebuilt.

---

## Common Pitfalls to Avoid
- Tuning retrieval before the eval set exists — you'll optimize against intuition, not measurement.
- Skipping human review on table descriptions to move faster — this is the highest-leverage low-cost step and skipping it compounds errors downstream.
- Using exact-string-match instead of result-set comparison for execution accuracy — SQL can be phrased differently and still be correct.
- Letting the repair loop retry unboundedly — cap it, and log unresolved failures for manual review instead.
- Evaluating only on "easy" hand-picked questions — deliberately include ambiguous and out-of-scope questions in the eval set.
