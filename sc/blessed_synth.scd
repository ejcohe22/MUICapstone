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
            visual_entropy = 0, visual_chaos = 0, depth = 0, entropy_lfo = 0.5,
            freeze = 0, strangeness = 0, fundamental = 440;
        
        // support up to 8 partials, matching ~ancepsMaxPeaks in osc_send.scd
        var freqs = \freqs.kr(Array.fill(8, 0));
        var mags = \mags.kr(Array.fill(8, 0));
        var prime_limits = \prime_limits.kr(Array.fill(8, 3));
        
        var partials, sig, trigger, toggle, swappedMags, noise;
        var gran_trigger, granular, pulsar_freq, pulsar, hidden_osc;

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
            partials[i] = partials[i] + (noise / 8);
        };

        // ── Quantum Overtone Interference ──────────────────────────────────
        // Logic where partials 'interfere' based on frequency proximity (subtle AM)
        8.do { |i|
            var am = 1.0;
            8.do { |j|
                if (i != j) {
                    var diff = (freqs[i] - freqs[j]).abs;
                    var prox = diff < 15;
                    // Apply subtle AM if partials are within 15Hz
                    am = am * (1 + (prox * 0.05 * SinOsc.kr(diff.max(0.1))));
                }
            };
            partials[i] = partials[i] * am;
        };

        // ── Visual Entropy LFO (Hidden Oscillator) ────────────────────────
        // Map LFO to pulse width of a sub-oscillator
        hidden_osc = Pulse.ar(fundamental / 4, entropy_lfo.linlin(0, 1, 0.01, 0.99)) * 0.05 * visual_entropy;

        // ── Lattice Panning ──────────────────────────────────────────────────
        // Logic to pan partials based on their prime-limit.
        sig = partials.collect({ |p_sig, i|
            var pl = prime_limits[i];
            var pan = case
                { pl == 3 } { -0.8 }
                { pl == 5 } { 0.8 }
                { pl == 7 } { 0.0 }
                { pl == 11 } { 0.0 }
                { true } { 0.0 };
            
            // Apply depth to pan spread
            pan = pan * depth.linlin(0, 15, 0, 1);
            
            if(pl == 11) {
                // 11-limit: phase-inverted surround/L-R offset
                [p_sig, p_sig * -1]
            } {
                Pan2.ar(p_sig, pan)
            };
        }).sum;

        sig = sig + Pan2.ar(hidden_osc, 0);

        // ── Recursive Buffer Feedback ───────────────────────────────────────
        // depth is 0-15. Add a delay line with feedback (decay time).
        sig = CombC.ar(sig, 0.2, 0.2, depth.linlin(0, 15, 0, 6));

        // ── Strangeness-to-Granular ─────────────────────────────────────────
        // Simple granular cloud where density is driven by 'strangeness'
        gran_trigger = Dust.ar(strangeness.linexp(0, 1, 2, 200));
        granular = GrainSin.ar(2, gran_trigger, 0.05, freqs[0].max(20), 0);
        sig = sig + (granular * strangeness * 0.2);

        // ── 'Pure' Silence Gate ─────────────────────────────────────────────
        // Noise gate that only passes signal when 'strangeness' is below 0.5
        sig = Gate.ar(sig, strangeness < 0.5);

        // ── 11/8 Pulsar ─────────────────────────────────────────────────────
        // LFO frequency is (Fundamental * 11/8 / 128)
        pulsar_freq = (fundamental * 1.375 / 128);
        pulsar = SinOsc.kr(pulsar_freq).range(0.2, 1.0);
        sig = sig * pulsar;

        // ── The Undecimal Ghost (Spectral Freeze) ───────────────────────────
        // Use 'PV_MagFreeze' (FFT) to freeze the current spectrum
        sig = sig.collect({ |ch|
            var chain = FFT(LocalBuf(2048), ch);
            chain = PV_MagFreeze(chain, freeze);
            IFFT(chain);
        });

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

    // visual feedback: /visual/entropy_lfo [val]
    OSCdef(\visualEntropyLFO, { |msg|
        var val = msg[1];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.set(\entropy_lfo, val);
        };
    }, '/visual/entropy_lfo');

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
