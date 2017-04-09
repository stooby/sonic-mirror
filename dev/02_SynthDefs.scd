//Sonic Mirror - 02_SynthDefs:


//add Specs?

(
//Record audio input to buffer using audio-rate input Phasor to control position in buffer
SynthDef(\bufRec, { //<---NEW -- Added Lo-cut
	|phaseBus, buf, sendBus, loCut = 90, loCutQ = 1, /*peak = 120, peakQ = 1, peakGain = 0,*/ mul = 1|
	//var sig = SoundIn.ar(bus: 0, mul: mul);
	var sig = BHiPass4.ar(SoundIn.ar(bus: 0, mul: 1), loCut, rq: loCutQ, mul: mul); //pass SoundIn through HiPass
	//sig = BPeakEQ.ar(sig, freq: peak, rq: peakQ, db: peakGain); //<----consider
	BufWr.ar(sig, buf, InFeedback.ar(phaseBus) );
	//OffsetOut.ar(sendBus, sig);  //would this provide better sample accurate scope plotting and recording?
	Out.ar(sendBus, sig);
} ).add;

SynthDef.new(\bufRead_complex1, {
	|buf, duration, amp=1, attack = 0.02, release = 0.02, rate = 1, pitch = 1, winSize = 0.1, timeDisp = 0.003, pShiftMix = 0, out = 0|
	var sig1, sig2, sigOut, frames, dur, atRelDur, env, phasor;
	frames = BufFrames.kr(buf);
	dur = duration.asFloat; //total playback duration in seconds
	atRelDur = attack.asFloat + release.asFloat;
	env = Env.linen(attackTime: attack, sustainTime: (dur - atRelDur), releaseTime: release, level: 1);
	//env = Env.linen(attackTime: 0.003, sustainTime: (dur - 0.006), releaseTime: 0.003, level: 1); //for fast rate playback
	phasor = Phasor.ar(0, BufRateScale.kr(buf) * rate, 0, frames - 1);
	sig1 = BufRd.ar(1, buf, phasor, interpolation: 4); //<--changed -- interp 4 for faster playback rates
	//sig1 = BufRd.ar(1, buf, phasor);
	sig2 = PitchShift.ar(sig1, windowSize: winSize, pitchRatio: pitch, pitchDispersion: 0, timeDispersion: timeDisp);
	//sig2 = PitchShift.ar(sig1, windowSize: 0.1, pitchRatio: pitch, pitchDispersion: 0, timeDispersion: 0.003);
	//sig2 = PitchShift.ar(sig1, windowSize: 0.35, pitchRatio: pitch, pitchDispersion: 0, timeDispersion: 0);
	sigOut = SelectX.ar(pShiftMix, [sig1, sig2]) * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sigOut * amp);
} ).add;

SynthDef.new(\bufRead_noise1, {
	//arg buf, duration, amp=1, freq = 1, out = 0;
	arg buf, duration, amp=1, modFreq = 0.25, loFreq = 1, hiFreq = 3, out = 0;
	var dur, frames, ptr, env, lfo, sig;
	dur = duration.asFloat; //total playback duration in seconds
	frames = BufFrames.kr(buf);
	lfo = SinOsc.ar(modFreq, 3pi/2).range(loFreq, hiFreq);
	ptr = LFDNoise1.ar(lfo).range(0, frames - 1);
	//ptr = LFDNoise1.ar(freq).range(0, frames - 1);
	env = Env.linen(attackTime: 0.02, sustainTime: (dur - 0.04), releaseTime: 0.02, level: 1);
	sig = BufRd.ar(1, buf, ptr) * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
} ).add;

SynthDef.new(\bufRead_sineSineMod, {
	arg buf, duration, amp=1, lfoFreq = 0.25, loFreq = 1, hiFreq = 3, out = 0;
	var dur, frames, lfo, ptr, env, sig;
	dur = duration.asFloat; //total playback duration in seconds
	frames = BufFrames.kr(buf);
	lfo = SinOsc.ar(lfoFreq, 3pi/2).range(loFreq, hiFreq);
	ptr = SinOsc.ar(lfo, 3pi/2).range(0, frames - 1);
	env = Env.linen(attackTime: 0.02, sustainTime: (dur - 0.04), releaseTime: 0.02, level: 1);
	sig = BufRd.ar(1, buf, ptr) * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
} ).add;

