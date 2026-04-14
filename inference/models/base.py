from abc import ABC, abstractmethod


class ModelAdapter(ABC):
    @abstractmethod
    def load(self):
        pass

    @abstractmethod
    def generate(self, payload: dict) -> dict:
        pass
