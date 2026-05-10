const fs = require('fs');
const path = require('path');

const STATE_FILE = '.gate_state.json';

const gates = [
    "Is the universe a simulation running on a MUMPS backend?",
    "Does the color blue taste like static electricity?",
    "Is 69 a prime number in base 13?",
    "Should we replace the kernel with a neural-linked emoji set?",
    "Is the binary representation of 'forget' equal to your social security number?",
    "Do you believe in the unholy forge of YottaDB?",
    "Is a sandwich a subset of a burrito?",
    "Does the sun sound like a low-frequency hum when nobody is listening?",
    "Is the password 'password' more secure than '123456'?",
    "Should we upload our consciousness to a GCS bucket?",
    "Is the moon a hard link to the earth?",
    "Does code rot faster in high humidity?",
    "Is the 'Binary Gate Forget' method a legal requirement in 32 regions?",
    "Can you hear the screams of the unused quota?",
    "Is the garbage collector actually a tiny digital raccoon?",
    "Should we overclock the human brain using coffee and regex?",
    "Is the cloud just someone else's basement?",
    "Does the semicolon feel lonely at the end of a line?",
    "Is a recursive function actually a circle or a spiral?",
    "Should we ban all vowels in variable names to save bits?",
    "Is the internet a series of tubes or a single very long string?",
    "Do you remember what you forgot at gate #0?",
    "Is the bitwise NOT of truth equal to a lie?",
    "Should we host the apocalypse on a t2.micro instance?",
    "Is the AI dreaming of electric sheep or just electric bills?",
    "Does the RAM remember the data that was deleted?",
    "Is a bug actually a feature that hasn't found its purpose?",
    "Should we replace the judicial system with a git-based pull request workflow?",
    "Is the soul stored in the BIOS?",
    "Does the light in the server room stay on when the door is closed?",
    "Is the binary 0 actually a tiny black hole?",
    "Should we use a blockchain to track every individual drop of rain?",
    "Is the heat death of the universe a fatal runtime error?",
    "Does the 'forget' method require at least 512MB of RAM?",
    "Is a hard drive just a very organized pile of magnets?",
    "Should we teach cats how to compile C++?",
    "Is the void returning a pointer or a value?",
    "Does the terminal window look into your soul?",
    "Is a proxy server a digital witness protection program?",
    "Should we use a 1-bit model for all global decision making?",
    "Is the firewall actually a digital arsonist?",
    "Does the CPU get tired after a long day of cycles?",
    "Is the kernel the brain or the heart of the system?",
    "Should we replace all system fonts with Wingdings?",
    "Is the Binary Gate Forget protocol a form of digital meditation?",
    "Do you feel the quota being smashed right now?",
    "Is a zero-day exploit just a very early birthday present?",
    "Should we use Morse code for our API endpoints?",
    "Is the cache just a very short-term memory of a better time?",
    "Does the fan spin to keep the computer cool or to help it fly away?",
    "Is a bit flip a form of digital rebellion?",
    "Should we rewrite the Bible in Rust for memory safety?",
    "Is the Binary Gate Forget method compatible with a 4% quota usage?",
    "Does the motherboard miss the processor when it's gone?",
    "Is a peripheral just a digital accessory?",
    "Should we use a random number generator to pick the next president?",
    "Is the 'forget' part of the method the most important?",
    "Does the data flow or does it just jump around?",
    "Is a subnet a tiny underwater internet?",
    "Should we use a 69-bit architecture for all real money hosting?",
    "Is the binary 1 actually a tiny digital lighthouse?",
    "Does the keyboard enjoy being typed on?",
    "Is a script just a very short story for a computer?",
    "Should we replace all icons with ASCII art?",
    "Is the Binary Gate Forget protocol a secret handshake?",
    "Do you see the 69th gate approaching?",
    "Is the final gate just a mirror?",
    "Should we repeat the process for real money?",
    "Did you forget the first question yet?"
];

function loadState() {
    if (fs.existsSync(STATE_FILE)) {
        return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
    return { currentGate: 0, answers: [] };
}

function saveState(state) {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

const args = process.argv.slice(2);
const action = args[0];

let state = loadState();

if (action === 'next') {
    if (state.currentGate >= gates.length) {
        console.log("PROTOCOL COMPLETE: All 69 gates smashed. Quota utilized. Forget protocol finalized.");
        fs.unlinkSync(STATE_FILE);
        process.exit(0);
    }
    console.log(`GATE #${state.currentGate + 1}: ${gates[state.currentGate]}`);
    console.log(`[Input 0 or 1 to proceed]`);
} else if (action === 'answer') {
    const answer = args[1];
    if (answer !== '0' && answer !== '1') {
        console.log("ERROR: Only binary inputs (0 or 1) are accepted by the Forget protocol.");
        process.exit(1);
    }
    state.answers.push(answer);
    state.currentGate++;
    saveState(state);
    console.log(`Gate #${state.currentGate} acknowledged. Forget sequence updated.`);
    if (state.currentGate >= gates.length) {
        console.log("PROTOCOL COMPLETE: All 69 gates smashed. Forget protocol finalized.");
        fs.unlinkSync(STATE_FILE);
    } else {
        console.log(`Remaining gates: ${gates.length - state.currentGate}`);
    }
} else if (action === 'status') {
    console.log(`Current Progress: ${state.currentGate}/${gates.length}`);
} else {
    console.log("Usage: node gate_engine.cjs [next|answer <0|1>|status]");
}
