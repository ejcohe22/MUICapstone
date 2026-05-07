from typing import Callable, Dict, Type

from inference.models.base import ModelAdapter
from inference.runtime.context import ModelContext


class ModelFactory:
    """
    A Factory class (GoF Factory Pattern) for managing model registrations
    and instantiations.
    """

    _registry: Dict[str, Type[ModelAdapter]] = {}

    @classmethod
    def register(cls, name: str, adapter_cls: Type[ModelAdapter]) -> None:
        """Register a new model adapter class."""
        cls._registry[name] = adapter_cls

    @classmethod
    def create(cls, name: str, context: ModelContext) -> ModelAdapter:
        """Create an instance of the requested model adapter."""
        if name not in cls._registry:
            raise ValueError(f"Model '{name}' is not registered in the Factory.")
        
        adapter_cls = cls._registry[name]
        return adapter_cls(context)


# Global factory instance (Singleton-like usage)
registry = ModelFactory


# Circular imports avoided by registering inside the implementations or here
def get_model(name: str, context: ModelContext) -> ModelAdapter:
    """Legacy compatibility wrapper for the factory."""
    # Note: Real implementations will be registered here or via decorators
    from .dummy import DummyModel
    from .sdxl import SDXLModel
    from .stylegan import StyleGANModel
    from .svd import SVDModel

    ModelFactory.register("dummy", DummyModel)
    ModelFactory.register("sdxl", SDXLModel)
    ModelFactory.register("svd", SVDModel)
    ModelFactory.register("stylegan", StyleGANModel)

    return ModelFactory.create(name, context)
