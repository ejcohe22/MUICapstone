// anceps — spectral flux module
//
// flux is the sum of positive magnitude changes between consecutive
// spectrum frames, normalized by loudness so it is level invariant.
// rises on onsets and new partials, falls toward zero on steady state
// tones, ignores decaying content because negative changes are clamped.
//
// this file is a self contained module. evaluate the main paren block
// to define the three closures on the current environment. osc_send.scd
// then calls ~ancepsFluxCompute once per frame and uses the return
// value as the new fifth arg in /anceps/descriptors.
//
// contract impact: appends flux to /anceps/descriptors. non breaking
// per the samhita sandhi extension policy. bumps contract v0.1 to v0.2.


// ══════════════════════════════════════════════════════════════════════════
// module definition
// ══════════════════════════════════════════════════════════════════════════

(
// state held on the environment so the closures and osc_send.scd can
// share it. nil until init is called.
~ancepsPrevMags = nil;
~ancepsFluxNormFloor = 0.0001;


// ── init ──────────────────────────────────────────────────────────────────
// call once at sender setup from ~ancepsStart. safe to call repeatedly.
~ancepsFluxInit = {
    ~ancepsPrevMags = nil;
    "anceps flux: init".postln;
};


// ── reset ─────────────────────────────────────────────────────────────────
// call from ~ancepsStop to drop held memory.
~ancepsFluxReset = {
    ~ancepsPrevMags = nil;
    "anceps flux: reset".postln;
};


// ── compute ───────────────────────────────────────────────────────────────
// call once per fetch frame with the current positive-half magnitude
// array and the current loudness value. returns a scalar in roughly
// [0, 10], with values below 0.01 reading as steady state and spikes
// indicating transients or newly entering partials.
~ancepsFluxCompute = { |mags, loudness|
    var diff, positiveOnly, raw, normalized, result;

    // first frame: no previous, seed zeros of the right length so the
    // first flux value is simply the sum of positive magnitudes.
    if (~ancepsPrevMags.isNil) {
        ~ancepsPrevMags = Array.fill(mags.size, 0);
    };

    // defensive: if the spectrum size changed under us (window resize),
    // zero out history so we do not compute against stale bins.
    if (~ancepsPrevMags.size != mags.size) {
        ~ancepsPrevMags = Array.fill(mags.size, 0);
    };

    // elementwise difference, clamp to positive
    diff = mags - ~ancepsPrevMags;
    positiveOnly = diff.collect({ |v| max(v, 0) });
    raw = positiveOnly.sum;

    // level invariant via loudness floor so a silent frame does not
    // divide by zero and a quiet onset still registers
    normalized = raw / max(loudness, ~ancepsFluxNormFloor);

    // clamp upper bound for friendly downstream values
    result = min(normalized, 10);

    // remember this frame for next time. copy is important because the
    // caller may mutate mags in place elsewhere.
    ~ancepsPrevMags = mags.copy;

    result
};

"anceps flux module loaded".postln;
)


// ══════════════════════════════════════════════════════════════════════════
// integration with osc_send.scd
// ══════════════════════════════════════════════════════════════════════════
//
// inside the ~ancepsStart block that allocates the spectrum buffer, add
// one line near the end:
//
//   ~ancepsFluxInit.();
//
// inside the fetch clock routine, after ~mags is decoded and ~loudness
// has been computed, add one line:
//
//   ~flux = ~ancepsFluxCompute.(~mags, ~loudness);
//
// in the bundle construction block, extend the descriptors message from
// four args to five:
//
//   ['/anceps/descriptors', ~loudness, ~centroid, ~flatness, ~onset, ~flux]
//
// inside ~ancepsStop add one line alongside the other cleanup:
//
//   ~ancepsFluxReset.();


// ══════════════════════════════════════════════════════════════════════════
// in-file test harness
// ══════════════════════════════════════════════════════════════════════════
// uncomment and evaluate to verify the module in isolation. simulates
// five frames: silence, tone onset, steady tone, new partial arriving,
// then decay. expect flux near zero on silence and steady state, a
// spike on onset and new-partial frames, and zero on decay even though
// the spectrum changes a lot (negative diffs are clamped out).

/*
(
~ancepsFluxInit.();

"frame 1 (silence):        flux = ".post;
~ancepsFluxCompute.([0, 0, 0, 0, 0, 0, 0, 0], 0.0001).postln;

"frame 2 (tone onset):     flux = ".post;
~ancepsFluxCompute.([0, 0, 0, 1.0, 0.3, 0.1, 0, 0], 1.0).postln;

"frame 3 (steady):         flux = ".post;
~ancepsFluxCompute.([0, 0, 0, 1.0, 0.3, 0.1, 0, 0], 1.0).postln;

"frame 4 (new partial):    flux = ".post;
~ancepsFluxCompute.([0, 0, 0, 1.0, 0.3, 0.8, 0.2, 0], 1.0).postln;

"frame 5 (decay):          flux = ".post;
~ancepsFluxCompute.([0, 0, 0, 0.3, 0.1, 0.2, 0.05, 0], 0.5).postln;

~ancepsFluxReset.();
)
*/


// ══════════════════════════════════════════════════════════════════════════
// verifying in the live pipeline
// ══════════════════════════════════════════════════════════════════════════
//
// with the internal test triad running, watch the octave side default
// printer. flux should be high on the very first frame after the test
// source starts (everything is a new partial), drop rapidly to near
// zero as the triad settles, and spike again whenever you free and
// respawn the source.
//
// if flux stays at nan on the octave side, the descriptors message is
// still shipping four args. double check osc_send.scd was updated.
// if flux is always exactly zero after frame one, ~ancepsPrevMags is
// being nil'd somewhere it should not be. check that ~ancepsFluxInit
// is only called at startup and not inside the fetch routine.
