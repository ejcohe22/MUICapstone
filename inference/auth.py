from fastapi import HTTPException

from inference.config import API_KEY


def verify_api_key(auth_header: str | None):
    if not auth_header:
        raise HTTPException(status_code=401, detail="Missing API key")

    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid auth format")

    token = auth_header.split(" ")[1]

    if token != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")
