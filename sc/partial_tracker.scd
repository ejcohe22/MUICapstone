// anceps — partial tracker module
//
// currently /anceps/peaks is frame-local: each frame picks peaks
// independently, and a slowly moving partial reads as a sequence of
// unrelated peaks. this module gives each partial a stable id that
// survives across frames as long as it can be matched.
//
// algorithm: mcaulay-quatieri style greedy nearest-neighbor matching
// in log frequency space.
//
//   for each peak in the current frame:
//     find the active track with smallest cents distance subject to a
//     maximum tolerance. if found, update that track's freq and mag
//     and mark both as claimed.
//
//   tracks without a match age a miss counter. after
//   ~ancepsMissToleranceFrames consecutive misses the track dies.
//   peaks without a match are born as new tracks.
//
// this file is a self contained module. evaluate the main paren block
// to define the three closures on the current environment. osc_send.scd
// then calls ~ancepsTrackerStep on its peaks array and ships the result.
//
// contract impact: /anceps/peaks gains a track_id per peak. breaking
// change. bump sandhi contract to v0.3. the matching one line patch
// for osc_receive.m is in the companion section below.


// ══════════════════════════════════════════════════════════════════════════
// module definition
// ══════════════════════════════════════════════════════════════════════════

(
// active tracks, keyed by id. each value is an event with:
//   \id, \freq, \mag, \age, \missCount
~ancepsTracks = IdentityDictionary.new;

// next track id to hand out. starts at 1 because 0 means "no track".
~ancepsNextTrackId = 1;

// tuning knobs. adjust per program material.
~ancepsMatchToleranceCents = 30;
~ancepsMissToleranceFrames = 3;


// ── init ──────────────────────────────────────────────────────────────────
// call once at sender setup from ~ancepsStart.
~ancepsTrackerInit = {
    ~ancepsTracks = IdentityDictionary.new;
    ~ancepsNextTrackId = 1;
    "anceps tracker: init".postln;
};


// ── reset ─────────────────────────────────────────────────────────────────
// call from ~ancepsStop to drop held memory.
~ancepsTrackerReset = {
    ~ancepsTracks = IdentityDictionary.new;
    ~ancepsNextTrackId = 1;
    "anceps tracker: reset".postln;
};


// ── step ──────────────────────────────────────────────────────────────────
// call once per frame with the current peaks array as pairs
// [[freq0, mag0], [freq1, mag1], ...] sorted ascending by frequency.
// returns a list of triples [[tid0, freq0, mag0], [tid1, freq1, mag1], ...]
// in the same order as the input peaks.
~ancepsTrackerStep = { |peaks|
    var candidates, claimedPeaks, claimedTracks, tracksToUpdate, toKill, output;

    // ── step 1: build candidate (cost, peakIndex, trackId) triples ───
    // cost is cents distance; only include pairs within tolerance.
    candidates = List.new;
    peaks.do({ |peak, pi|
        var pfreq = peak[0];
        ~ancepsTracks.keysValuesDo({ |tid, track|
            var tfreq = track[\freq];
            var cents = (1200 * log2(pfreq / tfreq)).abs;
            if (cents <= ~ancepsMatchToleranceCents) {
                candidates.add([cents, pi, tid]);
            };
        });
    });

    // ── step 2: greedy assignment in ascending cost order ────────────
    candidates = candidates.asArray.sort({ |a, b| a[0] < b[0] });
    claimedPeaks = Set.new;
    claimedTracks = Set.new;
    tracksToUpdate = Dictionary.new;

    candidates.do({ |c|
        var cost = c[0], pi = c[1], tid = c[2];
        if (claimedPeaks.includes(pi).not and: {
            claimedTracks.includes(tid).not
        }) {
            tracksToUpdate[pi] = tid;
            claimedPeaks.add(pi);
            claimedTracks.add(tid);
        };
    });

    // ── step 3: age all tracks, then update the matched ones ─────────
    ~ancepsTracks.keysValuesDo({ |tid, track|
        track[\missCount] = track[\missCount] + 1;
        track[\age] = track[\age] + 1;
    });

    tracksToUpdate.keysValuesDo({ |pi, tid|
        var track = ~ancepsTracks[tid];
        track[\freq] = peaks[pi][0];
        track[\mag] = peaks[pi][1];
        track[\missCount] = 0;
    });

    // ── step 4: kill long-absent tracks ──────────────────────────────
    toKill = List.new;
    ~ancepsTracks.keysValuesDo({ |tid, track|
        if (track[\missCount] > ~ancepsMissToleranceFrames) {
            toKill.add(tid);
        };
    });
    toKill.do({ |tid| ~ancepsTracks.removeAt(tid); });

    // ── step 5: birth new tracks for unmatched peaks ─────────────────
    peaks.do({ |peak, pi|
        var tid;
        if (claimedPeaks.includes(pi).not) {
            tid = ~ancepsNextTrackId;
            ~ancepsNextTrackId = ~ancepsNextTrackId + 1;
            // wrap before crossing int32 positive limit; 0 stays reserved
            if (~ancepsNextTrackId >= 0x80000000) {
                ~ancepsNextTrackId = 1;
            };
            ~ancepsTracks[tid] = (
                \id: tid,
                \freq: peak[0],
                \mag: peak[1],
                \age: 0,
                \missCount: 0
            );
            tracksToUpdate[pi] = tid;
        };
    });

    // ── step 6: emit the output list in input peak order ─────────────
    output = peaks.collect({ |peak, pi|
        var tid = tracksToUpdate[pi] ? 0;
        [tid, peak[0], peak[1]]
    });

    output
};

"anceps tracker module loaded".postln;
)


