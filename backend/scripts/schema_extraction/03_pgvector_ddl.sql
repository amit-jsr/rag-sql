-- ============================================================
-- Day 1 Step 3: pgvector schema for retrieval + few-shot store
-- Adjust vector dimension to match your embedding model
-- (1536 for OpenAI text-embedding-3-small / Titan v2; 1024 for bge-large)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 1. Table-level schema embeddings (used for coarse retrieval)
CREATE TABLE IF NOT EXISTS schema_embeddings (
    id SERIAL PRIMARY KEY,
    table_schema TEXT NOT NULL,
    table_name TEXT NOT NULL,
    full_table_name TEXT GENERATED ALWAYS AS (table_schema || '.' || table_name) STORED,
    description TEXT NOT NULL,          -- human-reviewed business description
    columns_json JSONB NOT NULL,        -- full column list with types/comments
    sample_values_json JSONB,           -- a few sample rows for grounding
    domain_cluster TEXT,                -- e.g. 'claims', 'policy', 'customer' - for coarse filter stage
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (table_schema, table_name)
);

CREATE INDEX IF NOT EXISTS idx_schema_embeddings_vector
    ON schema_embeddings USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_schema_embeddings_domain
    ON schema_embeddings (domain_cluster);

-- Keyword retrieval support (Phase 3 hybrid retrieval): FTS over description text,
-- trigram over table_name for fuzzy/typo-tolerant identifier matching.
CREATE INDEX IF NOT EXISTS idx_schema_embeddings_fts
    ON schema_embeddings USING gin (to_tsvector('english', description));

CREATE INDEX IF NOT EXISTS idx_schema_embeddings_trgm
    ON schema_embeddings USING gin (full_table_name gin_trgm_ops);

-- 2. Column-level embeddings (finer granularity, used if table-level retrieval isn't precise enough)
CREATE TABLE IF NOT EXISTS column_embeddings (
    id SERIAL PRIMARY KEY,
    table_schema TEXT NOT NULL,
    table_name TEXT NOT NULL,
    column_name TEXT NOT NULL,
    data_type TEXT,
    description TEXT,
    embedding VECTOR(1536) NOT NULL,
    UNIQUE (table_schema, table_name, column_name)
);

CREATE INDEX IF NOT EXISTS idx_column_embeddings_vector
    ON column_embeddings USING hnsw (embedding vector_cosine_ops);

-- 3. FK relationship graph (queried after retrieval to expand join context)
CREATE TABLE IF NOT EXISTS schema_relationships (
    id SERIAL PRIMARY KEY,
    fk_table TEXT NOT NULL,
    fk_column TEXT NOT NULL,
    referenced_table TEXT NOT NULL,
    referenced_column TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_relationships_fk_table ON schema_relationships (fk_table);
CREATE INDEX IF NOT EXISTS idx_relationships_ref_table ON schema_relationships (referenced_table);

-- 4. Golden query bank (few-shot examples, built up as you test)
CREATE TABLE IF NOT EXISTS golden_queries (
    id SERIAL PRIMARY KEY,
    question TEXT NOT NULL,
    sql_query TEXT NOT NULL,
    tables_used TEXT[],
    domain_cluster TEXT,
    verified BOOLEAN DEFAULT false,
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_golden_queries_vector
    ON golden_queries USING hnsw (embedding vector_cosine_ops);

-- 5. Business glossary (optional but recommended - maps business terms to columns)
CREATE TABLE IF NOT EXISTS business_glossary (
    id SERIAL PRIMARY KEY,
    term TEXT NOT NULL,              -- e.g. "churn", "written premium"
    maps_to_table TEXT,
    maps_to_column TEXT,
    definition TEXT,
    embedding VECTOR(1536)
);

CREATE INDEX IF NOT EXISTS idx_glossary_vector
    ON business_glossary USING hnsw (embedding vector_cosine_ops);
