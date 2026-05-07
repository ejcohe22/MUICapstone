from typing import Union

from fastapi import FastAPI, Header

from inference.auth import verify_api_key
from inference.config import MODEL_NAME
from inference.models.registry import get_model
from inference.runtime.context import ModelContext
from inference.runtime.model_runner import ModelRunner
from inference.schemas import (
    ImageGenerationRequest,
    VideoGenerationRequest,
    LatentInferenceRequest,
    InferenceResponse,
)

# Define a Union for all possible request types
AnyInferenceRequest = Union[
    ImageGenerationRequest, 
    VideoGenerationRequest, 
    LatentInferenceRequest
]

def create_app() -> FastAPI:
    app = FastAPI(
        title="MUIC Inference Engine",
        description="A 'slopn't' GoF-architected inference server for anceps.",
        version="1.0.0"
    )

    # Core runtime components (Singleton-like in this scope)
    ctx = ModelContext()
    model = get_model(MODEL_NAME, ctx)
    runner = ModelRunner(model)
    runner.load()

    @app.get("/health")
    def health():
        return {
            "status": "ok", 
            "model": MODEL_NAME, 
            "device": ctx.device
        }

    @app.post("/generate", response_model=InferenceResponse)
    def generate(
        req: AnyInferenceRequest, 
        authorization: str = Header(None)
    ):
        """
        Main inference endpoint. Uses Pydantic Union for polymorphism.
        """
        verify_api_key(authorization)
        return runner.generate(req)

    return app