// ══════════════════════════════════════════════════════════════════════════
// integration with osc_send.scd
// ══════════════════════════════════════════════════════════════════════════
//
// inside the ~ancepsStart block, add:
//
//   ~ancepsTrackerInit.();
//
// inside the fetch clock routine, after peak picking has produced the
// ~peaks array of [freq, mag] pairs, add:
//
//   ~peaksWithTracks = ~ancepsTrackerStep.(~peaks);
//   ~peakCount = ~peaksWithTracks.size;
//
// change the peaks message assembly from:
//
//   ~peaksMessage = ['/anceps/peaks', ~peakCount] ++ ~peaks.flat;
//
// to:
//
//   ~peaksMessage = ['/anceps/peaks', ~peakCount] ++ ~peaksWithTracks.flat;
//
// inside ~ancepsStop add:
//
//   ~ancepsTrackerReset.();


// ══════════════════════════════════════════════════════════════════════════
// octave side: consume the track ids
// ══════════════════════════════════════════════════════════════════════════
//
// osc_receive.m currently reads /anceps/peaks as
//   [count, freq0, mag0, freq1, mag1, ...]
// once this tracker ships, the message becomes
//   [count, tid0, freq0, mag0, tid1, freq1, mag1, ...]
//
// update the peaks branch of assemble_frame to:
//
//   p = zeros(n, 3);                    % [track_id, freq, mag]
//   for i = 1:n
//     p(i, 1) = m.args{3*i - 1};
//     p(i, 2) = m.args{3*i};
//     p(i, 3) = m.args{3*i + 1};
//   end
//   out.peaks = p(:, 2:3);               % public peaks stays [freq, mag]
//   out.track_ids = p(:, 1);             % sibling field
//
// this keeps the callback interface compatible (frame.peaks is still
// an n by 2 matrix of [freq, mag]) while adding frame.track_ids so
// downstream code that wants to smooth a partial over time can group
// frames by track id.


// ══════════════════════════════════════════════════════════════════════════
// in-file test harness
// ══════════════════════════════════════════════════════════════════════════
// uncomment and evaluate to verify the module in isolation. simulates
// six frames: three steady tones are born on frame 1, one drifts by
// 15 cents on frame 2 (within tolerance, should keep its id), a new
// partial appears on frame 3, one tone disappears on frame 4 through
// 6 (should die after miss tolerance expires).

