//Sonic Mirror - 02_SynthDefs:


//add Specs?

(
//Record audio input to buffer using audio-rate input Phasor to control position in buffer
SynthDef(\bufRec, { //<---NEW -- Added Lo-cut
	arg phaseBus, buf, sendBus, loCutoff = 90, rQ = 1, mul = 1;
	//var sig = SoundIn.ar(bus: 0, mul: mul);
	var sig = BHiPass4.ar( SoundIn.ar(bus: 0, mul: 1), loCutoff, rq: rQ, mul: mul); //pass SoundIn through HiPass
	BufWr.ar(sig, buf, InFeedback.ar(phaseBus) );
	//OffsetOut.ar(sendBus, sig);  //would this provide better sample accurate scope plotting and recording?
	Out.ar(sendBus, sig);
} ).add;


SynthDef.new(\bufRead_complex1, { //<----NEW --- TEST
	arg buf, duration, amp=1, rate = 1, pitch = 1, pShiftMix = 0, out = 0;
	var sig1, sig2, sigOut, frames, dur, env, phasor;
	frames = BufFrames.kr(buf);
	dur = duration.asFloat; //total playback duration in seconds
	env = Env.linen(attackTime: 0.02, sustainTime: (dur - 0.04), releaseTime: 0.02, level: 1);
	phasor = Phasor.ar(0, BufRateScale.kr(buf) * rate, 0, frames - 1);
	sig1 = BufRd.ar(1, buf, phasor);
	sig2 = PitchShift.ar(sig1, windowSize: 0.2, pitchRatio: pitch, pitchDispersion: 0, timeDispersion: 0.003);
	sigOut = SelectX.ar(pShiftMix, [sig1, sig2]) * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sigOut * amp);
} ).add;

SynthDef.new(\bufRead_noLoop, {
	arg buf, rate = 1, amp=1, out=0;
	var sig, frames, dur, env, phasor;
	frames = BufFrames.kr(buf);
	//dur = frames / BufSampleRate.kr(buf); // in seconds
	dur = BufDur.kr(buf); //in seconds
	env = Env.linen(attackTime: 0.02, sustainTime: (dur - 0.04), releaseTime: 0.02, level: 1);
	//phasor = Phasor.ar(0, BufRateScale.kr(buf) * rate, 0, frames);
	phasor = Phasor.ar(0, BufRateScale.kr(buf) * rate, 0, frames - 1);
	sig = BufRd.ar(1, buf, phasor, loop: 0) * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
} ).add;

SynthDef.new(\bufRead, { //define synth to read from buffer w/ phasor...
	arg amp=1, out=0, phaseBus, buf;
	var sig = BufRd.ar(1, buf, InFeedback.ar(phaseBus));
	sig = sig * amp;
	Out.ar(out, sig);
} ).add;

// Phasor indexes through buffer at audio rate
SynthDef(\phasor, {
	//arg out=0, buf, trig = 0, rate = 1, start = 0, end = BufFrames.kr(buf) - 1, resetPos = 0;
	arg out=0, buf, trig = 0, rate = 1, start = 0, end = 1, resetPos = 0; //<---don't remember why I used other lines....and why they worked...
	//Out.ar(out, Phasor.ar(trig, BufRateScale.kr(buf) * rate, start * BufFrames.kr(buf), (end * BufFrames.kr(buf)) - 1, resetPos ) );
	Out.ar(out, Phasor.ar(trig, BufRateScale.kr(buf) * rate, start, end, resetPos ) );
}).add;


SynthDef(\a2k_patch, {// Needed to monitor phasor val (don't fully understand why / how this works)
  arg in, out;
  Out.kr(out, A2K.kr(InFeedback.ar(in) ) ); //is InFeedback necessary?
}).add;

SynthDef.new(\pitchShifter, {
	//arg inBus, outBus, windowSize = 0.1, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.002, amp = 1; //<--orig
	arg inBus, outBus, windowSize = 0.1, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.003, amp = 1;
	//arg inBus, outBus, windowSize = 0.005, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.003, amp = 1; //<--decent settings for piezo....
	var sigIn, sigOut;
	sigIn = In.ar(inBus, 1);
	//sigIn = InFeedback.ar(inBus, 1);
	sigOut = PitchShift.ar(sigIn, windowSize, pitchRatio, pitchDispers, timeDispers, amp);
	Out.ar(outBus, sigOut);
}).add;

