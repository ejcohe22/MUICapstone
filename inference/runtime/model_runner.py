from typing import Generic, TypeVar

from inference.models.base import ModelAdapter, TIn, TOut


class ModelRunner(Generic[TIn, TOut]):
    """
    A typed runner that executes inference via the provided ModelAdapter.
    Implements the Command or Proxy pattern depending on future extensions
    (like async queuing).
    """

    def __init__(self, model: ModelAdapter[TIn, TOut]):
        self.model = model

    def load(self) -> None:
        """Delegate loading to the model adapter."""
        self.model.load()

    def generate(self, request: TIn) -> TOut:
        """
        Execute generation. The request is already a Pydantic model
        due to FastAPI validation.
        """
        return self.model.generate(request)
