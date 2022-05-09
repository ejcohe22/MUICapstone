/**
 * BigGanConnect.js
 * Author: Erik Cohen
 * MU492 Capstone Spring'22
 * 
 * Adapted from
 * https://github.com/msieg/deep-music-visualizer/blob/master/visualize.py
 */

const maxMSP = require('max-api');

//FileIO
const fs = require('fs');
const _ = require('lodash');

const axios = require('axios');// Promise Based Networking
var np = require('numjs');// numpy like library

const { spawn } = require('child_process');


/***********************************************************************************************
*										Setting Up Variables
************************************************************************************************/
//Print Out Params
let verbose = true; // additional checkpoint printouts
let debug = false; // information for vector generation
let videoDebug = false; //cmdline information for ffmpeg creation

// Arguments
let videoLength = 1; //seconds
let framePerSecond;
var count = 0; // image generation count
var randomness = .4; // how vivid an image gets restricts domain of noise vectors
var tempoSensitivity = .25; // Affects how sensitive the images are to tempo

// model params ** RUNWAYML **
let send = true; // whether to send to RunwayML
// get class labels for BigGan
var class_labels = JSON.parse(fs.readFileSync('./GanLabels.txt', {encoding:'utf8', flag:'r'}));
let port = 8000;
let postURL = `http://localhost:${port}/query`;
let getURL = `http://localhost:${port}/data`;
	
var power = [];//[.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9,.9];
var classVector=[];

var classList = [108,727,782];


// store image location
let imgFolder = "./imgs";
let base64String = '';

//initialize noise vector variables
var noiseVector1 = np.random(128);
var noiseVector2 = np.zeros(128);
var prevNoiseVector = np.zeros(128);
var updateDir = np.zeros(128);
var lastUpdateDir = np.zeros(128);
let noiseVectors = [];
var audioFile = "";


//set port
maxMSP.addHandler("verbose", v => {
	if(v > 0){
		verbose = true;
	}else{
		verbose = false;
	}
	maxMSP.post("verbose", verbose);
})

//set port
maxMSP.addHandler("tempoSensitivity", tS => {
    tempoSensitivity = tS;
	if(verbose){
    maxMSP.post("tempo sensitivity", tempoSensitivity);
	}
})

//set port
maxMSP.addHandler("randomness", r => {
    randomness = r;
	if(verbose){
    maxMSP.post("randomness", randomness);
	}
})

//set port
maxMSP.addHandler("port", p => {
    port = p;
    postURL = `http://localhost:${port}/query`;
    getURL = `http://localhost:${port}/data`;
	if(verbose){
    maxMSP.post("POST", postURL);
    maxMSP.post("GET", getURL);
	}
})

// set videoLength
maxMSP.addHandler("videoLength", len => {
    videoLength = len;
	if(verbose){
    maxMSP.post("video length", videoLength);
	}
})

// set fps
maxMSP.addHandler("fps", fps => {
    framePerSecond = fps;
	if(verbose){
    maxMSP.post("fps", framePerSecond);
	}
})

// set audioFile
maxMSP.addHandler("setAudioFile", fileName => {
	if(verbose){
		maxMSP.post("received Audio File", fileName);
	}
    audioFile = fileName
			
	
})


// set gradient
maxMSP.addHandler("setSongAnalysis", l => {
	if(verbose){
		//maxMSP.post("received", l);
	}
	
	classVector = [];
	var ff = l["flist"];
	
    loudness = l["plist"];
	power = computeGradient(loudness);
	
	classVector = getClasses(ff, classList);
			
	if(verbose){
		//for( let i = 0; i < loudness.length; i++){
		//	maxMSP.post(`loudness = ${loudness[i]}, powerGrad = ${power[i]}`);
		//}
		
    	maxMSP.post("power", power);
	}
	maxMSP.post("class length: ", classVector.length);
	maxMSP.post("power length: ", power.length);
	
})