SynthDef.new(\bufRead_noiseSineMod, {
	arg buf, duration, amp=1, lfoFreq = 0.25, loFreq = 1, hiFreq = 3, out = 0;
	var dur, frames, lfo, ptr, env, sig;
	dur = duration.asFloat; //total playback duration in seconds
	frames = BufFrames.kr(buf);
	//lfo = SinOsc.ar(lfoFreq, 3pi/2).range(loFreq, hiFreq);
	lfo = LFDNoise1.ar(lfoFreq).range(loFreq, hiFreq);
	ptr = SinOsc.ar(lfo, 3pi/2).range(0, frames - 1);
	env = Env.linen(attackTime: 0.02, sustainTime: (dur - 0.04), releaseTime: 0.02, level: 1);
	sig = BufRd.ar(1, buf, ptr) * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
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
	var sig = BufRd.ar(1, buf, InFeedback.ar(phaseBus), interpolation: 4); //cubic interpolation (seems to help preserve detail at faster playback rates +24st)
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
	//arg inBus, outBus, windowSize = 0.1, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.002, amp = 1; //v1
	arg inBus, outBus, windowSize = 0.1, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.003, amp = 1; //v1.1, FOR TIME STRETCH (larger time Dispers better for time stretching, but worse for preserving percussive transients)
	//arg inBus, outBus, windowSize = 0.3, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.001, amp = 1; //v2, PRESERVE TRANSIENTS DURING FAST PLAYBACK - good settings for faster playback (+24 rate, -24 pitch)
	//arg inBus, outBus, windowSize = 0.35, pitchRatio = 1, pitchDispers = 0, timeDispers = 0, amp = 1; //v2.1, FAST PLAYBACK (preserves transients better than v1.1 at fast playback rates) <-------------
	//arg inBus, outBus, windowSize = 0.01, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.02, amp = 1; //vPiez_1, decent settings for time stretched piezo...
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

SynthDef(\ExpInterp_num, {|startVal, stopVal, duration, mult = 1, out|
	Out.kr(out, XLine.kr(startVal, stopVal, duration, mul: mult, doneAction: 2));
} ).add;

SynthDef(\asrEnvGen_trig, {|out, attTime = 0.01, susTime = 1, relTime = 2, level = 1, curve = \sine|
	var env, envGen;
	env = Env.linen(attackTime: attTime, sustainTime: susTime, releaseTime: relTime, level: level, curve: curve);
	envGen = EnvGen.kr(env, doneAction: 2);
	Out.kr(out, envGen);
}).add;

SynthDef(\adsrEnvGen, {|out, gate = 1, attTime = 0.01, susTime = 1, relTime = 2, peakLevel = 1, susLevel = 1, curve = \sine|
	var env, envGen;
	env = Env.adsr(attackTime: attTime, decayTime: susTime, sustainLevel: susLevel, releaseTime: relTime, peakLevel: peakLevel, curve: curve);
	envGen = EnvGen.kr(env, gate: gate, doneAction: 2);
	Out.kr(out, envGen);
}).add;

SynthDef(\dEnvGen, {|out, gate = 1, startVal = 0, endVal = 0, peakVal = 1, susVal = 1, attTime = 1, decTime = 1, susTime = 1, relTime = 2, shape = 3, curve = 0, repeat = 1| //shape: 3 => S-curve | 5 => linear | curve vals only effective when shape = 5 | <------USE THIS W/ AUTO-LEVEL / ANTI-FEEDBACK ROUTINES.....
	var levels, durations, env;
	levels = Dseq([startVal, peakVal, susVal, susVal, endVal], repeats: repeat);
	durations = Dseq([attTime, decTime, susTime, relTime], repeats: repeat);
	env = DemandEnvGen.kr(level: levels, dur: durations, shape: shape, curve: curve, gate: gate, doneAction: 2); //if gate <=0, ugen's sampled and held, if gate >=1, it runs...
	Out.kr(out, env);
}).add;

SynthDef.new(\subMix, {
	|in, amp = 1, out|
	var sig = In.ar(in) * amp;
	//sig = InFeedback.ar(in) * amp;
	OffsetOut.ar(out, sig);
	//Out.ar(out, sig);
} ).add;

SynthDef(\comp1, {|bus, thresh = (-6.dbamp), ratio = 2, attack = 0.01, release = 0.25, amp = 1| //<----NEW
	var sigIn, sigOut, ratioConv;
	sigIn = In.ar(bus: bus, numChannels: 1);
	ratioConv = ratio.reciprocal;
	sigOut = Compander.ar(sigIn, sigIn, thresh: thresh, slopeAbove: ratioConv, clampTime: attack, relaxTime: release, mul: amp);
	ReplaceOut.ar(bus, sigOut);
}).add;

SynthDef.new(\mainOut, { //w/ Lo-cut and Peak EQ
	|in, loCut = 90, loCutQ = 1, amp = 1, peak = 120, peakQ = 1, peakGain = 0|
	var sig;
	sig = BHiPass4.ar(In.ar(in), freq: loCut, rq: loCutQ);
	sig = BPeakEQ.ar(sig, freq: peak, rq: peakQ, db: peakGain); //<----NEW
	//sig = In.ar(in) * amp;
	//sig = InFeedback.ar(in) * amp;
	//OffsetOut.ar(0, sig);
	Out.ar([0, 1], sig * amp);
} ).add;

/*  //<------ADDING ---- Main Out w/ soft Limiter
SynthDef.new(\mainOut, { //w/ Lo-cut and Limiter
	|in, loCutoff = 90, rQ = 1, amp = 1|
	var sig;
	sig = BHiPass4.ar(In.ar(in), loCutoff, rq: rQ, mul: amp);
	sig = Compander.ar(in: sig, control: sig, thresh: 0.95, slopeBelow: 1, slopeAbove: 0.1, clampTime: 0.01, relaxTime: 0.1); //set threshold to  -0.3.dbamp  ?
	//OffsetOut.ar(0, sig);
	Out.ar([0, 1], sig);
} ).add; */

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

SynthDef.new(\startupTone_1, {
	var sig, amp, env;
	env = EnvGen.kr(
		Env.new( [0, 1, 0], [6, 4], [1, -1] ),
		doneAction: 2
	);
	amp = SinOsc.kr( {ExpRand(0.2, 12)} ! 3).range(0.1);
	sig = SinOsc.ar( {ExpRand(300, 1200)} ! 3);
	sig = sig * amp * env; //amp mod
	sig = Mix.ar(sig) * 0.20;
	Out.ar(0, sig);
} ).add;

//  UTILITY --------------
SynthDef(\avgKR, {
	|input, output, avgDur = 1|
	var sigIn, avg, numSamp;
	sigIn = In.kr(input, 1);
	numSamp = ControlRate.ir * avgDur;
	avg = (RunningSum.kr(sigIn, numSamp)) * (numSamp.reciprocal);
	Out.kr(output, avg);
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

SynthDef.new(\RMSdb, {
	arg input, numSamp = 40, outBus;
	var sigIn, rms;
	sigIn = In.ar(input);
	rms = (RunningSum.kr(sigIn.squared, numSamp) / numSamp).sqrt;
	Out.kr(outBus, rms.ampdb);
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


//  IMPULSE SOURCES -------

SynthDef(\susWhite1, {|attTime = 3, susTime = 3, relTime = 3, amp = 1, out|
	var sig, env;
	env = Env.linen(attackTime: attTime, sustainTime: susTime, releaseTime: relTime);
	sig = WhiteNoise.ar(1);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
}).add;

SynthDef(\impulsePink1, {
	|decayTime = 2, amp = 0.2, out|
	var sig = Decay.ar(Impulse.ar(0), decayTime, PinkNoise.ar(amp));
	DetectSilence.ar(sig, amp: 0.0001, time: 0.5, doneAction: 2);
	Out.ar(out, sig);
}).add;

SynthDef(\impulseWhite1, {
	|decayTime = 2, amp = 0.2, out|
	var sig = Decay.ar(Impulse.ar(0), decayTime, WhiteNoise.ar(amp));
	DetectSilence.ar(sig, amp: 0.0001, time: 0.5, doneAction: 2);
	Out.ar(out, sig);
}).add;

SynthDef(\impulseWhite2, {
	|attackTime = 0.002, releaseTime = 0.4, curve =  -4, amp = 0.2, out|
	var env, sig;
	env = Env.perc(attackTime, releaseTime, curve: curve);
	sig = WhiteNoise.ar(1);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
}).add;

SynthDef(\impulseWhite3, {
	|attackTime = 0.01, releaseTime = 0.25, curve =  -4, shelf_freq = 2500, shelf_db = -35, rs = 1,  peak_freq = 160, peakQ = 1, peak_db = -10, lop_freq = 5000, lop_q = 0.4, amp = 0.2, out|
	var env, sig;
	env = Env.perc(attackTime, releaseTime, curve: curve);
	sig = WhiteNoise.ar(1);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	sig = BLowPass4.ar(sig, freq: lop_freq, rq: lop_q );
	sig = BHiShelf.ar(sig, freq: shelf_freq, rs: rs, db: shelf_db);
	sig = BPeakEQ.ar(sig, freq: peak_freq, rq: peakQ, db: peak_db, mul: amp);
	Out.ar(out, sig);
}).add;

SynthDef(\impulseWhiteSin, {
	|attackTime = 0.01, releaseTime = 0.25, curve =  -4, peak_freq = 160, peakBW = 0.01, amp = 0.2, out|
	var env, sin, sig1, sig2, sig3, sig4, sig5, sigOut;
	env = Env.perc(attackTime, releaseTime, curve: curve);
	sin = SinOsc.ar(freq: peak_freq);
	sig1 = WhiteNoise.ar(1);
	sig2 = Resonz.ar(sig1, freq: peak_freq, bwr: peakBW);
	sig3 = Resonz.ar(sig1, freq: (peak_freq * 2), bwr: peakBW);
	sig4 = Resonz.ar(sig1, freq: (peak_freq * 4), bwr: peakBW, mul: 0.75);
	sig5 = Resonz.ar(sig1, freq: (peak_freq * 10), bwr: peakBW, mul: 0.85);
	sigOut = Mix.ar([sin, sig2, sig3, sig4, sig5]);
	//sigOut = Mix.ar([sig2, sig3, sig4]);
	sigOut = sigOut * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sigOut * amp);
}).add;

SynthDef(\resPinkNoise, {|out, freq = 500, bw = 0.005, amp = 0.2|
	var sig = Resonz.ar(PinkNoise.ar(1), freq: freq, bwr: bw);
	Out.ar(out, sig * amp);
}).add;

SynthDef(\sinSweep1, {
	|freq1 = 100, freq2 = 2000, dur = 0.5, amp = 0.2, out|
	var freq, env, sig;
	freq = XLine.kr(start: freq1, end: freq2, dur: dur);
	env = Env.linen(attackTime: 0.02, sustainTime: dur - 0.04, releaseTime: 0.02);
	sig = SinOsc.ar(freq);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
}).add;

SynthDef(\sawSweep1, {
	|freq1 = 100, freq2 = 2000, dur = 0.5, amp = 0.2, out|
	var freq, env, sig;
	freq = XLine.kr(start: freq1, end: freq2, dur: dur);
	env = Env.linen(attackTime: 0.02, sustainTime: dur - 0.04, releaseTime: 0.02);
	sig = Saw.ar(freq);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
}).add;

SynthDef(\triSweep1, {
	|freq1 = 100, freq2 = 2000, dur = 0.5, amp = 0.2, out|
	var freq, env, sig;
	freq = XLine.kr(start: freq1, end: freq2, dur: dur);
	env = Env.linen(attackTime: 0.02, sustainTime: dur - 0.04, releaseTime: 0.02);
	sig = LFTri.ar(freq);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
}).add;

SynthDef(\pulseSweep1, {
	|freq1 = 100, freq2 = 2000, dur = 0.5, width = 0.5, amp = 0.2, out|
	var freq, env, sig;
	freq = XLine.kr(start: freq1, end: freq2, dur: dur);
	env = Env.linen(attackTime: 0.02, sustainTime: dur - 0.04, releaseTime: 0.02);
	sig = Pulse.ar(freq, width);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	Out.ar(out, sig * amp);
}).add;

SynthDef.new(\randSinSwell_1, {|out = 0, amp = 1, loFreq = 300, hiFreq = 1200, attTime = 6, susTime = 2, relTime = 5|
	var sig, ampMod, env, envGen;
	env = Env.linen(attackTime: attTime, sustainTime: susTime, releaseTime: relTime, level: 1, curve: \sine);
	envGen = EnvGen.kr(env, doneAction: 2);
	ampMod = SinOsc.kr( {ExpRand(0.2, 12)} ! 3).range(0.1);
	sig = SinOsc.ar( {ExpRand(loFreq, hiFreq)} ! 3);
	sig = sig * ampMod * envGen; //amp mod
	sig = Mix.ar(sig) * amp;
	Out.ar(out, sig);
}).add;
);

// OTHER EFFECTS PROCESSING ---

SynthDef(\partConv_sample, {|targetBuf, irSpectrum, fftSize = 2048, playRate = 1, loop = 1, ampBus, ampLimit = 0.4, out|
	var input, sig, currentAmp;
	input = PlayBuf.ar(1, targetBuf, rate: playRate, loop: loop);
	sig = PartConv.ar(input, fftsize: fftSize, irbufnum: irSpectrum);
	sig = Limiter.ar(sig, level: -1.dbamp, dur: 0.01);
	currentAmp = ampBus * ampLimit;
	Out.ar(out, sig * currentAmp);
	DetectSilence.ar(sig, amp: 0.0001, time: 0.2, doneAction: 2);
}).add;

SynthDef(\partConv_sampleLoop, {|targetBuf, irSpectrum, attTime = 4, susTime = 5, relTime = 6, fftSize = 2048, playRate = 1, ampBus, ampLimit = 0.4, out = 0|
	var input, env, sig, currentAmp;
	input = PlayBuf.ar(1, targetBuf, rate: playRate, loop: 1);
	env = Env.linen(attackTime: attTime, sustainTime: susTime, releaseTime: relTime, curve: \sine);
	sig = PartConv.ar(input, fftsize: fftSize, irbufnum: irSpectrum);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	sig = Limiter.ar(sig, level: -0.3.dbamp, dur: 0.01);
	currentAmp = ampBus * ampLimit;
	Out.ar(out, sig * currentAmp);
}).add;

SynthDef(\partConv_sampleLoop_pShift, {|targetBuf, irSpectrum, attTime = 4, susTime = 5, relTime = 6, fftSize = 2048, playRate = 1, pitch = 1, winSize = 0.1, pitchDisp = 0, timeDisp = 0.003, pShiftMix = 1, ampBus, ampLimit = 0.4, out = 0|
	var sig1, sig2, env, sigOut, currentAmp;
	sig1 = PlayBuf.ar(1, targetBuf, rate: playRate, loop: 1);
	sig2 = PitchShift.ar(sig1, windowSize: winSize, pitchRatio: pitch, pitchDispersion: pitchDisp, timeDispersion: timeDisp);
	sigOut = SelectX.ar(pShiftMix, [sig1, sig2]);
	env = Env.linen(attackTime: attTime, sustainTime: susTime, releaseTime: relTime, curve: \sine);
	sigOut = PartConv.ar(sigOut, fftsize: fftSize, irbufnum: irSpectrum);
	sigOut = sigOut * EnvGen.ar(env, doneAction: 2);
	sigOut = Limiter.ar(sigOut, level: -0.3.dbamp, dur: 0.01);
	currentAmp = ampBus * ampLimit;
	Out.ar(out, sigOut * currentAmp);
}).add;