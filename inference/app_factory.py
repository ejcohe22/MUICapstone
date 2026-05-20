from typing import Union, List, Optional, Dict
import asyncio
import base64
from io import BytesIO

import numpy as np
from PIL import Image
from pythonosc import udp_client

from fastapi import FastAPI, Header, WebSocket, WebSocketDisconnect, BackgroundTasks, HTTPException

from inference.auth import verify_api_key
from inference.osc_validation import OSCValidationMiddleware
from inference.config import MODEL_NAME
from inference.models.registry import get_model
from inference.runtime.context import ModelContext
from inference.runtime.model_runner import ModelRunner
from inference.schemas import (
    ImageGenerationRequest, 
    VideoGenerationRequest,
    LatentInferenceRequest,
    ConsensusRequest,
    InferenceResponse,
    OutputType,
)

# Define a Union for all possible request types
AnyInferenceRequest = Union[
    ImageGenerationRequest, 
    VideoGenerationRequest, 
    LatentInferenceRequest
]

def slerp_vectors(v0: List[float], v1: List[float], t: float) -> List[float]:
    """Spherical linear interpolation between two vectors."""
    v0_np = np.array(v0)
    v1_np = np.array(v1)
    
    n0 = np.linalg.norm(v0_np)
    n1 = np.linalg.norm(v1_np)
    
    if n0 == 0 or n1 == 0:
        return ((1 - t) * v0_np + t * v1_np).tolist()
        
    v0_n = v0_np / n0
    v1_n = v1_np / n1
    
    dot = np.dot(v0_n, v1_n)
    dot = np.clip(dot, -1.0, 1.0)
    
    theta_0 = np.arccos(dot)
    if theta_0 < 1e-6:
        res = (1 - t) * v0_np + t * v1_np
    else:
        sin_theta_0 = np.sin(theta_0)
        theta_t = theta_0 * t
        s0 = np.sin(theta_0 - theta_t) / sin_theta_0
        s1 = np.sin(theta_t) / sin_theta_0
        res_n = s0 * v0_n + s1 * v1_n
        res = res_n * ((1 - t) * n0 + t * n1)
        
    return res.tolist()

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[WebSocket, str] = {}
        self.user_latents: Dict[str, List[float]] = {}
        self.consensus_vector: Optional[List[float]] = None

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[websocket] = user_id

    def disconnect(self, websocket: WebSocket):
        user_id = self.active_connections.pop(websocket, None)
        if user_id:
            # Only remove latent if no other connection for this user_id exists
            if user_id not in self.active_connections.values():
                self.user_latents.pop(user_id, None)

    def update_latent(self, user_id: str, latent: List[float]):
        self.user_latents[user_id] = latent

    def compute_consensus(self):
        if not self.user_latents:
            self.consensus_vector = None
            return
        
        latents = np.array(list(self.user_latents.values()))
        # Harmonic averaging (implemented as uniform weighted average for now)
        self.consensus_vector = np.mean(latents, axis=0).tolist()

    async def broadcast(self, message: dict):
        for websocket in list(self.active_connections.keys()):
            try:
                await websocket.send_json(message)
            except:
                pass

# Synesthetic Feedback Loop state
class FeedbackState:
    def __init__(self):
        self.last_brightness = 0.5
        self.osc_client = udp_client.SimpleUDPClient("127.0.0.1", 57120)

feedback_state = FeedbackState()

def analyze_and_send_osc(response: InferenceResponse):
    """
    Analyzes visual output for brightness and flux, sending to SuperCollider.
    """
    try:
        brightness = None
        if response.type == OutputType.IMAGE and isinstance(response.payload, str):
            brightness = _calculate_brightness(response.payload)
        elif response.type == OutputType.VIDEO and isinstance(response.payload, list) and len(response.payload) > 0:
            brightness = _calculate_brightness(response.payload[0])
            
        if brightness is not None:
            flux = abs(brightness - feedback_state.last_brightness)
            feedback_state.last_brightness = brightness
            
            feedback_state.osc_client.send_message("/visual/brightness", float(brightness))
            feedback_state.osc_client.send_message("/visual/flux", float(flux))
    except Exception:
        # Avoid crashing background tasks
        pass

def _calculate_brightness(b64_data: str) -> float:
    img_bytes = base64.b64decode(b64_data)
    img = Image.open(BytesIO(img_bytes)).convert("L")
    return float(np.mean(np.array(img)) / 255.0)

manager = ConnectionManager()

async def consensus_loop(manager: ConnectionManager):
    """Background task to periodically update the consensus vector."""
    while True:
        try:
            manager.compute_consensus()
        except Exception:
            pass
        await asyncio.sleep(1)

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
        background_tasks: BackgroundTasks,
        authorization: str = Header(None)
    ):
        """
        Main inference endpoint. Executes in background to avoid blocking.
        """
        verify_api_key(authorization)
        response = runner.generate(req)
        
        # Pass metadata from request to response
        if req.metadata:
            if response.metadata is None:
                response.metadata = {}
            response.metadata.update(req.metadata)
        
        # Feature 69: Async broadcasting
        background_tasks.add_task(manager.broadcast, response.dict())
        background_tasks.add_task(analyze_and_send_osc, response)
        
        return response

    @app.post("/latent", response_model=InferenceResponse)
    async def latent_interpolate(
        req: LatentInferenceRequest,
        background_tasks: BackgroundTasks,
        authorization: str = Header(None)
    ):
        """
        Feature 69: Latent Space Interpolation (Slerp)
        """
        verify_api_key(authorization)
        
        if req.target_vector and req.alpha is not None:
            req.latent_vector = slerp_vectors(req.latent_vector, req.target_vector, req.alpha)
            
        response = runner.generate(req) 

        # Pass metadata from request to response
        if req.metadata:
            if response.metadata is None:
                response.metadata = {}
            response.metadata.update(req.metadata)

        background_tasks.add_task(manager.broadcast, response.dict())
        background_tasks.add_task(analyze_and_send_osc, response)
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

this_is_a_silly_variable = 'yeehaw' + 42 # BOOM (re-broken for safety)
