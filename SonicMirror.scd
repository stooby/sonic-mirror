/**********SONIC MIRROR**********

An open-ended audio software (and hardware) instrument designed for autonomous embedded audio recording, generative sound, and musical performance.


Project details and documentation online:  http://scott-tooby.com/sonic-mirror.html

=============
LAUNCH INSTRUCTIONS:

0. Configure (uncomment / comment) your audio hardware settings from the options in the "INITIALIZE - #1" braces below.  (Default settings are configured to run using your computer's default built-in soundcard at 44.1 kHz sampling rate.)

1. Execute chunk "INITIALIZE - #1"

2. Execute chunk "CREATE SYNTHDEFS AND BUSSES - #2"

3. Execute chunk "LAUNCH GUI AND RUN - #3"


=============
OPERATING INSTRUCTIONS:

1.

2.

3.

=============

This will be a work in progress for the foreseeable future.

Feel free to use, experiment, and contribute:  https://github.com/stooby/sonic-mirror

st, 2016





-----TODO-----:




*/
(
//INITIALIZE #1 - DEFAULT ============================
//run this chunk of code first to use your system's built-in soundcard at default 44.1k sampling rate
s = Server.local;
s.options.sampleRate = 44100;
s.options.inDevice = "Built-in Microph";
s.options.outDevice = "Built-in Output";
s.boot;
//if the SC server crashes and fails to start after executing, repeat this operation until it works....it's sometimes stubborn...alternatively, you can delete the brackets around this chunk of code and execute each line individually...this seems to be more agreeable to the SC server
)

(//INITIALIZE #1 - CUSTOM
//alternatively, edit and run this chunk of code first if you'd like to use configure the SC server with custom audio settings
s = Server.local;
s.options.sampleRate= 48000; //run before launching server if using Apogee USB mic input
s.options.inDevice = "MiC";
//s.options.device = "iConnectAudio4+";
s.boot;
)

s.quit;  //convenience method (for cleanup)
s.plotTree; //for debugging
Buffer.freeAll; //for cleanup

(//CREATE SYNTHDEFS AND BUSSES - #2 ============================

//Record audio input to buffer using audio-rate input Phasor to control position in buffer
SynthDef(\RecBuf_loop, { //<---NEW -- Added Lo-cut
	arg phaseBus, buf, sendBus, loCutoff = 90, rQ = 1, mul = 1;
	//var sig = SoundIn.ar(bus: 0, mul: mul);
	var sig = BHiPass4.ar( SoundIn.ar(bus: 0, mul: 1), loCutoff, rq: rQ, mul: mul); //pass SoundIn through HiPass
	BufWr.ar(sig, buf, InFeedback.ar(phaseBus) );
	//OffsetOut.ar(sendBus, sig);  //would this provide better sample accurate scope plotting and recording?
	Out.ar(sendBus, sig); //<---
} ).add;

/*SynthDef(\RecBuf_loop, { //pre-Hipass
	arg phaseBus, buf, sendBus, mul = 1;
	var sig = SoundIn.ar(bus: 0, mul: mul);
	BufWr.ar(sig, buf, InFeedback.ar(phaseBus) );
	//OffsetOut.ar(sendBus, sig);
	Out.ar(sendBus, sig); //<---
} ).add; */

/*//from earliest version of sonic mirror...use RecordBuf to continuously record to buffer 1, when reach end, loop back to beginning and write over prev data...not as flexible as writing to buffer with phasor
SynthDef.new(\RecBuf_loop, {
  arg buf = ~buffer.bufnum;
  var sound = SoundIn.ar(0);
  RecordBuf.ar(sound, buf, loop: 1, doneAction: 0); //consider making 'run' a configurable parameter to permit pickup at last buffer index when resuming recording after pause....
} ).add;*/

// Phasor drives the buffer scaling at audio rate
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

// Takes audio-rate input phase to control the buffer position
SynthDef.new(\ReadBuf_loop, { //define synth to read from buffer w/ phasor...
  arg amp=1, out=0, phaseBus, buf;
  var sig;
  sig = BufRd.ar(1, buf, InFeedback.ar(phaseBus));
  sig = sig * amp;
  //~sliderPlayPos.value_(ptr);
  Out.ar(out, sig);
} ).add;

SynthDef.new(\pitchShifter, {
	arg inBus, outBus, windowSize = 0.2, pitchRatio = 1, pitchDispers = 0, timeDispers = 0.2, amp = 1;
	var sigIn, sigOut;
	sigIn = In.ar(inBus, 1);
	//sigIn = InFeedback.ar(inBus, 1);
	sigOut = PitchShift.ar(sigIn, windowSize, pitchRatio, pitchDispers, timeDispers, amp);
	Out.ar(outBus, sigOut);
}).add;

/*SynthDef.new(\XFade, {
	|in1, in2, out, amountControlBus|
	var inArray, mixSignal;
	inArray = [In.ar(in1), In.ar(in2)];
	//inArray = [InFeedback.ar(in1), InFeedback.ar(in2)];
	mixSignal = SelectX.ar(amountControlBus, inArray);
	Out.ar(out, mixSignal);
} ).add;  */

SynthDef.new(\XFade, { //<---NEW MOD VERSION
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

SynthDef.new(\subMix, { //<--NEW - utility
	|in, amp = 1, out|
	var sig;
	sig = In.ar(in) * amp;
	//sig = InFeedback.ar(in) * amp;
	//OffsetOut.ar(out, sig);
	Out.ar(out, sig);
} ).add;

SynthDef.new(\mainOut, { //<--NEW w/ Lo-cut
	|in, loCutoff = 90, rQ = 1, amp = 1|
	var sig;
	sig = BHiPass4.ar( In.ar(in), loCutoff, rq: rQ, mul: amp);
	//sig = In.ar(in) * amp;
	//sig = InFeedback.ar(in) * amp;
	//OffsetOut.ar(0, sig);
	Out.ar([0, 1], sig);
} ).add;

/*SynthDef.new(\mainOut, { //ORIG mainOut
	|in, amp = 1|
	var sig;
	sig = In.ar(in) * amp;
	//sig = InFeedback.ar(in) * amp;
	//OffsetOut.ar(0, sig);
	Out.ar([0, 1], sig);
} ).add; */

SynthDef.new(\scopeOut, { //<------NEW
	|inBus, buf|
	var sig;
	sig = In.ar(inBus, 1);
	ScopeOut2.ar(sig, buf);
} ).add;

SynthDef(\write2Disk, {arg buf, inBus = 0; //record audio file to disk - mono
	DiskOut.ar(buf, In.ar(inBus, 1));
}).add;

// play audio file from disk WITH an amplitude envelope to avoid clicks @ beginning & end of sample
SynthDef(\readDisk, { arg buf, sampleDur, amp = 1, out; //<----NEW MOD VERS w/ amp control
	var env, envgen, sig;
	env = Env.linen(0.02, (sampleDur - 0.04), 0.02, 1, -1);
	envgen = EnvGen.ar(env, doneAction: 2);
	sig = (DiskIn.ar(1, buf) * envgen) * amp;
	Out.ar(out, sig);
}).add;

/*SynthDef(\readDisk, { arg buf, sampleDur, out;
	var env, envgen, sig;
	env = Env.linen(0.02, (sampleDur - 0.04), 0.02, 1, -1);
	envgen = EnvGen.ar(env, doneAction: 2);
	sig = DiskIn.ar(1, buf) * envgen;
	Out.ar(out, sig);
}).add; */


//BUSSES
~recInPosBus = Bus.control(s, 1);
~recOutPosBus = Bus.control(s, 1);
~playInPosBus = Bus.control(s, 1);
~playOutPosBus = Bus.control(s, 1);

~rateBus = Bus.control(s, 1);
~pitchBus = Bus.control(s, 1);
~pitchShiftMixValBus = Bus.control(s, 1); //mix % between orig and pitch-shifted signal
~pitchShiftOut = Bus.audio(s, 1);

~inputStreamLevelBus = Bus.control(s, 1);  //level of audio output from ~pShiftMix Synth  <-----NEW
~fileOutputLevelBus = Bus.control(s, 1);  //level of audio file playback <------- NEW

~revRateBusMon = Bus.control(s, 1);

~phaseBusRec = Bus.audio(s, 1);
~phaseBusMonRec = Bus.control(s, 1);
~inputLevelBus = Bus.control(s, 1);

~loCutBus_in = Bus.control(s, 1); //<----NEW
~loCutBus_out = Bus.control(s, 1); //<----NEW
~inputSendBus = Bus.audio(s, 1); //<---NEW

~phaseBusPly = Bus.audio(s, 1);
~phaseBusMonPly = Bus.control(s, 1);
~play1LevelBus = Bus.control(s, 1); //to control level of audioPlayback ("playhead1")
~playOut1Bus = Bus.audio(s, 1);

~outMainLevelBus = Bus.control(s, 1);
~outMainBus = Bus.audio(s, 1);
)

( //LAUNCH GUI & RUN - #3 ============================

////GLOBAL VARIABLES
~bufferSize = 60.0;
~buffer = Buffer.alloc(s, s.sampleRate * ~bufferSize, 1); //<---newly moved
~delayTime = 1.23;
~play2recOffset; //displacement of playhead pos from rec pos (in frames/samples)
~lastPlayPhasePos = 0; //for resume functionality - stores last pos (frame) of play head before playback disabled
~lastRecPhasePos = 0; //for resume functionality - stores last pos (frame) of rec head before recording disabled
~playTrig = false;
~recTrig = false;
~fixPlayRecOffset = false;

~pitchShiftValPrev_rate;
~pitchShiftValTarget_rate = 0;
~pitchInterp_rate = false;

~pitchShiftValPrev_freq;
~pitchShiftValTarget_freq;
~pitchInterp_freq = false;

~outMainLevVal_prev; //<--
~outMainLevVal_target; //<--not currently being used...could be useful in future though....
~outMainLevInterp = false; //<--not currently being monitored...

~reverseFlag = false; //currentlly using ~buttonRev.value as flag, but is that a good long-term idea????
~randomPos_flag = false;

~time2NextRandom_rate = 0;
~time2NextRandom_freq = 0;
~time2NextRandom_pitchShiftMix = 0;

~pitchShiftMix_prev;
~pitchShiftMix_target; //<- not using right now, might not need unless interpolating
~pitchShiftMix_prevChangeTime = 0;
~pitchShiftMix_interp = false;

~currentPlayInFrame = 0;
~currentPlayOutFrame = ~bufferSize * s.sampleRate - 1; //~buffer.numFrames - 1; (won't work unless ~buffer's already been allocated...)
~currentRecInFrame = 0;
~currentRecOutFrame = ~bufferSize * s.sampleRate - 1;

~playBehavior = 0; //stores state of playback behavior

////////////////
~minRecDur = 3.0; //<-----NEW: min sec per recorded sample
~maxRecDur = 6.0; //<----NEW: max sec per recorded sample
~recSound_input = false; //<---NEW:  write audio file 2 disk flag....should I store this info in a contol bus?
~recSound_input_startTime; //<---NEW: .............should I store this info in a contol bus?
~recSound_input_stopTime; //<---NEW: .............should I store this info in a contol bus?

~playSound = false; //<---NEW: play audio file from disk flag
~hearSound = false; //<---NEW: for machine listening
~listenInterval_intraSound = 1.0; //<----NEW: amount of time (sec) to continue listening for continuation of contiguous sound object between gaps of silence (e.g. seperation threshold for dividing sound objects)

~playSoundBuf = Buffer.alloc(s, 65536, 1); //buffer for playing back mono audio files from disk

~input1_specFlatVal; //<---NEW:  .........should I store this info in a contol bus?
~input1_ampVal; //<---NEW:  .........should I store this info in a contol bus?
//////////////////

~fileAudio_writeOut_nameNum = 0; //counter for writing/reading audio file names
//~fileAudio_writeOut_lastPath = ("~/Music/SCrecs/SncMir-MainOut_" ++ ~fileAudio_writeOut_nameNum ++ ".aiff");
~fileAudio_writeOut_lastPath = "~/Music/SCrecs/SncMir-MainOut_"; //stores string of file path for last written audio file from disk
//~fileAudio_lastReadPath = ("~/Music/SCrecs/SncMir-MainOut_" ++ ~fileAudio_writeOut_nameNum ++ ".aiff"); //stores string of file path for last read audio file from disk
~fileAudio_writeOut_maxNum = 30;  //<---NEW: max # of files written per session (wrap-around & overwrite limit)

~fileAudio_writeIn_nameNum = 0; //counter for writing/reading audio file name
~fileAudio_writeIn_lastPath = "~/Music/SCrecs/SncMir-In_"; //stores string of file path for last written audio file

~minNumFilesB4Playback = 1; //<----!!!!!NEW!!!!!!!  file # threshold before file playback routine commences

~loCutVal_in = 90; //<-----NEW initialization val for loCut (and also stores ongoing values?)
~loCutVal_out = 90; //<-----NEW ...for initialization
////
Window.closeAll;
w = Window.new("SonicMirror_1.85", Rect.new(470, 330, 780, 405))
.front
.alwaysOnTop_(true);

w.onClose_{s.freeAll; Buffer.freeAll(s); CmdPeriod.clearClocks; CmdPeriod.run;}; // clean up when window is closed

//(RESET BUS VALUES FOR INITIALIZATION OF SKETCH)
~playInPosBus.set(0);
~playOutPosBus.set(~currentPlayOutFrame);
~recInPosBus.set(0);
~recOutPosBus.set(~currentRecOutFrame);

~rateBus.set(1);
~pitchBus.set(1);
~pitchShiftMixValBus.set(0); //<---

~revRateBusMon.set(1); //<---

~inputLevelBus.set(1);
~play1LevelBus.set(1); //<--NO SLIDER CREATED YET!!!!!....
~inputStreamLevelBus.set(1);  //<---NEW
~fileOutputLevelBus.set(1);  //<---NEW

~outMainLevelBus.set(1);

~phaseBusMonPly.set(0);
~phaseBusMonRec.set(0);

~loCutBus_in.set(~loCutVal_in); //<---NEW
~loCutBus_out.set(~loCutVal_out); //<----NEW

////BUFFER CONTROLS////
~label_LoCut = StaticText(w, Rect(693, 226, 48, 20) )//<---
.string_("LoCut-Hz")
.font_(Font("Monaco", 10) )
.align_(\left);

~numBox_inputLoCut = NumberBox(w, Rect(680, 216, 32, 14))//<---
.value_(~loCutVal_in)
.clipLo_(10) //smallest possible length of buffer (in seconds)
.clipHi_(20000) //longest possible length of buffer (in seconds)
.font_(Font("Monaco", 8) )
.decimals_(2)
.action_( {
	arg obj;
	~loCutVal_in = obj.value.round(0.01);
	~loCutBus_in.set(~loCutVal_in);
	//~loCutBus_in.setSynchronous([~loCutVal_in]); //??????? for synchronous control? is this better?
	("***LoCutFreq_in=" ++ ~loCutVal_in ++ "Hz").postln;
} );

~numBox_outputLoCut = NumberBox(w, Rect(724, 216, 32, 14))//<---
.value_(~loCutVal_out)
.clipLo_(10) //smallest possible length of buffer (in seconds)
.clipHi_(20000) //longest possible length of buffer (in seconds)
.font_(Font("Monaco", 8) )
.decimals_(2)
.action_( {
	arg obj;
	~loCutVal_out = obj.value.round(0.01);
	~loCutBus_out.set(~loCutVal_out);
	//~loCutBus_out.setSynchronous([~loCutVal_out]); //??????? for synchronous control? is this better?
	("***LoCutFreq_out=" ++ ~loCutVal_out ++ "Hz").postln;
} );

~labelBufSize = StaticText(w, Rect(568, 380, 200, 20) )
.string_("Buf(sec)")
.font_(Font("Monaco", 12) )
.align_(\left);

~numBoxBuf = NumberBox(w, Rect(490, 377, 75, 25))
.value_(~bufferSize)
.clipLo_(10) //smallest possible length of buffer (in seconds)
.clipHi_(120) //longest possible length of buffer (in seconds)
.font_(Font("Monaco", 14) )
.decimals_(2)
.action_( {
	arg obj;
	~bufferSize = obj.value.round(0.01);
	("***Buffer Length=" + ~bufferSize + "seconds.").postln;
} );

~buttonBuf = Button(w, Rect(400, 377, 85, 25)) //Activate / Deactivate audio buffer
.states_( [
	["BUF_ACT", Color.black, Color.gray(0.8)] ,
	["BUF_ACT", Color.white, Color(0.8,0.8, 0)]
] )
.value_(1)
.font_(Font("Monaco", 14) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{//allocate(create) buffer w/ duration = bufferSize seconds
			~buffer = Buffer.alloc(s, s.sampleRate * ~bufferSize, 1);
		} , //else
		{~buffer.close; ~buffer.free;} //free(erase) buffer
	);
} );

~buttonRecOut = Button(w, Rect(16, 372, 45, 20) )
.states_( [
	["RECOUT", Color.black, Color(0.95, 0, 0, 0.3)] ,
	["RECOUT", Color.white, Color(0.95, 0, 0)]
] )
.font_(Font("Monaco", 11) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{//BEGIN RECORDING / WRITING MAIN AUDIO OUTPUT TO FILE
			~bufferMainOutWrite = Buffer.alloc(s, 65536, 1); //allocate a disk i/o buffer (min rec frame size is 65536)
			~bufferMainOutWrite.write((~fileAudio_writeOut_lastPath++~fileAudio_writeOut_nameNum++".aiff").standardizePath, "aiff", "int24", 0, 0, true); // create an output file for this buffer, leaving it "open" (not recording yet, just created file w/ format header)
			~write2Disk = Synth.tail(nil, \write2Disk, [\buf, ~bufferMainOutWrite, \inBus, 0] ); //record audio sent to bus 0 to buffer writing to audio file
		} ,
		{//STOP RECORDING / WRITING MAIN AUDIO OUTPUT TO FILE
			~write2Disk.free; //stop recording to disk
			~bufferMainOutWrite.close; //close the buffer to finish writing the sound file (won't be readable otherwise)
			~bufferMainOutWrite.free; //free buffer
			~fileAudio_writeOut_nameNum = ~fileAudio_writeOut_nameNum + 1; //increment file name suffix in prep for next rec file
		} );
} );

