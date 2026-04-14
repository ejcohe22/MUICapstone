from .dummy import DummyModel

MODEL_REGISTRY = {
    "dummy": DummyModel,
}


def get_model(name: str):
    if name not in MODEL_REGISTRY:
        raise ValueError(f"Unknown model: {name}")
    return MODEL_REGISTRY[name]()
