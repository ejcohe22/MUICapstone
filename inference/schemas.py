from enum import Enum
from typing import Any, List, Optional

from pydantic import BaseModel, Field


class OutputType(str, Enum):
    IMAGE = "image"
    VIDEO = "video"
    DATA = "data"


class BaseInferenceRequest(BaseModel):
    """Base class for all inference requests."""
    seed: Optional[int] = Field(None, description="Random seed for reproducibility")


class ImageGenerationRequest(BaseInferenceRequest):
    """Schema for text-to-image models like SDXL."""
    prompt: str = Field(..., description="Text prompt to generate an image")
    negative_prompt: Optional[str] = Field(None, description="What to exclude from the image")


class VideoGenerationRequest(BaseInferenceRequest):
    """Schema for image-to-video models like SVD."""
    image_base64: str = Field(..., description="Base64 encoded source image")
    num_frames: int = Field(25, description="Number of frames to generate")


class LatentInferenceRequest(BaseInferenceRequest):
    """Schema for GAN-style models like StyleGAN."""
    latent_vector: List[float] = Field(..., description="The latent space coordinates")
    class_index: Optional[int] = Field(None, description="Optional class label")


class InferenceResponse(BaseModel):
    """Unified response schema for all models."""
    success: bool = True
    type: OutputType
    payload: Any  # Could be base64 string, list of strings, or raw data
    metadata: Optional[dict] = None