~labelPlayFile = StaticText(w, Rect(130, 373, 135, 20) ) //<------NEW
.string_("FILENAMEFILENAME...")
.font_(Font("Monaco", 12) )
.align_(\left);

~buttonPlayFile = Button(w, Rect(62, 372, 65, 20) ) //<------NEW
.states_( [
	["PLAY FILE", Color.black, Color(0.0, 0.5, 0.5, 0.3)] ,
	["PLAY FILE", Color.white, Color(0.0, 0.5, 0.5)]
] )
.font_(Font("Monaco", 11) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{//BEGIN PLAYING AUDIO FILE

		} ,
		{//STOP RECORDING / WRITING AUDIO INPUT TO FILE

		} );
} );

~buttonRecIn = Button(w, Rect(16, 352, 45, 20) ) //<------NEW
.states_( [
	["RECIN", Color.black, Color(0.0, 0.5, 0, 0.3)] ,
	["RECIN", Color.white, Color(0.0, 0.5, 0)]
] )
.font_(Font("Monaco", 11) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{//BEGIN RECORDING / WRITING AUDIO INPUT TO FILE
			~bufferInWrite = Buffer.alloc(s, 65536, 1); //allocate a disk i/o buffer (min rec frame size is 65536)
			~bufferInWrite.write((~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath, "aiff", "int24", 0, 0, true); // create an output file for this buffer, leaving it "open" (not recording yet, just created file w/ format header)
			~writeIn2Disk = Synth.tail(nil, \write2Disk, [\buf, ~bufferInWrite, \inBus, ~inputSendBus] ); //record audio sent to first input channel bus to buffer, and write an audio file to hard disk
		} ,
		{//STOP RECORDING / WRITING AUDIO INPUT TO FILE
			~writeIn2Disk.free; //stop recording to disk
			~bufferInWrite.close; //close the buffer to finish writing the sound file (won't be readable otherwise)
			~bufferInWrite.free;
			~fileAudio_writeIn_nameNum = ~fileAudio_writeIn_nameNum + 1; //increment file name suffix in prep for next rec file
		} );
} );

~numBoxDel = NumberBox(w, Rect(610, 349, 75, 25))  //WORKS but a little buggy....
.value_(~delayTime)
.clipLo_(0)
.clipHi_(~bufferSize - 0.01)
.font_(Font("Monaco", 14) )
.decimals_(2)
.scroll_step_(0.01)
.step_(0.01)
.action_( {
	arg obj;
	var lastPlay2RecOffset;
	~delayTime = obj.value.round(0.01);
	//~delayTime.postln;
	//~sliderDelay.value = obj.value.linlin(0, ~bufferSize - 0.01, 0, 1); //ideally do this only when the numBox is being manipulated directly, otherwise it's redundantly updating value of slider...OBSOLESCED in 1.82

	~playHeadOffsetRoutine.reset;
	AppClock.play(~playHeadOffsetRoutine);

	/* ~phaseBusMonRec.get( { //<----works but BUGGY small delay values don't seem to be accurate...
		//calculate the offset of the playhead from the rechead
		arg val;
		~play2recOffset = val - ((~delayTime * s.sampleRate).round(1));
		lastPlay2RecOffset = val - ((~delayTime * s.sampleRate).round(1));
		//if (~play2recOffset < 0,
		if (lastPlay2RecOffset < 0,
			{//~lastPlayPhasePos = (~buffer.numFrames - 1) + ~play2recOffset;
				~lastPlayPhasePos = (~buffer.numFrames - 1) + lastPlay2RecOffset;
			} ,
			{//~lastPlayPhasePos = ~play2recOffset;
			 ~lastPlayPhasePos = lastPlay2RecOffset;
			}
		);
	} );

	if (~buttonPlay.value == 1, {~playPhase.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } ); */

} );

~labelDelTime = StaticText(w, Rect(688, 352, 78, 20) )
.string_("Offset(sec)")
.font_(Font("Monaco", 12) )
.align_(\left);

/*~sliderDelay = Slider(w, Rect(489, 332, 180, 15))
.background_(Color(0.85, 0.85, 0.0))
.value_(~delayTime.linlin(0, ~bufferSize - 0.01, 0, 1))
.action_( { //<----BUGGY....?????
	arg obj;
	var pos, playPosFrame;
	pos = obj.value.linlin(0, 1, 0, ~bufferSize - 0.01).round(0.01);
	//~numBoxDel.value_(pos); //update numBoxPitch value
	~numBoxDel.valueAction_(pos); //so we don't have to duplicate calc code from numBoxDel here
} ); */

