# capstone ai visualizer open source edition

### turning pure harmonic ratios into living visuals in real time

---

an open source ai music visualization system that analyzes audio through the lens of
extended just intonation and generates real time visuals using generative adversarial
networks. every piece of the pipeline is free and open. no proprietary software required.

today we propose the evolution of erik cohens original capstone ai visualizer
created for his music interdisciplinary computation major at colby college under
professor jose martinez. the original system used maxmsp and runwayml to analyze audio
with ircam descriptors and feed them into biggan for image generation. this edition
replaces the proprietary stack with supercollider gnu octave and a self hosted inference
server while adding deep support for extended just intonation tuning systems.

---

## table of contents

- [why this exists](#why-this-exists)
- [what changed from the original](#what-changed-from-the-original)
- [architecture overview](#architecture-overview)
- [the just intonation argument](#the-just-intonation-argument)
- [pipeline deep dive](#pipeline-deep-dive)
 - [supercollider audio engine](#supercollider-audio-engine)
 - [the descriptor set](#the-descriptor-set)
 - [gnu octave mapping layer](#gnu-octave-mapping-layer)
 - [generative adversarial network inference](#generative-adversarial-network-inference)
 - [real time renderer](#real-time-renderer)
- [the open sound control message format](#the-open-sound-control-message-format)
- [tuning system configuration](#tuning-system-configuration)
- [installation](#installation)
- [usage](#usage)
- [project structure](#project-structure)
- [design philosophy](#design-philosophy)
- [roadmap](#roadmap)
- [contributing](#contributing)
- [credits and lineage](#credits-and-lineage)
- [license](#license)
- [contact](#contact)

---

## why this exists

the original capstone ai visualizer proved something important. it proved that you can
take the acoustic properties of music and translate them into meaningful visual output
using neural networks. that core idea is powerful and beautiful and deserves to live
in a form that anyone can use.

but the original system requires maxmsp which costs money and locks you into cycling74s
ecosystem. it requires runwayml which adds another subscription and another dependency.
and it uses ircam descriptors which were designed around twelve tone equal temperament
assumptions which means they literally cannot hear the difference between the acoustic
realities of different tuning systems.

this edition exists because we believe three things

first that computational music tools should be free and open so that any musician with
curiosity and a laptop can run them modify them and build on them without asking
permission or paying rent

second that extended just intonation produces acoustic phenomena that are fundamentally
different from equal temperament and a visualization system that cant distinguish between
a pure 7/4 harmonic seventh and a tempered minor seventh is missing something essential
about what sound actually is

third that the best software is built by people with different expertise working together
on shared problems and an open architecture makes that collaboration possible in ways
that monolithic proprietary tools never can

---

## what changed from the original

| component | original | open source edition |
|-----------|----------|---------------------|
| audio engine | maxmsp (proprietary) | supercollider (open source) |
| descriptor extraction | ircam objects in max | native supercollider unit generators |
| tuning support | twelve tone equal temperament only | arbitrary just intonation systems |
| neural network hosting | runwayml (proprietary cloud) | self hosted inference server |
| communication protocol | internal max messages | open sound control (standard protocol) |
| video generation | batch image sequence + ffmpeg | real time rendering |
| output | pre rendered video file | live visual stream |
| cost to run | maxmsp license + runwayml subscription | free |
| can you modify it | limited by proprietary apis | yes everything |

the fundamental insight of eriks original project is preserved. audio features drive
neural network image generation. what changes is that every layer is now open
replaceable and tuning aware.

---

## architecture overview

```
┌─────────────────────────────────────────────────────────────┐
│                               │
│  live audio input / file playback             │
│                               │
└──────────────────────────┬──────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                               │
│  supercollider                       │
│                               │
│  real time digital signal processing engine        │
│  spectral descriptor extraction              │
│  just intonation tuning definitions as native objects   │
│  outputs descriptor streams via open sound control     │
│                               │
│      ┌──────────────────────────────┐         │
│      │               │         │
│      │  just intonation tuning   │         │
│      │  system configuration    │         │
│      │               │         │
│      │  ratios / prime limits /  │         │
│      │  scale definitions     │         │
│      │               │         │
│      └──────────────────────────────┘         │
│                               │
└──────────────────────────┬──────────────────────────────────┘
              │
          open sound control
          (descriptor stream:
           spectral centroid
           spectral flux
           pitch
           mel frequency cepstral coefficients
           onset detection
           harmonic distance
           prime limit
           consonance measure
           beating frequency)
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                               │
│  gnu octave                        │
│                               │
│  receives descriptors via open sound control        │
│  computes just intonation aware feature mappings      │
│  translates descriptor space into latent space vectors   │
│  handles the math that doesnt need sample level latency  │
│  fast fourier transform processing via built in bindings  │
│                               │
└──────────────────────────┬──────────────────────────────────┘
              │
           http or open sound control
           (latent vectors + class vectors)
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                               │
│  generative adversarial network inference server      │
│                               │
│  runs biggan (default) or stylegan3 (optional swap)    │
│  self hosted on local gpu or cloud instance        │
│  no proprietary service dependency             │
│  returns generated frames at target rate          │
│                               │
└──────────────────────────┬──────────────────────────────────┘
              │
            frame stream
            (websocket or shared memory)
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                               │
│  real time renderer                    │
│                               │
│  p5.js in browser (default zero install)         │
│  or processing (desktop higher performance)       │
│  or openframeworks (c++ maximum frame rate)       │
│  or webgl shader pipeline (custom deepest integration)  │
│                               │
│  composites generated frames with reactive geometry    │
│  driven by the live descriptor stream           │
│                               │
└─────────────────────────────────────────────────────────────┘
```

every node in this chain communicates through standard protocols. every node can be
replaced independently. someone can swap supercollider for puredata or swap biggan
for a diffusion model or swap the p5.js renderer for a custom opengl application
without touching anything else in the pipeline.

---

## the just intonation argument

if you already know what just intonation is you can skip this section. if you dont
this is the heart of why this branch exists.

### what is just intonation

western music settled on a tuning system called twelve tone equal temperament about
three hundred years ago. it divides the octave into twelve equally spaced steps. this
is convenient because you can play in any key and every key sounds the same. the
tradeoff is that every interval except the octave is slightly out of tune.

just intonation is older and more fundamental. instead of dividing the octave into
equal steps it builds intervals from pure frequency ratios derived from the harmonic
series. a perfect fifth is 3/2. a major third is 5/4. a harmonic seventh is 7/4. these
ratios produce intervals that are acoustically pure with minimal beating and maximal
consonance.

### what is extended just intonation

classical just intonation typically uses ratios involving prime factors 2 3 and 5.
extended just intonation goes further using prime factors 7 11 13 17 19 and beyond.
each new prime opens up a new dimension of harmonic space that has no equivalent in
equal temperament.

the 7th harmonic gives you the natural minor seventh (7/4) which is 31 cents flatter
than the equal tempered version and has a completely different spectral character.

the 11th harmonic gives you the undecimal tritone (11/8) which sits between a perfect
fourth and a tritone in a place that equal temperament literally cannot reach.

the 13th harmonic gives you neutral intervals that exist between major and minor in
a territory that most western instruments cannot play.

### why this matters for visualization

here is the key insight. when two frequencies are related by a simple ratio like 3/2
their combined spectrum is clean and periodic. the waveform repeats. the spectral
centroid is stable. the beating frequency is zero or very low.

when two frequencies are related by a complex or irrational ratio like an equal tempered
fifth (2^(7/12) which is approximately 1.4983 instead of exactly 1.5) the combined
spectrum is messy. the waveform never exactly repeats. the spectral centroid fluctuates.
there are beating patterns at various frequencies.

a visualization system that measures spectral centroid spectral flux and pitch is
literally measuring different things when you feed it just intonation versus equal
temperament. the acoustic reality is different. the descriptors are different. the
generated visuals should be different.

but the original ircam descriptors in the maxmsp pipeline have no concept of tuning
system. they cant tell you whether a measured interval is a pure ratio or a tempered
approximation. they cant compute harmonic distance or prime limit or consonance in
terms of ratio complexity. they just see frequencies.

this branch adds descriptors that understand tuning. the result is a visualization system
that can see the difference between acoustic realities that were previously invisible
to it.

### the harmonic series as visual organizing principle

the harmonic series is natures own frequency structure. every vibrating object produces
not just a fundamental frequency but a whole series of overtones at integer multiples
of that fundamental. the first six harmonics give you an octave a fifth a fourth a
major third and a minor third. go further and you get intervals that dont exist in
equal temperament at all.

in this system we use the harmonic series as the organizing principle for the visual
mapping itself. lower prime limits (2 3 5) which represent simpler harmonic relationships
map to simpler more coherent visual structures. higher prime limits (7 11 13) which
represent more complex harmonic relationships map to more intricate more elaborate
visual structures.

consonance maps to visual coherence. dissonance maps to visual complexity. the prime
limit of an interval determines the dimensional richness of the generated visual. this
isnt arbitrary. its grounded in the same mathematics that make these intervals sound
the way they do.

---

## pipeline deep dive

### supercollider audio engine

supercollider replaces maxmsp as the real time audio engine. it was chosen for several
reasons.

supercollider was built around the idea that sound is math and math is sound. frequency
ratios are first class citizens in the language not hacks bolted onto a system designed
for equal temperament. the Tuning and Scale classes accept arbitrary cent values or
ratios so you can define any just intonation scale as a native object.

supercollider has a rich set of analysis unit generators built into the audio server
itself. Pitch FFT SpectralCentroid MFCC Onsets and dozens of others run inside the
same process that produces the audio so there is no bottleneck between synthesis and
analysis.

open sound control is native to supercollider. its actually how the supercollider
language communicates with its own audio server. sending descriptor streams to external
processes is not an added feature its the fundamental architecture.

supercollider has a deep community of microtonal and just intonation practitioners
who have been building tuning aware instruments and analysis tools for years. this
means contributions to this project feed back into a broader ecosystem.

the supercollider component of this project lives in the `sc/` directory and consists
of

- `boot.scd` server configuration and startup
- `synths.scd` just intonation aware synthesizer definitions
- `analysis.scd` descriptor extraction chain
- `osc_send.scd` open sound control output routing
- `tunings/` directory of just intonation scale definitions

### the descriptor set

the descriptor set is the vocabulary that the system uses to describe what it hears.
the original ircam descriptors are replaced with a set that includes both standard
spectral descriptors and just intonation specific descriptors.

#### standard spectral descriptors

these are the same kinds of measurements that eriks original system used but computed
natively in supercollider instead of through ircam objects in maxmsp.

**spectral centroid** the brightness of the sound. computed as the weighted mean of
the frequency spectrum. higher values mean more energy in high frequencies. this is
probably the single most important descriptor for driving visual parameters because it
changes continuously and responds to almost everything happening in the audio.

**spectral flux** how quickly the spectrum is changing. computed as the difference
between successive spectral frames. high flux means the timbre is evolving rapidly.
low flux means it is stable. this maps naturally to visual motion and rate of change.

**pitch** the fundamental frequency of the sound. supercollider provides multiple
pitch detection algorithms. for just intonation work we use the one with the highest
frequency resolution because we need to distinguish between ratios that are very close
together like 7/4 (968.826 cents) and the equal tempered minor seventh (1000 cents).

**mel frequency cepstral coefficients** a compact representation of the spectral
envelope. these capture timbral quality in a way that is somewhat independent of pitch
and loudness. they are useful for distinguishing between different instruments or
different vowel sounds and they give the generative adversarial network something to
respond to beyond just brightness and flux.

**onset detection** when new sonic events begin. this drives the timing of visual
transitions and can trigger discrete changes in the generative adversarial network
class vector.

**root mean square amplitude** the loudness of the signal. simple but essential for
modulating the intensity of visual output.

#### just intonation specific descriptors

these are new descriptors that do not exist in the original ircam set because ircam
was not designed with tuning system awareness.

**harmonic distance** a measure of how far two frequencies are from each other in
harmonic space. for just intonation intervals this is computed from the prime
factorization of the ratio. a perfect fifth (3/2) has a short harmonic distance. a
ratio like 13/8 has a longer harmonic distance. this maps to visual complexity in the
generative adversarial network latent space.

**prime limit** the largest prime factor in the ratio defining an interval. a 5-limit
interval uses only primes 2 3 and 5. a 7-limit interval introduces the factor 7 which
opens a new harmonic dimension. an 11-limit interval goes further. the prime limit
determines which dimensions of the latent space are activated.

**consonance measure** a computed value representing the perceived consonance or
dissonance of the current sonority based on ratio complexity. simple ratios like 3/2
and 5/4 score high. complex ratios or irrational relationships score low. this is
not the same as spectral roughness though the two are correlated. this is a number
theoretic measure based on the mathematical structure of the interval itself.

**beating frequency** when two tones are close but not identical in frequency they
produce an audible beating pattern. in just intonation pure intervals have zero beating.
tempered intervals always have some. this descriptor measures the rate of any beating
present which tells you how far the current tuning is from a pure ratio.

**combination tone detection** when two tones sound simultaneously they produce
additional tones at the sum and difference of their frequencies. in just intonation
these combination tones fall on predictable harmonic series members. in equal
temperament they fall on irrational frequencies. this descriptor tracks the location
and amplitude of detected combination tones.

### gnu octave mapping layer

gnu octave sits between supercollider and the generative adversarial network inference
server. it receives the descriptor stream via open sound control and computes the
mapping from descriptor space to latent space.

why not do this in supercollider? because the mapping computation involves matrix
operations optimization routines and potentially iterative algorithms that benefit from
octaves numerical computing infrastructure. supercollider is optimized for sample level
audio processing. octave is optimized for the kind of linear algebra that latent space
manipulation requires.

the mapping is not a simple linear function. the relationship between acoustic
descriptors and visually meaningful latent space regions is learned through
experimentation and can be customized for different tuning systems different generative
adversarial network models and different aesthetic goals.

the octave component lives in the `octave/` directory and consists of

- `osc_receive.m` open sound control listener
- `descriptor_normalize.m` normalizes incoming descriptors to consistent ranges
- `latent_map.m` the core mapping function from descriptor space to latent space
- `class_select.m` selects or interpolates biggan class vectors based on descriptors
- `ji_math/` directory of just intonation specific computation functions
 - `prime_factorize.m` prime factorization of frequency ratios
 - `harmonic_distance.m` distance computation in harmonic space
 - `consonance.m` consonance measure from ratio complexity
 - `lattice.m` just intonation lattice construction and navigation

### generative adversarial network inference

the original system used runwayml to host biggan inference. this edition replaces
that with a self hosted inference server that you run on your own hardware.

the server accepts latent vectors and class vectors via http and returns generated
images. it can run on a local machine with a graphics processing unit or on a cloud
instance. the server code is a thin wrapper around the pretrained model weights.

biggan is the default model because it is what eriks original system used and it
produces recognizable structured images from class conditional input. but the
architecture supports swapping in any model that accepts a latent vector and produces
an image. stylegan3 is a natural upgrade path because it produces smoother interpolation
between latent space regions which means smoother visual transitions as the music
evolves.

the inference server lives in the `inference/` directory and consists of

- `server.py` http server that accepts latent and class vectors returns images
- `models/` directory for model weights (not tracked in git due to size)
- `biggan_wrapper.py` biggan specific inference code
- `stylegan_wrapper.py` stylegan3 inference code (optional)
- `requirements.txt` python dependencies

### real time renderer

the original system generated a sequence of images and then stitched them into a video
with ffmpeg. this edition renders in real time.

the default renderer is p5.js running in a browser. this was chosen because it requires
zero installation beyond a web browser and because the creative coding community around
p5.js is enormous which means more potential contributors.

the renderer receives generated frames from the inference server via websockets and
composites them with additional reactive geometry driven by the live descriptor stream.
this means the visuals are not just the generative adversarial network output but a
layered composition where the generated images form a base layer and additional visual
elements respond directly to the audio descriptors in real time.

the renderer lives in the `renderer/` directory and consists of

- `index.html` entry point
- `sketch.js` main p5.js visualization code
- `ws_client.js` websocket client for receiving frames and descriptors
- `compositor.js` layer compositing logic
- `shaders/` optional webgl shader files for advanced visual effects

alternative renderers can be implemented by consuming the same websocket stream. the
`renderer-processing/` and `renderer-of/` directories contain stubs for processing
and openframeworks implementations.

---

## the open sound control message format

all communication between supercollider and octave uses open sound control. the
message format is designed to be human readable and easy to parse.

```
/visualizer/descriptors

 /spectral/centroid    float (0.0 1.0 normalized)
 /spectral/flux      float (0.0 1.0 normalized)
 /spectral/rms       float (0.0 1.0 normalized)
 /spectral/mfcc      float[13] (13 coefficients)

 /pitch/frequency     float (hz)
 /pitch/confidence     float (0.0 1.0)

 /onset/detected      int (0 or 1)
 /onset/strength      float (0.0 1.0)

 /ji/harmonic_distance   float (0.0 unbounded)
 /ji/prime_limit      int (2, 3, 5, 7, 11, 13, 17, 19, 23...)
 /ji/consonance      float (0.0 1.0)
 /ji/beating_frequency   float (hz)
 /ji/combination_tones   float[] (detected combination tone frequencies)
 /ji/ratio_numerator    int
 /ji/ratio_denominator   int
 /ji/cents_deviation    float (cents from nearest just ratio)
```

the `/ji/` namespace is what makes this system different from any other audio
visualizer. these messages carry information about the harmonic identity of the
sound not just its spectral surface.

---

## tuning system configuration

tuning systems are defined in plain text files in the `sc/tunings/` directory. each
file defines a scale as a list of frequency ratios relative to the fundamental.

```
# 7-limit just intonation major scale
# each line is a ratio (numerator/denominator) and an optional name

1/1   unison
9/8   major whole tone
5/4   just major third
4/3   perfect fourth
3/2   perfect fifth
5/3   just major sixth
7/4   harmonic seventh
2/1   octave
```

you can define any tuning system you want. harry partchs 43 tone scale. la monte
youngs well tuned piano tuning. ben johnstons extended just intonation notation
mapped to actual ratios. any set of frequency ratios works.

the tuning file format also supports metadata

```
# metadata
name: 11-limit hexany
description: six tones derived from combinations of factors 1 3 5 7 9 11
prime_limit: 11
source: erv wilson

# ratios
1/1   origin
7/6   subminor third
5/4   just major third
11/8  undecimal tritone
3/2   perfect fifth
11/6  undecimal neutral seventh
2/1   octave
```

the prime limit metadata is used by the mapping layer to determine which dimensions
of the latent space to activate. higher prime limits open more dimensions which
generally produces more visually complex output.

---

## installation

### prerequisites

you need four things installed on your machine. all of them are free and open source.

1. **supercollider** download from https://supercollider.github.io
2. **gnu octave** download from https://octave.org/download
3. **python 3.8 or later** for the inference server
4. **a modern web browser** for the p5.js renderer (you already have this)

if you want to run the generative adversarial network inference locally you also need
a cuda capable graphics processing unit. if you dont have one you can run the
inference server on a cloud instance with a graphics processing unit and connect to
it over the network.

### setup

```bash
# clone the repository
git clone https://github.com/[repo-url]/capstone-ai-visualizer-open.git
cd capstone-ai-visualizer-open

# install python dependencies for the inference server
cd inference
pip install -r requirements.txt

# download model weights (biggan by default)
python download_weights.py

# install octave packages
cd ../octave
octave --eval "pkg install -forge control signal"

# thats it. no maxmsp license. no runwayml account. no subscriptions.
```

### verify installation

```bash
# start the inference server
cd inference
python server.py --model biggan --port 8080

# in a new terminal start the octave mapping layer
cd octave
octave osc_receive.m

# open supercollider and run boot.scd then analysis.scd

# open renderer/index.html in your browser

# play some music into your microphone or load an audio file in supercollider
```

---

## usage

### basic usage with a microphone

1. start the inference server: `python inference/server.py`
2. start the octave mapping layer: `octave octave/osc_receive.m`
3. open `sc/boot.scd` in supercollider and evaluate it
4. evaluate `sc/analysis.scd` to start descriptor extraction
5. open `renderer/index.html` in your browser
6. play music near your microphone and watch

### basic usage with an audio file

same as above but instead of using the microphone evaluate `sc/file_input.scd`
with the path to your audio file

### using a custom tuning system

1. create a tuning file in `sc/tunings/` following the format described above
2. in supercollider load your tuning: `~tuning = Tuning.new(ratios)`
3. the just intonation descriptors will automatically use the loaded tuning
  system for computing harmonic distance prime limit and consonance

### adjusting the mapping

the mapping from descriptor space to latent space is defined in
`octave/latent_map.m` and can be customized for different aesthetic goals.
the default mapping uses the following relationships

- spectral centroid drives latent space magnitude (brightness = visual intensity)
- spectral flux drives interpolation speed (changing timbre = visual motion)
- prime limit drives the number of active latent dimensions
- consonance drives the smoothness of latent space interpolation
- onset detection triggers class vector transitions
- mel frequency cepstral coefficients modulate fine grained latent features

you can modify these relationships by editing `latent_map.m`. the function takes
a descriptor vector and returns a latent vector. everything in between is yours to
change.

---

## project structure

```
capstone-ai-visualizer-open/
│
├── sc/               supercollider audio engine
│  ├── boot.scd           server startup
│  ├── synths.scd          just intonation synthesizers
│  ├── analysis.scd         descriptor extraction
│  ├── osc_send.scd         open sound control output
│  ├── file_input.scd        audio file playback
│  └── tunings/           tuning system definitions
│    ├── 5-limit-major.txt
│    ├── 7-limit-major.txt
│    ├── 11-limit-hexany.txt
│    ├── partch-43.txt
│    └── README.md
│
├── octave/             mapping and computation layer
│  ├── osc_receive.m        open sound control listener
│  ├── descriptor_normalize.m    normalization
│  ├── latent_map.m         descriptor to latent mapping
│  ├── class_select.m       class vector selection
│  └── ji_math/           just intonation math
│    ├── prime_factorize.m
│    ├── harmonic_distance.m
│    ├── consonance.m
│    └── lattice.m
│
├── inference/            generative adversarial network server
│  ├── server.py          http inference server
│  ├── biggan_wrapper.py      biggan model code
│  ├── stylegan_wrapper.py     stylegan3 model code
│  ├── download_weights.py     model weight downloader
│  └── requirements.txt       python dependencies
│
├── renderer/            p5.js browser renderer (default)
│  ├── index.html
│  ├── sketch.js
│  ├── ws_client.js
│  ├── compositor.js
│  └── shaders/
│
├── renderer-processing/       processing desktop renderer (stub)
├── renderer-of/           openframeworks renderer (stub)
│
├── docs/              documentation
│  ├── architecture.md
│  ├── descriptors.md
│  ├── tuning-systems.md
│  └── mapping-guide.md
│
├── examples/            example tunings and configurations
│  ├── la-monte-young-well-tuned.txt
│  ├── partch-monophonic-fabric.txt
│  ├── wilson-hexany.txt
│  └── demo-7-limit.scd
│
├── tests/              test files
│  ├── test_descriptors.scd
│  ├── test_osc.m
│  └── test_inference.py
│
├── LICENSE
├── CONTRIBUTING.md
└── README.md            you are here
```

---

## design philosophy

### every layer is replaceable

the pipeline communicates through standard protocols not internal apis. this means
any component can be swapped without affecting the others. if someone builds a
better renderer it drops in. if a new generative model comes out it drops in. if
someone prefers puredata over supercollider it drops in. the architecture serves
collaboration by making independence the default.

### tuning awareness is not optional

most audio visualization systems treat frequency as a continuous variable with no
harmonic structure. this system treats frequency relationships as having mathematical
identity. a 3/2 ratio is not just a pair of frequencies that happen to be 1.5 times
apart. it is a specific point in harmonic space with specific acoustic properties
that should produce specific visual results. this distinction is baked into every
layer of the pipeline.

### open source is not a feature its the point

the goal is not to build a tool that happens to be open source. the goal is to build
a tool that could not exist without being open source. the diversity of expertise
required to build something that spans real time audio processing tuning theory
numerical computation neural network inference and real time graphics is not found in
one person or one team. it is found in a community of people with different skills
and different knowledge working on shared problems with shared tools.

### real time is the goal

the original system generated images in batch then stitched them into a video. this
edition aims for real time visualization where the visuals respond to the music as
it happens. this changes the performance requirements at every layer but it also
changes what the tool can be. a real time visualizer is an instrument not just a
post production tool. you can perform with it. you can improvise with it. you can
use it in ways that batch processing can never support.

### musicians first programmers second

the interfaces and configuration formats are designed for musicians who may not be
programmers. tuning systems are defined as lists of ratios not as code. the default
renderer runs in a browser with no installation. the supercollider code is documented
for people who know music theory but may be new to code. when there is a tension
between technical elegance and musical accessibility we choose accessibility.

---

## roadmap

### phase 1 proof of concept (current)
- supercollider patch that synthesizes just intonation intervals and extracts
 spectral descriptors in real time
- open sound control output of descriptor stream
- simple receiver that maps descriptors to visual parameters
- verify the pipeline works end to end

### phase 2 just intonation descriptor set
- implement all custom descriptors (harmonic distance prime limit consonance
 beating frequency combination tone detection)
- validate descriptors against known tuning system properties
- document the descriptor set for contributors

### phase 3 mapping layer
- gnu octave scripts for mapping descriptors to latent space
- parameter relationships between interval qualities and latent dimensions
- configurable mapping profiles for different aesthetic goals

### phase 4 real time renderer
- p5.js renderer with websocket input
- frame compositing with reactive geometry
- basic user interface for parameter adjustment

### phase 5 polish and documentation
- installation scripts and automated setup
- comprehensive documentation
- example configurations for common tuning systems
- video demonstrations

### future possibilities
- diffusion model support (replacing generative adversarial networks with newer
 architectures)
- multi channel audio support (different instruments mapped to different visual
 layers)
- collaborative network mode (multiple musicians driving one visualization)
- virtual reality output
- mobile support
- integration with digital audio workstations via virtual studio technology plugins
- machine learning trained mappings that learn from user preferences
- support for scala tuning file format (.scl) which is the existing standard for
 microtonal tuning definitions
- lattice visualization mode that shows the just intonation lattice itself
 responding to the music in real time

---

## contributing

we follow eriks original contribution guidelines with some additions.

### process

1. if we havent met send an email. we would love to talk with you about the project
  and get to know you
2. work on your own feature branch and never commit directly to main
3. always start your feature branches from the most updated version of main
4. if you havent worked on your feature in a while rebase your branch
5. make narrow commits. do leave todo comments
6. commit often
7. once youve fully implemented your feature submit a pull request detailing the
  feature and any bugs it introduced
8. squash commits before making a pull request

### areas where we especially want help

- **supercollider expertise** people who know the unit generator architecture and
 can help build efficient descriptor extraction chains
- **just intonation theory** people who understand extended just intonation harmonic
 lattices combination tones and the mathematics of pure intervals
- **generative adversarial network / generative model expertise** people who can help
 optimize inference speed and explore alternative model architectures
- **creative coding** people who can make the renderer output beautiful and responsive
- **documentation** people who can write clear guides for musicians who are new to
 these tools
- **testing** people who can help validate descriptor accuracy and pipeline reliability

### what makes a good contribution

- it works
- it has tests
- it is documented
- it follows the project structure
- it does one thing well rather than many things partially
- it is kind to the next person who reads the code

### code of conduct

be kind. be patient. be generous with your knowledge. remember that people come to
this project with different backgrounds and different expertise. someone who knows
everything about the 43 tone scale might not know what a websocket is and thats fine.
someone who can write a generative adversarial network inference server in their sleep
might not know what a harmonic seventh is and thats also fine. the whole point is that
we need each other.

---

## credits and lineage

this project is built on the foundation of erik cohens original capstone ai visualizer
created for his music interdisciplinary computation major at colby college under the
guidance of professor jose martinez. the original project demonstrated that neural
network image generation could be driven by acoustic analysis in a musically meaningful
way. everything here grows from that insight.

### the original project

- **erik cohen** colby college class of 2022 original concept design and
 implementation
- **professor jose martinez** colby college department of music academic advisor

### open source tools this project depends on

- **supercollider** james mccartney and the supercollider community
- **gnu octave** john w eaton and the octave development community
- **biggan** andrew brock jeff donahue and karen simonyan at deepmind
- **p5.js** lauren lee mccarthy and the processing foundation
- **ffmpeg** fabrice bellard and the ffmpeg developers

### intellectual lineage

the just intonation foundations of this project draw on the work of

- **harry partch** who built instruments to play in extended just intonation and
 proved that pure intervals are not a theoretical curiosity but a living musical
 practice
- **la monte young** whose well tuned piano installation demonstrated that sustained
 just intonation intervals produce acoustic phenomena that equal temperament cannot
- **ben johnston** who developed a notation system for extended just intonation and
 composed string quartets that explore harmonic space up to the 31st prime
- **erv wilson** who mapped the geometric structures of just intonation scales and
 discovered the combination product sets that this projects tuning configurations
 draw from
- **marc sabat and wolfgang von schweinitz** whose helmholtz ellis just intonation
 pitch notation provides a practical framework for working with extended primes

---

## license

this project is released under the mit license. use it. modify it. share it.
build something beautiful with it.

---

## contact

### original project
erik cohen erikjkcohen@gmail.com

### open source edition
[your name] [your email]

submit issues and pull requests through github.
we respond to everything.

---

*built with math and music and the belief that the best tools are the ones everyone
can use*
