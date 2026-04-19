// anceps — supercollider open sound control sender (language side)
//
// runs on a self scheduling clock at the analysis frame rate.
// each tick:
//   1. fetches the current spectrum buffer from the server
//   2. decodes the fast fourier transform complex layout into magnitudes
//   3. picks the top N polyphonic peaks with parabolic interpolation
//   4. bundles frame metadata, cached descriptors, and peaks into a
//      single timestamped open sound control bundle
//   5. sends the bundle to the target (octave) and schedules the next tick
//
// the SendReply from the analyzer synth populates the descriptor cache
// out of band. we latch the most recent values at send time so every
// frame the sender emits carries fresh peaks plus the freshest available
// descriptors.

(
// ── configuration ──────────────────────────────────────────────────────────

~ancepsTarget        = NetAddr("127.0.0.1", 57121);   // octave listens here
~ancepsMaxPeaks      = 8;
~ancepsPeakFloorDb   = -40;                            // peaks this much below
                                                       // the strongest peak get dropped
~ancepsFrameCounter  = 0;
~ancepsLastDescriptors = [0.0, 0.0, 0.0, 0];           // loudness, centroid,
                                                       // flatness, onset

// defaults if analysis.scd has not been loaded yet. harmless fallback values.
~ancepsAnalysisFrameRate = ~ancepsAnalysisFrameRate ? 30;
~ancepsAnalysisWindow    = ~ancepsAnalysisWindow    ? 2048;

// ── descriptor intake ──────────────────────────────────────────────────────
// arrives from SendReply on the analyzer synth. message layout is:
//   [path, nodeId, replyId, loudness, centroid, flatness, onset]

OSCdef(\ancepsDescriptors, { |msg|
    ~ancepsLastDescriptors = msg[3..];
}, '/anceps/descriptors');

// ── spectrum decoder ───────────────────────────────────────────────────────
// supercollider fast fourier transform buffer layout for N frames:
//   index 0             : direct current bin (real only)
//   index 1             : nyquist bin (real only)
//   index 2k, 2k+1      : real and imaginary parts for bin k (k from 1 upward)
// returns a magnitude array of length N/2

~ancepsDecodeMagnitudes = { |fftData|
    var half = fftData.size / 2;
    var magnitudes = Array.newClear(half);
    magnitudes[0]        = fftData[0].abs;
    magnitudes[half - 1] = fftData[1].abs;
    (1 .. (half - 2)).do { |binIdx|
        var realPart = fftData[2 * binIdx];
        var imagPart = fftData[(2 * binIdx) + 1];
        magnitudes[binIdx] = (realPart.squared + imagPart.squared).sqrt;
    };
    magnitudes;
};

// ── peak picker ────────────────────────────────────────────────────────────
// parabolic interpolation around a local maximum at bin k using neighbors
// at k-1 and k+1. returns the sub bin location and the interpolated magnitude.

~ancepsParabolic = { |magLeft, magCenter, magRight, binK|
    var denom = magLeft - (2 * magCenter) + magRight;
    var delta = if(denom.abs < 1e-12) { 0.0 } {
        0.5 * (magLeft - magRight) / denom
    };
    var interpolatedMag = magCenter - (0.25 * (magLeft - magRight) * delta);
    [binK + delta, interpolatedMag];
};

// scans the magnitude array for local maxima above the threshold, applies
// parabolic interpolation, keeps the strongest `maxPeaks`, and returns them
// sorted by frequency ascending as [freqHz, magnitude] pairs.

~ancepsFindPeaks = { |magnitudes, sampleRate, fftSize, maxPeaks, floorDb|
    var candidates = List.new;
    var maxMag = magnitudes.maxItem;
    var threshold = maxMag * floorDb.dbamp;
    var binToHz = sampleRate / fftSize;

    (1 .. (magnitudes.size - 2)).do { |binIdx|
        var magLeft   = magnitudes[binIdx - 1];
        var magCenter = magnitudes[binIdx];
        var magRight  = magnitudes[binIdx + 1];
        if((magCenter > magLeft)
            and: { magCenter > magRight }
            and: { magCenter > threshold }) {
            var interp = ~ancepsParabolic.(magLeft, magCenter, magRight, binIdx);
            candidates.add([interp[0] * binToHz, interp[1]]);
        };
    };

    candidates.array
        .sort { |a, b| a[1] > b[1] }    // strongest first
        .keep(maxPeaks)                 // cap at maxPeaks
        .sort { |a, b| a[0] < b[0] };   // re sort by frequency ascending
};

// ── send loop ──────────────────────────────────────────────────────────────
// self scheduling via AppClock. the next tick schedules itself from inside
// the spectrum fetch callback so we never pile up if the server is slow.

~ancepsRunning = false;

~ancepsTick = {
    if(~ancepsRunning) {
        ~spectrumBuffer.getn(0, ~spectrumBuffer.numFrames, { |fftData|
            var magnitudes = ~ancepsDecodeMagnitudes.(fftData);
            var peaks = ~ancepsFindPeaks.(
                magnitudes,
                s.sampleRate,
                ~ancepsAnalysisWindow,
                ~ancepsMaxPeaks,
                ~ancepsPeakFloorDb
            );
            var peakPayload = peaks.collect { |pair| pair }.flat;
            var wallClockSeconds = SystemClock.seconds;

            // atomic bundle. three messages go out with a single timestamp
            // so the downstream side can treat them as one frame.
            ~ancepsTarget.sendBundle(0,
                ['/anceps/frame',
                    ~ancepsFrameCounter,
                    wallClockSeconds,
                    s.sampleRate,
                    ~ancepsAnalysisWindow],
                ['/anceps/descriptors'] ++ ~ancepsLastDescriptors,
                ['/anceps/peaks', peaks.size] ++ peakPayload
            );

            ~ancepsFrameCounter = ~ancepsFrameCounter + 1;

            // schedule the next tick from inside the completion callback.
            // returning nil from the scheduled function stops rescheduling.
            AppClock.sched(~ancepsAnalysisFrameRate.reciprocal, {
                ~ancepsTick.();
                nil
            });
        });
    };
};

~ancepsStart = {
    if(~ancepsRunning.not) {
        ~ancepsRunning = true;
        ~ancepsTick.();
        "anceps sender: running".postln;
        "  target: ".post; ~ancepsTarget.postln;
        "  rate:   ".post; ~ancepsAnalysisFrameRate.post; " hertz".postln;
    };
};

~ancepsStop = {
    ~ancepsRunning = false;
    "anceps sender: stopped".postln;
};

"anceps open sound control sender: loaded (call ~ancepsStart.() to begin)".postln;
)