~buttonDel = Button(w, Rect(550, 349, 55, 25)) //Delay Offset Sync button --- WORKS but a little buggy....
.states_( [
	["SYNC", Color.black, Color(0.7, 0.7, 0, 0.3)] ,
	["SYNC", Color.white, Color(0.8, 0.8, 0)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1, // when sync button enabled
		{
			~fixPlayRecOffset = true; //IS THIS BETTER THAN POLLING BUTTON.VALUE?????
			~playHeadOffsetRoutine.reset;
			AppClock.play(~playHeadOffsetRoutine);

			/*
			//snap playhead to position based on delay offset from rechead<------
			~phaseBusMonRec.get( { //<----this block doesn't function properly when uncommented, needs to be in a routine?????
				//calculate the offset of the playhead from the rechead
				arg val;
				~play2recOffset = val - ((~delayTime * s.sampleRate).round(1));
				if (~play2recOffset < 0,
					{~lastPlayPhasePos = (~buffer.numFrames - 1) + ~play2recOffset;
						//lastPlay2RecOffset = ~lastPlayPhasePos;
					} ,
					{~lastPlayPhasePos = ~play2recOffset;
						//lastPlay2RecOffset = ~play2recOffset;
					}
				);
			} );

			if (~buttonPlay.value == 1, {~playPhase.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } );
			*/

		},
		{ //when button disabled
			~fixPlayRecOffset = false;
			~playHeadOffsetRoutine.stop;
		}
	);
} )
.value_(0);

/////ROUTINES/////
~soundRoutine_autoRec = Routine.new( {
	if (~recSound_input == true,
		{

		} ,
		{

		}
	);
} );

~soundRoutine_autoPlay = Routine.new( {
	if (~playSound == true,
		{ //if already playing sound file, we can assume it's completed by the time this routine has stopped yielding based on commands when ~playSound == false (see below code in 'else' of this conditional)...
			var time2yield, interpSynth;

			interpSynth = Synth(\LinInterp_num, [\startVal, 0.0, \stopVal, 1.0, \duration, 0.2, \out, ~inputStreamLevelBus]); //turn inStreamLevel back to 1.0 in 0.2 sec (++++\startVal should probs = variable storing current value of inputStreamLevel++++)
			~sliderInStreamLevel.value = 1;  //update GUI
			~numBoxInStreamLevel.value = 1; //update GUI
			0.2.yield;  //<----is this necessary????

			~playSound = false;
			~buttonPlayFile.value = 0; //update GUI button

			~playSoundBuf.close; //<----IS THIS REALLY NECESSARY IF GOING TO REASSIGN LATER, SHOULD I ONLY DO THIS DURING FINAL CLEANUP????
			~playSoundBuf.free; //<----IS THIS REALLY NECESSARY HERE????
			~playSoundBuf = Buffer.alloc(s, 65536, 1);  //<----IS THIS REALLY NECESSARY HERE????
			time2yield = rrand(12, 35); //<-----TIME RANGE - TRIGGER RATE (IN SEC).....
			("---time2nextSoundPlay=" ++ time2yield ++ "sec").postln;
			time2yield.yieldAndReset;
		},
		{//if not playing a soundFile, ~playSound == false
			if (~recSound_input == false,
				{
					if (~fileAudio_writeIn_nameNum >= ~minNumFilesB4Playback, //if min # of files have been written
						{
							//INSERT CONDITIONAL HERE TO DETERMINE WHETHER OR NOT TO PLAY AUDIO FILE-----

							//PLAYBACK AUDIO FILE FROM DISK
							var readDiskSynth, interpSynth, readFileFunc, randFilePick, duration;

							~playSound = true; //set flag
							randFilePick = rrand(0, (~fileAudio_writeIn_nameNum - 1)); //pick a random file to play (needs to be "current nameNum counter val - 1" b/c current counter value doesn't have a file associated w/ it yet due to counter incrementing after a new file has been written...)
							("PLAYING BACK FILE:" + (~fileAudio_writeIn_lastPath++randFilePick++".aiff").standardizePath).postln;
							~buttonPlayFile.value = 1; //update GUI

							readDiskSynth = Synth.basicNew(\readDisk);

							readFileFunc = { arg buf;
								var fileDir, soundFile;
								fileDir = (~fileAudio_writeIn_lastPath++randFilePick++".aiff").standardizePath;
								soundFile = SoundFile.new;
								soundFile.openRead(fileDir);
								duration = soundFile.numFrames/s.sampleRate;
								//duration = soundFile.duration;
								//("soundFileDur=" + duration).postln;
								soundFile.close;
								readDiskSynth.addToHeadMsg(nil, [\buf, buf, \sampleDur, duration, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]) //<---!!!!!Now w/ amp control
							};

							interpSynth = Synth(\LinInterp_num, [\startVal, 1.0, \stopVal, 0.0, \duration, 0.2, \out, ~inputStreamLevelBus]); //silence input stream in 0.25 sec (++++\startVal should probs = variable storing current value of inputStreamLevel++++)
							~sliderInStreamLevel.value = 0;  //update GUI
							~numBoxInStreamLevel.value = 0; //update GUI

							0.2.yield;  //<----is this necessary??????

							~playSoundBuf = Buffer.cueSoundFile(s, (~fileAudio_writeIn_lastPath++randFilePick++".aiff").standardizePath, 0, 1, completionMessage: readFileFunc);  //PLAY SOUND FILE from disk

							(duration + 0.2).yieldAndReset; //<-----can shorten to +0.1 or less?
						},
						{15.yieldAndReset;} //<------------ wait if not enough files have been written yet
					);
				}, //else if (~recSoundInput == true)
				{5.yieldAndReset;}
			);
		}
	);
} );

~playHeadOffsetRoutine = Routine.new( {
	~phaseBusMonRec.get( {
		arg val;
		~play2recOffset = val - ((~delayTime * s.sampleRate).round(1)); //calculate the offset of the playhead from the rechead
		if (~play2recOffset < 0,
			{~lastPlayPhasePos = (~buffer.numFrames - 1) + ~play2recOffset;} ,
			{~lastPlayPhasePos = ~play2recOffset;}
		);
	} );
	0.1.yield; //<--------------IS THERE ANY OTHER WAY???????????

	if (~buttonPlay.value == 1, {~playPhase.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } );
	nil;
} );

~updateGUI_rate = Routine.new ( {
	~rateBus.get( {
		arg val;
		var thisVal = val.abs; //in case "Reverse" enabled and rate is negative...   <-----
		AppClock.sched(0.0, { //this is necessary for some reason...
			//"pitchBusVal= ".post; val.ratiomidi.round(0.01).postln;
			//~sliderRate.value_(val.ratiomidi.linlin(-48, 48, 0, 1) );
			~sliderRate.value_(thisVal.ratiomidi.linlin(-48, 48, 0, 1) );
			//~numBoxRate.value_(val.ratiomidi.round(0.01));
			~numBoxRate.value_(thisVal.ratiomidi.round(0.01));
			nil;
		} );
	} );
	0.1.yieldAndReset;
} );

~updateGUI_freq = Routine.new ( {
	~pitchBus.get( {
		arg val;
		AppClock.sched(0.0, { //this is necessary for some reason...???????
			//"pitchBusVal= ".post; val.ratiomidi.round(0.01).postln;
			~sliderPitch.value_(val.ratiomidi.linlin(-48, 24, 0, 1) );
			~numBoxPitch.value_(val.ratiomidi.round(0.01));
			nil;
		} );
	} );
	0.1.yieldAndReset;
} );

~updateGUI_outMainLevel = Routine.new ( {
	~outMainLevelBus.get( {
		arg val;
		AppClock.sched(0.0, { //this is necessary for some reason...??????
			~sliderOutputLevel.value_(val);
			~numBoxOutputLevel.value_(val.round(0.01));
			nil;
		} );
	} );
	0.1.yieldAndReset;
} );

~updateGUI_pitchShiftMix = Routine.new ( {
	~pitchShiftMixValBus.get( {
		arg val;
		AppClock.sched(0.0, { //this is necessary for some reason...??????
			~sliderPitchShiftMix.value_(val);
			~numBoxPitchMix.value_((val * 100).round(1));
			nil;
		} );
	} );
	0.1.yieldAndReset;
} );

~randomRoutine_freq = Routine.new ( {
	//Automatically randomize pitch w/out time change (granular pitch shift)
	var time2nextRandomize, randNum4transp, newPitch, pitchCase, pitchInterp, interpTime;

	~pitchBus.get( {
		arg val;
		//AppClock.sched(0.0, {
			~pitchShiftValPrev_freq = val.ratiomidi;
			//("-*-prevFreq=" + ~pitchShiftValPrev_freq).postln;
			//nil;
		//} );
	} );

	0.1.yield; //<<<<<works, but not sure if ideal way...???

	randNum4transp = rrand(1.0, 10.0); //based on random # from 1-10, determine type of pitch transposition
	pitchCase = case
	{randNum4transp <= 5} { //50% chance of raising/lowering pitch randomly
		var thisRandNum = rrand(1, 10);
		if (thisRandNum <= 5, // 50/50 change pitch is raised or lowered
			{newPitch = rrand(-24.0, -0.2).round(0.01);},
			{newPitch = rrand(0.2, 24).round(0.01);} );
	}
	{randNum4transp > 5 && randNum4transp <= 8.5} { //35% chance pitch change in response to current rate
		newPitch = ~pitchShiftValTarget_rate * -1;
	}
	{randNum4transp > 8.5} { //15% chance of no pitch change
		newPitch = ~pitchShiftValPrev_freq;
	};
	~pitchShiftValTarget_freq = newPitch; //set target pitch to shift to
	//(" | targetPitch_freq=" + ~pitchShiftValTarget_freq).postln;

	if (newPitch != ~pitchShiftValPrev_freq, { //if newPitch isn't the same as the last...
		var thisDangoRandomNum;
		interpTime = rrand(0.25, 6.0); //===INTERP TIME===
		//("-*-freq_interpTime=" + interpTime).postln;
		pitchInterp = Synth(\LinInterp_pitch, [\out, ~pitchBus, \startVal, ~pitchShiftValPrev_freq, \stopVal, ~pitchShiftValTarget_freq, \duration, interpTime] );

		~pitchInterp_freq = true;
		//("*****pitchInterp=" + ~pitchInterp_rate).postln;
		~updateGUI_freq.reset;
		AppClock.play(~updateGUI_freq);

		(interpTime + 0.1).yield; //<----IS IT ALWAYS NECESSARY TO ADD 0.1 to accommodate Synth interp? ?????????????????
		//1.3.yield; //keep or no!??? <-----

		~pitchInterp_freq = false;
		//("*****pitchInterp=" + ~pitchInterp_rate).postln;
		~updateGUI_freq.stop;
		//var thisDangoRandomNum = rrand(1, 10);
		thisDangoRandomNum = rrand(1.0, 10.0);
		if (thisDangoRandomNum <= 4.5, { //45% chance  time2next pitch change is SHORT
			time2nextRandomize = rrand(0.3, 4.0).round(0.1); //if newPitch != the last pitch
		}, { //55% chance  time2next pitch change is LONG
			time2nextRandomize = rrand(4, 17);
		} );
	} , { //ELSE
		time2nextRandomize = rrand(4, 10);  //if newPitch == last pitch
	} );
	~time2NextRandom_freq = time2nextRandomize; //for populating GUI
	time2nextRandomize.yieldAndReset;
} );