SynthDef.new(\XFade, {
	|in1, in2, out, amountControlBus, amp = 1|
	var inArray, mixSignal, sig;
	inArray = [In.ar(in1), In.ar(in2)];
	//inArray = [InFeedback.ar(in1), InFeedback.ar(in2)];
	mixSignal = SelectX.ar(amountControlBus, inArray);
	sig = mixSignal * amp;
	Out.ar(out, sig);
} ).add;

SynthDef(\LinInterp_pitch, {
	arg startVal, stopVal, duration, out;
	Out.kr(out, Line.kr(startVal, stopVal, duration, doneAction: 2).midiratio);
} ).add;

SynthDef(\LinInterp_rate, {
	arg startVal, stopVal, duration, out, rateMod = 1;
	var outputVal = rateMod * Line.kr(startVal, stopVal, duration, doneAction: 2).midiratio;
	Out.kr(out, outputVal);
} ).add;

SynthDef(\LinInterp_num, {
	arg startVal, stopVal, duration, mult = 1, out;
	Out.kr(out, Line.kr(startVal, stopVal, duration, mul: mult, doneAction: 2));
} ).add;

SynthDef.new(\subMix, {
	|in, amp = 1, out|
	var sig;
	sig = In.ar(in) * amp;
	//sig = InFeedback.ar(in) * amp;
	//OffsetOut.ar(out, sig);
	Out.ar(out, sig);
} ).add;

SynthDef.new(\mainOut, { //w/ Lo-cut
	|in, loCutoff = 90, rQ = 1, amp = 1|
	var sig;
	sig = BHiPass4.ar( In.ar(in), loCutoff, rq: rQ, mul: amp);
	//sig = In.ar(in) * amp;
	//sig = InFeedback.ar(in) * amp;
	//OffsetOut.ar(0, sig);
	Out.ar([0, 1], sig);
} ).add;

SynthDef.new(\scopeOut, { //<------NEW
	//|inBus, buf, frames = 4096|
	|inBus, buf|
	var sig;
	sig = In.ar(inBus, 1);
	ScopeOut2.ar(sig, buf);
	//ScopeOut2.ar(sig, buf, BufFrames.kr(buf));
	//ScopeOut2.ar(sig, buf, 262144, 524288);
	//ScopeOut2.ar(sig, buf, 2641920, 2641920);
	//ScopeOut2.ar(sig, buf, frames);
} ).add;

SynthDef(\write2Disk, {arg buf, inBus = 0; //record audio file to disk - mono
	DiskOut.ar(buf, In.ar(inBus, 1));
}).add;

// play audio file from disk w/ fade in-out
SynthDef(\readDisk, { arg buf, sampleDur, amp = 1, out;
	var env, envgen, sig;
	env = Env.linen(attackTime: 0.02, sustainTime: (sampleDur - 0.04), releaseTime: 0.02, level: 1);
	envgen = EnvGen.ar(env, doneAction: 2);
	sig = (DiskIn.ar(1, buf) * envgen) * amp;
	Out.ar(out, sig);
}).add;

//  FEATURE EXTRACTORS --------------

SynthDef.new(\Loudness, {
	//arg input, buffer, outBus;
	arg input, outBus;
	var sigIn, fft, loudness;
	sigIn = In.ar(input);
	//fft = FFT(buffer, sigIn, wintype: 1);
	fft = FFT(LocalBuf(1024), sigIn, wintype: 1); //using LocalBuf per HelpFile recommendation, 1024 frame size recommended for samp rates 44100 and 48000 and 2048 for rates 88200 and 96000
	loudness = Loudness.kr(fft);
	//loudness.poll(trig: 10, label: "Sones");
	Out.kr(outBus, loudness);
}).add;

