import torch
from diffusers import StableVideoDiffusionPipeline
from PIL import Image
import base64
from io import BytesIO

from inference.models.base import ModelAdapter
from inference.schemas import VideoGenerationRequest, InferenceResponse, OutputType


class SVDModel(ModelAdapter[VideoGenerationRequest, InferenceResponse]):
    """
    Stable Video Diffusion adapter.
    """

    def load(self) -> None:
        self.pipe = StableVideoDiffusionPipeline.from_pretrained(
            "stabilityai/stable-video-diffusion-img2vid",
            torch_dtype=torch.float16,
        ).to(self.context.device)

    def generate(self, request: VideoGenerationRequest) -> InferenceResponse:
        # Decode base64 image
        img_bytes = base64.b64decode(request.image_base64)
        image = Image.open(BytesIO(img_bytes)).convert("RGB")

        # Actual inference
        frames = self.pipe(image, num_frames=request.num_frames, decode_chunk_size=8).frames[0]

        # In a real scenario, we'd encode frames to video. 
        # For now, we'll return the frame count as metadata.
        return InferenceResponse(
            type=OutputType.VIDEO,
            payload=[self._img_to_b64(f) for f in frames],
            metadata={"model": "svd", "frame_count": len(frames)}
        )

    def _img_to_b64(self, img: Image.Image) -> str:
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        return base64.b64encode(buffer.getvalue()).decode()
