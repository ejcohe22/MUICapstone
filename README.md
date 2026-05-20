# anceps (slopn't edition) 🎸🌌

**anceps** is an open-source, real-time artificial intelligence music visualization system. It bridges the gap between acoustic frequency ratios (Just Intonation) and high-fidelity generative visuals, rejecting AI "slop" in favor of deterministic, math-driven beauty.

## 🚀 The Architecture (The "Slopn't" Pipeline)

The system is built as a distributed high-signal pipeline:

1.  **Analysis (SuperCollider)**: Tracks spectral peaks and OSC-broadcasts raw frequency data.
2.  **Math Layer (GNU Octave)**: Analyzes ratios via **Extended Just Intonation**, now featuring **^BLUE Septimal Biasing** and **^RIFF Extraction**.
3.  **Bridge (Octave/HTTP)**: Maps harmonic descriptors to semantic prompts in real-time, featuring the **Partch/Johnston Preset Engine**.
4.  **Inference Engine (FastAPI/Cloud Run)**: A GoF-architected server that generates images/video, featuring **Multi-User Consensus** and **Data-Carrot Visual Jitter**.
5.  **Broadcast (Websockets)**: Real-time event bus that pushes visuals and **Mathematical Metadata** to all connected clients.
6.  **Renderer (p5.js/GCS)**: A browser-based visualizer with a real-time **"Strangeness" HUD** and lattice visualization.
7.  **Feedback (Synesthetic Loop)**: Visual flux, entropy, and recursion depth data are sent back to SuperCollider to modulate the **Blessed Synth**.

## 🌟 Major Additions & Advanced Features

### 1. Lexicographical Anarchist Agent
Located in `/agents/lexicographical_anarchist`, this agent intercepts and deconstructs standard semantic prompts. It transforms "slop" into mythological JI-mathematical descriptions, now featuring a **'Bluesy' Personality Mode**.

### 2. Multi-User Latent Consensus
Collaborative visualization is now live. Multiple users can submit latent vectors to the `/consensus` endpoints; the engine calculates a weighted harmonic average to drive the visual stream, creating a shared resonance.

### 3. Real-Time "Strangeness" HUD
The renderer now includes a high-fidelity Heads-Up Display. It visualizes the current **Strangeness** (harmonic distance), **Prime Limit**, and **Blend Name** in real-time, rendering the underlying mathematical lattice of the audio.

### 4. Partch/Johnston Preset Engine
A modular tuning system in GNU Octave. Swap between Harry Partch’s 43-tone scale, Ben Johnston’s extended JI, and the new **Septimal Blues Preset** on the fly via OSC.

### 5. The "Blessed" Synesthetic Loop
The inference engine and frontend now feed deep cross-modal data back to SuperCollider (`sc/blessed_synth.scd`):
*   **Prime-Limit Phase Shimmer**: spectral peaks have a sub-ms jitter driven by the prime-limit.
*   **^HARMONY Gravity**: YottaDB globals store long-term harmonic averages, biasing analysis toward stable states.
*   **Septimal Saturation**: Tube-distortion warming modulated by 7-limit septimal ratios.
*   **Visual Entropy Noise Floor**: Pixel-level entropy from generated frames drives a resonant noise floor.
*   **Overtone Quantum Tunneling**: Stochastic amplitude swapping between overtones creating timbral "glints."
*   **Recursive Spatial Expansion**: Audio stereo width expands based on visual recursion depth.

## 🔷 The Septimal YottaDB Expansion (7-Limit Blues)

In honor of the septimal ratio, 7 YottaDB-integrated features have been unleashed:

- **^BLUE Septimal Shift**: Frequency biasing toward "blue notes" stored in YottaDB globals.
- **^RIFF Generative Sequences**: Melodic fragments harvested from `^RIFF` globals and pushed to SuperCollider.
- **Septimal Saturation**: Warm, analog-style clipping driven by 7-limit harmonic dominance.
- **Data-Carrot Visual Jitter**: Node-depth analysis of YottaDB globals drives metadata-based visual jitter.
- **Septimal Blues Preset**: A custom JI scale (`1/1, 7/6, 4/3, 3/2, 7/4`) for deep-blue exploration.
- **^GHOST Overtone Echoes**: Ghostly spectral after-images in SuperCollider driven by YottaDB history.
- **'Bluesy' Agent Personality**: The Anarchist Agent enters a melancholic, soulful mode during septimal analysis.

## 🔢 The Undecimal Expansion (11:8 Ratio Updates)

In honor of the undecimal neutral fourth, 11 more subtle features have been integrated:

### 🎹 SuperCollider (Blessed Synth v11.8)
- **The Undecimal Ghost**: 11-limit complexity triggers a spectral freeze (`PV_MagFreeze`).
- **Lattice Panning**: Automatic spatialization of overtones based on their prime-limit (3, 5, 7, 11).
- **Strangeness-to-Granular**: High harmonic distance drives a stochastic granular cloud.
- **The 'Pure' Silence Gate**: Strict signal gating based on real-time JI rational approximation.
- **The 11/8 Pulsar**: An amplitude LFO derived from the 11/8 neutral fourth frequency.
- **Quantum Overtone Interference**: Partials beat against one another based on lattice proximity.
- **Recursive Buffer Feedback**: Visual recursion depth modulates a feedback delay line.

### 🐍 Python & Agents
- **Visual Entropy LFO**: Continuous modulation signal derived from generative image chaos.
- **Lexical Vibe-Shift**: The Anarchist Agent scales its linguistic entropy based on audio flux.

### 🐘 Octave & YottaDB
- **^HISTORY Harmonic Decay**: Historical resonance stored in YottaDB creates a sonic "patina."
- **Preset Morphing**: Smooth temporal interpolation between different tuning presets.

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
