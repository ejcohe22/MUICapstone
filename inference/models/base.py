from abc import ABC, abstractmethod

from inference.runtime.context import ModelContext


class ModelAdapter(ABC):
    def __init__(self, context: ModelContext):
        self.context = context

    @abstractmethod
    def load(self):
        pass

    @abstractmethod
    def generate(self, payload: dict) -> dict:
        pass
