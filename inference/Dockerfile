# inference/Dockerfile
FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# copy project files first (layer cache)
COPY pyproject.toml ./
COPY inference/ ./inference/

# install the package properly — uv sees pyproject.toml, installs inference as a package
RUN uv sync

ENV HF_HOME=/app/.cache/huggingface

RUN useradd -m -u 1500 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["sh", "-c", "uv run uvicorn inference.server:app --host 0.0.0.0 --port ${PORT:-8000}"]
