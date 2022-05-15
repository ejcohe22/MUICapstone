# Capstone AI visualizer
Erik Cohen - Colby College '22
Professor Jose Martinez - Colby College Department of Music

An AI Music Visualizer created for Music Interdisciplinary Computation Major. Input to BigGAN is created by analyzing an audio file with IRCAM descriptors.

This project is built for musicians and is meant to bring this type of AI into the hands of computational musicians with the tools that they use. 

---
# Install Instructions

This system requires [MaxMSP](https://cycling74.com/downloads), [Node.js](https://nodejs.org/en/), [RunwayML](https://runwayml.com/), and the [FFmpeg tool](https://ffmpeg.org/).

1. Make sure the above software is installed on your machine.
2. Gain access to the source code in this repository (you can download as a zip file or clone the repository).
3. In the MaxMSP package manager install the MaxSoundBox and Bach Libraries. You may also need specify access to your current folder in "Options > File Preferences…".
4. Install the node dependencies. To do this move into the project "src" folder in terminal and run "npm install".
5. In Runway ML, setup your network by going to the ML Lab. Search for BigGAN and add it to your workspace. 

---
# How to use
1.  Open ML.maxpat. (src >ML.maxpat) This is the main system designed for MaxMSP. 
2. Open Runway and start your model (this may take 1-3 minutes)
3. In Max specify the FPs, model port, and your parameters. Choose a song and click "run analysis".
4. Clear the "imgs" folder. Once your model is ready click "generate image" to start creating your visualization. This process can take a long time depending on your fps and song length. There is a progress bar that will show the proportion of images generated.
5. Once the images are generated, the "imgs" folder will be filled. Click "generate video" and the final video will be stored in the "imgs" folder.

---
# Contact
If you have any questions, suggestions, or want to contribute to this project submit an issue or reach out at:
erikjkcohen@gmail.com

---
# Process for Contributing
If we haven't met, send me an email (erikjkcohen@gmail.com). I would love to talk with you about this project and get to know you!
	
1. Work on your own feature branch and never commit directly to main.
2. Always start your feature branches from the most updated version of the main branch.
3. If you haven't worked on your feature in quite some time, rebase your branch.
4. Make narrow commits. Do leave TODO comments.
5. Commit often. If you need to roll changes back, it's nice to have a recent commit as opposed to re-writing 100 lines of code just to undo a couple of changes.
6. Once you've fully implemented the feature you've worked on, submit a pull request detailing the feature and any bugs it introduced.
7. Squash commits before making a pull request.
