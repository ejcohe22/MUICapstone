# anceps (slopn't edition) 🎸🌌

**anceps** is an open-source, real-time artificial intelligence music visualization system. It bridges the gap between acoustic frequency ratios (Just Intonation) and high-fidelity generative visuals, rejecting AI "slop" in favor of deterministic, math-driven beauty.

## 🚀 The Architecture (The "Slopn't" Pipeline)

The system is built as a distributed high-signal pipeline:

1.  **Analysis (SuperCollider)**: Tracks spectral peaks and OSC-broadcasts raw frequency data.
2.  **Math Layer (GNU Octave)**: Analyzes ratios via **Extended Just Intonation**, calculating "strangeness" and prime-limit blends.
3.  **Bridge (Octave/HTTP)**: Maps harmonic descriptors to semantic prompts in real-time, now featuring the **Partch/Johnston Preset Engine**.
4.  **Inference Engine (FastAPI/Cloud Run)**: A GoF-architected server that generates images/video, featuring **Multi-User Consensus** and **Latent Slerp**.
5.  **Broadcast (Websockets)**: Real-time event bus that pushes visuals and **Mathematical Metadata** to all connected clients.
6.  **Renderer (p5.js/GCS)**: A browser-based visualizer with a real-time **"Strangeness" HUD** and lattice visualization.
7.  **Feedback (Synesthetic Loop)**: Visual flux, entropy, and recursion depth data are sent back to SuperCollider to modulate the **Blessed Synth**.

## 🌟 Major Additions & Advanced Features

### 1. Lexicographical Anarchist Agent
Located in `/agents/lexicographical_anarchist`, this agent intercepts and deconstructs standard semantic prompts. It transforms "slop" into mythological JI-mathematical descriptions, ensuring visual purity.

### 2. Multi-User Latent Consensus
Collaborative visualization is now live. Multiple users can submit latent vectors to the `/consensus` endpoints; the engine calculates a weighted harmonic average to drive the visual stream, creating a shared resonance.

### 3. Real-Time "Strangeness" HUD
The renderer now includes a high-fidelity Heads-Up Display. It visualizes the current **Strangeness** (harmonic distance), **Prime Limit**, and **Blend Name** in real-time, rendering the underlying mathematical lattice of the audio.

### 4. Partch/Johnston Preset Engine
A modular tuning system in GNU Octave. Swap between Harry Partch’s 43-tone scale and Ben Johnston’s extended Just Intonation philosophies on the fly via OSC commands on `/anceps/tuning/set`.

### 5. The "Blessed" Synesthetic Loop
The inference engine and frontend now feed deep cross-modal data back to SuperCollider (`sc/blessed_synth.scd`):
*   **Prime-Limit Phase Shimmer**: spectral peaks have a sub-ms jitter driven by the prime-limit of the ratio.
*   **^HARMONY Gravity**: YottaDB globals (`^HARMONY`) store long-term harmonic averages, biasing analysis toward stable previous states.
*   **Visual Entropy Noise Floor**: Pixel-level entropy from generated frames drives a resonant noise floor.
*   **Overtone Quantum Tunneling**: Stochastic amplitude swapping between overtones creates sharp timbral "glints."
*   **Recursive Spatial Expansion**: Audio stereo width expands and contracts based on the visual recursion depth (0-15 layers).

## 🤖 The Agentic Layer (Triple-Headed Orchestration)

1.  **Agent Agent**: The "sudo sudo" class orchestrator designed to harvest "data-carrots" (hierarchical globals) from YottaDB.
2.  **Binary Gate Forget**: A sequential, 69-step state verification protocol for interactive quota consumption.
3.  **Lexicographical Anarchist**: Aesthetic etymological deconstruction specialist for JI-semantic liberation.

## 🌍 Cloud Deployment

Anceps is cloud-native. Run heavy inference on Google Cloud while keeping analysis local.

- **Backend URL**: `https://anceps-inference-hxaum2omaa-uc.a.run.app`
- **Live Link**: [View Renderer](http://storage.googleapis.com/project-117f1e92-119b-47be-a05-anceps-renderer/index.html?backend=https://anceps-inference-hxaum2omaa-uc.a.run.app)

## 🛠️ Local Setup

1.  **Clone and Configure**: `git clone git@github.com:ejcohe22/anceps.git`
2.  **Start the Bridge**: `docker compose up octave`
3.  **Run SuperCollider**: Load `sc/main.scd` for analysis and `sc/blessed_synth.scd` for synesthesia.

## 📜 Philosophy: Slopn't
Anceps rejects "slop" (low-effort AI filler). Every visual frame is a direct, deterministic reflection of the harmonic lattice of the music. We don't just "generate" images; we render the math of the ear.

## ⚖️ License
MIT / Unlicense. This is free and unencumbered software released into the public domain.
