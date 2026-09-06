import anthropic

from app.config import Settings


class AnthropicClient:
    """Thin wrapper around the Anthropic SDK for the generation/linking/repair nodes.

    Kept deliberately small: callers own their own prompts and JSON parsing/retry
    logic (see linking/schema_linker.py, generation/sql_generator.py,
    execution/repair.py) since each has different validation needs.
    """

    def __init__(self, settings: Settings):
        self._client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
        self._model = settings.anthropic_model

    def complete(
        self,
        *,
        system: str,
        user_message: str,
        max_tokens: int = 4096,
        effort: str = "medium",
    ) -> str:
        """Single-turn completion, returns concatenated text blocks.

        Adaptive thinking runs by default on claude-sonnet-5 (no `thinking` param
        needed); `effort` controls how much reasoning it does before answering.
        """
        response = self._client.messages.create(
            model=self._model,
            max_tokens=max_tokens,
            output_config={"effort": effort},
            system=system,
            messages=[{"role": "user", "content": user_message}],
        )
        if response.stop_reason == "refusal":
            raise RuntimeError(f"Anthropic refused the request: {response.stop_details}")
        return "".join(block.text for block in response.content if block.type == "text")
