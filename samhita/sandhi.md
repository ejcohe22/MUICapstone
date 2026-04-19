# sandhi

in sanskrit, sandhi means the rules that govern how sounds meet at
boundaries. in anceps, sandhi means the rules that govern how data
meets at layer boundaries. this document is the canonical open sound
control contract between layers of the pipeline. code in `sc/` must
emit these messages. code in `octave/` must accept these messages.
code in `renderer/` must interpret the output stream that octave
generates downstream.

everything here is versioned. changes to any message layout are
breaking changes. bump the contract version and document the migration.

---

## contract version

version 0.1 (initial draft, scaffold with supercollider sender and
pending octave receiver)

---

## transport

- udp
- default target: `127.0.0.1:57121`
- the supercollider sender may be pointed at any host:port via
  `~ancepsTarget`

---

## frame semantics

one bundle per analysis frame. the sender runs at a configurable frame
rate (30 hertz by default). every bundle is atomic. messages inside a
bundle share one timestamp and describe one frame of analysis. the
receiver must not treat messages from one bundle as belonging to
different frames.

frame numbers are monotonically increasing integers starting at zero
from sender startup. receivers should tolerate skipped frames (udp
drops) and should treat frame numbers only as ordering hints.

---

## messages

### /anceps/frame

frame metadata. always present.

```
/anceps/frame [frameNumber, wallClockSeconds, sampleRate, windowSize]
```

- `frameNumber` (int) — monotonic counter from sender startup
- `wallClockSeconds` (float) — sender wall clock at emission, seconds
- `sampleRate` (float) — audio sample rate in hertz
- `windowSize` (int) — fast fourier transform window in samples

### /anceps/descriptors

scalar spectral and temporal descriptors. always present.

```
/anceps/descriptors [loudness, centroid, flatness, onset]
```

- `loudness` (float) — root mean square amplitude, 0 to 1
- `centroid` (float) — spectral centroid in hertz
- `flatness` (float) — spectral flatness, 0 (tonal) to 1 (noisy)
- `onset` (int) — 1 if an onset was detected within the most recent
  frame window, else 0

future fields (reserved for a later contract version):
- `flux` (float) — spectral flux between this frame and the previous
- `pitch` (float) — strongest monophonic pitch estimate in hertz
- melFrequencyCepstralCoefficients (13 floats)

### /anceps/peaks

polyphonic peak data. always present. may carry zero peaks.

```
/anceps/peaks [peakCount, freq0, mag0, freq1, mag1, ..., freqN, magN]
```

- `peakCount` (int) — number of peaks in the message
- `freqK` (float) — frequency of peak k in hertz (sub bin accurate)
- `magK` (float) — linear magnitude of peak k

peaks are sorted by frequency ascending. peaks weaker than the frame
maximum minus `~ancepsPeakFloorDb` are dropped by the sender before
emission. the sender caps the count at `~ancepsMaxPeaks` (default 8).

---

## downstream expectations

the octave receiver on the other end of this contract is expected to:

1. pair peaks to form candidate ratios. for N peaks there are N choose
   2 candidate pairs. the octave layer decides which pairs are
   musically meaningful (for example by magnitude, by harmonic
   relation, or by proximity to tuning system entries).
2. feed ratios into `ji_math/affect.m` and `ji_math/blend.m` to
   derive strangeness and blend affect values.
3. feed peak frequencies into `ji_math/heterodyne.m` for combination
   tone analysis.
4. use the scalar descriptors (loudness, centroid, flatness, onset)
   as audio features that perturb the latent vector in the stylegan
   phase (see erik's plan: monzo primary signal, audio features
   secondary perturbation).

---

## invariants the sender guarantees

- bundles arrive atomically or not at all (udp may drop whole bundles)
- frame numbers are monotonic
- `/anceps/frame` is always emitted first within a bundle
- all three messages appear in every bundle even if peak count is zero
  or all descriptors are zero
- peaks are sorted by frequency ascending
- frequencies are in hertz, not cents and not bin indices

---

## invariants the sender does not guarantee

- consistent frame rate under system load
- delivery order of bundles across udp (in practice order is preserved
  on localhost but this is not guaranteed across networks)
- perceptually silent frames are skipped (they are not; silent frames
  still emit)
- peaks correspond to the same underlying partial across frames (no
  partial tracking; partials are matched per frame independently)

---

## extension policy

to add a new field to an existing message: bump the contract version,
append the field to the end of the argument list, and document the
default value receivers should assume if absent. receivers should read
arguments positionally and tolerate trailing unknown arguments.

to add a new message path: bump the contract version, document the
path, and treat it as optional until the next major contract version.

to change an existing field's semantics or position: this is a major
breaking change. bump the major version and document the migration.
