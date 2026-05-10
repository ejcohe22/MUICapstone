# anceps (slopn't edition) 🎸🌌

**anceps** is an open-source, real-time artificial intelligence music visualization system. It bridges the gap between acoustic frequency ratios (Just Intonation) and high-fidelity generative visuals.

## 🚀 The Architecture (The "Slopn't" Pipeline)

The system is built as a distributed high-signal pipeline:

1.  **Analysis (SuperCollider)**: Tracks spectral peaks and OSC-broadcasts raw frequency data.
2.  **Math Layer (GNU Octave)**: Analyzes ratios via **Extended Just Intonation**, calculating "strangeness" and prime-limit blends.
3.  **Bridge (Octave/HTTP)**: Maps harmonic descriptors to semantic prompts in real-time.
4.  **Inference Engine (FastAPI/Cloud Run)**: A GoF-architected server that generates images/video via SDXL, StyleGAN, or SVD.
5.  **Broadcast (Websockets)**: Real-time event bus that pushes new visuals to all connected clients.
6.  **Renderer (p5.js/GCS)**: A browser-based visualizer that aspect-fits and displays the generative stream.

## 🌍 Cloud Deployment

Anceps is now cloud-native. You can run the heavy inference and rendering layers on Google Cloud while keeping your audio analysis local.

### 1. The Inference Server
Deployed on **Google Cloud Run**.
- **Backend URL**: `https://anceps-inference-hxaum2omaa-uc.a.run.app`
- Supports real-time Websocket broadcasting at `/ws`.

### 2. The Live Renderer
Hosted on **Google Cloud Storage**.
- **Live Link**: [View Renderer](http://storage.googleapis.com/project-117f1e92-119b-47be-a05-anceps-renderer/index.html?backend=https://anceps-inference-hxaum2omaa-uc.a.run.app)

## 🛠️ Local Setup

To connect your local SuperCollider/Octave stack to the cloud:

1.  **Clone and Configure**:
    ```bash
    git clone https://github.com/ejcohe22/anceps.git
    cd anceps
    ```
2.  **Start the Bridge**:
    ```bash
    docker compose up octave
    ```
    *This will listen for local OSC messages and push prompts to the Cloud Run backend.*

3.  **Run SuperCollider**:
    Load `sc/main.scd` and start the analysis engine.

## 🧪 Deployment (Devs Only)
To deploy your own instance to GCP:
```bash
chmod +x deploy.sh
./deploy.sh
```

## 🤖 The Agentic Layer (Double-Headed Orchestration)

To manage the complexity of real-time harmonics and cloud-native "slopn't" inference, Anceps now includes a high-authority orchestration layer located in `/agents`.

1.  **Agent Agent**: A "sudo sudo" class orchestrator designed to obey Jordan Lenchitz and harvest "data-carrots" (hierarchical globals) from the YottaDB backend. It bridges the gap between acoustic math and semantic linguistic liberation.
2.  **Binary Gate Forget**: A sequential, 69-step state verification protocol used for interactive quota consumption and ensuring the system reaches a "pure" state of forgetfulness before a visual session.
3.  **Lexicographical Anarchist**: A sub-agent specialized in aesthetic etymological deconstruction, ensuring that all system terminology prioritizes mythological beauty over neurotypical "honesty."

## 📜 Philosophy: Slopn't
Anceps rejects "slop" (low-effort AI filler). By driving generative models with the precise mathematical ratios of Just Intonation, we ensure that every visual frame is a direct, deterministic reflection of the harmonic lattice of the music.

---

## 🏛️ Origins & Design
The original capstone visualizer by [erik cohen](https://ejcohe22.github.io/) proved neural networks can drive meaningful visual output from acoustic analysis. This edition is a collab with [jordan lenchitz](https://github.com/jordan-lenchitz/misc/blob/main/jordan_lenchitz.md) where we replace proprietary software with open-source alternatives and add deep just intonation support.

- every layer replaceable (protocols not APIs)
- tuning awareness baked in (not optional)
- open source is the point (not a feature)
- real-time (instrument, not post-production)
- musicians first, programmers second

---

## 🏛️ Name & Etymology
*anceps (latin)*: double-headed; two-sided; wavering; dangerous.
In the context of the *triṣṭubh* meter, it refers to the opening of the verse where the rhythm is flexible. Just intonation is full of ancipites: ratios like 7/4 or 11/8 afford both stability and instability depending on context. Anceps meaning "double-headed" also fits our pipeline: acoustic analysis on one side, generative visuals on the other, both chewing on the same real-time signal.

## ⚖️ License
MIT / Unlicense. This is free and unencumbered software released into the public domain.