~randomRoutine_outputLevel = Routine.new ( {
	var time2nextRandomize, randNum, interpLevel, interpTime;
	//("***OUTPUTlevl_randomRoutine***").postln;

	~outMainLevelBus.get( { //////method derived from ~randomRoutine_rate and freq....
		arg val;
		~outMainLevVal_prev = val;
		//("--OutputLvlRtn: CURRENTLVL =" + val).postln;
	} );
	0.1.yield; //<<<<<works, but not sure if ideal way...

	if (~outMainLevVal_prev < 1.0, { //if outMainLevel is 0 or less than 1, SET LVL BACK TO 1
		//("--CASE1-SET LVL TO 1: outLevelPrev=" + ~outMainLevVal_prev).postln;
		randNum = rrand(1, 10);
		//("randNum1=" + randNum + " | ").post;
		if (randNum <= 4, //PICK INTERPTIME BASED ON RAND NUM
			{interpTime = rrand(0.25, 0.75); /* ("interpTime=" + interpTime).postln; */ },
			{interpTime = rrand(3.25, 6.0); /* ("interpTime=" + interpTime).postln; */ } );

		interpLevel = Synth(\LinInterp_num, [\out, ~outMainLevelBus, \startVal, ~outMainLevVal_prev, \stopVal, 1.0, \duration, interpTime] );
		~outMainLevInterp = true;
		~updateGUI_outMainLevel.reset;
		AppClock.play(~updateGUI_outMainLevel);

		(interpTime + 0.1).yield; //<----IS IT ALWAYS NECESSARY TO ADD 0.1 to accommodate Synth interp?

		~outMainLevInterp = false;
		~updateGUI_outMainLevel.stop;

		randNum = rrand(1, 10);
		//("randNum2=" + randNum + " | ").post;
		//("---outLevel-randNum=" + randNum).postln;
		if (randNum >= 8,
			{time2nextRandomize = rrand(8, 20); //80% of time, long time2nextRand
				//("time2Next=" + time2nextRandomize).postln;
			} ,
			{time2nextRandomize = rrand(0.25, 3).round(0.01); //20% of time short time2nextRand
			//("time2Next=" + time2nextRandomize).postln;
			}
		);
		//("---outLevel-randomTime=" + time2nextRandomize).postln;
		//time2nextRandomize.yieldAndReset;
	}, { //else if val >= 1
		//("--CASE2: outLevelprev=" + ~outMainLevVal_prev).postln;
		randNum = rrand(1.0, 10.0);
		//("randNum1=" + randNum + " | ").post;
		//("---outLevel-randNum=" + randNum).postln;
		if (randNum <= 8.8, { //88% of time keep level at 1
			//~outMainLevelBus.set(1);
			//~sliderOutputLevel.value_(1);
			time2nextRandomize = rrand(12, 18);
			//("--NO LEVEL CHANGE...time2next=" + time2nextRandomize).postln;
		},
		{ //12% of time set level to 0
			interpTime = rrand(0.1, 0.35).round(0.01);
			//("--SET LVL to 0...interpTime=" + interpTime).postln;
			interpLevel = Synth(\LinInterp_num, [\out, ~outMainLevelBus, \startVal, ~outMainLevVal_prev, \stopVal, 0.0, \duration, interpTime] );
			~outMainLevInterp = true;
			~updateGUI_outMainLevel.reset;
			AppClock.play(~updateGUI_outMainLevel);

			(interpTime + 0.1).yield; //<----IS IT ALWAYS NECESSARY TO ADD 0.1 to accommodate Synth interp?

			~outMainLevInterp = false;
			~updateGUI_outMainLevel.stop;

			/*  //ORIG randomization to pick time2nextRandomize
			randNum = rrand(1, 10);
			if (randNum <= 4, {
				time2nextRandomize = rrand(3.0, 5.0).round(0.01);
			}, {
				time2nextRandomize = rrand(5.0, 10.0).round(0.01);
			} );
			*/
			time2nextRandomize = rrand(2.5, 4.0).round(0.01);
			//("--SET LVL TO 0 | time2nextRand=" + time2nextRandomize).postln;
		} );
		//("---outLevel-randomTime=" + time2nextRandomize).postln;
		//time2nextRandomize.yieldAndReset;
	} );
	//("---outLevel-randomTime=" + time2nextRandomize).postln;
	time2nextRandomize.yieldAndReset;
} );

~randomRoutine_reverse = Routine.new ( {
	var time2nextRandomize, thisRandomNum;
	thisRandomNum = rrand(1.0, 10.0);
	//("randRoutine: randNum=" + thisRandomNum).postln;
	if (~buttonRev.value == 0, { //if REVERSE disabled
		if (thisRandomNum <= 3.2, { //32% chance REVERSE enabled
			~buttonRev.valueAction_(1);
			//~revRateBusMon.set(-1); // <--DO THIS instead of valueAction !!!!!!!!!!
			//~buttonRev.value_(1); // <--DO THIS instead of valueAction !!!!!!!!!!!!
			thisRandomNum = rrand(1, 10);
			//("***thisRandNum-reroll" + thisRandomNum).postln;
			if (thisRandomNum <= 8,
				{time2nextRandomize = rrand(3.5, 6.0);},
				{time2nextRandomize = rrand(6.0, 10.0);} );
			//("time2NextRand=" + time2nextRandomize).postln;
			time2nextRandomize.yieldAndReset;
		}, { //71% chance REVERSE remains disabled
			time2nextRandomize = rrand(9, 20);
			//("time2NextRand=" + time2nextRandomize).postln;
			time2nextRandomize.yieldAndReset;
		} );
	}, { //if REVERSE enabled
		if (thisRandomNum <= 9, {
			~buttonRev.valueAction_(0); //90% chance REVERSE disabled
			//~revRateBusMon.set(1); // <--DO THIS instead of valueAction !!!!!!!!!!
			//~buttonRev.value_(0); // <--DO THIS instead of valueAction !!!!!!!!!!!!

			time2nextRandomize = rrand(9, 20);
			//("time2NextRand=" + time2nextRandomize).postln;
			time2nextRandomize.yieldAndReset;
		}, {
			time2nextRandomize = rrand(3.0, 5.0); //20% chance REVERSE remains enabled
			//("time2NextRand=" + time2nextRandomize).postln;
			time2nextRandomize.yieldAndReset;
		} );
	} );
} );

/*
~randomRoutine_pitchShiftMix = Routine.new ( {
	var time2nextRandomize, mixCase; /*, currentTime, newMixVal, interpTime*/

	~pitchShiftMixValBus.get( {
		arg val;
		~pitchShiftMix_prev = val;
	} );

	//currentTime = Date.localtime;
	//("-->pShftMixCurntTime=" + currentTime).postln;
	0.1.yield;

	//simple chance based method-------
	if (~pitchShiftMix_prev == 0, {
		var thisRandomNum = rrand(1, 10);
		mixCase = case
		{thisRandomNum <= 7} {
			~sliderPitchShiftMix.valueAction_(1); //maybe not best way in long run, but convenient for now...
			//~pitchShiftMixValBus.set(1);
			//~numBoxPitchMix.value_(100);
		}
		{thisRandomNum >= 8 && thisRandomNum <= 9} {
			~sliderPitchShiftMix.valueAction_(0.5);
		}
		{thisRandomNum >= 10} {
			~sliderPitchShiftMix.valueAction_(0);
		};
	} , { //else if pitchShiftMix != 0
		var thisRandomNum = rrand(1, 10);
		mixCase = case
		{thisRandomNum <= 6} {
			~sliderPitchShiftMix.valueAction_(1); //maybe not best way in long run, but convenient for now...
			//~pitchShiftMixValBus.set(1);
			//~numBoxPitchMix.value_(100);
		}
		{thisRandomNum >= 7 && thisRandomNum <= 8} {
			~sliderPitchShiftMix.valueAction_(0.5);
		}
		{thisRandomNum >= 9} {
			~sliderPitchShiftMix.valueAction_(0);
		};
	} );

	time2nextRandomize = rrand(5, 20);
	~time2NextRandom_pitchShiftMix = time2nextRandomize;
	time2nextRandomize.yieldAndReset;

	//------more complicated chance and time based method-------

	//currentTime = Date.localtime;
	//~pitchShiftMix_prevChangeTime = currentTime.rawSeconds;
} ); */

~randomRoutine_pitchShiftMix = Routine.new ( {
	var time2nextRandomize, randNum, mixCase, interpMix, interpTime;

	~pitchShiftMixValBus.get( {
		arg val;
		~pitchShiftMix_prev = val;
	} );

	//!!!!!CONSIDER ALSO GETTING CURRENT pitchShift value....if == 0 make mixVal = 0 !!!!!!!!!!!!!

	0.1.yield; //<<<<<works, but not sure if ideal way...

	if (~pitchShiftMix_prev == 0, {  //<-----CONSIDER CHANGING THIS TO CASE INSTEAD BASED ON PRECISE CURRENT VALUE OF PITCH SHIFT MIX TO AVOID NEEDLESS GUI INTERPOLATION ROUTINES-------
		randNum = rrand(1.0, 10.0);
		mixCase = case
		{randNum <= 4} { //set mix to 100%
			interpTime = rrand(0.25, 5.0); //("interpTime=" + interpTime).postln;
			interpMix = Synth(\LinInterp_num, [\out, ~pitchShiftMixValBus, \startVal, ~pitchShiftMix_prev, \stopVal, 1.0, \duration, interpTime] );
			~pitchShiftMix_interp = true;
			~updateGUI_pitchShiftMix.reset;
			AppClock.play(~updateGUI_pitchShiftMix);
			(interpTime + 0.1).yield;

			~pitchShiftMix_interp = false;
			~updateGUI_pitchShiftMix.stop;
		}
		{randNum > 4 && randNum <= 7} { //set mix to 50%
			interpTime = rrand(0.25, 5.0); //("interpTime=" + interpTime).postln;
			interpMix = Synth(\LinInterp_num, [\out, ~pitchShiftMixValBus, \startVal, ~pitchShiftMix_prev, \stopVal, 0.5, \duration, interpTime] );
			~pitchShiftMix_interp = true;
			~updateGUI_pitchShiftMix.reset;
			AppClock.play(~updateGUI_pitchShiftMix);
			(interpTime + 0.1).yield;

			~pitchShiftMix_interp = false;
			~updateGUI_pitchShiftMix.stop
		};
		//else if randNum > 7, leave mix at 0%

	} , { //else if pitchShiftMix != 0
		randNum = rrand(1.0, 10.0);
		mixCase = case
		{randNum <= 4} { //set mix to 100%
			interpTime = rrand(0.25, 5.0); //("interpTime=" + interpTime).postln;
			interpMix = Synth(\LinInterp_num, [\out, ~pitchShiftMixValBus, \startVal, ~pitchShiftMix_prev, \stopVal, 1.0, \duration, interpTime] );
			~pitchShiftMix_interp = true;
			~updateGUI_pitchShiftMix.reset;
			AppClock.play(~updateGUI_pitchShiftMix);
			(interpTime + 0.1).yield;

			~pitchShiftMix_interp = false;
			~updateGUI_pitchShiftMix.stop
		}
		{randNum > 4 && randNum <= 7} { //set mix to 50%
			interpTime = rrand(0.25, 5.0); //("interpTime=" + interpTime).postln;
			interpMix = Synth(\LinInterp_num, [\out, ~pitchShiftMixValBus, \startVal, ~pitchShiftMix_prev, \stopVal, 0.5, \duration, interpTime] );
			~pitchShiftMix_interp = true;
			~updateGUI_pitchShiftMix.reset;
			AppClock.play(~updateGUI_pitchShiftMix);
			(interpTime + 0.1).yield;

			~pitchShiftMix_interp = false;
			~updateGUI_pitchShiftMix.stop
		}
		{randNum > 7} { //set mix to 0%
			interpTime = rrand(0.25, 5.0); //("interpTime=" + interpTime).postln;
			interpMix = Synth(\LinInterp_num, [\out, ~pitchShiftMixValBus, \startVal, ~pitchShiftMix_prev, \stopVal, 0, \duration, interpTime] );
			~pitchShiftMix_interp = true;
			~updateGUI_pitchShiftMix.reset;
			AppClock.play(~updateGUI_pitchShiftMix);
			(interpTime + 0.1).yield;

			~pitchShiftMix_interp = false;
			~updateGUI_pitchShiftMix.stop
		};
	} );

	time2nextRandomize = rrand(5, 20);
	~time2NextRandom_pitchShiftMix = time2nextRandomize;
	time2nextRandomize.yieldAndReset;

	//------more complicated chance and time based method-------

	//currentTime = Date.localtime;
	//~pitchShiftMix_prevChangeTime = currentTime.rawSeconds;
} );


