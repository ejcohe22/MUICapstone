# MUICapstone Architecture

## Pipeline

Live audio → SuperCollider → (open sound control) → GNU Octave → (HTTP or open sound control) → Generative adversarial network inference server → (websocket or shared memory) → Real-time renderer

## Pipeline Stages

### 1. SuperCollider (audio engine)
Real-time digital signal processing. Extracts spectral descriptors and just intonation-specific descriptors. Hosts tuning system definitions as native objects. Outputs descriptor streams via open sound control.

### 2. GNU Octave (mapping layer)
Receives descriptors via open sound control. Computes just intonation-aware feature mappings. Translates descriptor space into latent space vectors using matrix operations and optimization routines. Handles fast fourier transform processing via built-in bindings.

### 3. Generative adversarial network inference server
Runs BigGAN (default) or StyleGAN3 (optional). Self-hosted on local graphics processing unit or cloud instance. Accepts latent vectors and class vectors via HTTP, returns generated frames.

### 4. Real-time renderer
Default: p5.js in browser (zero install). Alternatives: Processing (desktop), OpenFrameworks (C++), WebGL shader pipeline. Composites generated frames with reactive geometry driven by the live descriptor stream.

## vibecoded directory structure

```
capstone-ai-visualizer-open/
├── sc/                    SuperCollider audio engine
│   ├── boot.scd
│   ├── synths.scd
│   ├── analysis.scd
│   ├── osc_send.scd
│   ├── file_input.scd
│   └── tunings/
├── octave/                Mapping and computation layer
│   ├── osc_receive.m
│   ├── descriptor_normalize.m
│   ├── latent_map.m
│   ├── class_select.m
│   └── ji_math/
├── inference/             Generative adversarial network server
│   ├── server.py
│   ├── app_factory.py
│   ├── auth.py
│   ├── config.py
│   ├── schemas.py
│   ├── models/
│   ├── runtime/
│   └── tests/
├── renderer/              p5.js browser renderer
├── renderer-processing/   Processing desktop renderer (stub)
├── renderer-of/           OpenFrameworks renderer (stub)
├── docs/
├── examples/
└── tests/
```
