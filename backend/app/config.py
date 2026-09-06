from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "text2sql"
    db_user: str = "text2sql"
    db_password: str = "text2sql"

    # LLM providers
    anthropic_api_key: str = ""
    anthropic_model: str = "claude-sonnet-5"
    openai_api_key: str = ""
    openai_embedding_model: str = "text-embedding-3-small"

    # Retrieval / generation knobs
    retrieval_dense_top_k: int = 30
    retrieval_keyword_top_k: int = 30
    retrieval_rerank_top_k: int = 10
    reranker_model: str = "BAAI/bge-reranker-base"
    max_repair_retries: int = 3
    execution_row_limit: int = 200
    execution_statement_timeout_ms: int = 5000

    # API server
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    cors_origins: str = "http://localhost:5173"

    @property
    def database_url(self) -> str:
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
