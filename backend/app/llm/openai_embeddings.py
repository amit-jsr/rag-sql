import openai

from app.config import Settings


class OpenAIEmbeddingClient:
    """Wraps OpenAI's embeddings endpoint. Model fixed to text-embedding-3-small
    (1536-dim) to match the VECTOR(1536) columns in 03_pgvector_ddl.sql."""

    def __init__(self, settings: Settings):
        self._client = openai.OpenAI(api_key=settings.openai_api_key)
        self._model = settings.openai_embedding_model

    def embed(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        response = self._client.embeddings.create(model=self._model, input=texts)
        return [item.embedding for item in response.data]

    def embed_one(self, text: str) -> list[float]:
        return self.embed([text])[0]
