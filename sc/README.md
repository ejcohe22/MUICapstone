# the supercollider layer of anceps

real time polyphonic audio analysis. extracts spectral descriptors and
polyphonic peak frequencies via parabolic interpolation, bundles them
atomically, and sends them over open sound control to the gnu octave
math layer.

## files

- `analysis.scd` — server side synthdefs and shared spectrum buffer
- `osc_send.scd` — language side peak picking and open sound control bundler
- `main.scd` — orchestrator that boots the server and starts everything

## what it sends

the sender emits one open sound control bundle per analysis frame at 30
hertz by default. each bundle carries three messages sharing one
timestamp. see `samhita/sandhi.md` for the full contract.

```
bundle (timestamp)
  /anceps/frame         [frameNumber, wallClockSeconds, sampleRate, windowSize]
  /anceps/descriptors   [loudness, centroid, flatness, onset]
  /anceps/peaks         [peakCount, freq0, mag0, freq1, mag1, ...]
```

## running

open `main.scd` in supercollider and evaluate the top parenthesized
block. the server boots, synthdefs load, the test chord starts, and the
sender begins streaming to `127.0.0.1:57121`.

## verifying it works

the internal test source generates a just major triad at 200 hertz:

- 1/1 → 200 hertz
- 5/4 → 250 hertz
- 3/2 → 300 hertz

the `/anceps/peaks` message should carry exactly three peaks at or very
close to these frequencies. parabolic interpolation handles the sub bin
accuracy so you should see values like 199.8, 249.6, 299.9 rather than
the nearest bin center multiples of 21.5 hertz.

to sanity check without the octave layer, open a terminal and run a
simple open sound control dump. a minimal python listener:

```python
# requires: uv run --with python-osc python this_file.py
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import BlockingOSCUDPServer

def dump(path, *args):
    print(path, args)

d = Dispatcher()
d.set_default_handler(dump)
BlockingOSCUDPServer(("127.0.0.1", 57121), d).serve_forever()
```

you should see frames arriving at roughly 30 hertz with peaks around
200 / 250 / 300 hertz.

## swapping to microphone input

after things are running, evaluate the mic swap block in `main.scd`.
this frees the test chord and spins up an input synth that routes
hardware channel 0 onto the analysis bus.

## tuning parameters

edit at the top of `analysis.scd`:

- `~ancepsAnalysisWindow` — fast fourier transform window in samples.
  larger gives better frequency resolution (bin width = sample rate /
  window) but worse time resolution. 2048 is a reasonable default for
  audio visualization. go to 4096 for finer just intonation work at the
  cost of latency.
- `~ancepsAnalysisHop` — overlap as normalized hop fraction.
  0.25 means 75% overlap. smaller values give smoother spectra at
  higher cpu cost.
- `~ancepsAnalysisFrameRate` — how often SendReply fires and how often
  the language side sends a bundle.

edit at the top of `osc_send.scd`:

- `~ancepsTarget` — net address for the downstream receiver. change
  the port or host if octave is not on localhost.
- `~ancepsMaxPeaks` — cap on peaks reported per frame.
- `~ancepsPeakFloorDb` — peaks quieter than this (relative to the
  frame maximum) are discarded. raise to reject more noise.

## known limits of this scaffold

- flux is not computed yet. easy to add language side by differencing
  consecutive magnitude arrays. dropped from the first pass to keep the
  server graph on pure vanilla supercollider with no sc3-plugins
  dependency.
- mel frequency cepstral coefficients are not computed. add via
  sc3-plugins `MFCC.kr` or compute language side.
- peak frequency tracking is per frame only. a partial that moves
  slightly between frames will register as two unrelated peaks rather
  than a single tracked partial. partial tracking over time is the
  natural next step once peak picking is verified.
- spectrum fetch is asynchronous so the spectrum used for peak picking
  is marginally newer than the descriptors that travel alongside it.
  acceptable for visualization; not acceptable for sub millisecond
  synchronous applications.
- no voice activity detection. peaks get emitted even in silence.
  consider gating on loudness below some threshold.

## next steps

1. write `octave/osc_receive.m` to listen on `127.0.0.1:57121` and
   pass the peak frequencies into the just intonation math functions.
   ratios come from pitch pairs so the receiver needs to form pairs
   from the incoming peak array and call `affect` and `blend` on the
   resulting ratios.
2. write flux on the language side (difference of consecutive
   magnitude arrays, sum of positive changes).
3. add partial tracking so a slowly moving pitch reads as one peak
   over time rather than a sequence of independent peaks.
