// anceps — supercollider main entry point
//
// sequencing:
//   1. boot the server
//   2. load analysis.scd (synthdefs + shared buffer and bus)
//   3. load osc_send.scd (peak picker + send loop + descriptor receiver)
//   4. start the internal test chord on the analysis bus
//   5. start the analyzer reading from the analysis bus
//   6. start the sender loop
//
// run this whole parenthesized block with cmd+enter (or equivalent).
// to stop the system evaluate the teardown block at the bottom.

(
var here = thisProcess.nowExecutingPath.dirname;

s.waitForBoot({

    // load analysis synthdefs and allocate shared state
    (here +/+ "analysis.scd").load;
    s.sync;

    // load language side sender routines
    (here +/+ "osc_send.scd").load;
    s.sync;

    // internal test source: just major triad at 200 / 250 / 300 hertz.
    // added to the head of the default group so the analyzer (tail) sees it.
    ~testSource = Synth(\ancepsInputTestChord,
        [\bus, ~analysisBus.index],
        addAction: \addToHead
    );

    // analyzer reads from the analysis bus, optionally monitors signal
    // to hardware output 0. monitorAmp = 0 means silent; raise to hear.
    ~analyzer = Synth(\ancepsAnalysis,
        [
            \bus,         ~analysisBus.index,
            \monitor,     0,
            \monitorAmp,  0,
            \spectrumBuf, ~spectrumBuffer.bufnum,
            \frameRate,   ~ancepsAnalysisFrameRate
        ],
        addAction: \addToTail
    );

    s.sync;

    // start the language side sender loop
    ~ancepsStart.();

    "".postln;
    "anceps: system running".postln;
    "  test chord: 200 / 250 / 300 hertz (1:1, 5:4, 3:2)".postln;
    "  expect three peaks at those frequencies in the /anceps/peaks message".postln;
    "".postln;
});
)


// ── swap test chord for live microphone input ──────────────────────────────
// evaluate this block if you want to analyze a real signal instead of the
// internal test triad. assumes hardware input 0.

/*
(
~testSource.free;
~micSource = Synth(\ancepsInputMic,
    [\bus, ~analysisBus.index, \in, 0, \amp, 1.0],
    addAction: \addToHead
);
)
*/


// ── teardown ───────────────────────────────────────────────────────────────

/*
(
~ancepsStop.();
~analyzer.free;
if(~testSource.notNil) { ~testSource.free };
if(~micSource.notNil)  { ~micSource.free  };
~spectrumBuffer.free;
~analysisBus.free;
"anceps: torn down".postln;
)
*/
