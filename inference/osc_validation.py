import json
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi.responses import JSONResponse

class OSCValidationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path == "/osc/validate" and request.method == "POST":
            try:
                body = await request.json()
                path = body.get("path")
                value = body.get("value")
                
                valid_paths = {
                    "/spectral/centroid": float,
                    "/spectral/flux": float,
                    "/spectral/rms": float,
                    "/spectral/mfcc": list,
                    "/pitch/frequency": float,
                    "/pitch/confidence": float,
                    "/onset/detected": int,
                    "/onset/strength": float,
                    "/ji/harmonic_distance": float,
                    "/ji/prime_limit": int,
                    "/ji/consonance": float,
                    "/ji/beating_frequency": float,
                    "/ji/combination_tones": list,
                    "/ji/ratio_numerator": int,
                    "/ji/ratio_denominator": int,
                    "/ji/cents_deviation": float,
                }
                
                if path not in valid_paths:
                    return JSONResponse(status_code=400, content={"error": f"Invalid OSC path: {path}"})
                
                expected_type = valid_paths[path]
                if expected_type is float and isinstance(value, int):
                    value = float(value)
                
                if not isinstance(value, expected_type):
                    return JSONResponse(status_code=400, content={"error": f"Invalid type for {path}. Expected {expected_type.__name__}"})
                    
                return JSONResponse(status_code=200, content={"status": "valid"})
            except Exception as e:
                return JSONResponse(status_code=400, content={"error": str(e)})
        
        response = await call_next(request)
        return response
