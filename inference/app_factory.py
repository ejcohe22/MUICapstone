from fastapi import FastAPI, Header

from inference.auth import verify_api_key
from inference.config import MODEL_NAME
from inference.models.registry import get_model
from inference.runtime.context import ModelContext
from inference.runtime.model_runner import ModelRunner
from inference.schemas import GenerateRequest


def create_app() -> FastAPI:
    app = FastAPI(title="MUIC Inference Engine")

    ctx = ModelContext()

    model = get_model(MODEL_NAME, ctx)
    runner = ModelRunner(model)
    runner.load()

    @app.get("/health")
    def health():
        return {"status": "ok", "model": MODEL_NAME}

    @app.post("/generate")
    def generate(req: GenerateRequest, authorization: str = Header(None)):
        verify_api_key(authorization)
        result = runner.generate(req)
        return {"success": True, "result": result}

    return app
