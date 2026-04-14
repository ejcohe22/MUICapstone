# inference/runtime/context.py
import torch


class ModelContext:
    def __init__(self, device: str | None = None):
        if device is not None:
            self.device = device
        elif torch.cuda.is_available():
            self.device = "cuda"
        elif torch.backends.mps.is_available():
            self.device = "mps"
        else:
            self.device = "cpu"
