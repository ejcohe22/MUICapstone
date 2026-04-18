# inference/Dockerfile
FROM python:3.12-slim

# install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# system deps for torch / diffusers / PIL
RUN apt-get update && apt-get install -y \
    git \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# copy dependency files first (layer cache)
COPY requirements.txt ./

# install deps with uv into the system python (no venv needed in container)
RUN uv pip install --system -r requirements.txt

# diffusers missing from requirements — add it here
RUN uv pip install --system diffusers accelerate transformers

# copy source
COPY . .

# non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# huggingface cache survives restarts if you mount a volume here
ENV HF_HOME=/app/.cache/huggingface

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uv", "run", "--system", "uvicorn", "inference.server:app", "--host", "0.0.0.0", "--port", "8000"]
