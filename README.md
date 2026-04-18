# anceps
open source artificial intelligence music visualization of frequencies ratios in real time
analyzes audio through extended just intonation. generates live visuals with generative adversarial networks. everything free and open.
## why
the original capstone visualizer (erik cohen, colby college) proved neural networks can drive meaningful visual output from acoustic analysis. this edition replaces proprietary maxmsp + runwayml with supercollider + gnu octave + self-hosted inference. adds deep just intonation support.
three beliefs: 
(1) music tools should be free and open
(2) just intonation produces fundamentally different acoustic phenomena than equal temperament
(3) the best outcomes comes from diverse people solving meaningful difficult shared problems
## design
- every layer replaceable (protocols not APIs)
- tuning awareness baked in (not optional)
- open source is the point (not a feature)
- real-time (instrument, not post-production)
- musicians first, programmers second
## license
this is free and unencumbered software released into the public domain. anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means. in jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. we make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. we intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law. the software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and non-infringement. in no event shall the authors be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
## secret steps for erik's eyes only1
conda create -n octave-env -c conda-forge octave
conda activate octave-env
octave