/**
* Each time point is equal to the (difference on either side )/ ∆ time
* Boundaries contain only one difference.
**/

function computeGradient(loudness){
	power = [];
	// ** compute gradient **
	power.push(loudness[1] - loudness[0]);
	
	// get ∆
	for (let i = 2 ; i < loudness.length - 1; i++) {
		power.push( (loudness[i] - loudness[i-2])/2 );
	}
	power.push(loudness[loudness.length - 1] - loudness[loudness.length - 2]);
	var npPower = np.array(power);
	
	//maxMSP.post("nd", npPower);
	
	var maximum = npPower.max();
	
	// //normalize + clip negatives
	for (let i = 0 ; i < power.length; i++) {
		if(power[i] < 0){
			power[i] = 0;
		}
		power[i] = power[i] / maximum;
	}
	
	return power

}

/**
* Takes in an array of Fundamental Frequencies
* and a list of desired classes.
* Generates a list of the classes mapped 
* to the Fundamental Frequency
**/
function getClasses(ff, classList){
	var segment = 1/classList.length;
	
	for (let i = 0 ; i < power.length; i++) {
		var class_index = 0;
		
		while((segment * (class_index + 1)) < ff[i]){
			segment = segment 
			class_index++;
		}
		maxMSP.post(class_index);
		classVector[i] = classList[class_index];
	}
	
	
	return classVector;
}



/***********************************************************************************************
*
*									Generate Noise Vector
*
************************************************************************************************/

function getNewUpdateDir(_callback){
	for (const [index, element] of noiseVector2.tolist().entries()) {
        if(element >= (2 * randomness - tempoSensitivity)){
            updateDir.set(index, -1);
        }else if(element < (-2 * randomness + tempoSensitivity)){
            updateDir.set(index, 1);
        }
    }
    _callback();
}


function initializeNoiseVectors(_callback){
    noiseVector1 = np.random(128);
    noiseVector1 = noiseVector1.multiply(2).add(-1);
    // initialize the direction of noise vector unit updates
    for (const [index, element] of noiseVector1.tolist().entries()) {
        if(element < 0){
            updateDir.set(index, 1);
        }else{
            updateDir.set(index, -1);
        }
    }
    prevNoiseVector = np.abs(noiseVector1);
    noiseVectors = [prevNoiseVector];
    lastUpdate = np.zeros(128);
    _callback();
}

function createNoiseVector(timeStep, _callback){
    noiseVector1 = prevNoiseVector;
    // set update
	var intensity = .1;
    var update = np.ones(128).multiply(tempoSensitivity);
    update = update.multiply(updateDir);
	if(timeStep< power.length){
		 intensity = power[timeStep];
	}
    var change = np.ones(128);
	change = change.multiply(intensity);
    update = update.multiply(change); //* (gradm[i]+specm[i]) * jitters
    
    //smooth update
    update = ((update.add(lastUpdate)).multiply(3)).divide(4);
    lastUpdate = update;
    
    noiseVector2 = noiseVector1.add(update);
    noiseVectors.push(np.abs(noiseVector2));
    
    prevNoiseVector = noiseVector2;
                   
    getNewUpdateDir(function(){
	if(debug){
        maxMSP.post("updated direction!");
        //maxMSP.post(`nv1: ${noiseVector1}, nv2: ${noiseVector2}, update: ${update}, updateDir: ${updateDir}`)
		maxMSP.post("val", noiseVector2.get(0));
	}
    })
    _callback();
}


/***********************************************************************************************
*									Get Images from Runway to Save
************************************************************************************************/

function generateImage() {
    let latentSpaceVector = noiseVectors[count].tolist();
	const data = {
            z: latentSpaceVector,
            category: class_labels[classVector[count]], //978, /972, 727 975
	}
	if(send){
    axios
        .post(postURL, data) // send image to Runway
        .then(() => {
            axios
                .get(getURL)// receive image
                .then((response) => {
                    base64String = response.data.generated_output;
                    writeBinaryImagesToDisk();
                })
                .catch((error) => {
                    maxMSP.post(error);
                })
        })
	}
}


