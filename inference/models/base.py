from abc import ABC, abstractmethod
from typing import Generic, TypeVar

from pydantic import BaseModel

from inference.runtime.context import ModelContext

# Define TypeVars for Input and Output schemas
TIn = TypeVar("TIn", bound=BaseModel)
TOut = TypeVar("TOut", bound=BaseModel)


class ModelAdapter(ABC, Generic[TIn, TOut]):
    """
    Abstract Base Class for Model Adapters using the Strategy Pattern.
    Enforces strict typing for input and output payloads via Generics.
    """

    def __init__(self, context: ModelContext):
        self.context = context

    @abstractmethod
    def load(self) -> None:
        """Initialize the model and load weights into memory/VRAM."""
        pass

    @abstractmethod
    def generate(self, request: TIn) -> TOut:
        """Execute the model inference logic."""
        pass
