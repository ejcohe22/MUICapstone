import numpy as np

from .base import ModelAdapter

"""
Model for unit tests
"""


class DummyModel(ModelAdapter):
    def load(self):
        return self

    def generate(self, payload: dict) -> dict:

        seed = hash(str(payload)) % (2**32)
        rng = np.random.default_rng(seed)

        img = (rng.random((64, 64, 3)) * 255).astype("uint8")

        return {
            "type": "image",
            "shape": img.shape,
            "data": img.tolist(),
            "input_echo": payload,
        }
