/*
Synesthetic Feedback Loop: SuperCollider Receiver
This script demonstrates how visual parameters (brightness, flux) 
received from the inference engine can modulate a synthesizer.
*/

(
s.waitForBoot({
    // A simple synth that we can modulate
    SynthDef(\synesthetic_osc, {
        arg out=0, freq=440, cutoff=1000, amp=0.2, gate=1;
        var sig, env;
        
        env = EnvGen.kr(Env.adsr(0.1, 0.3, 0.5, 1.0), gate, doneAction: 2);
        sig = LFSaw.ar(freq, 0, amp);
        sig = RLPF.ar(sig, cutoff.lag(0.1), 0.1);
        
        Out.ar(out, sig ! 2 * env);
    }).add;

    s.sync;

    // Start the synth
    ~synth = Synth(\synesthetic_osc, [\freq, 110, \cutoff, 400]);

    // OSC Responder for Brightness
    OSCdef(\brightness_receiver, { |msg|
        var val = msg[1];
        "Visual Brightness: %".format(val).postln;
        // Modulate cutoff frequency based on brightness (e.g., 400Hz to 10kHz)
        ~synth.set(\cutoff, val.linexp(0, 1, 400, 10000));
    }, '/visual/brightness');

    // OSC Responder for Flux
    OSCdef(\flux_receiver, { |msg|
        var val = msg[1];
        "Visual Flux: %".format(val).postln;
        // Visual flux can be used to add some 'grit' or resonance
        // Or modulate amp
        ~synth.set(\amp, val.linlin(0, 1, 0.2, 0.8));
    }, '/visual/flux');

    "Synesthetic Feedback Loop Active. Listening on port 57120...".postln;
});
)