/*
(
~ancepsTrackerInit.();

// frame 1: three new tones at 200, 250, 300 hz. all get fresh ids.
// expect tids 1, 2, 3.
"frame 1 (birth):     ".post;
~ancepsTrackerStep.([[200.0, 1.0], [250.0, 0.8], [300.0, 0.9]]).postln;

// frame 2: 200 drifts up by 10 cents (~1.16 hz), 250 drifts down by
// 15 cents. both well under 30 cent tolerance. 300 is unchanged.
// expect the same tids 1, 2, 3 in the same order.
"frame 2 (small drift):".post;
~ancepsTrackerStep.([[201.16, 1.0], [247.84, 0.8], [300.0, 0.9]]).postln;

// frame 3: same three tones plus a new partial at 450 hz. existing
// tids stay stable, 450 gets a fresh tid 4.
"frame 3 (new partial):".post;
~ancepsTrackerStep.([[201.16, 1.0], [247.84, 0.8], [300.0, 0.9], [450.0, 0.5]]).postln;

// frame 4: 250 disappears. expect its track to age a miss but still
// exist. the remaining three peaks keep their tids.
"frame 4 (tone missing 1):".post;
~ancepsTrackerStep.([[201.16, 1.0], [300.0, 0.9], [450.0, 0.5]]).postln;

// frame 5: 250 still missing (miss = 2).
"frame 5 (tone missing 2):".post;
~ancepsTrackerStep.([[201.16, 1.0], [300.0, 0.9], [450.0, 0.5]]).postln;

// frame 6: 250 still missing (miss = 3). with the default miss
// tolerance of 3, after step 4 the track will be killed on the
// next step's aging pass. keep watching the tracks dict to confirm.
"frame 6 (tone missing 3):".post;
~ancepsTrackerStep.([[201.16, 1.0], [300.0, 0.9], [450.0, 0.5]]).postln;

// inspect state: should show tid 2 (the 250 hz track) has been removed.
"".postln;
"active tracks after test:".postln;
~ancepsTracks.keysValuesDo({ |tid, track|
    ("  tid " ++ tid
     ++ ": freq=" ++ track[\freq].round(0.01)
     ++ " mag=" ++ track[\mag].round(0.01)
     ++ " age=" ++ track[\age]
     ++ " miss=" ++ track[\missCount]).postln;
});

~ancepsTrackerReset.();
)
*/


// ══════════════════════════════════════════════════════════════════════════
// tuning the knobs
// ══════════════════════════════════════════════════════════════════════════
//
// ~ancepsMatchToleranceCents too small  ->  tracks break on vibrato
// ~ancepsMatchToleranceCents too large  ->  adjacent partials get confused
// ~ancepsMissToleranceFrames too small  ->  legato notes restart on dropouts
// ~ancepsMissToleranceFrames too large  ->  reused ids cling to ghosts
//
// 30 cents and 3 frames (100 ms at 30 hz) is a reasonable starting
// point for vocal and acoustic instrument material. percussive material
// with fast transients may want tighter miss tolerance. drones and
// sustained instruments can tolerate looser cents tolerance.


// ══════════════════════════════════════════════════════════════════════════
// verifying in the live pipeline
// ══════════════════════════════════════════════════════════════════════════
//
// with the internal test triad running, the first frame after startup
// should birth three tracks with ids 1, 2, 3. every subsequent frame
// should reuse those same three ids so the track id column of
// /anceps/peaks stays constant. free the test source and watch the ids
// disappear from the stream three frames later (default miss tolerance).
// respawn the source and watch fresh ids (4, 5, 6) get assigned since
// the old ones retired.
//
// if new ids are assigned every frame, the tolerance is too tight or
// the prev state is not persisting. double check that ~ancepsTrackerInit
// is called only from ~ancepsStart, not from the fetch routine.
