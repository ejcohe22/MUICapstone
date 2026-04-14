# Open Sound Control API Contract

This is the message format for all communication between SuperCollider and GNU Octave. Code that sends or receives descriptors MUST conform to this spec. Do not invent new paths or change types without updating this contract.

## Namespace: /visualizer/descriptors

### Spectral descriptors

| Path | Type | Range | Description |
|------|------|-------|-------------|
| /spectral/centroid | float | 0.0–1.0 (normalized) | Brightness of the sound. Weighted mean of frequency spectrum. |
| /spectral/flux | float | 0.0–1.0 (normalized) | Rate of spectral change between successive frames. |
| /spectral/rms | float | 0.0–1.0 (normalized) | Root mean square amplitude (loudness). |
| /spectral/mfcc | float[13] | 13 coefficients | Mel frequency cepstral coefficients. Compact spectral envelope representation. |

### Pitch descriptors

| Path | Type | Range | Description |
|------|------|-------|-------------|
| /pitch/frequency | float | Hz | Fundamental frequency. |
| /pitch/confidence | float | 0.0–1.0 | Pitch detection confidence. |

### Onset descriptors

| Path | Type | Range | Description |
|------|------|-------|-------------|
| /onset/detected | int | 0 or 1 | Whether a new sonic event began. |
| /onset/strength | float | 0.0–1.0 | Onset strength. |

### Just intonation descriptors

| Path | Type | Range | Description |
|------|------|-------|-------------|
| /ji/harmonic_distance | float | 0.0–unbounded | Distance in harmonic space computed from prime factorization of the ratio. |
| /ji/prime_limit | int | 2, 3, 5, 7, 11, 13, 17, 19, 23… | Largest prime factor in the interval ratio. |
| /ji/consonance | float | 0.0–1.0 | Perceived consonance/dissonance from ratio complexity. |
| /ji/beating_frequency | float | Hz | Rate of beating between tones. Zero for pure just intonation intervals. |
| /ji/combination_tones | float[] | Hz | Detected combination tone frequencies (sum and difference tones). |
| /ji/ratio_numerator | int | | Numerator of the detected interval ratio. |
| /ji/ratio_denominator | int | | Denominator of the detected interval ratio. |
| /ji/cents_deviation | float | cents | Deviation from the nearest just ratio. |
