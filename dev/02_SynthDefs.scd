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

// Takes audio-rate input phase to control the buffer position
SynthDef.new(\bufRead, { //define synth to read from buffer w/ phasor...
  arg amp=1, out=0, phaseBus, buf;
  var sig;
  sig = BufRd.ar(1, buf, InFeedback.ar(phaseBus));
  sig = sig * amp;
  //~sliderPlayPos.value_(ptr);
  Out.ar(out, sig);
} ).add;

// Phasor indexes through buffer at audio rate
SynthDef(\phasor, {
	arg out=0, buf, trig = 0, rate = 1, start = 0, end = BufFrames.kr(buf) - 1, resetPos = 0;
	//Out.ar(out, Phasor.ar(trig, BufRateScale.kr(buf) * rate, start * BufFrames.kr(buf), (end * BufFrames.kr(buf)) - 1, resetPos ) );
	Out.ar(out, Phasor.ar(trig, BufRateScale.kr(buf) * rate, start, end, resetPos ) );
}).add;

// Needed to monitor phasor
SynthDef(\a2k_patch, {
  arg in, out;
  Out.kr(out, A2K.kr(InFeedback.ar(in) ) ); //is InFeedback necessary?
}).add;

SynthDef.new(\pitchShifter, {
	arg inBus, outBus, windowSize = 0.2, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.2, amp = 1;
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
	|inBus, buf|
	var sig;
	sig = In.ar(inBus, 1);
	ScopeOut2.ar(sig, buf);
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

);