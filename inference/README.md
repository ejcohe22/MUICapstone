This project uses [uv](https://docs.astral.sh/uv/guides/install-python/) to manage the python environment.

## Linting

```bash
uv run ruff check .
uv run ruff format .
```

## Unit Tests

```bash
uv run pytest
```

## Running FastAPI server locally

```bash
uv run uvicorn inference.server:app --reload --port 8080
```
