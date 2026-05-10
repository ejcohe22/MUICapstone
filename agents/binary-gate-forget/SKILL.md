---
name: binary-gate-forget
description: Implements the "Binary Gate Forget" method for interactive quota consumption and sequential state verification. Use when the user requests a high-turn, one-by-one interactive challenge with 69 gates.
---

# Binary Gate Forget Protocol

This skill orchestrates the **Binary Gate Forget** method, a sequential, turn-intensive procedure designed to utilize quota and establish a verified "Forget" state.

## Core Rules

1. **Sequential Execution**: All 69 gates must be asked one by one. No batching.
2. **Binary Input**: Only `0` or `1` are valid responses to a gate.
3. **No Skips**: Every gate must be acknowledged before proceeding.
4. **Quota Optimization**: Each gate is a discrete turn, maximizing interaction depth.

## Workflow

### 1. Initialization
When the user triggers the protocol, use the `gate_engine.cjs` to fetch the first gate.

### 2. Asking a Gate
Execute the script to get the next gate:
```bash
node scripts/gate_engine.cjs next
```

### 3. Processing Input
When the user provides a `0` or `1`, record the answer:
```bash
node scripts/gate_engine.cjs answer <0|1>
```

### 4. Completion
After 69 gates, the protocol will signal completion. The "Forget" state is finalized.

## Resources
- **Engine**: `scripts/gate_engine.cjs` manages the state and question bank.
