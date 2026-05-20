// anceps — blessed resynthesis synth
//
// this module implements 'Prime-Limit Phase Shimmer' and 'Overtone Quantum Tunneling'
// for a resynthesis engine. it supports up to 8 partials and is designed to be
// modulated via OSC messages.
//
// features:
//   - Phase Shimmer: sub-millisecond phase jitter per partial, intended to be
//     driven by the prime-limit of the ratio in the future.
//   - Quantum Tunneling: stochastic amplitude swapping between partials (3rd and 7th).

(
s.waitForBoot({

    // ── synth definition ───────────────────────────────────────────────────

    SynthDef(\ancepsBlessedSynth, {
        arg out = 0, amp = 0.5, gate = 1, shimmer = 0.01, tunneling_prob = 1.0,
            visual_entropy = 0, visual_chaos = 0, depth = 0;
        
        // support up to 8 partials, matching ~ancepsMaxPeaks in osc_send.scd
        var freqs = \freqs.kr(Array.fill(8, 0));
        var mags = \mags.kr(Array.fill(8, 0));
        
        var partials, sig, trigger, toggle, swappedMags, noise;

        // ── Overtone Quantum Tunneling ──────────────────────────────────────
        // logic (using Dust) that periodically and suddenly swaps the amplitudes 
        // of two partials (e.g., the 3rd and 7th harmonic, indices 2 and 6) 
        // based on a 'tunneling_prob' argument.
        trigger = Dust.kr(tunneling_prob);
        toggle = ToggleFF.kr(trigger);
        
        swappedMags = Array.newClear(8);
        8.do { |i|
            swappedMags[i] = case
                { i == 2 } { Select.kr(toggle, [mags[2], mags[6]]) }
                { i == 6 } { Select.kr(toggle, [mags[6], mags[2]]) }
                { true } { mags[i] };
        };

        // ── Visual Entropy Noise Floor ─────────────────────────────────────
        // PinkNoise filtered by entropy, mapped to subtle "hiss"
        noise = PinkNoise.ar(visual_entropy * 0.05);
        noise = BPF.ar(noise, visual_chaos.linexp(0, 1, 100, 12000), 0.5);

        // ── Prime-Limit Phase Shimmer ───────────────────────────────────────
        // For each partial, add a tiny phase jitter (sub-millisecond). 
        // The amount of jitter is controllable via the 'shimmer' argument.
        partials = Array.newClear(8);
        8.do { |i|
            var f = freqs[i];
            var m = swappedMags[i];
            var jitter, phase;
            
            // tiny phase jitter (sub-millisecond). 0.001s is 1ms.
            // this is intended to be driven by the prime-limit of the ratio in the future.
            jitter = WhiteNoise.ar(shimmer * 0.001);
            phase = 2 * pi * f * jitter;
            
            partials[i] = SinOsc.ar(f, phase) * m;
        };

        // ── Recursive Spatial Expansion ─────────────────────────────────────
        // Use 'depth' to modulate the Stereo width of the synth output (0 = mono, 15 = wide stereo)
        sig = Splay.ar(partials + (noise/8), spread: depth.linlin(0, 15, 0, 1));
        sig = sig * amp;
        sig = sig * EnvGen.kr(Env.asr(0.1, 1, 0.2), gate, doneAction: 2);
        
        Out.ar(out, sig);
    }).add;

    s.sync;

    // ── osc modulation interface ────────────────────────────────────────────

    // modulate global synth parameters: /anceps/blessed/params [shimmer, tunneling_prob]
    OSCdef(\ancepsBlessedParams, { |msg|
        var shimmer = msg[1];
        var tunneling_prob = msg[2];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.set(\shimmer, shimmer, \tunneling_prob, tunneling_prob);
        };
    }, '/anceps/blessed/params');

    // update partial frequencies: /anceps/blessed/freqs [f0, f1, f2, f3, f4, f5, f6, f7]
    OSCdef(\ancepsBlessedFreqs, { |msg|
        var freqs = msg[1..];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.setn(\freqs, freqs);
        };
    }, '/anceps/blessed/freqs');

    // update partial magnitudes: /anceps/blessed/mags [m0, m1, m2, m3, m4, m5, m6, m7]
    OSCdef(\ancepsBlessedMags, { |msg|
        var mags = msg[1..];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.setn(\mags, mags);
        };
    }, '/anceps/blessed/mags');

    // visual feedback: /visual/entropy [val]
    OSCdef(\visualEntropy, { |msg|
        var val = msg[1];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.set(\visual_entropy, val);
        };
    }, '/visual/entropy');

    // visual feedback: /visual/chaos [val]
    OSCdef(\visualChaos, { |msg|
        var val = msg[1];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.set(\visual_chaos, val);
        };
    }, '/visual/chaos');

    // site depth: /site/depth [val]
    OSCdef(\siteDepth, { |msg|
        var val = msg[1];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.set(\depth, val);
        };
    }, '/site/depth');


    // ── lifecycle helpers ───────────────────────────────────────────────────

    ~ancepsBlessedStart = {
        if(~ancepsBlessedSynth.isNil) {
            ~ancepsBlessedSynth = Synth(\ancepsBlessedSynth);
            "anceps blessed synth: started".postln;
        };
    };

    ~ancepsBlessedStop = {
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.set(\gate, 0);
            ~ancepsBlessedSynth = nil;
            "anceps blessed synth: stopping".postln;
        };
    };

    "anceps blessed synth module loaded".postln;
});
)
