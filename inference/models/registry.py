from .dummy import DummyModel
from .sdxl import SDXLModel
from .svd import SVDModel

MODEL_REGISTRY = {
    "dummy": lambda ctx: DummyModel(ctx),
    "sdxl": lambda ctx: SDXLModel(ctx),
    "svd": lambda ctx: SVDModel(ctx),
}


def get_model(name: str, ctx):
    if name not in MODEL_REGISTRY:
        raise ValueError(f"Unknown model: {name}")
    return MODEL_REGISTRY[name](ctx)