~randomRoutine_rate = Routine.new ( { //Automatically randomize playback rate and adjust playHead
	var time2nextRandomize, randNum4transp, newPitch, pitchCase, pitchInterp, interpTime;

	~rateBus.get( {
		arg val;
		//("*****currentRate=" + val).post;
			~pitchShiftValPrev_rate = val.ratiomidi;
			//("---prevPitch=" + ~pitchShiftValPrev_rate).postln;
	} );

	0.1.yield; //<<<<<works, but not sure if ideal way...

	randNum4transp = rrand(1, 10); //based on random # from 1-10, determine type of pitch transposition
	//"randNum4transp= ".post; randNum4transp.postln;
	pitchCase = case
	{randNum4transp <= 4} { //40% chance of lowering pitch
		newPitch = rrand(-7.0, -0.2).round(0.01);
		//("--newPitch=" + newPitch).post;
	}
	{randNum4transp >= 5 && randNum4transp <= 8} { //40% chance of no pitch change
		newPitch = 0.0; //no transposition...
		//("--newPitch=" + newPitch).post;
	}
	{randNum4transp >= 9} { //20% chance of raising pitch
		newPitch = rrand(1.0, 5.0).round(0.01);
		//("--newPitch=" + newPitch).post;
	};

	~pitchShiftValTarget_rate = newPitch; //set target pitch to shift to
	//(" | targetPitch=" + ~pitchShiftValTarget_rate).postln;

	if (newPitch != ~pitchShiftValPrev_rate, {
		interpTime = rrand(1.2, 7.0);
		//("interpTime=" + interpTime).postln;

		//interpolate to new rate, is able to reverse during interpolation
		pitchInterp = Synth(\LinInterp_rate, [\out, ~rateBus, \startVal, ~pitchShiftValPrev_rate, \stopVal, ~pitchShiftValTarget_rate, \duration, interpTime, \rateMod, ~revRateBusMon.asMap] );

		//pitchInterp = Synth(\LinInterp_pitch, [\out, ~rateBus, \startVal, ~pitchShiftValPrev_rate, \stopVal, ~pitchShiftValTarget_rate, \duration, interpTime] );
		/*
		if (~buttonRev.value == 1, { //when REVERSE mode enabled  <-----worked, but not during interp-------
			pitchInterp = Synth(\LinPitchInterpRev, [\out, ~rateBus, \startVal, ~pitchShiftValPrev_rate, \stopVal, ~pitchShiftValTarget_rate, \duration, interpTime] );
		} , { //when REVERSE mode disabled
			pitchInterp = Synth(\LinInterp_pitch, [\out, ~rateBus, \startVal, ~pitchShiftValPrev_rate, \stopVal, ~pitchShiftValTarget_rate, \duration, interpTime] );
		} ); */

		~pitchInterp_rate = true; //flag (currently prevents playRecOffsetAdjust routine from interrupting pitchInterp)
		//("*****pitchInterp=" + ~pitchInterp_rate).postln;
		~updateGUI_rate.reset;
		AppClock.play(~updateGUI_rate);

		(interpTime + 0.1).yield;
		//1.3.yield; //keep or no!??? <-----

		~pitchInterp_rate = false;
		//("*****pitchInterp=" + ~pitchInterp_rate).postln;
		~updateGUI_rate.stop;
		time2nextRandomize = rrand(13, 22); //if newPitch != prevPitch
	} , {
		time2nextRandomize = rrand(5, 10); //reduced possible time2nextRand in case newPitch == prevPitch
	} );
	~time2NextRandom_rate = time2nextRandomize; //for populating GUI
	time2nextRandomize.yieldAndReset;
} );

~numBoxCountdownRoutine = Routine.new( { //crude somewhat inaccurate way to do this but good enough for now
	if (~time2NextRandom_rate <= 0, {~time2NextRandom_rate = 0;} );
	~numBoxRandomState.value_(~time2NextRandom_rate);
	~time2NextRandom_rate = ~time2NextRandom_rate - 0.1;
	0.1.yieldAndReset;
} );

~playRecOffsetCheckRoutine = Routine.new( {
	//"**playRecOffsetIsGoing**  ".post;
	//("revFlag=" + ~reverseFlag).postln;
	if ((~pitchInterp_rate == false) && (~buttonRev.value == 0) /*&& (~pitchInterp_freq == false) */, { //<---ADDED reverse & pitchInterp detection---
		var currentTimeOffset, newOffsetPos, newOffsetAmount, pitchCase;

		~phaseBusMonRec.get( {
			arg recPos;
			~lastRecPhasePos = recPos;
			//("recPos="+recPos).post;
			//(" | lastRecPhasePos=" + ~lastRecPhasePos).postln;
		} );

		~phaseBusMonPly.get( {
			arg playPos;
			//~lastPlayPhasePos = playPos;
			~lastPlayPhasePos = playPos;
			//("playPos=" + playPos).post;
			//(" | lastPlayPhasePos=" + ~lastPlayPhasePos).postln;
		} );

		0.1.yield; //<--not sure if needed...not ideal and crude

		if (~lastRecPhasePos < ~lastPlayPhasePos, //measure distance between rec and play - if rec's wrapped around to start of buffr before play
			{currentTimeOffset = ( (~currentPlayOutFrame - ~currentPlayInFrame) - (~lastPlayPhasePos - ~lastRecPhasePos) ) / (s.sampleRate); } ,
			{currentTimeOffset = (~lastRecPhasePos - ~lastPlayPhasePos)/(s.sampleRate); } //else measure offset if no wrap around has occured (will happen most of the time)
		);
		currentTimeOffset = currentTimeOffset.round(0.01);
		//("!!!currentTimeOffset=" + currentTimeOffset).postln;

		pitchCase = case
		{~pitchShiftValTarget_rate > 0} {
			if ( (currentTimeOffset <= 0.3) || (currentTimeOffset >= 6.5), {
				newOffsetAmount = rrand(2.7, 4.0); //generate random offset amount (in seconds)
				newOffsetPos = ~lastRecPhasePos - ((newOffsetAmount * s.sampleRate).round(1)); //deduce new playPhase position based on newOffsetAmount (converted to frames)

				/*if (newOffsetPos < 0, //orig simple safe driving
				{newOffsetPos = (~buffer.numFrames - 1) + newOffsetPos;} //wrap around buffer if negative position generated
				); */

				if ( (~currentPlayInFrame == 0) && (newOffsetPos < 0), { //safe driving: case 1
					newOffsetPos = ~currentPlayOutFrame + newOffsetPos; //wrap around buffer if negative position generated
					if (newOffsetPos < 0, {
						/*newOffsetPos = 0;*/ //think this could potentially cause issues if current recPos = 0 too...
						newOffsetPos = ~lastRecPhasePos + 1000;} ); //to avoid never ending loop if result is still < 0
				} );

				if ( (~currentPlayInFrame > 0) && (newOffsetPos < ~currentPlayInFrame), { //safe driving: case 2
					newOffsetPos = newOffsetPos + (~currentPlayOutFrame - ~currentPlayInFrame);
					if (newOffsetPos < ~currentPlayInFrame, {newOffsetPos = ~lastRecPhasePos + 1000;}); //to avoid never-ending loop
				} );

				~playPhase.set(\resetPos, newOffsetPos, \trig, 1); //set new position of playPhase (move playHead)
			} );
		}
		{~pitchShiftValTarget_rate <= 0} {
			if ( (currentTimeOffset >= 6.0) || (currentTimeOffset <= 0.3),
			{
				newOffsetAmount = rrand(0.5, 2.75); //generate random offset amount (in seconds)
				newOffsetPos = ~lastRecPhasePos - ((newOffsetAmount * s.sampleRate).round(1)); //deduce new playPhase position based on newOffsetAmount (convert to frames)

				if ( (~currentPlayInFrame == 0) && (newOffsetPos < 0), { //safe driving: case 1
					newOffsetPos = ~currentPlayOutFrame + newOffsetPos; //wrap around buffer if negative position generated
					if (newOffsetPos < 0, {
						/*newOffsetPos = 0;*/ //think this could potentially cause issues if current recPos = 0 too...
						newOffsetPos = ~lastRecPhasePos + 1000;} ); //to avoid never ending loop if result is still < 0
				} );

				if ( (~currentPlayInFrame > 0) && (newOffsetPos < ~currentPlayInFrame), { //safe driving: case 2
					newOffsetPos = newOffsetPos + (~currentPlayOutFrame - ~currentPlayInFrame);
					if (newOffsetPos < ~currentPlayInFrame, {newOffsetPos = ~lastRecPhasePos + 1000;}); //to avoid never-ending loop
				} );

				~playPhase.set(\resetPos, newOffsetPos, \trig, 1); //set new position of playPhase (move playHead)
			} );
		};
	} );

	2.0.yieldAndReset;
} );

////////
~randomRoutine_playBehavior = Routine.new ( { //<----working...CONSIDER AUGMENTING EVENTUALLY to be aware of current rate and pitchShift values (so it can avoid feedback if randomRate or randomPitch routines not enabled by disabling playRecOffset if this is the case, for example) AAAANNDD ALSO BE AWARE OF previous and current playBehavior states to more intelligently govern probability of transitioning to new state (e.g. if previously was at randomState, increase the chances of reverting back to followPlayhead state upon next state change)
	var time2nextRandomize, thisRandomNum, selectedBehavior, behaviorCase, newPos, offsetSec, minOffsetSec = 12, maxOffsetSec = 55;

	thisRandomNum = rrand(1.0, 10.0);
	if (((~randomPos_flag == false) && (thisRandomNum <= 8)) || (~randomPos_flag == true), { //80% chance playHead will follow recHead if randomPos not previously active
		~randomPos_flag = false; //reset flag to remember randomPos no longer active after routine reset
		~playRecOffsetCheckRoutine.reset;
		AppClock.play(~playRecOffsetCheckRoutine);
		time2nextRandomize = rrand(12, 20);
		("***FOLLOW RECHEAD behavior running for " + time2nextRandomize + " secs...").postln;
		time2nextRandomize.yieldAndReset;
	}, { //else 25% chance playHead moved to random position...
		//("***RANDOM POSITION***").postln;
		~randomPos_flag = true;  //set flag to remember randomPos triggered after this routine is reset
		~playRecOffsetCheckRoutine.stop;
		~phaseBusMonRec.get( {
			arg recPos;
			~lastRecPhasePos = recPos;
			//("recPos="+recPos).post;
			//(" | lastRecPhasePos=" + ~lastRecPhasePos).postln;
		} );

		~phaseBusMonPly.get( {
			arg playPos;
			//~lastPlayPhasePos = playPos;
			~lastPlayPhasePos = playPos;
			//("playPos=" + playPos).post;
			//(" | lastPlayPhasePos=" + ~lastPlayPhasePos).postln;
		} );

		0.1.yield;

		offsetSec = rrand(minOffsetSec, maxOffsetSec); //generate random offset value (in seconds)
		//("offsetSec=" + offsetSec).postln;
		thisRandomNum = rrand(1, 2);
		if (thisRandomNum == 1,
			{ //50% chance playHead offset backwards in time
				//newPos = rrand(0, ~lastPlayPhasePos);

				//("--BACKWARDS--").postln;
				newPos = ~lastPlayPhasePos - (offsetSec * s.sampleRate);
				if (newPos < 0, {newPos = (~buffer.numFrames - 1) + newPos;} ); //wrap around if newPos initially less than 0
				//("lastPlayPhaseFrame=" + ~lastPlayPhasePos + " | lastPlaySec=" + (~lastPlayPhasePos/s.sampleRate) ).postln;
				//("newPos=" + newPos + " | " + (newPos/s.sampleRate) + "sec").postln;
			},
			{ //50% chance playHead offset forwards in time
				//newPos = rrand(~lastPlayPhasePos, ~buffer.numFrames - 1);

				//("--FORWARDS--").postln;
				newPos = ~lastPlayPhasePos + (offsetSec * s.sampleRate);
				if (newPos > (~buffer.numFrames - 1), {newPos = (newPos % ~buffer.numFrames) - 1;} ); //wrap around if newPos greater than buffer length

				if ( ((~lastRecPhasePos - newPos) <= (2 * s.sampleRate) ) && ((~lastRecPhasePos - newPos) >= 0), {
					//("---AVOIDING FEEDBACK---").postln;
					//("lastRecHeadPos =" + (~lastRecPhasePos/s.sampleRate) + " | ").post;
					//("newPos WAS: " + (newPos/s.sampleRate).round(0.01) + "sec").postln;
					newPos = ~lastRecPhasePos + (1.5 * s.sampleRate); //reset newPos to 1.5 seconds AFTER recHead to avoid inducing rapid feedback (only would happen if rate and pitch shift == 0)
					if (newPos > (~buffer.numFrames - 1), {newPos = (newPos % ~buffer.numFrames) - 1;} ); //wrap around if newPos greater than buffer length
					//("newPos IS NOW: " + (newPos/s.sampleRate).round(0.01) + "sec").postln;
				} ); //to avoid landing too close to recHead and causing rapid audio feedback

				//("lastPlayPhaseFrame=" + ~lastPlayPhasePos + " | lastPlaySec=" + (~lastPlayPhasePos/s.sampleRate) ).postln;
				//("newPos=" + newPos + " | " + (newPos/s.sampleRate) + "sec").postln;
			}
		);
		~playPhase.set(\resetPos, newPos, \trig, 1); //set new position of playPhase (move playHead)
		time2nextRandomize = rrand(4.5, 10.0).round(0.01);
		("***RANDOM POSITION behavior running for " + time2nextRandomize + " secs...").postln;
		time2nextRandomize.yieldAndReset;
	} );



/*	behaviorCase = case  //<------REINCORPORATE
	{~playBehavior == 0} { //"follow recHead" behavior
		~playRecOffsetCheckRoutine.reset;
		AppClock.play(~playRecOffsetCheckRoutine);
		if (thisRandomNum <= 7.5, {
			time2nextRandomize = rrand(12.0, 25.0);
			("***FOLLOW RECHEAD behavior running next " + time2nextRandomize + " secs...").postln;
			time2nextRandomize.yieldAndReset;
		}, {
			/////////////////
		} );
	}
	{  } { //"random play" behavior

	}
	{  } {//"random loop" behavior

	}; */
} );
//////

