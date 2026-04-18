import torch
from diffusers import StableVideoDiffusionPipeline

from inference.models.base import ModelAdapter


class SVDModel(ModelAdapter):
    def load(self):
        self.pipe = StableVideoDiffusionPipeline.from_pretrained(
            "stabilityai/stable-video-diffusion-img2vid",
            torch_dtype=torch.float16,
        ).to(self.context.device)

    def generate(self, payload: dict) -> dict:
        image = payload["image"]  # PIL image expected

        frames = self.pipe(image).frames

        return {
            "type": "video",
            "frames": frames,
        }
