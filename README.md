# anceps
open source artificial intelligence music visualization of frequency ratios in real time.
analyzes audio through extended just intonation. generates live visuals with generative models. everything free and open.

## why
the original capstone visualizer (erik cohen, colby college) proved neural networks can drive meaningful visual output from acoustic analysis. this edition replaces proprietary maxmsp + runwayml with supercollider + gnu octave + self-hosted inference. adds deep just intonation support.

three beliefs:
(1) music tools should be free and open
(2) just intonation produces fundamentally different acoustic phenomena than equal temperament
(3) the best outcomes come from diverse people solving meaningful difficult shared problems

## design
- every layer replaceable (protocols not APIs)
- tuning awareness baked in (not optional)
- open source is the point (not a feature)
- real-time (instrument, not post-production)
- musicians first, programmers second

---

## how it works

```
live audio → supercollider → (osc) → gnu octave → (http) → inference server → (websocket) → renderer
```

see [architecture doc](claude_stuffs/architecture.md) for the full pipeline breakdown and directory structure.

the just intonation math layer lives in `octave/ji_math/` — see the [osc api contract](claude_stuffs/social-contract.md) for the message format between layers, and the [ji glossary](claude_stuffs/ji-glossary.md) for domain terminology.

---

## running it

requires [docker desktop](https://www.docker.com/products/docker-desktop/). that's it.

```bash
make help
```
```
  anceps
  ──────────────────────────────────────────
  make octave     drop into octave math shell
  make inference  start inference server only
  make up         start full stack
  make down       stop everything
  make build      rebuild all images
  ──────────────────────────────────────────
```

---

### try the octave math layer

```bash
make octave
```

drops you into an interactive octave shell with all `ji_math` functions loaded:

```octave
% strangeness of common intervals
affect('strangeness', 3, 2)    % fifth   → ~0.42
affect('strangeness', 7, 4)    % blue 7  → ~0.58
affect('strangeness', 11, 8)   % alien   → ~0.69

% blend character of composite ratios
blend('name', 15, 8)           % → 'power-sweetness'
blend('name', 385, 256)        % → 'sweetness-blue-alien'

% combination tones of a just fifth
heterodyne('products_ji', 3, 2, 200, 3)

% lattice navigation
lattice('neighbors', 1, 1, 7)  % one step from unison up to 7-limit
```

---

### run the inference server

```bash
make inference          # dummy model — instant, no weights needed
make sdxl               # stable diffusion xl (~7gb download on first run)
MODEL_NAME=stylegan make inference  # stylegan (requires local stylegan.pt)
```

server runs at `http://localhost:8000`. test it:

```bash
curl http://localhost:8000/health
# {"status":"ok","model":"dummy"}

curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-key" \
  -d '{"prompt": "a penrose triangle dissolving into fifths"}'
```

model weights are cached in a docker volume so subsequent starts are fast.

**gpu (nvidia):** uncomment the `deploy` block in `docker-compose.yml` and install the [nvidia container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

---

### run the full stack

```bash
make up
```

---

### local dev (inference server without docker)

requires [uv](https://docs.astral.sh/uv/guides/install-python/).

```bash
cd inference
uv run uvicorn inference.server:app --reload --port 8000

# tests
uv run pytest

# lint
uv run ruff check .
uv run ruff format .
```

---

## available models

| name | description | notes |
|------|-------------|-------|
| `dummy` | random noise, no weights | instant, good for testing |
| `sdxl` | stable diffusion xl | ~7gb download, needs gpu for speed |
| `svd` | stable video diffusion | image → video frames |
| `stylegan` | stylegan3 | requires local `stylegan.pt` weights |

set via `MODEL_NAME` environment variable.

---

## license
this is free and unencumbered software released into the public domain. anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means. in jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. we make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. we intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law. the software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and non-infringement. in no event shall the authors be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