SynthDef.new(\RMS, {
	arg input, numSamp = 40, outBus;
	var sigIn, rms;
	sigIn = In.ar(input);
	rms = (RunningSum.kr(sigIn.squared, numSamp) / numSamp).sqrt;
	//rms.poll(trig: 10, label: "RMS");
	Out.kr(outBus, rms);
}).add;

SynthDef.new(\Pitch, {
	arg input, ampThresh = 0.04, median = 7, minFreq = 60, maxFreq = 4000, clar = 0, outBus;
	var sigIn, freq, hasFreq;
	sigIn = In.ar(input);
    # freq, hasFreq = Pitch.kr(sigIn, ampThreshold: ampThresh, median: median, minFreq: minFreq, maxFreq: maxFreq, clar: clar);
    //freq = Lag.kr(freq.cpsmidi.round(1).midicps, 0.05);
	Out.kr(outBus, [freq, hasFreq]);
    //freq.poll(trig: 10, label: "Freq");
	//hasFreq.poll(trig: 10, label: "HasFreq");
}).add;

SynthDef.new(\Pitch2, {
	arg input, ampThresh = 0.04, median = 7, minFreq = 60, maxFreq = 4000, clar = 0, outBus;
	var sigIn, freq, hasFreq, midinote;
	sigIn = In.ar(input);
    # freq, hasFreq = Pitch.kr(sigIn, ampThreshold: ampThresh, median: median, minFreq: minFreq, maxFreq: maxFreq, clar: clar);
	//midinote = Lag.kr(freq.cpsmidi.round(1), 0.05);
	midinote = freq.cpsmidi.round(1);
	Out.kr(outBus, [freq, hasFreq, midinote]);
    //freq.poll(trig: 10, label: "Freq");
	//hasFreq.poll(trig: 10, label: "HasFreq");
}).add;

SynthDef.new(\MFCC, {
	//arg input, buffer, outBus;
	arg input, outBus;
	var sigIn, fft, array;
	sigIn = In.ar(input);
	//fft = FFT(buffer, sigIn, wintype: 1);
	fft = FFT(LocalBuf(1024), sigIn, wintype: 1);
	array = MFCC.kr(fft); //outputs 13 coefficients by default
	Out.kr(outBus, array);
	//array.poll(trig: 10, label: "MFCCs");
}).add;

SynthDef.new(\specCent, {
	arg input, outBus;
	var sigIn, fft, centroid;
	sigIn = In.ar(input);
	fft = FFT(LocalBuf(2048), sigIn, wintype: 1);
	centroid = SpecCentroid.kr(fft);
	Out.kr(outBus, centroid);
}).add;

SynthDef.new(\specFlat, {
	arg input, outBus;
	var sigIn, fft, flatness, flatdb, flatdbScaled;
	sigIn = In.ar(input);
	fft = FFT(LocalBuf(2048), sigIn, wintype: 1);
	flatness = SpecFlatness.kr(fft);

	//flatdb = 10 * flat.log; //convert flatness to decibels
	//flatdbScaled = LinLin.kr(flatdb, -45, -1.6, 0, 1).max(-10); // Rescale db roughly to 0...1

	Out.kr(outBus, flatness);
}).add;

SynthDef.new(\onsets, {
	arg input, outBus, threshold = 0.5, trigtime = 0.1, odtype = \rcomplex, reltime = 1.0, floor = 0.1;
	var sigIn, fft, onsets, trigger;
	sigIn = In.ar(input);
	fft = FFT(LocalBuf(1024), sigIn, wintype: 1);
	onsets = Onsets.kr(fft, threshold, odtype, reltime, floor);
	trigger = Trig1.kr(onsets, trigtime);
	//trigger.poll(10, label: 'trig'); //uncomment this to monitor trigger val constantly
	Out.kr(outBus, trigger);
}).add;

//------

SynthDef.new(\monAudioInput, { //not sure if I need this currently.....
	arg inChannel = 0, amp = 1, outBus;
	var sig = SoundIn.ar(bus: inChannel, mul: amp); //defaults to first channel of system audio input
	OffsetOut.ar(outBus, sig);
}).add;

);