//BEHAVIOR BUTTONS

~buttonRev = Button(w, Rect(490, 349, 45, 25)) //Reverse playback
.states_( [
	["REV", Color.black, Color(0.8, 0.5, 0, 0.3)] ,
	["REV", Color.white, Color(0.85, 0.5, 0)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{  //reverse playback when enabled
			~rateBus.get( {
				arg val;
				if (val > 0, {
					var newRate = -1 * val;
					//("newRate=" + newRate).postln;
					~rateBus.set(newRate);
				} );
			} );
			~revRateBusMon.set(-1);
			//~reverseFlag = true;
		},
		{  //normal playback when disabled
			~rateBus.get( {
				arg val;
				var newRate = val.abs;
				//("newRate=" + newRate).postln;
				~rateBus.set(newRate);
			} );
			~revRateBusMon.set(1);
			//~reverseFlag = false;
		}
	);
} )
.value_(0);

~buttonRecInOut = Button(w, Rect(62, 352, 70, 20))
.states_( [
	["REC-InOut", Color.black, Color(0.9, 0.9, 0.3, 0.3)] ,
	["REC-InOut", Color.black, Color(0.9, 0.9, 0.3)]
] )
.font_(Font("Monaco", 12) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{
			~buttonRecIn.valueAction = 1;
			~buttonRecOut.valueAction = 1;
		},
		{
			~buttonRecIn.valueAction = 0;
			~buttonRecOut.valueAction = 0;
		}
	);
} )
.value_(0);

~buttonRandAutoRecPlayFiles = Button(w, Rect(215, 349, 25, 25))
.states_( [
	["^v", Color.black, Color(0.6, 0.9, 0.4, 0.3)] ,
	["^v", Color.white, Color(0.8, 1.0, 0.4)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{
			~soundRoutine_autoPlay.reset;
			AppClock.play(~soundRoutine_autoPlay);
		},
		{
			~soundRoutine_autoPlay.stop;
		}
	);
} )
.value_(0);

~buttonRandomState_3 = Button(w, Rect(243, 349, 25, 25))
.states_( [
	["!", Color.black, Color(0.6, 0.9, 0.0, 0.3)] ,
	["!", Color.white, Color(0.8, 1.0, 0.0)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1, // when randomize button enabled
		{
			~randomRoutine_reverse.reset;
			~randomRoutine_playBehavior.reset;
			AppClock.play(~randomRoutine_reverse);
			AppClock.play(~randomRoutine_playBehavior);
		},
		{ //when randomize button disabled
			~randomRoutine_reverse.stop;
			~randomRoutine_playBehavior.stop;
			~playRecOffsetCheckRoutine.stop;
		}
	);
} )
.value_(0);

~buttonRandomState_2 = Button(w, Rect(271, 349, 40, 25))
.states_( [
	["!!", Color.black, Color(0.0, 0.3, 0.9, 0.3)] ,
	["!!", Color.white, Color(0.8, 0.3, 0.8)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1, // when randomize button enabled
		{
			~randomRoutine_freq.reset;
			~randomRoutine_pitchShiftMix.reset;
			~randomRoutine_outputLevel.reset;
			//~numBoxCountdownRoutine.reset;
			//~playRecOffsetCheckRoutine.reset;
			//~updateGUI_rate.reset;

			AppClock.play(~randomRoutine_freq);
			AppClock.play(~randomRoutine_pitchShiftMix);
			AppClock.play(~randomRoutine_outputLevel);
		},
		{ //when randomize button disabled
			//~randomRoutine.stop;
			~randomRoutine_freq.stop;
			~randomRoutine_pitchShiftMix.stop;
			~randomRoutine_outputLevel.stop;
			//~numBoxRandomState.value_(0.0);
		}
	);
} )
.value_(0);

~buttonRandomState_1 = Button(w, Rect(314, 349, 55, 25)) //<------playRecOffsetCheck DISABLED
.states_( [
	["!!!", Color.black, Color(0.7, 0.3, 0.7, 0.3)] ,
	["!!!", Color.white, Color(0.8, 0.3, 0.8)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1, // when randomize button enabled
		{
			~randomRoutine_rate.reset;
			~numBoxCountdownRoutine.reset;
			//~playRecOffsetCheckRoutine.reset;
			~updateGUI_rate.reset;
			AppClock.play(~randomRoutine_rate);
			AppClock.play(~numBoxCountdownRoutine);
			//AppClock.play(~playRecOffsetCheckRoutine); //<--CREATE ROUTINE TO VARY THIS (e.g. ON for 60 - 90, OFF for 10 - 25)
		},
		{ //when randomize button disabled
			~randomRoutine_rate.stop;
			~numBoxCountdownRoutine.stop;
			//~playRecOffsetCheckRoutine.stop;
			~updateGUI_rate.stop;
			~numBoxRandomState.value_(0.0);
		}
	);
} )
.value_(0);

~numBoxRandomState = NumberBox(w, Rect(313, 378, 50, 25))
.value_(0.0)
.clipLo_(0)
.clipHi_(120)
.font_(Font("Monaco", 14) )
.decimals_(1);

~labelRandomTime = StaticText(w, Rect(368, 380, 30, 20) )
.string_("T2R")
.font_(Font("Monaco", 12) )
.align_(\left);

//SCOPE VIEW//

~scopeView = ScopeView(w.view, Rect(15, 10, 665, 170) );
~scopeView.server_(s);
~scopeView.xZoom = 1.0;  //changing these values doesn't seem to effect display
~scopeView.x = 0;  //changing these values doesn't seem to effect display
~scopeView.yZoom = 1.0;


//PLOTTER//

/*
~bufPlot = Plotter.new("Buffer", Rect(15, 10, 665, 170), w); //CREATE PLOTTER
~bufPlot.value = 0; //initialize w/ value of 0
//~bufPlot.value = ~buffer;
~bufPlot.setProperties(
	\fontColor, Color.red,
	\plotColor, Color.blue,
	\backgroundColor, Color.black,
	\gridColorX, Color.white,
	\gridColorY, Color.cyan,
	\gridOnY, true,
	\gridOnX, true
);
~bufPlot.refresh;
*/

////RECORD TO BUFFER////

~buttonRec = Button(w, Rect(372, 349, 55, 25)) //REC BUTTON: activate / deactivate recording to buffer
.states_( [
	["REC", Color.black, Color(0.95, 0, 0, 0.3)] ,
	["REC", Color.white, Color(0.95, 0, 0)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1, // when REC button enabled (start recording to buffer)
		{
			~recPhase = Synth(\phasor, [\out, ~phaseBusRec, \buf, ~buffer, \rate, 1, \start, ~recInPosBus.asMap, \end, ~recOutPosBus.asMap, \trig, 0, \resetPos, ~lastRecPhasePos] ); //***can experiment w/ in/out locking w/ in/OutPosBus or fixed pos at beg and end of buf...***
			~a2kRec = Synth(\a2k_patch, [\in, ~phaseBusRec, \out, ~phaseBusMonRec] );
			//~bufRecSynth = Synth(\RecBuf_loop, [\phaseBus, ~phaseBusRec, \buf, ~buffer, \mul, ~inputLevelBus.asMap] );
			//~bufRecSynth = Synth(\RecBuf_loop, [\phaseBus, ~phaseBusRec, \buf, ~buffer, \sendBus, ~inputSendBus, \mul, ~inputLevelBus.asMap] );
			~bufRecSynth = Synth(\RecBuf_loop, [\phaseBus, ~phaseBusRec, \buf, ~buffer, \sendBus, ~inputSendBus, \loCutoff, ~loCutBus_in.asMap, \mul, ~inputLevelBus.asMap] ); //<----NEW!!!!!!
			//~lastRecPhasePos.value.postln;
			~recTrig = true;

			//////////////SCOPE

			~bufferScope = Buffer.alloc(s, ~buffer.numFrames, 1); //create additional buffer for displaying contents of audio buffer...is this the only way to do this?? what happens if I 'scopeOut' to ~buffer?
			~scopeView.bufnum = ~bufferScope.bufnum; //<----
			~scopeOut = Synth.tail(s, \scopeOut, [\inBus, ~inputSendBus, \buf, ~bufferScope]); //<----
			~scopeView.start; //<----

			//////////
		},
		{ //when REC button disabled (when recording stops)
			~phaseBusMonRec.get( {arg val; ~lastRecPhasePos = val;} ); //store last pos of recPhase
			~recPhase.free;
			~a2kRec.free;
			~bufRecSynth.free; //stop recording to buffer and free RecBuf_loop synth

			 ///FOR SCOPE
			~scopeView.stop; //<----
			~scopeOut.free; //<----
			~bufferScope.free; //<----

		}
	);
} );

///LEVELS///

~labelInputLevel = StaticText(w, Rect(687, 195, 12, 20) )
.string_("IN")
.font_(Font("Monaco", 10) )
.align_(\center);

~sliderInputLevel = Slider(w, Rect(684, 8, 17, 173) )
.background_(Color(0.9, 0.0, 0.0, 0.2))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~inputLevelBus.set(val);
	//~bufRecSynth.set(\mul, val);
	~numBoxInputLevel.value_(val);
	//~bufRecSynth.get(\mul, {arg mulval; mulval.postln;} );
	//~inputLevelBus.get({arg val; val.postln;} );
} );

~numBoxInputLevel = NumberBox(w, Rect(682, 183, 26, 15))
.value_(1.0)
.clipLo_(0.0)
.clipHi_(1.0)
.decimals_(2)
.font_(Font("Monaco", 8) )
.scroll_step_(0.01)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~inputLevelBus.set(val);
	~sliderInputLevel.value_(val);
} );

