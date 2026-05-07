import base64
from io import BytesIO

import torch
from diffusers import StableDiffusionXLPipeline

from inference.models.base import ModelAdapter
from inference.schemas import ImageGenerationRequest, InferenceResponse, OutputType


class SDXLModel(ModelAdapter[ImageGenerationRequest, InferenceResponse]):
    """
    Standard SDXL adapter. 
    Implements Template Method pattern via its inheritance from ModelAdapter.
    """

    def load(self) -> None:
        self.pipe = StableDiffusionXLPipeline.from_pretrained(
            "stabilityai/stable-diffusion-xl-base-1.0",
            torch_dtype=torch.float16,
        ).to(self.context.device)

    def generate(self, request: ImageGenerationRequest) -> InferenceResponse:
        # Actual inference
        image = self.pipe(
            prompt=request.prompt, 
            negative_prompt=request.negative_prompt
        ).images[0]

        # Serialization logic
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        img_str = base64.b64encode(buffer.getvalue()).decode()

        return InferenceResponse(
            type=OutputType.IMAGE,
            payload=img_str,
            metadata={"model": "sdxl", "seed": request.seed}
        )
