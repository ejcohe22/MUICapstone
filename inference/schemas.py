from typing import Any, Dict, Optional

from pydantic import BaseModel


class GenerateRequest(BaseModel):
    model: Optional[str] = None
    prompt: Optional[str] = None
    latent: Optional[list[float]] = None
    seed: Optional[int] = None
    audio_features: Optional[Dict[str, Any]] = None