~sliderInStreamLevel = Slider(w, Rect(684, 242, 12, 73) )
.background_(Color(0.0, 0.5, 0.9))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~inputStreamLevelBus.set(val);
	~numBoxInStreamLevel.value_(val);
} );

~numBoxInStreamLevel = NumberBox(w, Rect(678, 315, 26, 15))
.value_(1.0)
.clipLo_(0.0)
.clipHi_(1.0)
.decimals_(2)
.font_(Font("Monaco", 8) )
.scroll_step_(0.01)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~inputStreamLevelBus.set(val);
	~sliderInStreamLevel.value_(val);
} );

~labelinStreamLevel = StaticText(w, Rect(670, 332, 40, 8) )
.string_("IN+FX")
.font_(Font("Monaco", 10) )
.align_(\center);

~sliderFileOutLevel = Slider(w, Rect(715, 242, 12, 73) )
.background_(Color(0.0, 0.8, 0.2))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~fileOutputLevelBus.set(val);
	~numBoxFileOutLevel.value_(val);
} );

~numBoxFileOutLevel = NumberBox(w, Rect(709, 315, 26, 15))
.value_(1.0)
.clipLo_(0.0)
.clipHi_(1.0)
.decimals_(2)
.font_(Font("Monaco", 8) )
.scroll_step_(0.01)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~fileOutputLevelBus.set(val);
	~sliderFileOutLevel.value_(val);
} );

~labelFileOutLevel = StaticText(w, Rect(707, 332, 32, 8) )
.string_("FILE")
.font_(Font("Monaco", 10) )
.align_(\center);

~labelOutputLevel = StaticText(w, Rect(730, 195, 20, 20) )
.string_("OUT")
.font_(Font("Monaco", 10) )
.align_(\center);

~numBoxOutputLevel = NumberBox(w, Rect(728, 183, 26, 15))
.value_(1.0)
.clipLo_(0.0)
.clipHi_(1.0)
.decimals_(2)
.font_(Font("Monaco", 8) )
.scroll_step_(0.01)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~outMainLevelBus.set(val);
	~sliderOutputLevel.value_(val);
} );

~sliderOutputLevel = Slider(w, Rect(733, 8, 17, 173) )
.background_(Color(0.0, 0.8, 0.2, 0.01))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~outMainLevelBus.set(val);
	~numBoxOutputLevel.value_(val);
} );

///////

~sliderRecPos = Slider(w, Rect(15, 212, 470, 20))
.background_(Color(0.95, 0.0, 0.0))
.action_( {
	arg obj;
	var pos;
	//pos = obj.value.linlin(0, 1, 0, ((s.sampleRate * ~bufferSize) - 1)).round(1); //convert slider value to frame
	pos = obj.value.linlin(0, 1, 0, ~buffer.numFrames - 1); //convert slider value to frame
	~recPhase.set ( //update ~recPhase phasor synth position....
		\resetPos, pos,
		\trig, 1
	);
	//~numBoxRecPos.value_(pos/s.sampleRate).round(0.1); //convert frames to seconds and display
	~numBoxRecPos.value = (pos/s.sampleRate).round(0.01); //convert frames to seconds and display

	//SYNC functionality----------------
	if (~fixPlayRecOffset == true, //<-----
		{
			~play2recOffset = pos - ((~delayTime * s.sampleRate).round(1));
			if (~play2recOffset < 0,
				{~lastPlayPhasePos = (~buffer.numFrames - 1) + ~play2recOffset;} ,
				{~lastPlayPhasePos = ~play2recOffset; }
			);
				if (~buttonPlay.value == 1, {~playPhase.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } ); //is this best way to do it or should I create a flag indicating whenever recPhase position is updated w/ click so that playPhase is updated w/ clock instead???
		} ,
	    { //else
			~phaseBusMonPly.get( {
				arg val;
				if (pos >= val,
					{
					 ~play2recOffset = pos - val;
					 ~delayTime = ~play2recOffset/s.sampleRate;
					},
					{
					 ~play2recOffset = ~buffer.numFrames - (pos - val);
					 ~delayTime = ~play2recOffset/s.sampleRate;
					}
				);
			} );
			~numBoxDel.value = ~delayTime;
			//~sliderDelay.value = ~delayTime.linlin(0, ~bufferSize - 0.01, 0, 1); //obsolesced in 1.82
		}
	 );
	//SYNC functionality----------------
} )
.value_(0.0);

~numBoxRecPos = NumberBox(w, Rect(490, 208, 75, 25)) //numBox PlayPos
.value_(0)
.clipLo_(0)
//.clipHi_(~bufferSize) //HOW COME UNCOMMENTING THIS MESSES UP THE GUI??????
.font_(Font("Monaco", 14) )
.decimals_(2);
//.action_( {
	//arg obj;
	//~sliderRecPos.valueAction = obj.value / ~bufferSize; //<---
//} );

~labelRecPos = StaticText(w, Rect(568, 182, 100, 80) )
.string_("RecPos(sec)")
.font_(Font("Monaco", 10) )
.align_(\left);

////PLAYBACK BUFFER (DELAYED OUTPUT)////

~buttonPlay = Button(w, Rect(430, 349, 55, 25)) //activate / deactivate playback output
.states_( [
	["PLAY", Color.black, Color(0.0, 0.8, 0.2, 0.3)] ,
	["PLAY", Color.white, Color(0.0, 0.8, 0.2)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (obj.value == 1,
		{
			/* //<----- SYNC PLAYHEAD OFFSET FUNCTIONALITY...buggy, not working 100% ----------
			//"fixPlayOffset= ".post; ~buttonDel.value.postln;
			//"buttonRec= ".post; ~buttonRec.value.postln;
			//~phaseBusMonPly.get( {arg val; ~lastPlayPhasePos = val;} );
			if (~buttonDel.value == 1 && ~buttonRec.value == 1,
				{
					"--ifSyncDelActive".postln;
					//var newPlayPos;
					"lastPlayPhasePos= ".post; ~lastPlayPhasePos.postln;
					~phaseBusMonRec.get( {
						arg val;
						"recPhase= ".post; val.postln;
						~play2recOffset = val - ((~delayTime * s.sampleRate).round(1));
						"play2recOffset= ".post; ~play2recOffset.postln;
						if (~play2recOffset < 0,
							{
								~lastPlayPhasePos = (~buffer.numFrames - 1) + ~play2recOffset; //if true, wrap around buffer
								//newPlayPos = (~buffer.numFrames - 1) + ~play2recOffset;
							} ,
							{
								~lastPlayPhasePos = ~play2recOffset; //else normal subtraction
								//newPlayPos = ~play2recOffset;
							}
						);
					} );
					//~playPhase = Synth(\phasor, [\out, ~phaseBusPly, \buf, ~buffer, \rate, ~rateBus.asMap, \start, ~playInPosBus.asMap, \end, ~playOutPosBus.asMap, \trig, 0, \resetPos, newPlayPos] );
					"lastPlayPhasePosafterOffsetAdjust".post; ~lastPlayPhasePos.postln;
				} //,
				//{
					//~playPhase = Synth(\phasor, [\out, ~phaseBusPly, \buf, ~buffer, \rate, ~rateBus.asMap, \start, ~playInPosBus.asMap, \end, ~playOutPosBus.asMap, \trig, 0, \resetPos, ~lastPlayPhasePos] );
				//}
			); */ //<------------------------------^^^^^^^^^^^^^^^^^^^

			//"--afterIf".postln;
			//~lastPlayPhasePos.postln;

			~playPhase = Synth(\phasor, [\out, ~phaseBusPly, \buf, ~buffer, \rate, ~rateBus.asMap, \start, ~playInPosBus.asMap, \end, ~playOutPosBus.asMap, \trig, 0, \resetPos, ~lastPlayPhasePos] ); //.asMap needs to follow control bus arguments for current values to constantly update phasor
			~a2k = Synth(\a2k_patch, [\in, ~phaseBusPly, \out, ~phaseBusMonPly]); //converting phaseBus values at ar to kr and sending to phaseBusMon so sliderPlayPos can receive current value of phasor
			//~playBuf = Synth(\ReadBuf_loop, [\amp, ~outMainLevelBus.asMap, \out, 0, \phaseBus, ~phaseBusPly] ); //orig
			~playBuf = Synth(\ReadBuf_loop, [\amp, ~play1LevelBus.asMap, \out, ~playOut1Bus, \phaseBus, ~phaseBusPly] );  //<!!!--NEW--!!!
			~playTrig = true;
			//~lastPlayPhasePos.postln; //for debugging...

			//~pShift = Synth.after(~playBuf, \pitchShifter,
				//[\inBus, ~playOut1Bus, \outBus, ~pitchShiftOut, \pitchRatio, ~pitchBus.asMap]);
			~pShift = Synth(\pitchShifter,
				[\inBus, ~playOut1Bus, \outBus, ~pitchShiftOut, \pitchRatio, ~pitchBus.asMap]);
			~pShift.moveAfter(~playBuf);

			~pShiftMix = Synth(\XFade, [
			\in1, ~playOut1Bus,
			\in2, ~pitchShiftOut,
			\out, ~outMainBus,
			\amountControlBus, ~pitchShiftMixValBus.asMap,
			\amp, ~inputStreamLevelBus.asMap //<--NEW
			] );
			~pShiftMix.moveAfter(~pShift);

			~mainOut = Synth.tail(s, \mainOut, [\in, ~outMainBus, \loCutoff, ~loCutBus_out.asMap, \amp, ~outMainLevelBus.asMap]);
		} ,
		{
			//"-PlayBackOff-".postln;
			("playb4Get=" + ~lastPlayPhasePos).postln;
			~phaseBusMonPly.get( {arg val; ~lastPlayPhasePos = val; ("playInGet=" + val).postln;} );
			("playAfterGet=" + ~lastPlayPhasePos).postln;
			~playPhase.free;
			~a2k.free;
			~playBuf.free;
			//~sliderPlayPos.value_(0.0);

			~pShift.free;
			~pShiftMix.free;
			~mainOut.free;
		} );
} );
~sliderPlayPos = Slider(w, Rect(15, 237, 470, 20))
.background_(Color(0, 0.8, 0.2))
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, 0, ~buffer.numFrames - 1).round(1); //convert slider value to frame
	~playPhase.set (  //is set the correct method??? //update ~playPhase phasor synth position....
		\resetPos, pos,
		\trig, 1
	);
	~numBoxPlayPos.value = (pos/s.sampleRate).round(0.01); //convert frames to seconds and display
	//~numBoxPlayPos.value_(pos/s.sampleRate).round(0.1); //convert frames to seconds and display
} )
.value_(0.0);

~numBoxPlayPos = NumberBox(w, Rect(490, 234, 75, 25))
.value_(0)
.clipLo_(0)
//.clipHi_(~buffer.numFrames-1)
.font_(Font("Monaco", 14) )
.decimals_(2);

~labelPlayPos = StaticText(w, Rect(568, 207, 100, 80) )
.string_("PlayPos(sec)")
.font_(Font("Monaco", 10) )
.align_(\left);