/***********************************************************************************************
*									Helper method to save files
************************************************************************************************/

function writeBinaryImagesToDisk() {
    let base64Data = base64String.replace(/^data:image\/\w+;base64,/, '');
    let binaryImage = Buffer.from(base64Data, 'base64');
    let imgNumber = _.padStart(count, 4, '0');
	maxMSP.outlet('totalImg', Math.ceil(framePerSecond * videoLength));
	maxMSP.outlet('imgProgress', count);
    count++
    // combine folder and image number
    let imgTitle = `${imgFolder}/image_${imgNumber}.png`;
	

    fs.writeFile(`${imgTitle}`, binaryImage, function (err, data) {
		if(verbose){
        maxMSP.post(`The file ${imgTitle} has been saved!`)
		}
        if (count < Math.ceil(framePerSecond * videoLength)) {
            setTimeout(function(){generateImage();}, 300) // delay time
        }else{
            maxMSP.post("Finished!")
        }
    });
}


/***********************************************************************************************
*									Create Images
************************************************************************************************/

maxMSP.addHandler('generateImage', () => {
	count = 0;
	maxMSP.post(framePerSecond, videoLength, numberOfFrames);
    var numberOfFrames = Math.ceil(framePerSecond * videoLength);
	maxMSP.post(framePerSecond, videoLength, numberOfFrames);
	
    initializeNoiseVectors(function(){
	if(verbose){
        maxMSP.post(`Generate vector: 1/${numberOfFrames}`)
	}
    }); // wait to finish

    var noiseVectorsToGenerate = numberOfFrames - 1;
    for (let j = 0; j < noiseVectorsToGenerate; j++) {
		createNoiseVector(j, function(){
		if(verbose){
            maxMSP.post(`Generated vector: ${j+2}/${numberOfFrames}`)
		}
        });
    }
    maxMSP.post("Finished Generating Vectors!")
	generateImage();
})

/***********************************************************************************************
*									Create Movie
************************************************************************************************/

function generateVideo() {
    var cmd = '/usr/local/Cellar/ffmpeg/5.0/bin/ffmpeg'
		//ffmpeg -r 60 -f image2 -s 1280x720 -i pic%05d.png -i MP3FILE.mp3 -vcodec libx264 -b 4M -vpre normal -acodec copy OUTPUT.mp4 
        // ffmpeg -r 25 -vcodec mjpeg -s 512x512 -i image%04d.png -vb 20M output.mov

    var args = [
        '-y', // overwrite output file
        '-r', // rate fps codec format
        framePerSecond,
        '-vcodec', // codec format
        'mjpeg',
        '-s', // size
        '512x512',
        '-i', //input file name
        `${imgFolder}/image_%04d.png`,
		'-i',
		audioFile,
        '-vb', // video bitrate
        '20M',
        `${imgFolder}/output.mov`,
    ]

	maxMSP.post(args);

    // run the command line given by cmd, args
    var proc = spawn(cmd, args)
    proc.stdout.on('data', function(data) {
	if(videoDebug){
        maxMSP.post(data);
	}
    })

    // print progesses on max console
    proc.stderr.setEncoding('utf8');
    proc.stderr.on('data', function(data) {
	if(videoDebug){
        maxMSP.post(data);
	}
    })

    // once the process is done, we send the video path to jit.qt.movie
    proc.on('close', function() {
        maxMSP.outlet('videoExported', 'done!');
        maxMSP.post('Finished Video');
        maxMSP.outlet('videoPath', "/Users/ErikCohen/Desktop/491/output.mov");
    })
}

maxMSP.addHandler('generateVideo', () => {
    generateVideo();
})