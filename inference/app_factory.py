from typing import Union, List

from fastapi import FastAPI, Header, WebSocket, WebSocketDisconnect

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

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            await connection.send_json(message)

manager = ConnectionManager()

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
    async def generate(
        req: AnyInferenceRequest, 
        authorization: str = Header(None)
    ):
        """
        Main inference endpoint. Uses Pydantic Union for polymorphism.
        """
        verify_api_key(authorization)
        response = runner.generate(req)
        
        # Broadcast to all connected renderers
        await manager.broadcast(response.dict())
        
        return response

    @app.websocket("/ws")
    async def websocket_endpoint(websocket: WebSocket):
        await manager.connect(websocket)
        try:
            while True:
                # Keep connection alive
                await websocket.receive_text()
        except WebSocketDisconnect:
            manager.disconnect(websocket)

    return app
