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
            freeze = 0, strangeness = 0, fundamental = 440, saturation = 0,
            formant = 0, glitch_density = 0, hilbert_shift = 0;
        
        // support up to 8 partials, matching ~ancepsMaxPeaks in osc_send.scd
        var freqs = \freqs.kr(Array.fill(8, 0));
        var mags = \mags.kr(Array.fill(8, 0));
        var prime_limits = \prime_limits.kr(Array.fill(8, 3));
        
        var partials, sig, trigger, toggle, swappedMags, noise;
        var gran_trigger, granular, pulsar_freq, pulsar, hidden_osc;
        var glitch_trigger, glitch_env, comb_lattice, hilbert_sig;

        // ── Aperiodic Glitch Generator ──────────────────────────────────────
        // Use Dust.kr to trigger sudden, 17ms spectral gaps in the audio.
        glitch_trigger = Dust.kr(glitch_density);
        glitch_env = 1 - EnvGen.kr(Env([0, 1, 1, 0], [0, 0.017, 0]), glitch_trigger);

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
            var jitter, phase, p_sig;
            
            // tiny phase jitter (sub-millisecond). 0.001s is 1ms.
            // this is intended to be driven by the prime-limit of the ratio in the future.
            jitter = WhiteNoise.ar(shimmer * 0.001);
            phase = 2 * pi * f * jitter;
            
            p_sig = SinOsc.ar(f, phase) * m;

            // ── Spectral Formant Shift ──────────────────────────────────────
            // Apply FreqShift.ar to each partial, modulated by 'formant'
            p_sig = FreqShift.ar(p_sig, formant * (f / fundamental));

            partials[i] = p_sig + (noise / 8);
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

        // ── Comb Filter Lattice (17/14) ────────────────────────────────────
        // Parallel comb filters tuned to 17/14 harmonic ratios.
        comb_lattice = [1, 17/14, (17/14).squared].collect({ |ratio|
            CombC.ar(sig, 0.1, 1 / (fundamental * ratio), 0.5)
        }).sum * 0.2;
        sig = sig + comb_lattice;

        // ── Septimal Hilbert Transform (SSB) ──────────────────────────────
        // SSB frequency shifter using Hilbert.ar for wide spatialization.
        // Link Hilbert width to 'depth' (0-15) by offsetting L/R phase.
        hilbert_sig = Hilbert.ar(sig);
        // Multiply by complex oscillator for shift: (R * cos) - (I * sin)
        // [0, 1] array for phase offset between L and R
        sig = (hilbert_sig[0] * SinOsc.ar(hilbert_shift, [0.5 * pi, 0.5 * pi + depth.linlin(0, 15, 0, pi)])) - 
              (hilbert_sig[1] * SinOsc.ar(hilbert_shift, [0, depth.linlin(0, 15, 0, pi)]));

        // ── Resonant Feedback Matrix (17x14) ──────────────────────────────
        // 17 delay lines in a recursive matrix for 'infinite' sustain.
        // Sustains when depth thresholds are met (mapped to feedback gain).
        {
            var fb_in = LocalIn.ar(17);
            var matrix_sig, fb_gain;
            
            // Feedback gain reaches 1.0 at depth=14, and 1.01 at depth=15 for 'infinite' sustain.
            fb_gain = depth.linlin(0, 14, 0, 1.0).max(0) + (depth > 14).if(0.01, 0);

            matrix_sig = 17.collect({ |i|
                var delayTime = (i + 1) * (17/14) / fundamental;
                var s = sig.sum + (fb_in[i] * fb_gain);
                DelayC.ar(s, 0.5, delayTime.wrap(0.001, 0.5))
            });

            LocalOut.ar(matrix_sig);
            sig = sig + (Pan2.ar(matrix_sig.sum, SinOsc.kr(0.1)) * 0.15 * depth.linlin(0, 15, 0, 1));
        }.();

        // ── Recursive Buffer Feedback ───────────────────────────────────────
        // depth is 0-15. Add a delay line with feedback (decay time).
        sig = CombC.ar(sig, 0.2, 0.2, depth.linlin(0, 15, 0, 6));

        // ── Strangeness-to-Granular ─────────────────────────────────────────
        // Simple granular cloud where density is driven by 'strangeness'
        gran_trigger = Dust.ar(strangeness.linexp(0, 1, 2, 200));
        granular = GrainSin.ar(2, gran_trigger, 0.05, freqs[0].max(20), 0);
        sig = sig + (granular * strangeness * 0.2);

        // Apply Glitch Env
        sig = sig * glitch_env;

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

        // ── Septimal Saturation ─────────────────────────────────────────────
        // subtle tube-distortion effect using tanh modulated by 'saturation'
        sig = sig * (1 + (saturation * 2));
        sig = sig.tanh;

        sig = sig * amp;
        sig = sig * EnvGen.kr(Env.asr(0.1, 1, 0.2), gate, doneAction: 2);
        
        Out.ar(out, sig);
    }).add;

    // ── Septimal Overtone Echo (^GHOST) ──────────────────────────────────
    // Ghostly "after-image" using a long feedback delay
    SynthDef(\ancepsGhost, {
        arg out = 0, freq = 440, amp = 0.1, gate = 1;
        var sig, env;
        sig = Resonz.ar(WhiteNoise.ar(0.1), freq, 0.001) * amp * 80;
        sig = CombC.ar(sig, 2.0, 2.0, 12); // Very long feedback delay
        env = EnvGen.kr(Env.asr(2, 1, 8), gate, doneAction: 2);
        Out.ar(out, Pan2.ar(sig * env, Rand(-0.7, 0.7)));
    }).add;

    s.sync;

    // ── osc modulation interface ────────────────────────────────────────────

    // modulate global synth parameters: /anceps/blessed/params [shimmer, tunneling_prob, saturation, formant, glitch_density, hilbert_shift]
    OSCdef(\ancepsBlessedParams, { |msg|
        var shimmer = msg[1];
        var tunneling_prob = msg[2];
        var saturation = msg[3];
        var formant = msg[4];
        var glitch_density = msg[5];
        var hilbert_shift = msg[6];
        if(~ancepsBlessedSynth.notNil) {
            ~ancepsBlessedSynth.set(
                \shimmer, shimmer, 
                \tunneling_prob, tunneling_prob,
                \saturation, saturation,
                \formant, formant,
                \glitch_density, glitch_density,
                \hilbert_shift, hilbert_shift
            );
        };
    }, '/anceps/blessed/params');

    // listen for ghost overtone echoes: /anceps/ghost [freq, amp]
    OSCdef(\ancepsGhost, { |msg|
        var freq = msg[1];
        var amp = msg[2];
        Synth(\ancepsGhost, [\freq, freq, \amp, amp]);
    }, '/anceps/ghost');

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
