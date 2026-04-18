.PHONY: octave inference up down build help

help:
	@echo ""
	@echo "  anceps"
	@echo "  ──────────────────────────────────────────"
	@echo "  make octave     drop into octave math shell"
	@echo "  make inference  start inference server only"
	@echo "  make up         start full stack"
	@echo "  make down       stop everything"
	@echo "  make build      rebuild all images"
	@echo "  ──────────────────────────────────────────"
	@echo ""

# drop into an interactive octave shell with ji_math loaded
octave:
	docker build -t anceps-octave ./octave
	docker run --rm -it anceps-octave

# run inference server (dummy model by default, no weights needed)
inference:
	MODEL_NAME=$${MODEL_NAME:-dummy} docker compose up inference

# run inference with stable diffusion xl
sdxl:
	MODEL_NAME=sdxl docker compose up inference

# full stack
up:
	docker compose up

# full stack, rebuild images first
up-build:
	docker compose up --build

down:
	docker compose down

build:
	docker compose build
