## 2026 current SOTA baseline for image generation

import base64
from io import BytesIO

import torch
from diffusers import StableDiffusionXLPipeline

from inference.models.base import ModelAdapter


class SDXLModel(ModelAdapter):
    def load(self):
        self.pipe = StableDiffusionXLPipeline.from_pretrained(
            "stabilityai/stable-diffusion-xl-base-1.0",
            torch_dtype=torch.float16,
        ).to(self.context.device)

    def generate(self, payload: dict) -> dict:
        prompt = payload.get("prompt", "")

        image = self.pipe(prompt=prompt).images[0]

        buffer = BytesIO()
        image.save(buffer, format="PNG")
        img_str = base64.b64encode(buffer.getvalue()).decode()

        return {
            "type": "image",
            "image_base64": img_str,
        }