AppClock.sched(0.0, { //AppClock scheduler increments slider positions...<<!!!!!!!!!!!!!!=======?????????????????????
	//THIS DOUBLE APPCLOCK ENCAPS IS NECESSARY FOR SOME REASON (otherwise errors thrown)
	~phaseBusMonPly.get( {
		arg val;
		AppClock.sched(0.0, { //<--1111111BBBBBB??????????????????
			//(val / (s.sampleRate * ~bufferSize)).postln; //uncomment to view sliderPlayPos from 0-1 (debugging)
			~sliderPlayPos.value = val / (s.sampleRate * ~bufferSize); //update slider position
			~numBoxPlayPos.value = (val.round(1)/s.sampleRate).round(0.1); //convert frames to seconds and display
			nil;
		} );
	} );

	~phaseBusMonRec.get( {
		arg val;
		AppClock.sched(0.0, { //<--errors thrown w/out this but still functions properly for some reason...why?
			//(val / (s.sampleRate * ~bufferSize)).postln; //uncomment to view sliderPlayPos from 0-1
			~sliderRecPos.value = val / (s.sampleRate * ~bufferSize); //update slider position
			~numBoxRecPos.value = (val.round(1)/s.sampleRate).round(0.01) ; //convert frames to seconds and display

			/* PLOTTER UPDATE CODE IN PROGRESS.........<<<<<<<<<<<<!!!!!!!!!!#########!!!!!!!!!!###########!!!!!!!!

			//~buffer.getToFloatArray(wait:0.01, action: {arg array; a = array; ~bufPlot.value = a; ~bufPlot.refresh;} );
			if (~buttonBuf.value == 1, {
				//var bufCurrent;
				AppClock.sched(0.0, {
					~buffer.get(val, {
						|bufVal|
						~bufPlot.value = (0..(~buffer.numFrames - 1)).normalize(0, rrand(2,50)).sin;
						//~bufPlot.value = bufVal.(0..(~buffer.numFrames - 1)).normalize;
						~bufPlot.refresh;
					} ); //<----------??????
					nil;
				} );
			} );
			//~bufPlot.value = ~buffer.read;
			//~bufPlot.refresh;
			*/
			//<<<<<<<<<<<<!!!!!!!!!!#########!!!!!!!!!!###########!!!!!!!!

			nil;
		} );
	} );

	if (~buttonPlay.value == 1, { //I think this intermittently buggy, but not able to reliably reproduce.....consider moving to SystemClock????
		if (~playTrig == true,
			{
				~playPhase.set(\trig, 1); //trigger to move phasor pos
				~playTrig = false;
			} ,
			{ //else
				~playPhase.get(\trig, { |trigval| if (trigval > 0) {~playPhase.set(\trig, 0) ;} } ); //reset trigger val to 0 if prev triggered
			}
		);
	} );

	if (~buttonRec.value == 1, { //I think this intermittently buggy, but not able to reliably reproduce.....
		if (~recTrig == true,
			{
				~recPhase.set(\trig, 1); //trigger to move phasor pos
				~recTrig = false;
			} ,
			{ //else
				~recPhase.get(\trig, { |trigval| if (trigval > 0) {~recPhase.set(\trig, 0) ;} } ); //reset trigger val to 0 if prev triggered
			}
		);
	} );

	/*~rateBus.get( {
		arg val;
		AppClock.sched(0.0, {
			if (val != 1, {
				//calculate distance between rec and play heads and delay time
			});
		} );
	} );*/

	//d = ~sliderRecPos.value - ~sliderPlayPos.value; //to check jitter distance between playheads (fairly consistent)
	//d.postln;
	0.1;
});

/*AppClock.sched(0.5, { //test to monitor phasor value
	~phaseBusMonPly.get( {
		arg val;
		val.postln;
	} );
	//~phaseBusMonPly.value.postln; //just posts info about bus, not its current stored value...
	0.5;
} );
*/


/////OTHER PLAYBACK PARAMETER CONTROLS/////
~sliderRecInOut = RangeSlider(w, Rect(15, 187, 470, 20)) //SLIDER => Play In/Out
.lo_(0.0)
.hi_(1.0)
//.background_(Color(0.0, 0.5, 0.2))
.action_({
	|slider|

	var recIn, recOut;

	recIn = slider.lo.round(0.0001).linlin(0, 1.0, 0, ~buffer.numFrames - 1).round(1);
	("recIn=" + recIn).postln;
	recOut = slider.hi.round(0.0001).linlin(0, 1.0, 0, ~buffer.numFrames - 1).round(1);
	("recOut=" + recOut).postln;

	~recInPosBus.set(recIn);
	~currentRecInFrame = recIn;
	("RecInFrame=" + ~currentRecInFrame).postln;
	~recOutPosBus.set(recOut);
	~currentRecOutFrame = recOut;
	("RecOutFrame=" + ~currentRecOutFrame).postln;

	//~numBoxPlayIn.value_((playIn * ~bufferSize).round(0.1));
	~numBoxRecIn.value_( (recIn / s.sampleRate).round(0.01) ); //
	//~numBoxPlayIn.value_( (slider.lo.round(0.0001) * ~bufferSize).round(0.1)  );

	//~numBoxPlayOut.value_((playOut * ~bufferSize).round(0.1));
	~numBoxRecOut.value_( (recOut / s.sampleRate).round(0.01) );
} );

~numBoxRecIn = NumberBox(w, Rect(490, 187, 46, 20))
.value_(0.0)
.clipLo_(0.0)
//.clipHi_(~bufferSize)
.clipHi_(~numBoxBuf.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2);
/*
.action_( {
	arg obj;
	~sliderPlayInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} ); */

~numBoxRecOut = NumberBox(w, Rect(535, 187, 46, 20))
.value_(~bufferSize)
.clipLo_(0.0)
//.clipHi_(~bufferSize)
.clipHi_(~numBoxBuf.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2);
/*
.action_( {
	arg obj;
	~sliderPlayInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} )*/

~labelRecInOut = StaticText(w, Rect(582, 189, 90, 20) )
.string_("In/Out-Rec")
.font_(Font("Monaco", 10) )
.align_(\left);

~sliderPlayInOut = RangeSlider(w, Rect(15, 259, 470, 20)) //SLIDER => Play In/Out
.lo_(0.0)
.hi_(1.0)
//.background_(Color(0.0, 0.5, 0.2))
.action_({
	|slider|

	var playIn, playOut;

	//playIn = slider.lo.round(0.0001);
	playIn = slider.lo.round(0.0001).linlin(0, 1.0, 0, ~buffer.numFrames - 1).round(1);
	("playIn=" + playIn).postln;
	//playOut = slider.hi.round(0.0001);
	playOut = slider.hi.round(0.0001).linlin(0, 1.0, 0, ~buffer.numFrames - 1).round(1);
	("playOut=" + playOut).postln;

	~playInPosBus.set(playIn);
	//~currentPlayInFrame = playIn.linlin(0, 1.0, 0, ~buffer.numFrames - 1).round(1);
	~currentPlayInFrame = playIn;
	("currentInFrame=" + ~currentPlayInFrame).postln;
	~playOutPosBus.set(playOut);
	//~currentPlayOutFrame = playOut.linlin(0, 1.0, 0, ~buffer.numFrames - 1).round(1);
	~currentPlayOutFrame = playOut;
	("currentOutFrame=" + ~currentPlayOutFrame).postln;

	//~numBoxPlayIn.value_((playIn * ~bufferSize).round(0.1));
	~numBoxPlayIn.value_( (playIn / s.sampleRate).round(0.01) ); //
	//~numBoxPlayIn.value_( (slider.lo.round(0.0001) * ~bufferSize).round(0.1)  );

	//~numBoxPlayOut.value_((playOut * ~bufferSize).round(0.1));
	~numBoxPlayOut.value_( (playOut / s.sampleRate).round(0.01) );
} );

~labelPlayInOut = StaticText(w, Rect(584, 259, 90, 20) )
.string_("In/Out-Play")
.font_(Font("Monaco", 10) )
.align_(\left);

~numBoxPlayIn = NumberBox(w, Rect(490, 260, 46, 20))
.value_(0.0)
.clipLo_(0.0)
//.clipHi_(~bufferSize)
.clipHi_(~numBoxBuf.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2);
/*
.action_( {
	arg obj;
	~sliderPlayInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} ); */

~numBoxPlayOut = NumberBox(w, Rect(535, 260, 46, 20))
.value_(~bufferSize)
.clipLo_(0.0)
//.clipHi_(~bufferSize)
.clipHi_(~numBoxBuf.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2)
/*
.action_( {
	arg obj;
	~sliderPlayInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} )*/;


//RATE

~sliderRate = Slider(w, Rect(15, 280, 470, 20))
.background_(Color(0.0, 0.5, 0.9))
.value_(0.5)
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, -48, 48).round(0.01); //used to be round(1)
	if (~buttonRev.value == 1,
		{~rateBus.set(pos.midiratio * -1);}, //negative rate when REV button enabled
		{~rateBus.set(pos.midiratio); //positive rate when REV button disabled
	} );
	 //change playback pitch!
	~numBoxRate.value_(pos); //update numBoxPitch value
} ) ;

~numBoxRate = NumberBox(w, Rect(490, 280, 48, 20))
.value_(0)
.clipLo_(-48)
.clipHi_(48)
.font_(Font("Monaco", 12) )
.decimals_(2)
.scroll_step_(0.01)
.step_(0.01)
.action_( {
	arg obj;
	var semiToneVal, pos;
	semiToneVal = obj.value.clip(-48, 48).round(0.01);
	~rateBus.set(semiToneVal.midiratio); //change playback rate (in semi tones)
	pos = obj.value.clip(-48, 48).linlin(-48, 48, 0, 1).round(0.001);
	~sliderRate.value_(pos);
} );

~labelRate = StaticText(w, Rect(541, 270, 135, 40) )
.string_("Rate(semi)")
.font_(Font("Monaco", 12) )
.align_(\left);


//PITCH
~sliderPitch = Slider(w, Rect(15, 301, 470, 20))
.background_(Color(0.0, 0.7, 0.9))
.value_(0.linlin(-48, 24, 0.0, 1.0))
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, -48, 24).round(0.01);
	~pitchBus.set(pos.midiratio);
	~numBoxPitch.value_(pos);
} );

~numBoxPitch = NumberBox(w, Rect(490, 301, 48, 20))
.value_(0)
.clipLo_(-48)
.clipHi_(24)
.font_(Font("Monaco", 12) )
.decimals_(2)
.scroll_step_(0.01)
.step_(0.01)
.action_( {
	arg obj;
	var semiToneVal, pos;
	semiToneVal = obj.value.clip(-48, 24).round(0.01);
	~pitchBus.set(semiToneVal.midiratio); //change pitch (in semi tones)
	pos = obj.value.linlin(-48, 24, 0, 1).round(0.001);
	~sliderPitch.value_(pos);
} );

~labelPitch = StaticText(w, Rect(541, 290, 135, 40) )
.string_("Pitch(semi)")
.font_(Font("Monaco", 12) )
.align_(\left);

~sliderPitchShiftMix = Slider(w, Rect(350, 322, 135, 15))
.background_(Color(0.0, 0.6, 0.8, 0.2))
.value_(0.0)
.action_( {
	arg obj;
	var mixAmount;
	mixAmount = obj.value.round(0.001);
	~pitchShiftMixValBus.set(mixAmount);
	//("sliderVal2PBus=" + mixAmount).postln;
	mixAmount = mixAmount.round(0.01);
	~numBoxPitchMix.value_(mixAmount * 100);
} );

~numBoxPitchMix = NumberBox(w, Rect(490, 322, 48, 20))
.value_(0)
.clipLo_(0)
.clipHi_(100)
.font_(Font("Monaco", 12) )
.decimals_(0)
.scroll_step_(1)
.step_(1)
.action_( {
	arg obj;
	var mixVal, pos;
	mixVal = obj.value.clip(0, 100).round(1);
	("mixValIn=" + mixVal).post;
	mixVal = mixVal/100;
	(" | mixValToPbus=" + mixVal).postln;
	~pitchShiftMixValBus.set(mixVal); //change pitch (in semi tones)
	~sliderPitchShiftMix.value_(mixVal);
} );

~labelPitchMix = StaticText(w, Rect(541, 326, 135, 10) )
.string_("PitchShiftMix")
.font_(Font("Monaco", 12) )
.align_(\left);

)