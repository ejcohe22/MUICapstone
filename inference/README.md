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


running the Stable Diffusion XL Pipeline model:
```bash
## start the server - this will download weights the first time
MODEL_NAME=sdxl uv run uvicorn inference.server:app --reload


## make a request


```
$ curl -X POST "http://127.0.0.1:8000/generate" \                                                                 [20:48:44]
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-key" \
  -d '{
    "prompt": "a cinematic photo of a futuristic city at sunset"
  }'


```

and the response is a base64 image:

`{"success":true,"result":{"type":"image","image_base64":<long string>}}`


