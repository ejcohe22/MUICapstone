from typing import Union, List, Optional, Dict
import asyncio
import base64
import httpx
from io import BytesIO

import numpy as np
from PIL import Image
from scipy.signal import convolve2d
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
from agents.lexicographical_anarchist.agent import deconstruct_prompt

YDB_API_BASE = "http://localhost:8080/api"

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
        self.last_entropy = 0.5
        self.osc_client = udp_client.SimpleUDPClient("127.0.0.1", 57120)
        self.lfo_phase = 0.0
        self.latest_genotype: Optional[float] = None

feedback_state = FeedbackState()

async def entropy_lfo_loop():
    """Generates a continuous LFO signal whose frequency is modulated by visual entropy."""
    while True:
        try:
            # Frequency ranges from 0.1Hz to 5.0Hz based on entropy
            freq = feedback_state.last_entropy * 4.9 + 0.1
            # Update phase (assuming 20Hz update rate, so 0.05s steps)
            dt = 0.05
            feedback_state.lfo_phase = (feedback_state.lfo_phase + freq * dt) % 1.0
            lfo_val = (np.sin(2 * np.pi * feedback_state.lfo_phase) + 1) / 2
            feedback_state.osc_client.send_message("/visual/entropy_lfo", float(lfo_val))
        except Exception:
            pass
        await asyncio.sleep(0.05)

async def data_carrot_loop(manager: ConnectionManager):
    """
    Simulates 'harvesting data-carrots' from YottaDB and broadcasts 
    'visual_jitter' to the renderer via WebSocket.
    """
    while True:
        try:
            # Simulate querying a random node depth (e.g., 0-64)
            simulated_depth = np.random.uniform(0, 64)
            # Map depth to visual_jitter (0.0-1.0)
            visual_jitter = np.clip(simulated_depth / 64.0, 0.0, 1.0)
            
            # Broadcast to renderer via WebSocket
            await manager.broadcast({
                "type": "metadata_update",
                "field": "visual_jitter",
                "value": float(visual_jitter)
            })
        except Exception:
            pass
        # Harvest every 0.8 seconds for a rhythmic "data-shimmer"
        await asyncio.sleep(0.8)

async def genetic_algo_loop(manager: ConnectionManager):
    """
    Simulates 'genetic crossover' between previous prompt results stored in YottaDB globals.
    Broadcasts 'mutation_rate' metadata via WebSocket.
    """
    while True:
        try:
            # Simulate fetching 'genotypes' from YottaDB
            async with httpx.AsyncClient() as client:
                # In a real scenario, we'd fetch actual prompt data from a global like ^PROMPTS
                # For now, we simulate the 'harvest'
                m_code = 'K ^TMP("ALGO") S ^TMP("ALGO",$I(^TMP("ALGO")))=$R(100)'
                await client.post(f"{YDB_API_BASE}/execute", json={"mCode": m_code})
            
            # Simulate mutation rate calculation
            mutation_rate = np.random.uniform(0.01, 0.17)
            feedback_state.latest_genotype = float(mutation_rate)
            
            await manager.broadcast({
                "type": "metadata_update",
                "field": "mutation_rate",
                "value": float(mutation_rate)
            })
        except Exception:
            pass
        # Rhythmic evolution every 1.7 seconds
        await asyncio.sleep(1.7)

def analyze_and_send_osc(response: InferenceResponse):
    """
    Analyzes visual output for brightness, flux, entropy, and chaos, sending to SuperCollider.
    Also calculates 'High-Frequency Noise' (grain) density.
    """
    try:
        brightness = None
        entropy = None
        grain = None
        if response.type == OutputType.IMAGE and isinstance(response.payload, str):
            brightness = _calculate_brightness(response.payload)
            entropy = _calculate_entropy(response.payload)
            grain = _calculate_grain(response.payload)
        elif response.type == OutputType.VIDEO and isinstance(response.payload, list) and len(response.payload) > 0:
            brightness = _calculate_brightness(response.payload[0])
            entropy = _calculate_entropy(response.payload[0])
            grain = _calculate_grain(response.payload[0])
            
        if brightness is not None:
            flux = abs(brightness - feedback_state.last_brightness)
            feedback_state.last_brightness = brightness
            
            feedback_state.osc_client.send_message("/visual/brightness", float(brightness))
            feedback_state.osc_client.send_message("/visual/flux", float(flux))

        if entropy is not None:
            chaos = abs(entropy - feedback_state.last_entropy)
            feedback_state.last_entropy = entropy
            
            feedback_state.osc_client.send_message("/visual/entropy", float(entropy))
            feedback_state.osc_client.send_message("/visual/chaos", float(chaos))

        if grain is not None:
            feedback_state.osc_client.send_message("/visual/grain", float(grain))
    except Exception:
        # Avoid crashing background tasks
        pass

def _calculate_brightness(b64_data: str) -> float:
    img_bytes = base64.b64decode(b64_data)
    img = Image.open(BytesIO(img_bytes)).convert("L")
    return float(np.mean(np.array(img)) / 255.0)

def _calculate_entropy(b64_data: str) -> float:
    """Calculates normalized pixel entropy (0.0-1.0)."""
    img_bytes = base64.b64decode(b64_data)
    img = Image.open(BytesIO(img_bytes)).convert("L")
    arr = np.array(img).flatten()
    hist, _ = np.histogram(arr, bins=256, range=(0, 255), density=True)
    hist = hist[hist > 0]
    # Max entropy for 8-bit image is 8 bits (log2(256))
    return float(-np.sum(hist * np.log2(hist)) / 8.0)

def _calculate_grain(b64_data: str) -> float:
    """Calculates High-Frequency Noise (grain) density using variance of Laplacian."""
    img_bytes = base64.b64decode(b64_data)
    img = Image.open(BytesIO(img_bytes)).convert("L")
    arr = np.array(img, dtype=np.float32)
    # Simple Laplacian kernel
    kernel = np.array([[0, 1, 0], [1, -4, 1], [0, 1, 0]])
    laplacian = convolve2d(arr, kernel, mode='same')
    # Normalized variance as grain density
    return float(np.var(laplacian) / 10000.0)

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

        # Traditional 17 Expansion: Genetic Prompt Mutation
        if isinstance(req, ImageGenerationRequest):
            vibe = feedback_state.latest_genotype or 0.5
            # Tuning defaults to traditional_17 for this expansion push
            tuning = "traditional_17"
            # Oasis Silence Mode: check audio duration (mocked via genotype if not present)
            audio_duration = req.metadata.get("audio_duration", 2.0) if req.metadata else 2.0
            
            req.prompt = deconstruct_prompt(req.prompt, vibe=vibe, tuning=tuning, audio_duration=audio_duration)
        
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
    async def websocket_endpoint(websocket: WebSocket, user_id: Optional[str] = None):
        if not user_id:
            user_id = f"user_{id(websocket)}"
        await manager.connect(websocket, user_id)
        try:
            while True:
                data = await websocket.receive_json()
                if isinstance(data, dict) and data.get("type") == "depth":
                    depth = data.get("value", 0)
                    feedback_state.osc_client.send_message("/site/depth", float(depth))
        except (WebSocketDisconnect, Exception):
            manager.disconnect(websocket)

    @app.on_event("startup")
    async def startup_event():
        asyncio.create_task(entropy_lfo_loop())
        asyncio.create_task(data_carrot_loop(manager))
        asyncio.create_task(genetic_algo_loop(manager))

    return app

this_is_a_silly_variable = 'yeehaw' + 42 # BOOM (re-broken for safety)
