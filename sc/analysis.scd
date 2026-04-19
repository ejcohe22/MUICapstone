// anceps — supercollider analysis layer (server side)
//
// loads three synthdefs and allocates the shared spectrum buffer:
//   ancepsInputMic       — routes microphone input onto the analysis bus
//   ancepsInputTestChord — internal polyphonic test signal for isolated debugging
//   ancepsAnalysis       — performs the fast fourier transform and reports
//                          cheap descriptors up to the language side via SendReply
//
// the spectrum buffer stays on the server. language side (osc_send.scd)
// fetches it on a clock to perform polyphonic peak picking with parabolic
// interpolation for sub bin frequency accuracy.

(
s.waitForBoot({

    // ── configuration ───────────────────────────────────────────────────────
    // these values also drive the language side sender. we hang them off the
    // current environment so osc_send.scd can read them without duplication.

    ~ancepsAnalysisWindow    = 2048;   // fast fourier transform window in samples
    ~ancepsAnalysisHop       = 0.25;   // normalized hop: 0.25 == 75% overlap
    ~ancepsAnalysisFrameRate = 30;     // hertz — how often SendReply fires and
                                       //         how often the language side pulls
                                       //         the spectrum and bundles output

    // ── shared buffers and buses ────────────────────────────────────────────

    ~spectrumBuffer = Buffer.alloc(s, ~ancepsAnalysisWindow);
    ~analysisBus    = Bus.audio(s, 1);

    // ── synth definitions ───────────────────────────────────────────────────

    // microphone source — reads from hardware input and writes to the analysis bus.
    // swap this in at run time if you want to analyze live audio.
    SynthDef(\ancepsInputMic, { |in = 0, bus = 0, amp = 1.0|
        Out.ar(bus, SoundIn.ar(in) * amp);
    }).add;

    // internal test source — sums three sine waves on a just major triad.
    // fundamental of 200 hertz with ratios 1/1, 5/4, 3/2 gives us three
    // peaks at 200, 250, and 300 hertz. the peak picker should find exactly
    // these three frequencies and nothing else.
    SynthDef(\ancepsInputTestChord, { |bus = 0, fundamental = 200, amp = 0.2|
        var ratios = [1.0, 5.0/4.0, 3.0/2.0];
        var partials = ratios.collect { |r| SinOsc.ar(fundamental * r) };
        var mix = Mix.new(partials) / partials.size;
        Out.ar(bus, mix * amp);
    }).add;

    // analyzer — reads from the analysis bus, runs the spectrum, and reports
    // descriptors up to the language side. also passes the signal through
    // to a monitor output so you can optionally listen while debugging.
    SynthDef(\ancepsAnalysis, { |bus = 0, monitor = 0, monitorAmp = 0,
                                 spectrumBuf = 0, replyId = 1000,
                                 frameRate = 30|
        var signal, spectrum, loudness, centroid, flatness, onset, triggerRate;

        signal = In.ar(bus);

        // compute the spectrum into the shared buffer. language side will
        // fetch this buffer asynchronously.
        spectrum = FFT(spectrumBuf, signal, hop: 0.25, wintype: 1);

        // cheap server side descriptors that ride along with every frame.
        // flux intentionally omitted — it is cheaper to compute language side
        // by differencing consecutive spectrum fetches and that keeps the
        // server graph to vanilla supercollider (no sc3-plugins needed).
        loudness = Amplitude.kr(signal);
        centroid = SpecCentroid.kr(spectrum);
        flatness = SpecFlatness.kr(spectrum);

        // onset detector. latches the trigger across one analysis frame so
        // the reported value is 1 if an onset happened recently, else 0.
        onset = Trig1.kr(Onsets.kr(spectrum, 0.3, \rcomplex), frameRate.reciprocal);

        // fire the reply at the analysis frame rate. values arrive language
        // side via OSCdef on the path /anceps/descriptors.
        triggerRate = Impulse.kr(frameRate);
        SendReply.kr(triggerRate, '/anceps/descriptors',
            [loudness, centroid, flatness, onset], replyId);

        Out.ar(monitor, signal.dup * monitorAmp);
    }).add;

    s.sync;
    "anceps analysis: synthdefs loaded, spectrum buffer ready".postln;
});
)
