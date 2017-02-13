//Sonic Mirror - 00_Main:

//== Main Performance Doc ==

//~writeSampFromBuf.(~audioBuf0, (~playInFrame/s.sampleRate), (~playOutFrame/s.sampleRate));
//~writeSampFromBuf.(~audioBuf0, 58, 8.37);

//~audifyRout = ~audifyScene1.(~fileAudio_writeIn_lastPath, ampBus: ~fileOutputLevelBus, outBus: ~outMainBus, fileNum: 14, cycle: 2, rate: 48, pitch: -48);
//SystemClock.play(~audifyRout);
//~audifyRout.stop;
//~audifyRout.reset;

//---- refactor in progress ----

~dir = "/home/pi/Desktop/dev/";

(~dir ++ "01_Startup.scd").load;           // Server Options and Startup
(~dir ++ "02_SynthDefs.scd").load;       // SynthDefs
(~dir ++ "03_Busses.scd").load;            // Busses
(~dir ++ "04_Functions.scd").load;        // Functions and Routines

s.quit;  //convenience method (for cleanup)
s.plotTree; //for debugging
Buffer.freeAll; //for cleanup

( //INITIALIZE - Env Variables, Set Busses, Routine Defs, Func Defs?, GUI - #3 ============================

////GLOBAL VARIABLES
~sampBitDepth = "int16"; //alt = "int16"  (specify bit depth for all samples recorded by SM)

~audioBuf0_dur = 60.0;
~audioBuf0 = Buffer.alloc(s, s.sampleRate * ~audioBuf0_dur, 1);

~delayTime = 1.23;
~play2recOffset; //displacement of playhead pos from rec pos (in frames/samples)

~lastPlayPhasePos = 0; //for resume functionality - stores last pos (frame) of play head before playback disabled
~lastRecPhasePos = 0; //for resume functionality - stores last pos (frame) of rec head before recording disabled
~playPosLatchTrig = false;
~recPosLatchTrig = false;
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

~reverseFlag = false; //currentlly using ~button_rev.value as flag, but is that a good long-term idea????
~randPlayPos_flag = false;

~time2NextRandom_rate = 0;
~time2NextRandom_freq = 0;
~time2NextRandom_pitchShiftMix = 0;

~pitchShiftMix_prev;
~pitchShiftMix_target; //<- not using right now, might not need unless interpolating
~pitchShiftMix_prevChangeTime = 0;
~pitchShiftMix_interp = false;

~playInFrame = 0;  //<--- consider renaming
~playOutFrame = ~audioBuf0_dur * s.sampleRate - 1; //~audioBuf0.numFrames - 1; (won't work unless ~audioBuf0's already been allocated...)

~recInFrame = 0;
~recOutFrame = ~audioBuf0_dur * s.sampleRate - 1;
//---------

//(RESET BUS VALUES FOR INITIALIZATION OF SKETCH)
~playInPosBus.set(0);
~playOutPosBus.set(~playOutFrame);
~recInPosBus.set(0);
~recOutPosBus.set(~recOutFrame);

~rateBus.set(1);
~pitchBus.set(1);
~pitchShiftMixValBus.set(0); //<---

~revRateBusMon.set(1); //<---

~inputLevelBus.set(1);
~play1LevelBus.set(1); //<--NO SLIDER CREATED YET!!!!!....
~inputStreamLevelBus.set(1);
~fileOutputLevelBus.set(1);

~outMainLevelBus.set(1);

~phaseBusMonPly.set(0);
~phaseBusMonRec.set(0);


~loCutVal_in = 90;
~loCutVal_out = 90;
~loCutBus_in.set(~loCutVal_in);
~loCutBus_out.set(~loCutVal_out);
//-----------------

// --------- SET UP SOME INITIAL SYNTHS? ------------
~mainOut = Synth.tail(s, \mainOut, [\in, ~outMainBus, \loCutoff, ~loCutBus_out.asMap, \amp, ~outMainLevelBus.asMap]);
//Synth(\pitchShift1)???

//-------------------

////
Window.closeAll;
//w = Window.new("SonicMirror", Rect.new(250, 330, 780, 405))
w = Window.new("SonicMirror", Rect.new(100, 330, 792, 380), resizable: false)
.front
.alwaysOnTop_(true);

w.onClose_{s.freeAll; Buffer.freeAll(s); CmdPeriod.clearClocks; CmdPeriod.run;}; // clean up when window is closed

~view_main = CompositeView(w, Rect(3, 3, 788, 380));
~view_MainLevels = CompositeView(~view_main, Rect(625, 26, 75, 147));
~view_altLevels = CompositeView(~view_main, Rect(693, 26, 68, 105));
~view_bufConfig = CompositeView(~view_main, Rect(625, 0, 160, 25));
~view_bufPlot = CompositeView(~view_main, Rect(0, 0, 620, 170)).background_(Color.gray).resize_(1);
~view_transport = CompositeView(~view_main, Rect(0, 172, 788, 95));
~view_perfButtons = CompositeView(~view_main, Rect(5, 268, 308, 52));
~view_sampButtons = CompositeView(~view_main, Rect(5, 320, 250, 45));
~view_procControls1 = CompositeView(~view_main, Rect(317, 268, 460, 65));


//------ Main In/Out Controls (Levels & Lo-Cut) -----------

//Main Input Level --
~slider_inMainLevel = Slider(~view_MainLevels, Rect(8, 2, 15, 90) )
.background_(Color(0.9, 0.0, 0.0, 0.2))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~inputLevelBus.set(val);
	//~bufRecorder.set(\mul, val);
	~numBox_inMainLevel.value_(val);
	//~bufRecorder.get(\mul, {arg mulval; mulval.postln;} );
	//~inputLevelBus.get({arg val; val.postln;} );
} );

~numBox_inMainLevel = NumberBox(~view_MainLevels, Rect(2, 92, 26, 15))
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
	~slider_inMainLevel.value_(val);
} );

~label_inMainLevel = StaticText(~view_MainLevels, Rect(8, 103, 12, 20) )
.string_("IN")
.font_(Font("Monaco", 10) )
.align_(\center);

//Main Out Level --
//~slider_outMainLevel = Slider(w, Rect(733, 8, 17, 173) )
~slider_outMainLevel = Slider(~view_MainLevels, Rect(40, 2, 15, 90) )
.background_(Color(0.0, 0.8, 0.2, 0.01))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~outMainLevelBus.set(val);
	~numBox_outMainLevel.value_(val);
} );

~numBox_outMainLevel = NumberBox(~view_MainLevels, Rect(34, 92, 26, 15))
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
	~slider_outMainLevel.value_(val);
} );

~label_outMainLevel = StaticText(~view_MainLevels, Rect(37, 103, 20, 20) )
.string_("OUT")
.font_(Font("Monaco", 10) )
.align_(\center);

//Main In / Out Lo-Cuts --
~numBox_inMainLoCut = NumberBox(~view_MainLevels, Rect(2, 120, 30, 14))//<---
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

~numBox_outMainLoCut= NumberBox(~view_MainLevels, Rect(32, 120, 30, 14))//<---
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

~label_inoutMainLoCut = StaticText(~view_MainLevels, Rect(8, 130, 48, 20) )//<---
.string_("LoCut-Hz")
.font_(Font("Monaco", 10) )
.align_(\left);
//------------

//----- AUDIO BUFFER --------

~button_audioBuf_0 = Button(~view_bufConfig, Rect(0, 0, 65, 25)) //Activate / Deactivate audio buffer
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
			~audioBuf0 = Buffer.alloc(s, s.sampleRate * ~audioBuf0_dur, 1);
		} , //else
		{~audioBuf0.close; ~audioBuf0.free;} //free(erase) buffer
	);
} );

~numBox_audioBuf0_dur = NumberBox(~view_bufConfig, Rect(67, 0, 65, 25))
.value_(~audioBuf0_dur)
.clipLo_(10) //smallest possible length of buffer (in seconds)
.clipHi_(120) //longest possible length of buffer (in seconds)
.font_(Font("Monaco", 14) )
.decimals_(2)
.action_( {
	arg obj;
	~audioBuf0_dur = obj.value.round(0.01);
	("***Buffer Length=" + ~audioBuf0_dur + "seconds.").postln;
} );

~label_audioBuf0_dur = StaticText(~view_bufConfig, Rect(134, 2, 200, 20) )
.string_("DUR
(sec)")
.font_(Font("Monaco", 8) )
.align_(\left);

//--------------------------------

//--------- Soundfile Rec / Playback ---------------

//--put these variables back w/ the rest of env variables at some point??--

~playBehavior = 0; //stores state of playback behavior, not currently being used....

~currentSound = "silence"; //state of current heard sound (0 = silence, 1 = unpitched sound, 2 = pitched sound...?)
~currentScene = "quiet"; //sound scene index (0 = quiet, 1 = sparse transient sounds, 2 = drone, 3 = noise.........?)

~playSamp = false; //<--- flag:  playing audio file from disk

~fileAudio_writeOut_nameNum = 0; //counter for writing/reading audio file names
~fileAudio_writeOut_lastPath = "/home/pi/Desktop/SMaudio/SM_"; //stores string of file path for last written audio file from disk
~fileAudio_writeIn_nameNum = 0; //counter for writing/reading audio file name
~fileAudio_writeIn_lastPath = "/home/pi/Desktop/SMaudio/SM_"; //stores string of file path for last written audio file
~fileAudio_writeIn_lastFile = (~fileAudio_writeIn_lastPath ++ ~fileAudio_writeIn_nameNum ++ ".wav").standardizePath;

~fileAudio_writeIn_lastFileDur; //<--------NEW (not currently being used)

~fileAudio_lastPlay; //<---NEW (not needed if using below array though)

~fileHistory_rec = Array.newClear(5); //history of last 5 samples recorded <--NEW
~fileHistory_play = Array.newClear(5); //history of last 5 samples played back <--NEW

~soundMemory = []; //<-------NEW (init)
//~soundMemory = [["sound1Name", sound1timeIn, sound1timeOut, sound1dur, sus / transient, mean loudness, pitchiness, mean pitch], ["sound2Name", sound2timeIn, sound2timeOut, ....], ["sound3Name", ...], ["soundMaxNumName", ...]];

~minNumFilesB4Playback = 1; // file # threshold before file playback routine commences
~fileAudio_writeIn_maxNum = 30; //max # of audio samples written per session (wrap-around & overwrite limit - inclusive of 0)
~fileAudio_writeOut_maxNum = 30;  //max # of audio out samples written per session (wrap-around & overwrite limit)

//---
~listenDur_noiseFloor = 5.0; //<---not currently being used....
/*~senseNoiseFloor = Routine.new( {
	//sets ~loudnessThresh
} );  */

~loudnessThresh = 5; //set w/ ~senseNoiseFloor eventually?
~pitchThresh = 0.55;

//~hearFeedback = false;
//~fdbackDetect = false;
~input_loud = 0; //consider integer scale: 0 = < min thresh | 1 = > lowThresh, < uprThresh, 2 = > uprThres
~input_loudSus = false;
~listen_input_loudness = false; //flag indicating activity of loudness monitoring function (active / disabled)

~hearSound = false;
~listening = false;  //flag indicates audio analysis activity

~minRecDur = 1.0; //<-----min sec per recorded sample
~maxRecDur = 30.0; //<----max sec per recorded sample (shorten or don't use w/ autoRec_random)

~recSamp_input = false;
~recSamp_output = false;
~recSamp_input_startFrame = 0;
~recSamp_input_stopFrame = 0;

~autoRecPlay_state = 0; //0 == only trigger auto rec, 1 == only trigger auto play

~preRecDur = 0.2; //amount of time to sample from buffer prior to start of ~autoRec
~postRecSnip = -0.3; //amount of time to subtract from total dur of sampled sound (to cut silence at end of sample after ~autoRec finished and ~listenDur_intraSound pads end...)

~listenDur_intraSound = 0.8; //<----amount of time (sec) to continue listening for continuation of contiguous sound object between gaps of silence (e.g. seperation threshold for dividing sound objects) ADJUSTING THIS PARAM INCREASES / DECREASES AMOUNT OF SOUND SAMPLE FRAGMENTATION / SENSITIVITY TO DISCRETE TRANSIENT SOUND EVENTS.....
~listenDur_soundPatience = 10; // time to wait during autoRecMode b4 playing sample if no sound's heard

~time_listenTimeOut;  //time to wait until when testing for cessation of sound event
~time_recTimeOut; //maximum time to record until (to avoid runaway recordings and trolls)
~time_minRec;

~time_lastRec_start;
~time_lastRec_stop;
~time_lastPlay_start;
~time_lastPlay_stop;

~autoRec_rate = 0.1; //finest timing resolution of ~autoRec_soundTrig routine (NOT BEING USED)
//~yieldTime_autoRec = 0.1;  //val to be reassigned as routine runs... (OLD APPROACH....ABANDONING THIS)

~autoRecStartTrig = true; //flag triggered when ~autoRec routines initiated (used for debounce time when triggered via button press to avoid false sound detection)


//AUTO REC / AUTO PLAY ROUTINES ----------

~autoPlay_soundTrigAuto = Routine({
	if (~playSamp == true,
		{ //if already playing sound file, we can assume it's completed by the time this routine has stopped yielding based on commands when ~playSamp == false (see below code in 'else' of this conditional)...
			~playSamp = false;
			~time_lastPlay_stop = Main.elapsedTime.round(0.001); //log sample playback stop time
			//~audioBuf_play0.close; //not needed? didn't fix bug....
			~audioBuf_play0.free;
			{~button_playSamp.value = 0;}.defer; //update GUI button
			~autoRecPlay_state = 0; // (cycle state to trigger ~autoRec before next ~autoPlay)
			0.1.yieldAndReset;
		},
		{//if not playing a soundFile or autoRecording...
			//if (((~recSamp_input == false) && (~fileAudio_writeIn_nameNum >= ~minNumFilesB4Playback) && (~autoRecPlay_state == 1)), //second condition ~minNumFilesB4Playback kills playback after filename wraparound
			if (((~recSamp_input == false) && (~autoRecPlay_state == 1)), //only play back sounds if not recording...
				{
					//PLAYBACK AUDIO FILE FROM DISK
					var interpSynth, fileDir, file, duration, temp, /*rate, pitch, mix,*/ currentTime;

					//<---***CONDITION CHECKING TRIGGERING SAMPLE PLAYBACK GOES HERE****----
					//---e.g. routines checking machine listening ugen output control busses...

					~playSamp = true; //set flag
					//pitch = 1; //<--
					//mix = 0; //<--

					/*
					//<--- this chunk no longer necessary???
					if (~bufPlayer.isRunning, { //if playing buffer audio, silence it for audio sample playback
					//get current signal flow/chain level val from ~inputStreamLevelBus and assign to local variable used for \startVal arg in interpSynth below...
					interpSynth = Synth(\LinInterp_num, [\startVal, 1.0, \stopVal, 0.0, \duration, 0.2, \out, ~inputStreamLevelBus]); //silence input stream in 0.2 sec (***startVal should probs = variable storing current value of inputStreamLevel***
					{~slider_inFlow1_level.value = 0;}.defer;  //update GUI
					{~numBox_inFlow1_level.value = 0;}.defer; //update GUI
					("~bufPlayer.isRunning - 0.2.yield").postln;
					0.2.yield;
					});
					*/
					//("--after checking ~bufPlayer.isRunning").postln;

					//vvvvvv ---- make this into a reusable function for audio file playback ---- vvvvvv

					//---------------!!!!!!!
					//>-----FILE SELECTION CONDITIONS GO HERE-----<<<<<<------------DO
					// IF IT'S BEEN AWHILE since last recorded sound OR if have played back previous sample already, be more likely to play a random sample or second to last sample or older samples <--------- DO THIS ---<<<<<!!!

					/*
					currentTime = Main.elapsedTime.round(0.001); //<----IN PROGRESS
					if (currentTime <= (~time_lastRec_stop + 5),
						{//if just recorded new sound, play last recorded sound
							fileDir = ~fileAudio_writeIn_lastFile;
						},
						{//else if it's been awhile since last recorded sound
							if (~fileHistory_play[0] != ~fileHistory_play[1], //if last played sound isn't the same as previously played sound
								{
									if (0.85.coin == true,
										{fileDir = ~fileAudio_writeIn_lastFile;}, //~85% select last recorded file for playback
										{fileDir = ~fileHistory_play[1];}//else select second to last played file
									);
									if (fileDir == nil, {fileDir = ~fileAudio_writeIn_lastFile;}); //safe driving
								}
							);

							if (~fileHistory_play[0] == ~fileHistory_play[1], //if played same sound twice
								{

									if ((~fileHistory_play[2] != nil) && (~fileHistory_play[2] != ~fileHistory_play[0]),
										{fileDir = ~fileHistory_play[2];}
									);
								}
							);
						}
					); //<---IN PROGRESS - END
					*/

					fileDir = ~fileAudio_writeIn_lastFile; //orig

					//file = SoundFile.new(fileDir); //<--- new
					//file.openRead; //<--- new
					//0.5.yield;  //<----testing for RPI, might help? not sure....
					//duration = file.duration; //<--- new, BUT this DOESN'T have different effect b/c being changed inside action function....

					//PLAY SOUND FILE from disk
					~audioBuf_play0 = Buffer.read(s, fileDir, action: {arg buffer;
						var rand, procSelect;
						//duration = buffer.numFrames/s.sampleRate;
						duration = buffer.numFrames/buffer.sampleRate; //<--orig

						//EVENTUALLY consider selecting proc behaviors based on features of analyzed audio <<<<
						rand = rrand(1.0, 10.0).round(0.1);

						procSelect = case
						//{rand <= 10} {
						{rand <= 6.5} {
							"==randAudify==".postln;
							duration = ~sample_randAudify.value(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus, outBus: ~outMainBus); //<---THIS
						}
						{rand > 8.7} {
						//{rand == 11} {
							"==NOIZ MANGLE==".postln;
							duration = ~sample_noiseMangle.value(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus, outBus: ~outMainBus); //<---THIS
						}
						{rand > 6.5 && rand <= 8.7} {
						//{rand == 12} {
							var lfoFreq, loFreq, hiFreq;
							"==SINE MODs==".postln;
							lfoFreq = rrand(0.1, 1.0).round(0.01);
							loFreq = rrand(0.05, 0.3).round(0.01);
							hiFreq = rrand(0.1, 0.7).round(0.01);

							if (0.5.coin == true,
								{
									("---SineSine: lfoFreq =" + lfoFreq + "| loFreq =" + loFreq + "| hiFreq =" + hiFreq).postln;
									//~samp0 = Synth(\bufRead_sineSineMod, [\buf, buffer, \duration, duration, \lfoFreq, 0.5, \loFreq, 0.1, \hiFreq, 0.5, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]);
									~samp0 = Synth(\bufRead_sineSineMod, [\buf, buffer, \duration, duration, \lfoFreq, lfoFreq, \loFreq, loFreq, \hiFreq, hiFreq, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]);
								},
								{
									("---NoiseSine: lfoFreq =" + lfoFreq + "| loFreq =" + loFreq + "| hiFreq =" + hiFreq).postln;
									//~samp0 = Synth(\bufRead_noiseSineMod, [\buf, buffer, \duration, duration, \lfoFreq, 0.5, \loFreq, 0.1, \hiFreq, 0.5, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]);
									~samp0 = Synth(\bufRead_noiseSineMod, [\buf, buffer, \duration, duration, \lfoFreq, lfoFreq, \loFreq, loFreq, \hiFreq, hiFreq, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]);
								}
							);
						};

						//NodeWatcher.register(~samp0);
						~time_lastPlay_start = Main.elapsedTime.round(0.001); //log sample play start time
						("PLAYING BACK FILE:" + fileDir).postln;

						~fileAudio_lastPlay = fileDir; //<---NEW - to keep track of last played sample (not needed if using below array for playback memory)

						temp = ~fileHistory_play.shift(1, fileDir); //<---NEW - longer-term playback memory
						~fileHistory_play = temp; //<---NEW - longer-term playback memory
					});

					{~button_playSamp.value = 1;}.defer; //update GUI
					("Pre-yield samp Dur = " ++ duration).postln;

					s.sync; //<------USING THIS INSTEAD OF YIELD, FIXES RPI ISSUE AND NO MORE NEED FOR YIELD!!
					//0.2.yield;  //<---UNFORTUNATE YIELD needed to update duration variable (probs doesn't need to be that long, thought short yield times was causing a "Buffer UGen: buffer data" error - INCREASE FOR RPI<-----<<<
					("Post-yield samp Dur = " ++ duration).postln;

					//duration.yieldAndReset; //<---might not be necessary to add 0.02 sec, experiment
					(duration + 0.02).round(0.01).yieldAndReset; //<--maybe not necessary to add more time
					//---------- ^^^^^^^^^^^^^^^^^^^ ---------------------------
				},
				{0.25.yieldAndReset;} //else if (~recSoundInput == true)
			);
		}
	);
});

~autoRec_soundTrigAuto =  {|featureBus, rate = 0.1, debounceDur = 0.5|
	Routine( {
		if (~recSamp_input == true,
			{
				// add if (~listening == true, {  }); <---yes or no?
				var currentTime = Main.elapsedTime.round(0.001);
				if (currentTime <= ~time_minRec,
					{
						("----------").postln;
						("RECORDING.....").postln;
						("currentTime:" + currentTime + "< ~time_minRec:" + ~time_minRec).postln;
					},
					{
						featureBus.get({|val| //get sum bus "lop" - 4 features: [Loudness, Onset, Freq, Pitch Measure]
							if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
								{//SOUND DETECTED
									~hearSound = true;
									//CONTINUE RECORDING / DO NOTHING....
									("-----=======-----").postln;
									("**Recording... SOUND DETECTED").postln;
									("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

									//anti-troll / runaway recording measure...
									if (currentTime >= ~time_recTimeOut, //terminate recording if we've exceeded recTimeOut
										{
											("===MAX RECORD DUR EXCEEDED - STOP RECORDING===" ).postln;
											~recSamp_input_stopFrame = ~lastRecPhasePos;
											~writeSampFromBufCopy_input.value(); //sets GUI and ~recSamp_input = false
											~time_lastRec_stop = currentTime; //<---
											~hearSound = false;
											~autoRecPlay_state = 1; //advance state to trigger ~autoPlay before next ~autoRec
										}
									);
								},
								{//IF NO SOUND DETECTED...
									if (~hearSound == false,
										{
											//var currentTime = Main.elapsedTime.round(0.001); //<---already got this above
											if (currentTime >= ~time_listenTimeOut, //<---
												{
													//Sound Stop Confirmed - WRITE AUDIO SAMPLE (sound was stopped since last iteration)
													("--------++++++++-------").postln;
													("**Recording... SOUND STOP CONFIRMED").postln;
													("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
													~writeSampFromBufCopy_input.value(); //sets GUI and ~recSamp_input = false

													~autoRecPlay_state = 1; //advance state to trigger ~autoPlay before next ~autoRec
													("~autoRecPlay_state = 1 | ~autoPlay ONLY").postln;
													("---.....---").postln;

													//Analyze written audio file for features (avg loudness, pitchiness, MFCCs, etc)
													//Add sound file's extracted feature summary to a ~soundMemory buffer for future analysis and behavior triggering based on past history of sound events...
												},
												{//if currentTime < ~time_listenTimeOut....sound may not have stopped yet....
													("----").postln;
													("**Testing for sound stop...** - Current Time:" + currentTime).postln;
													("---Terminate Test at:" + ~time_listenTimeOut).postln;
												}
											);
										},
										{//else if ~hearSound == true (test to make sure sound has stopped but continue recording)
											//~time_listenTimeOut = ~listenDur_intraSound + Main.elapsedTime.round(0.001);
											~time_listenTimeOut = ~listenDur_intraSound + currentTime; //<---
											("-------").postln;
											("**Recording...SOUND STOP? ... Testing until: " + ~time_listenTimeOut).postln;
											("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

											//GET recHead phasor position and log "STOP  SAMPLE TIME"
											~phaseBusMonRec.get({|val|
												~recSamp_input_stopFrame = (val - (~postRecSnip * s.sampleRate)).round(1);
												if (~recSamp_input_stopFrame < 0, { //if presumed stopFrame is negative...
													~recSamp_input_stopFrame = ~audioBuf0.numFrames + ~recSamp_input_stopFrame; //wrap around buffer and log sound stop frame
												} );
												("--Sound Stop (in get) = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;

												//~time_lastRec_stop = Main.elapsedTime.round(0.001); //<--- NEW - log sound rec stop time
												~time_lastRec_stop = currentTime; //<---
												~hearSound = false;
											});
										}
									);
								}
							);
						});
					}
				);
			} ,
			{//else if ~recSamp_input == false
				if (~listening == false,
					{
						"***Can't record, not listening...***".postln;
						1.yieldAndReset;
					},
					{//if ~listening == true...
						if (~playSamp == false && ~autoRecPlay_state == 0,  //<-------
							{ //don't enter autorecord mode if playing back samples and not in state 0...
								if(~autoRecStartTrig == true, {//DEBOUNCE when routine first launched (avoids false sound detection from mouse click)
										~hearSound = false; //<--- probs not necessary here....just debugging....
										~autoRecStartTrig = false;
										~bus_onsets.set(0);  //<----?
										("Debounce =" + debounceDur + "sec").postln;
										debounceDur.yield;
								});

								//GET SUM BUS
								featureBus.get({|val|  //<----- MOVE THIS TO ~listen_sound function?  < -----<--!!!!
									if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
										{//SOUND DETECTED
											("---").postln;
											("**HEAR SOUND**").postln;
											("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

											if (~hearSound == false, //TEST SOUND START...
												{
													~phaseBusMonRec.get({|val| //log recHead pos
														~recSamp_input_startFrame = (val - (~preRecDur * s.sampleRate)).round(1);
														if (~recSamp_input_startFrame < 0, { //if startFrame is negative...
															~recSamp_input_startFrame = ~audioBuf0.numFrames + ~recSamp_input_startFrame; //wrap around buffer and log sound start frame
														});
														("---------").postln;
														("--> Sound START?: " ++( ~recSamp_input_startFrame/s.sampleRate)).postln;
														~hearSound = true; //<--- moved inside get
													});
												},
												{//else ~hearSound == true
													var currentTime = Main.elapsedTime.round(0.001);
													~time_minRec = currentTime + ~minRecDur; //minimum time to stop recording

													~time_lastRec_start = currentTime - rate; //<---NEW - subtract rate b/c sound detected in previous cycle of routine
													~time_recTimeOut = ~time_lastRec_start + ~maxRecDur; //<--NEW - prevent runaway recordings and trolls

													("- - - - -").postln;
													("--> Sound START CONFIRMED:" + ( ~recSamp_input_startFrame/s.sampleRate)).postln;
													("--REC Sample Start").postln;
													~recSamp_input = true; //causes us to LEAVE THIS SIDE OF ROUTINE
													{~button_recIn.value = 1;}.defer;
												}
											);
										},
										{//if NO SOUND DETECTED ........
											("--- NO SOUND ---").postln;
											("Ldns-Onst-pitMsr = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
											if (~hearSound == true,
												{
													~hearSound = false;
													("--> ...false alarm?...").postln;
												},
												{ //else if ~hearSound == false
													("-->...silence...").postln;

													if (~fileHistory_play[0] != nil, {//if recorded & played @ least 1 sound
														var currentTime = Main.elapsedTime.round(0.001);
														if (currentTime >= (~time_lastPlay_stop + ~listenDur_soundPatience),
															{
																~autoRecPlay_state = 1;
																//adjust ~listenDur_soundPatience based on timespan since ~time_lastRec_stop; ? <--------CONSIDER DOING THIS ----------------<<<<<<<<<<
																~listenDur_soundPatience = rrand(6.0, 20.0); //temporary<---?
															}
														);
													});
												}
											);
										}
									);
								});
							},
							{ //else if (~playSamp == true)
								//("---Can't record when playSamp == true || autoRecPlay_state != 0").postln;
								0.25.yieldAndReset;
							}
						);
					}
				);
			}
		);
		rate.asFloat.yieldAndReset;
	} );
};

~autoRec_soundTrig1 =  {|featureBus, rate = 0.1, debounceDur = 0.5|
	Routine( {
		if (~recSamp_input == true,
			{
				// add if (~listening == true, {  }); <---yes or no?
				var currentTime = Main.elapsedTime.round(0.001);
				if (currentTime <= ~time_minRec,
					{
						("----------").postln;
						("RECORDING.....").postln;
						("currentTime:" + currentTime + "< ~time_minRec:" + ~time_minRec).postln;
					},
					{
						featureBus.get({|val| //get sum bus "lop" - 4 features: [Loudness, Onset, Freq, Pitch Measure]
							if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
								//if (( (val[0] >= ~loudnessThresh) || (val[3] >= ~pitchThresh) ),
								{//SOUND DETECTED
									~hearSound = true;
									//CONTINUE RECORDING / DO NOTHING....
									("-----=======-----").postln;
									("**Recording... SOUND DETECTED").postln;
									("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
								},
								{//IF NO SOUND DETECTED...
									if (~hearSound == false,
										{
											var currentTime = Main.elapsedTime.round(0.001);
											if (currentTime >= ~time_listenTimeOut,
												{
													//Sound Stop Confirmed - WRITE AUDIO SAMPLE (sound was stopped since last iteration)
													("--------++++++++-------").postln;
													("**Recording... SOUND STOP CONFIRMED").postln;
													("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

													~writeSampFromBufCopy_input.value(); //sets GUI and ~recSamp_input = false

													//Analyze written audio file for features (avg loudness, pitchiness, MFCCs, etc)
													//Add sound file's extracted feature summary to a ~soundMemory buffer for future analysis and behavior triggering based on past history of sound events...
												},
												{//if currentTime < ~time_listenTimeOut....sound may not have stopped yet....
													("----").postln;
													("**Testing for sound stop...** - Current Time:" + currentTime).postln;
													("---Terminate Test at:" + ~time_listenTimeOut).postln;
												}
											);
										},
										{//else if ~hearSound == true (test to make sure sound has stopped but continue recording)
											~time_listenTimeOut = ~listenDur_intraSound + Main.elapsedTime.round(0.001);
											("-------").postln;
											("**Recording...SOUND STOP? ... Testing until: " + ~time_listenTimeOut).postln;
											("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

											//GET recHead phasor position and log "STOP  SAMPLE TIME"
											~phaseBusMonRec.get({|val|
												~recSamp_input_stopFrame = (val - (~postRecSnip * s.sampleRate)).round(1);
												if (~recSamp_input_stopFrame < 0, { //if presumed stopFrame is negative...
													~recSamp_input_stopFrame = ~audioBuf0.numFrames + ~recSamp_input_stopFrame; //wrap around buffer and log sound stop frame
												} );
												("--Sound Stop (in get) = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;
												~hearSound = false;
											});
										}
									);
								}
							);
						});
					}
				);
			} ,
			{//else if ~recSamp_input == false
				if (~listening == false,
					{
						"***Can't record, not listening...***".postln;
						1.yieldAndReset;
					},
					{//if ~listening == true...
						if (~playSamp == false,
							{ //don't record if playing back samples...
								if(~autoRecStartTrig == true, {//DEBOUNCE when routine first launched (avoids false sound detection from mouse click)
										~hearSound = false; //<--- probs not necessary here....just debugging....
										~autoRecStartTrig = false;
										~bus_onsets.set(0);  //<----?
										("Debounce =" + debounceDur + "sec").postln;
										debounceDur.yield;
								});

								//GET SUM BUS
								featureBus.get({|val|
									if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
										{//SOUND DETECTED
											("---").postln;
											("**HEAR SOUND**").postln;
											("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

											if (~hearSound == false, //TEST SOUND START...
												{
													~phaseBusMonRec.get({|val| //log recHead pos
														~recSamp_input_startFrame = (val - (~preRecDur * s.sampleRate)).round(1);
														if (~recSamp_input_startFrame < 0, { //if startFrame is negative...
															~recSamp_input_startFrame = ~audioBuf0.numFrames + ~recSamp_input_startFrame; //wrap around buffer and log sound start frame
														});
														("---------").postln;
														("--> Sound START?: " ++( ~recSamp_input_startFrame/s.sampleRate)).postln;
														~hearSound = true; //<--- moved inside get
													});
												},
												{//else ~hearSound == true
													~time_minRec = Main.elapsedTime.round(0.001) + ~minRecDur; //minimum time stamp to stop recording
													("- - - - -").postln;
													("--> Sound START CONFIRMED:" + ( ~recSamp_input_startFrame/s.sampleRate)).postln;
													("--REC Sample Start").postln;
													~recSamp_input = true; //causes us to LEAVE THIS SIDE OF ROUTINE
													{~button_recIn.value = 1;}.defer;
												}
											);
										},
										{//if NO SOUND DETECTED ........
											("--- NO SOUND ---").postln;
											("Ldns-Onst-pitMsr = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
											if (~hearSound == true,
												{
													~hearSound = false;
													("--> ...false alarm?...").postln;
												},
												{ //else if ~hearSound == false
													("-->...silence...").postln;
												}
											);
										}
									);
								});
							},
							{ //else if (~playSamp == true)
								("---Can't record when playSamp == true").postln;
								1.yieldAndReset; //shorten to make more responsive after sample playback ends
							}
						);
					}
				);
			}
		);
		rate.asFloat.yieldAndReset;
	} );
};

/*s.plotTree;
~inputSendLoudSus
~listen_loudness.(1, ~inputSendBus, outBus: \bus_inputdb, featSynth: \rms1, loudFlag: \inputSendLoud, loudSusFlag: \inputSendLoudSus, post: 1);
~listen_loudness.(0, outBus: \bus_inputdb, featSynth: \rms1, loudFlag: \inputSendLoud, loudSusFlag: \inputSendLoudSus);
//~listen_loudness.(0, outBus: \bus_inputdb, featSynth: \rms1);
*/

//<-----------PICK UP HERE----------------><--------!!!!!!!!!!!!!!!!!---------<<<<<<<<<<<<<<<
//double check ~listen_loudness and ~monitor_loudness routine......

/*~listen_loudness = {|active = 1, input, outBus, featSynth, loudFlag, loudSusFlag, lowThresh = -6, lowThreshDur = 0.4, uprThresh = -4, rate = 0.1, post = 0, monRoutine| //<--IN PROGRESS....
	if (active == 1, {//start detecting feedback
		if (~bufRecorder.isRunning, {
			var thisOutBus;
			//RMS monitor
			outBus.envirPut(Bus.control(s, 1));
			thisOutBus = outBus.envirGet;
			featSynth.envirPut(Synth(\RMSdb, [\input, input, \outBus, thisOutBus]).moveAfter(~bufRecorder));
			NodeWatcher.register(featSynth.envirGet);
			//featSynth.envirPut(Synth(\RMSdb, [\input, input, \outBus, ~bus_rms]).moveAfter(~bufRecorder));
			//RMS > ~.47 || db > -6 == verging on clipping and feedback <-----

			//LOUDNESS monitor  input = ~inputSendBus
			//l = Synth(\Loudness, [\input, input, \outBus, ~bus_loudness]).moveAfter(~bufRecorder);

			//outBus.envirPut(~sumFunc_xin.([~bus_rms], sumSynth)); //assign bus and resulting summing synth to new env vars

			if (post == 1, { //only run this routine to monitor features w/ post window...
				~listenPost = ~streamFeatures.value(bus: thisOutBus, rate: rate, post: post);
				//~listenPost = ~streamFeatures.value(bus: ~bus_rms, rate: rate, post: post);
				SystemClock.play(~listenPost);
			});

			//~input_loud = 0; //maybe assign this via arg instead...DON'T HARDCODE!!! not necessary here, in else
			loudFlag.envirPut(0);
			//~input_loudSus = false; //maybe assign this via arg instead...DON'T HARDCODE!!! not necessary here, in else
			loudSusFlag.envirPut(false);
			//~listen_input_loudness = true; //maybe assign this via arg instead...DON'T HARDCODE!!!

			//START LOUDNESS/FEEDBACK MONITOR ROUTINE
			monRoutine.envirPut(~monitor_loudness.(input: thisOutBus, loudFlag: loudFlag, loudSusFlag: loudSusFlag, lowThresh: lowThresh, lowThreshDur: lowThreshDur, uprThresh: uprThresh, rate: rate)); //<----UNTESTED---!!!!

			"====FEEDBACK DETECTION ACTIVE====".postln;
		}, {
			"===CAN'T DETECT FEEDBACK UNLESS BUF RECORDER ACTIVE===".postln;
		} );
	}, {//if active == 0, stop feature extraction and clean up...
		//if (~fdbackDetect == true, { //only free synths and cleanup if we were detecting feedback in the first place, otherwise don't do anything and avoid server errors....
		if (~listenPost != nil, {~listenPost.stop; ~listenPost.free;}); //this cleanup only needed if post==1

		//STOP LOUDNESS/FEEDBACK MONITOR ROUTINE

		featSynth.envirGet.free; //free RMS feature extractor synth
		//sumSynth.envirGet.free;
		outBus.envirGet.free;

		loudFlag.envirPut(0);
		//~input_loud = 0; //maybe assign this via arg instead...DON'T HARDCODE!!!
		loudSusFlag.envirPut(false);
		//~input_loudSus = false; //maybe assign this via arg instead...DON'T HARDCODE!!!
		//~listen_input_loudness = false; //maybe assign this via arg instead...DON'T HARDCODE!!!

		"====FEEDBACK DETECTION DISABLED====".postln;
		//});
	} );
};

//IN PROGRESS <-------------
~monitor_loudness = {|input, loudFlag, loudSusFlag, lowThresh = -6, lowThreshDur = 0.4, uprThresh = -4, lastLowThreshTime, rate = 0.1|
	Routine({
		input.get({|val|
			switch (val,
				(val >= lowThresh && val < upThresh), {
					if (loudFlag.envirGet == 0,
						{
							loudFlag.envirPut(1);
							lastLowThreshTime.envirPut(Main.elapsedTime.round(0.001));
							("-->LOUD SOUND! (low thresh): input db =" + val + "|" + lastLowThreshTime + "=" + lastLowThreshTime.envirGet).postln;
						},
						{//else if loudFlag already == 1 (or higher...)
							if ((Main.elapsedTime.round(0.001) - lastLowThreshTime.envirGet) >= lowThreshDur, {
								loudSusFlag.envirPut(true);
								("-->LOUD SOUND SUS CONFIRMED! (low thresh): input db =" + val).postln;
							}, {
								("-->LOUD SOUND SUS TEST... (low thresh): input db =" + val).postln;
							});
						}
					);
				},
				(val >= upThresh), {
					loudFlag.envirPut(2);
					("-->VERY LOUD SOUND!!!: input db =" + val).postln;
				},
				(val < lowThresh), {
					if (loudFlag.envirGet > 0, {
						loudFlag.envirPut(0);
						loudSusFlag.envirPut(false);
						("-->LOUDNESS STOPPED: input db =" + val).postln;
					});
				}
			);
		});
		s.sync;
		rate.yieldAndReset;
	});
}; */

~listen_sound = { |active = 1, input, outBus, sumSynth, rate = 0.1, post = 0| //setup/shutdown feat extractors on a bus
	//|active = 1, input, rate = 0.1, post = 0| //orig args...
	if (active == 1, {//start feature extraction...
		if (~bufRecorder.isRunning, {
			//LOUDNESS monitor  input = ~inputSendBus
			l = Synth(\Loudness, [\input, input, \outBus, ~bus_loudness]).moveAfter(~bufRecorder);
			//PITCH tracker
			p = Synth(\Pitch, [\input, input, \outBus, ~bus_pitch, \ampThresh, 0.02, \clar, 1]).moveAfter(l);
			//ONSET detector
			n = Synth(\onsets, [\input, input, \outBus, ~bus_onsets, \threshold, 0.5, \trigtime, 0.25]).moveAfter(l);
			//etc....

			//fire off ~senseNoiseFloor routine....?

			outBus.envirPut(~sumFunc_xin.([~bus_loudness, ~bus_onsets, ~bus_pitch], sumSynth)); //assign bus and resulting summing synth to new env vars

			if (post == 1, { //only run this routine to monitor features w/ post window...
				//===THIS IS WHERE ~transmit feature via OSC routine from SCML could live if needed
				~listenPost = ~streamFeatures.value(bus: outBus.envirGet, rate: rate, post: post);
				SystemClock.play(~listenPost);
			});

			~hearSound = false;
			~listening = true;
			"====LISTENING NOW====".postln;
		}, {
			"===CAN'T LISTEN UNLESS BUF RECORDER ENABLED===".postln;
		} );
	}, {//if active == 0, stop feature extraction and clean up...
		if (~listening == true, { //only free synths and cleanup if we were listening in the first place, otherwise don't do anything and avoid server errors....
			if (~listenPost != nil, {~listenPost.stop; ~listenPost.free;}); //this cleanup only needed if post==1

			sumSynth.envirGet.free;
			outBus.envirGet.free;
			l.free;
			p.free;
			n.free;
			~listening = false;
			~hearSound = false;

			~bus_onsets.set(0); //reset value in case mouse click triggers onset detector at termination of routine
			//zero out loudness and other feature busses here too???

			"====STOPPED LISTENING====".postln;
		});
	} );
};

~button_autoRecPlay = Button(~view_perfButtons, Rect(113, 25, 25, 25))
//~view_perfButtons, Rect(94, 25, 25, 25)
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
			//~listen_sound.value(active: 1, input: ~inputSendBus, post: 0); //start listening
			~listen_sound.value(active: 1, input: ~inputSendBus, outBus: \busSum_lop, sumSynth: \sumSyn_1, post: 0); //start listening
			~autoRecStartTrig = true; //enables debounce when ~autoRecStart initialized

			~autoRecStart = ~autoRec_soundTrigAuto.value(featureBus: ~busSum_lop, rate: 0.1, debounceDur: 0.5);
			SystemClock.play(~autoRecStart);

			~autoPlay_soundTrigAuto.reset;
			SystemClock.play(~autoPlay_soundTrigAuto);

		},
		{
			~autoRecStart.stop;
			~autoRecStart.free;

			~autoPlay_soundTrigAuto.stop;

			if (~recSamp_input == true, { //pertains to ~autoRec_soundTrig1
				if (~hearSound == true, { //if actively "recording" sound, stop recording and write sample file
					~phaseBusMonRec.get({|val|
						~recSamp_input_stopFrame = val.round(1);
						("--Sound Stop at = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;
						~writeSampFromBufCopy_input.value(); //writes sample, sets ~recSamp = false, updates GUI
						~autoRecPlay_state = 0; //<----- NEW
					});
				});
			}, { //if ~recSamp_input == false
				~button_recIn.value = 0; //<---not needed?
				~autoRecPlay_state = 0; //<----- NEW
			});

			~listen_sound.(0, outBus: \busSum_lop, sumSynth: \sumSyn_1); //stop listening

			/*if (~recSamp_input == true, { //pertains to ~autoRec_random routine only...
				~writeIn2Disk.free;
				~audioBuf_inMainWrite.close;
				~audioBuf_inMainWrite.free;
				~fileAudio_writeIn_nameNum = ~fileAudio_writeIn_nameNum + 1;
				if (~fileAudio_writeIn_nameNum > ~fileAudio_writeIn_maxNum, { //cap max file count...
					~fileAudio_writeIn_nameNum = 0;
				});
				~recSamp_input = false;
				~button_recIn.value = 0;
			} ); */

			if (~playSamp == true, {
				~samp0.free;
				~audioBuf_play0.close; //<---not needed...?
				~audioBuf_play0.free;
				~playSamp = false;
				~button_playSamp.value = 0;
				~autoRecPlay_state = 0; //<----- NEW
			} );
		}
	);
} )
.value_(0);

~button_recIn = Button(~view_sampButtons, Rect(0, 0, 45, 20))
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
			~audioBuf_inMainWrite = Buffer.alloc(s, 65536, 1); //allocate a disk i/o buffer (min rec frame size is 65536)
			~audioBuf_inMainWrite.write((~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".wav").standardizePath, "wav", ~sampBitDepth, 0, 0, true); // create an output file for this buffer, leaving it "open" (not recording yet, just created file w/ format header)
			~writeIn2Disk = Synth.tail(nil, \write2Disk, [\buf, ~audioBuf_inMainWrite, \inBus, ~inputSendBus] ); //record audio from rec playhead (bufRead synth sends audio input to ~inputSendBus), and write an audio file to hard disk
			~recSamp_input = true; //<--- not sure if this flag's needed right now...
		} ,
		{//STOP RECORDING / WRITING AUDIO INPUT TO FILE
			~writeIn2Disk.free; //stop recording to disk
			~audioBuf_inMainWrite.close; //close the buffer to finish writing the sound file (won't be readable otherwise)
			~audioBuf_inMainWrite.free;
			~fileAudio_writeIn_nameNum = ~fileAudio_writeIn_nameNum + 1; //increment file name suffix in prep for next rec file
			if (~fileAudio_writeIn_nameNum > ~fileAudio_writeIn_maxNum, { //cap max file count...
				~fileAudio_writeIn_nameNum = 0;
			});
			~recSamp_input = false; //<--- not sure if this flag's needed right now...
		} );
} );

~button_recOut = Button(~view_sampButtons, Rect(0, 22, 45, 20))
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
			~audioBuf_outMainWrite = Buffer.alloc(s, 65536, 1); //allocate a disk i/o buffer (min rec frame size is 65536)
			~audioBuf_outMainWrite.write((~fileAudio_writeOut_lastPath++~fileAudio_writeOut_nameNum++".wav").standardizePath, "wav", ~sampBitDepth, 0, 0, true); // create an output file for this buffer, leaving it "open" (not recording yet, just created file w/ format header)
			~write2Disk = Synth.tail(nil, \write2Disk, [\buf, ~audioBuf_outMainWrite, \inBus, 0] ); //record audio sent to bus 0 to buffer writing to audio file
			~recSamp_output = true;  //<--- not sure if this flag's needed right now...
		} ,
		{//STOP RECORDING / WRITING MAIN AUDIO OUTPUT TO FILE
			~write2Disk.free; //stop recording to disk
			~audioBuf_outMainWrite.close; //close the buffer to finish writing the sound file (won't be readable otherwise)
			~audioBuf_outMainWrite.free; //free buffer
			~fileAudio_writeOut_nameNum = ~fileAudio_writeOut_nameNum + 1; //increment file name suffix in prep for next rec file
			if (~fileAudio_writeOut_nameNum > ~fileAudio_writeOut_maxNum, { //cap max file count...
				~fileAudio_writeOut_nameNum = 0;
			});
			~recSamp_output = false; //<--- not sure if this flag's needed right now...
		} );
} );

~button_recInOut = Button(~view_sampButtons, Rect(45, 0, 66, 20))
.states_( [
	["RECinOut", Color.black, Color(0.9, 0.9, 0.3, 0.3)] ,
	["RECinOut", Color.black, Color(0.9, 0.9, 0.3)]
] )
.font_(Font("Monaco", 12) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{
			~button_recIn.valueAction = 1;  //<---NOT GOOD IN LONG RUN...CREATE FUNCTION TO TRIGGER AUDIO FILE WRITING SYNTHS...
			~button_recOut.valueAction = 1;
		},
		{
			~button_recIn.valueAction = 0;
			~button_recOut.valueAction = 0;
		}
	);
} )
.value_(0);

~button_playSamp = Button(~view_sampButtons, Rect(45, 22, 66, 20) )
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
			//play random or pre-selected or wildcard, etc. file(s) from sample folder?

			if (~fileAudio_writeIn_nameNum >= ~minNumFilesB4Playback,
				{
					var randFilePick, fileDir;
					~playSamp = true;  //yes or no?
					randFilePick = rrand(0, (~fileAudio_writeIn_nameNum - 1));
					fileDir = (~fileAudio_writeIn_lastPath++randFilePick++".wav").standardizePath;
					fileDir.postln;
					~audioBuf_play0 = Buffer.read(s, fileDir, action: {arg buffer;
						~samp0 = Synth(\bufRead_noLoop, [\buf, buffer, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]);
						NodeWatcher.register(~samp0);

						//---put routine here that will turn off button when sample playback complete? ----
					});
				}
			);

		} ,
		{//STOP Sample playback
			~playSamp = false; //yes or no?
			if (~samp0.isRunning, {~samp0.free;});
			~audioBuf_play0.free;
		} );
} );

~label_playSamp = StaticText(~view_sampButtons, Rect(113, 23, 135, 20))
.string_("/PATH/../FILENAME")
.font_(Font("Monaco", 12) )
.align_(\left);


//++++ADD FILE SELECTOR INTERFACE (OPEN DIALOG?) FOR SAMPLE LOADING...

//++++ADD BUFFSCOPE FOR PLAYING / LOADED AUDIO FILE(s) (make into re-usable view for GUI of multi-channel & multi-sample playback)

//--------------------------


///---------- LEVELS ----------///

~slider_inFlow1_level = Slider(~view_altLevels, Rect(9, 2, 12, 73))
.background_(Color(0.0, 0.5, 0.9))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~inputStreamLevelBus.set(val);
	~numBox_inFlow1_level.value_(val);
} );

~numBox_inFlow1_level = NumberBox(~view_altLevels, Rect(2, 75, 26, 15))
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
	~slider_inFlow1_level.value_(val);
} );

~label_inFlow1_level = StaticText(~view_altLevels, Rect(0, 94, 30, 8))
.string_("IN+FX")
.font_(Font("Monaco", 10) )
.align_(\center);

~slider_sampOut_level = Slider(~view_altLevels, Rect(44, 2, 12, 73))
.background_(Color(0.0, 0.8, 0.2))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~fileOutputLevelBus.set(val);
	~numBox_sampOut_level.value_(val);
} );

~numBox_sampOut_level = NumberBox(~view_altLevels, Rect(37, 75, 26, 15))
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
	~slider_sampOut_level.value_(val);
} );

~label_sampOut_level = StaticText(~view_altLevels, Rect(35, 94, 30, 8) )
.string_("SAMP")
.font_(Font("Monaco", 10) )
.align_(\center);

//----------

/*
//------- SCOPE VIEW (AUDIO BUF0) ------------

//~scopeView = ScopeView(w.view, Rect(15, 10, 665, 170) );
~scopeView = ScopeView(w, Rect(15, 10, 665, 170) );
~scopeView.server_(s);
~scopeView.xZoom = 1;  //changing these values doesn't seem to effect display
//~scopeView.x = 0;  //changing these values doesn't seem to effect display
~scopeView.yZoom = 1.0;
*/


//-------- PLOTTER ----------//
/*
GUI.skin.plot.fontColor = Color.red;
GUI.skin.plot.plotColor = Color.blue;
GUI.skin.plot.background = Color.black;
GUI.skin.plot.gridColorX = Color.white;
GUI.skin.plot.gridColorY = Color.cyan;
//GUI.skin.plot.gridOnY = false;
//GUI.skin.plot.gridOnX = false;

~bufPlot = Plotter.new("Buffer", parent: ~view_bufPlot); //CREATE PLOTTER

~audioBuf0.loadToFloatArray(action: {arg array;
	{~bufPlot.value = array}.defer; //create bufPlot matrix w/ as many values as buffer (very big...should probably scale this to be smaller more light weight plotter, i.e. divide buffer frames by 10 or 100 to represent average of every 10 - 100ms slices of buffer...
});

{
	~bufPlot.setProperties(
		\gridOnY, false,
		\gridOnX, true
	);
	~bufPlot.plotMode = \linear;
	~bufPlot.domainSpecs = ControlSpec(0, ~audioBuf0_dur);
	//~bufPlot.resolution = 1; //<---too coarse...
	~bufPlot.resolution = 0.04; //good compromise for GUI speed, smaller resos (.02, .01) causes GUI to lag...
	~bufPlot.updatePlots.refresh;
}.defer(0.2); //<--if this is any shorter, these properties won't be set for some reason....

~updateBufPlot_prevUpdateFrame = nil;

~updateBufPlot = Routine({ //basic incremental buf plotter
	if (~updateBufPlot_prevUpdateFrame == nil,
		{//if first time routine's run since program launch
			var plotDur, currentFrame;

			0.5.yield; //wait for buffer to fill w/ values...

			//then evaluate bufPlot function from frame 0 to currentFrame
			currentFrame = ~lastRecPhasePos;

			//plotDur = ~lastRecPhasePos + 1; //inclusive of frame 0
			plotDur = currentFrame + 1; //inclusive of frame 0
			~audioBuf0.loadToFloatArray(index: 0, count: plotDur, action: {|array|
				{
					//(">>>INIT PLOT<<<").postln;
					//("startFrame: 0 | count:" + plotDur + "| stopFrame:" + currentFrame).postln;
					array.collect({|item, i| ~bufPlot.value[i] = item;});
					~bufPlot.updatePlots.refresh;
					//~updateBufPlot_prevUpdateFrame = ~lastRecPhasePos; //set prevUpdateFrame to currentFrame
					~updateBufPlot_prevUpdateFrame = currentFrame; //set prevUpdateFrame to currentFrame
				}.defer;
			});
		},
		{//else if routine's been running: plot from prevUpdateFrame+1 to currentFrame
			var startFrame, currentFrame;

			startFrame = ~updateBufPlot_prevUpdateFrame + 1;
			if (startFrame >= ~audioBuf0.numFrames, {startFrame = 0;}); //if ~prevUpdateFrame == lastBufFrame, wrap around to 0
			currentFrame = ~lastRecPhasePos; //store in local var b/c env var frequently updated by other routine

			//if(~lastRecPhasePos > startFrame,
			if (currentFrame > startFrame,
				{//simple contiguous span
					var plotDur;
					//plotDur = ~lastRecPhasePos - ~updateBufPlot_prevUpdateFrame; //inclusive of startFrame
					plotDur = currentFrame - ~updateBufPlot_prevUpdateFrame; //inclusive of startFrame
					~audioBuf0.loadToFloatArray(index: startFrame, count: plotDur, action: {|array|
						{
							//(">>>SIMPLE PLOT<<<").postln;
							//("startFrame:" + startFrame + "| count:" + plotDur + "| stopFrame:" + currentFrame).postln;
							array.collect({|item, i| ~bufPlot.value[startFrame + i] = item;});
							~bufPlot.updatePlots.refresh;
							//~updateBufPlot_prevUpdateFrame = ~lastRecPhasePos; //set prevUpdateFrame to currentFrame
							~updateBufPlot_prevUpdateFrame = currentFrame; //set prevUpdateFrame to currentFrame
						}.defer;
					});
				},
				{//wrapped around buffer, two chunks...
					var chunk1Dur, chunk2Dur;
					chunk1Dur = ~audioBuf0.numFrames - startFrame; //dur from start frame to last buf frame (inclusive of startFrame)
					//chunk2Dur = ~lastRecPhasePos + 1; //dur from frame 0 to lastRecPhasePos (inclusive of frame 0)
					chunk2Dur = currentFrame + 1; //dur from frame 0 to lastRecPhasePos (inclusive of frame 0)

					//plot from startFrame to lastBufFrame
					~audioBuf0.loadToFloatArray(index: startFrame, count: chunk1Dur, action: {|array|
						{
							//(">>>WRAP PLOT<<<").postln;
							//("CHUNK1 - startFrame:" + startFrame + "| chunk1Dur:" + chunk1Dur).postln;
							array.collect({|item, i| ~bufPlot.value[startFrame + i] = item;});
						}.defer;
					});

					//plot from frame 0 to ~lastRecPhasePos
					~audioBuf0.loadToFloatArray(index: 0, count: chunk2Dur, action: {|array|
						{
							//("CHUNK2 - startFrame: 0" + "| count:" + chunk2Dur + "| stopFrame:" + currentFrame).postln;
							//("TOTAL - startFrame:" + startFrame + "| dur:" + (chunk1Dur + chunk2Dur) + "| stopFrame:" + currentFrame).postln;
							array.collect({|item, i| ~bufPlot.value[i] = item;});
							~bufPlot.updatePlots.refresh;
							//~updateBufPlot_prevUpdateFrame = ~lastRecPhasePos; //set prevUpdateFrame to currentFrame
							~updateBufPlot_prevUpdateFrame = currentFrame; //set prevUpdateFrame to currentFrame
						}.defer;
					});
				}
			);
		}
	);
	0.5.yieldAndReset;
});
*/
//----------

/*~phaseBusMonRec.get({|val| (val/s.sampleRate).postln;});  //junk for monitoring
~phaseBusRec.get({|val| val.postln;});
~phaseBusMonRec.get({|val| val.postln;});
~phaseBusMonRec.get({|val| val.postln;});
~phaseBusMonPly.get({|val| (val/s.sampleRate).postln;});  //<----this is where to get phasor value....
*/

////---------------RECORD TO BUFFER BUTTON--------------////
~button_recBuf = Button(~view_perfButtons, Rect(0, 0, 55, 25)) //REC BUTTON: activate / deactivate recording to buffer
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
			if ((~lastRecPhasePos >= ~recInFrame) && (~lastRecPhasePos <= ~recOutFrame), {
				//if rec head is still w/in rec In/Out range
				~phasor_rec = Synth(\phasor, [\out, ~phaseBusRec, \buf, ~audioBuf0, \rate, 1, \start, ~lastRecPhasePos, \end, ~recOutPosBus.asMap] ).moveToHead;
				~recPosLatchTrig = true; //used to trigger reset of \start arg to ~recInPosBus.asMap after init
			} , { //else ~lastRecPhasePos is outside of rec In/Out range
				~phasor_rec = Synth(\phasor, [\out, ~phaseBusRec, \buf, ~audioBuf0, \rate, 1, \start, ~recInPosBus.asMap, \end, ~recOutPosBus.asMap] ).moveToHead;  //have phasor start at ~recInFrame
			} );

			~a2k_rec = Synth(\a2k_patch, [\in, ~phaseBusRec, \out, ~phaseBusMonRec] ).moveAfter(~phasor_rec); //<--don't fully understand why this allows me to monitor phasor value and why I can't do so by getting value of ~phaseBusRec (doing so always outputs 1)...

			~bufRecorder = Synth(\bufRec, [\phaseBus, ~phaseBusRec, \buf, ~audioBuf0, \sendBus, ~inputSendBus, \loCutoff, ~loCutBus_in.asMap, \mul, ~inputLevelBus.asMap] ).moveAfter(~a2k_rec);

			NodeWatcher.register(~bufRecorder); //this ensures all synths associated w/ buf play back are positioned after all these buf recording synths in the node-tree, no matter when they're created

			//~lastRecPhasePos.value.postln;

			//START REC SLIDER UPDATE ROUTINE...
			~getBus_updateGUI_recPhase.reset;
			AppClock.play(~getBus_updateGUI_recPhase);

			//////PLOTTER ----------
			~updateBufPlot.reset;
			AppClock.play(~updateBufPlot);

			/*
			//////////////SCOPE
			~scopeBuf_audioBuf0 = Buffer.alloc(s, ~audioBuf0.numFrames, 1); //create additional buffer for displaying contents of audio buffer...is this the only way to do this?? what happens if I 'scopeOut' to ~audioBuf0?
			~scopeView.bufnum = ~scopeBuf_audioBuf0.bufnum; //<----
			//~scopeView.bufnum = ~audioBuf0.bufnum; //<----this will also work (no addtl buffer needed)...
			~scopeOut = Synth.tail(s, \scopeOut, [\inBus, ~inputSendBus, \buf, ~scopeBuf_audioBuf0]); //<----
			//~scopeOut = Synth.tail(s, \scopeOut, [\inBus, ~inputSendBus, \buf, ~audioBuf0]); //<--this works also
			~scopeView.start; //<----
			//////////
			*/

		},
		{ //when REC button disabled (when recording stops)
			~phaseBusMonRec.get( {arg val;
				~lastRecPhasePos = val.round(1); //store last pos of recPhase
				//("LastRecPhasePos = " ++ ~lastRecPhasePos).postln;
			} );
			~phasor_rec.free;
			~a2k_rec.free;
			~bufRecorder.free; //stop recording to buffer and free RecBuf_loop synth

			~getBus_updateGUI_recPhase.stop;

			~updateBufPlot.stop;  //PLOTTER

			/*
			 ///FOR SCOPE
			~scopeView.stop; //<----
			~scopeOut.free; //<----
			~scopeBuf_audioBuf0.free; //<----
			*/
		}
	);
} );
//--------------

////------------ PLAY FROM BUFFER BUTTON -----------////

~button_playBuf = Button(~view_perfButtons, Rect(56, 0, 55, 25)) //activate / deactivate playback output
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
			//"fixPlayOffset= ".post; ~button_delaySync.value.postln;
			//"buttonRec= ".post; ~button_recBuf.value.postln;
			//~phaseBusMonPly.get( {arg val; ~lastPlayPhasePos = val;} );
			if (~button_delaySync.value == 1 && ~button_recBuf.value == 1,
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
								~lastPlayPhasePos = (~audioBuf0.numFrames - 1) + ~play2recOffset; //if true, wrap around buffer
								//newPlayPos = (~audioBuf0.numFrames - 1) + ~play2recOffset;
							} ,
							{
								~lastPlayPhasePos = ~play2recOffset; //else normal subtraction
								//newPlayPos = ~play2recOffset;
							}
						);
					} );
					//~phasor_play = Synth(\phasor, [\out, ~phaseBusPly, \buf, ~audioBuf0, \rate, ~rateBus.asMap, \start, ~playInPosBus.asMap, \end, ~playOutPosBus.asMap, \trig, 0, \resetPos, newPlayPos] );
					"lastPlayPhasePosafterOffsetAdjust".post; ~lastPlayPhasePos.postln;
				} //,
				//{
					//~phasor_play = Synth(\phasor, [\out, ~phaseBusPly, \buf, ~audioBuf0, \rate, ~rateBus.asMap, \start, ~playInPosBus.asMap, \end, ~playOutPosBus.asMap, \trig, 0, \resetPos, ~lastPlayPhasePos] );
				//}
			); */ //<------------------------------^^^^^^^^^^^^^^^^^^^

			//"--afterIf".postln;
			//~lastPlayPhasePos.postln;

			if ((~lastPlayPhasePos >= ~playInFrame) && (~lastPlayPhasePos <= ~playOutFrame), {
				//if play head is still w/in play In/Out range
				~phasor_play = Synth(\phasor, [\out, ~phaseBusPly, \buf, ~audioBuf0, \rate, ~rateBus.asMap, \start, ~lastPlayPhasePos, \end, ~playOutPosBus.asMap] );
				~playPosLatchTrig = true; //used to start playPhasor at lastPlayPhasePos
			} , { //else ~lastPlayPhasePos is outside of play In/Out range
				~phasor_play = Synth(\phasor, [\out, ~phaseBusPly, \buf, ~audioBuf0, \rate, ~rateBus.asMap, \start, ~playInPosBus.asMap, \end, ~playOutPosBus.asMap] );  //have phasor start at ~playInFrame
			} );

			if (~bufRecorder.isRunning, {~phasor_play.moveAfter(~bufRecorder);}); //regulate node-tree order

			~a2k_play = Synth(\a2k_patch, [\in, ~phaseBusPly, \out, ~phaseBusMonPly]).moveAfter(~phasor_play); //converting phaseBus values at ar to kr and sending to phaseBusMon so sliderPlayPos can receive current value of phasor
			~bufPlayer = Synth(\bufRead, [\amp, ~play1LevelBus.asMap, \out, ~playOut1Bus, \phaseBus, ~phaseBusPly, \buf, ~audioBuf0] ).moveAfter(~a2k_play);

			NodeWatcher.register(~bufPlayer);  //<---not currently being monitored anymore....

			~pShift = Synth(\pitchShifter,
				[\inBus, ~playOut1Bus, \outBus, ~pitchShiftOut, \pitchRatio, ~pitchBus.asMap]).moveAfter(~bufPlayer);

			~pShiftMix = Synth(\XFade, [
			\in1, ~playOut1Bus,
			\in2, ~pitchShiftOut,
			\out, ~outMainBus,
			\amountControlBus, ~pitchShiftMixValBus.asMap,
			\amp, ~inputStreamLevelBus.asMap //<--NEW
			] ).moveAfter(~pShift);

			~getBus_updateGUI_playPhase.reset;
			AppClock.play(~getBus_updateGUI_playPhase);
		} ,
		{
			~phaseBusMonPly.get( {|val| ~lastPlayPhasePos = val.round(1);} );
			~phasor_play.free;
			~a2k_play.free;
			~bufPlayer.free;
			~pShift.free;
			~pShiftMix.free;
			~getBus_updateGUI_playPhase.stop;
		} );
} );

//--------REVERSE BUTTON ---------

~button_rev = Button(~view_perfButtons, Rect(113, 0, 45, 25)) //Reverse playback
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

//------ DELAY OFFSET -------
~button_delaySync = Button(~view_perfButtons, Rect(160, 0, 55, 25)) //Delay Offset Sync button --- WORKS but a little buggy....
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
			~routine_playHeadOffset.reset;
			AppClock.play(~routine_playHeadOffset);

			/*
			//snap playhead to position based on delay offset from rechead<------
			~phaseBusMonRec.get( { //<----this block doesn't function properly when uncommented, needs to be in a routine?????
				//calculate the offset of the playhead from the rechead
				arg val;
				~play2recOffset = val - ((~delayTime * s.sampleRate).round(1));
				if (~play2recOffset < 0,
					{~lastPlayPhasePos = (~audioBuf0.numFrames - 1) + ~play2recOffset;
						//lastPlay2RecOffset = ~lastPlayPhasePos;
					} ,
					{~lastPlayPhasePos = ~play2recOffset;
						//lastPlay2RecOffset = ~play2recOffset;
					}
				);
			} );

			if (~button_playBuf.value == 1, {~phasor_play.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } );
			*/

		},
		{ //when button disabled
			~fixPlayRecOffset = false;
			~routine_playHeadOffset.stop;
		}
	);
} )
.value_(0);

~numBox_delay = NumberBox(~view_perfButtons, Rect(217, 0, 55, 25))  //WORKS but a little buggy....
.value_(~delayTime)
.clipLo_(0)
.clipHi_(~audioBuf0_dur - 0.01)
.font_(Font("Monaco", 14) )
.decimals_(2)
.scroll_step_(0.01)
.step_(0.01)
.action_( {
	arg obj;
	var lastPlay2RecOffset;
	~delayTime = obj.value.round(0.01);
	//~delayTime.postln;
	//~slider_delay.value = obj.value.linlin(0, ~audioBuf0_dur - 0.01, 0, 1); //ideally do this only when the numBox is being manipulated directly, otherwise it's redundantly updating value of slider...OBSOLESCED in 1.82

	~routine_playHeadOffset.reset;
	AppClock.play(~routine_playHeadOffset);

	/* ~phaseBusMonRec.get( { //<----works but BUGGY small delay values don't seem to be accurate...
		//calculate the offset of the playhead from the rechead
		arg val;
		~play2recOffset = val - ((~delayTime * s.sampleRate).round(1));
		lastPlay2RecOffset = val - ((~delayTime * s.sampleRate).round(1));
		//if (~play2recOffset < 0,
		if (lastPlay2RecOffset < 0,
			{//~lastPlayPhasePos = (~audioBuf0.numFrames - 1) + ~play2recOffset;
				~lastPlayPhasePos = (~audioBuf0.numFrames - 1) + lastPlay2RecOffset;
			} ,
			{//~lastPlayPhasePos = ~play2recOffset;
			 ~lastPlayPhasePos = lastPlay2RecOffset;
			}
		);
	} );

	if (~button_playBuf.value == 1, {~phasor_play.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } ); */

} );

~label_delayTime = StaticText(~view_perfButtons, Rect(275, 2, 78, 20) )
//~label_delayTime = StaticText(w, Rect(720, 157, 78, 20) )
.string_("Offset
(sec)")
.font_(Font("Monaco", 8) )
.align_(\left);

/*~slider_delay = Slider(w, Rect(489, 332, 180, 15))
.background_(Color(0.85, 0.85, 0.0))
.value_(~delayTime.linlin(0, ~audioBuf0_dur - 0.01, 0, 1))
.action_( { //<----BUGGY....?????
	arg obj;
	var pos, playPosFrame;
	pos = obj.value.linlin(0, 1, 0, ~audioBuf0_dur - 0.01).round(0.01);
	//~numBox_delay.value_(pos); //update numBoxPitch value
	~numBox_delay.valueAction_(pos); //so we don't have to duplicate calc code from numBoxDel here
} ); */

~routine_playHeadOffset = Routine.new( {
	~phaseBusMonRec.get( {
		arg val;
		~play2recOffset = val - ((~delayTime * s.sampleRate).round(1)); //calculate the offset of the playhead from the rechead
		if (~play2recOffset < 0,
			{~lastPlayPhasePos = (~audioBuf0.numFrames - 1) + ~play2recOffset;} ,
			{~lastPlayPhasePos = ~play2recOffset;}
		);
	} );
	0.1.yield; //<--------------IS THERE ANY OTHER WAY???????????

	if (~button_playBuf.value == 1, {~phasor_play.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } );
	nil;
} );

//--------------------

//-------------- BEHAVIOR BUTTONS ------------

~button_Behavior1 = Button(~view_perfButtons, Rect(0, 25, 55, 25)) //randomize rate control
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
			//~updateGUI_counter_rateT2rand.reset;
			~updateGUI_rate.reset; //<---not sure if this is necessary here, but buggy rate random rate interp behavior may have been caused when commenting it out...
			AppClock.play(~randomRoutine_rate);
			//AppClock.play(~updateGUI_counter_rateT2rand);
		},
		{ //when randomize button disabled
			~randomRoutine_rate.stop;
			//~updateGUI_counter_rateT2rand.stop;
			//~playHeadFollowRecHead.stop;
			~updateGUI_rate.stop;
			//~numBox_counter_rateT2rand.value_(0.0);
		}
	);
} )
.value_(0);

/*
//Monitoring support GUI objects for ~button_Behavior1 activity
~numBox_counter_rateT2rand = NumberBox(w, Rect(313, 378, 50, 25))
.value_(0.0)
.clipLo_(0)
.clipHi_(120)
.font_(Font("Monaco", 14) )
.decimals_(1);

~label_counter_rateT2rand = StaticText(w, Rect(368, 380, 30, 20) )
.string_("T2R")
.font_(Font("Monaco", 12) )
.align_(\left);
*/

~button_Behavior2 = Button(~view_perfButtons, Rect(55, 25, 30, 25)) //Randomize pitch shift, pitch shift mix, and output level control
.states_( [
	["!!", Color.black, Color(0.0, 0.3, 0.9, 0.3)] ,
	["!!", Color.white, Color(0.8, 0.3, 0.8)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1, // when enabled
		{
			~randomRoutine_freq.reset;
			~randomRoutine_pitchShiftMix.reset;
			//~randomRoutine_outputLevel.reset;
			//~updateGUI_counter_rateT2rand.reset;
			//~playHeadFollowRecHead.reset;
			//~updateGUI_rate.reset;

			AppClock.play(~randomRoutine_freq);
			AppClock.play(~randomRoutine_pitchShiftMix);
			//AppClock.play(~randomRoutine_outputLevel);
		},
		{ //when randomize button disabled
			//~randomRoutine.stop;
			~randomRoutine_freq.stop;
			~randomRoutine_pitchShiftMix.stop;
			//~randomRoutine_outputLevel.stop;
			//~numBox_counter_rateT2rand.value_(0.0);
		}
	);
} )
.value_(0);

~button_Behavior3 = Button(~view_perfButtons, Rect(86, 25, 25, 25)) //randomize Reverse and PlayHead Behavior control
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
			~randomRoutine_playHeadBehavior.reset;
			AppClock.play(~randomRoutine_reverse);
			AppClock.play(~randomRoutine_playHeadBehavior);
		},
		{ //when randomize button disabled
			~randomRoutine_reverse.stop;
			~randomRoutine_playHeadBehavior.stop;
			~playHeadFollowRecHead.stop;
		}
	);
} )
.value_(0);
//--------------------

// ------------- REC HEAD / PLAY HEAD ----------

~slider_recPos = Slider(~view_transport, Rect(5, 25, 610, 20))
.background_(Color(0.95, 0.0, 0.0))
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, 0, ~audioBuf0.numFrames - 1).round(1); //convert slider value to frame

	if (~button_recBuf.value == 1,
		{//update ~phasor_rec phasor synth position when actively recording to buffer
			~phasor_rec.set (
				\resetPos, pos,
				\trig, 1
			);
		},
		{//update phasor pos when not actively recording to buffer
			~lastRecPhasePos = pos;
		}
	);

	~numBox_recPos.value = (pos/s.sampleRate).round(0.01); //convert frames to seconds and display

	/*
	//SYNC functionality---------------- (double check and debug, haven't worked with this in awhile)
	if (~fixPlayRecOffset == true, //<-----
		{
			~play2recOffset = pos - ((~delayTime * s.sampleRate).round(1));
			if (~play2recOffset < 0,
				{~lastPlayPhasePos = (~audioBuf0.numFrames - 1) + ~play2recOffset;} ,
				{~lastPlayPhasePos = ~play2recOffset; }
			);

			if (~button_playBuf.value == 1, {~phasor_play.set(\resetPos, ~lastPlayPhasePos, \trig, 1); } ); //is this best way to do it or should I create a flag indicating whenever recPhase position is updated w/ click so that playPhase is updated w/ clock instead???
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
					 ~play2recOffset = ~audioBuf0.numFrames - (pos - val);
					 ~delayTime = ~play2recOffset/s.sampleRate;
					}
				);
			} );
			~numBox_delay.value = ~delayTime;
			//~slider_delay.value = ~delayTime.linlin(0, ~audioBuf0_dur - 0.01, 0, 1); //obsolesced in 1.82
		}
	 );
	//SYNC functionality----------------
	*/

} )
.value_(0.0);

~numBox_recPos = NumberBox(~view_transport, Rect(625, 25, 65, 20)) //numBox PlayPos
.value_(0)
.clipLo_(0)
//.clipHi_(~audioBuf0_dur) //HOW COME UNCOMMENTING THIS MESSES UP THE GUI??????
.font_(Font("Monaco", 14) )
.decimals_(2);
//.action_( {
	//arg obj;
	//~slider_recPos.valueAction = obj.value / ~audioBuf0_dur; //<---
//} );

~label_recPos = StaticText(~view_transport, Rect(692, 32, 100, 10) )
.string_("RecPos(sec)")
.font_(Font("Monaco", 10) )
.align_(\left);


~slider_playPos = Slider(~view_transport, Rect(5, 48, 610, 20))
.background_(Color(0, 0.8, 0.2))
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, 0, ~audioBuf0.numFrames - 1).round(1); //convert slider value to frame
	//~phasor_play.set (\resetPos, pos, \trig, 1);
	if (~button_playBuf.value == 1,
		{//update ~phasor_play phasor synth position when actively playing from buffer
			~phasor_play.set(
				\resetPos, pos,
				\trig, 1
			);
		},
		{//update phasor pos when not actively playing from buffer
			~lastPlayPhasePos = pos;
		}
	);
	~numBox_playPos.value = (pos/s.sampleRate).round(0.01); //convert frames to seconds and display
} )
.value_(0.0);


~numBox_playPos = NumberBox(~view_transport, Rect(625, 48, 65, 20))
.value_(0)
.clipLo_(0)
//.clipHi_(~audioBuf0.numFrames-1)
.font_(Font("Monaco", 14) )
.decimals_(2);

~label_playPos = StaticText(~view_transport, Rect(692, 53, 100, 10) )
.string_("PlayPos(sec)")
.font_(Font("Monaco", 10) )
.align_(\left);

~slider_recInOut = RangeSlider(~view_transport, Rect(5, 2, 610, 20))
.lo_(0.0)
.hi_(1.0)
//.background_(Color(0.0, 0.5, 0.2))
.action_({
	|slider|

	var recIn, recOut;

	recIn = slider.lo.round(0.0001).linlin(0, 1.0, 0, ~audioBuf0.numFrames - 1).round(1);
	("recIn=" + recIn).postln;
	recOut = slider.hi.round(0.0001).linlin(0, 1.0, 0, ~audioBuf0.numFrames - 1).round(1);
	("recOut=" + recOut).postln;

	~recInPosBus.set(recIn);
	~recInFrame = recIn;
	("RecInFrame=" + ~recInFrame).postln;
	~recOutPosBus.set(recOut);
	~recOutFrame = recOut;
	("RecOutFrame=" + ~recOutFrame).postln;

	//~numBox_playIn.value_((playIn * ~audioBuf0_dur).round(0.1));
	~numBox_recIn.value_( (recIn / s.sampleRate).round(0.01) ); //
	//~numBox_playIn.value_( (slider.lo.round(0.0001) * ~audioBuf0_dur).round(0.1)  );

	//~numBox_playOut.value_((playOut * ~audioBuf0_dur).round(0.1));
	~numBox_recOut.value_( (recOut / s.sampleRate).round(0.01) );
} );

~numBox_recIn = NumberBox(~view_transport, Rect(625, 2, 46, 20))
.value_(0.0)
.clipLo_(0.0)
//.clipHi_(~audioBuf0_dur)
.clipHi_(~numBox_audioBuf0_dur.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2);
/*
.action_( {
	arg obj;
	~slider_playInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} ); */

~numBox_recOut = NumberBox(~view_transport, Rect(672, 2, 46, 20))
.value_(~audioBuf0_dur)
.clipLo_(0.0)
//.clipHi_(~audioBuf0_dur)
.clipHi_(~numBox_audioBuf0_dur.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2);
/*
.action_( {
	arg obj;
	~slider_playInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} )*/

~label_recInOut = StaticText(~view_transport, Rect(720, 3, 90, 20) )
.string_("In/Out-Rec")
.font_(Font("Monaco", 10) )
.align_(\left);

~slider_playInOut = RangeSlider(~view_transport, Rect(5, 71, 610, 20)) //SLIDER => Play In/Out
.lo_(0.0)
.hi_(1.0)
//.background_(Color(0.0, 0.5, 0.2))
.action_({
	|slider|

	var playIn, playOut;

	//playIn = slider.lo.round(0.0001);
	playIn = slider.lo.round(0.0001).linlin(0, 1.0, 0, ~audioBuf0.numFrames - 1).round(1);
	("playIn=" + playIn).postln;
	//playOut = slider.hi.round(0.0001);
	playOut = slider.hi.round(0.0001).linlin(0, 1.0, 0, ~audioBuf0.numFrames - 1).round(1);
	("playOut=" + playOut).postln;

	~playInPosBus.set(playIn);
	//~playInFrame = playIn.linlin(0, 1.0, 0, ~audioBuf0.numFrames - 1).round(1);
	~playInFrame = playIn;
	("currentInFrame=" + ~playInFrame).postln;
	~playOutPosBus.set(playOut);
	//~playOutFrame = playOut.linlin(0, 1.0, 0, ~audioBuf0.numFrames - 1).round(1);
	~playOutFrame = playOut;
	("currentOutFrame=" + ~playOutFrame).postln;

	//~numBox_playIn.value_((playIn * ~audioBuf0_dur).round(0.1));
	~numBox_playIn.value_( (playIn / s.sampleRate).round(0.01) ); //
	//~numBox_playIn.value_( (slider.lo.round(0.0001) * ~audioBuf0_dur).round(0.1)  );

	//~numBox_playOut.value_((playOut * ~audioBuf0_dur).round(0.1));
	~numBox_playOut.value_( (playOut / s.sampleRate).round(0.01) );
} );

~numBox_playIn = NumberBox(~view_transport, Rect(625, 71, 46, 20))
.value_(0.0)
.clipLo_(0.0)
//.clipHi_(~audioBuf0_dur)
.clipHi_(~numBox_audioBuf0_dur.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2);
/*
.action_( {
	arg obj;
	~slider_playInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} ); */

~numBox_playOut = NumberBox(~view_transport, Rect(672, 71, 46, 20))
.value_(~audioBuf0_dur)
.clipLo_(0.0)
//.clipHi_(~audioBuf0_dur)
.clipHi_(~numBox_audioBuf0_dur.clipHi)
.font_(Font("Monaco", 12) )
.decimals_(2)
/*
.action_( {
	arg obj;
	~slider_playInOut.lo.valueAction_(obj.value); //updates value & position of slider and triggers action when numberBox value is changed...
} )*/;

~label_playInOut = StaticText(~view_transport, Rect(720, 72, 90, 20) )
.string_("In/Out-Play")
.font_(Font("Monaco", 10) )
.align_(\left);

//-----------

// ------- OTHER PLAYBACK CONTROLS ------

//RATE --
~slider_rate = Slider(~view_procControls1, Rect(0, 0, 300, 20))
.background_(Color(0.0, 0.5, 0.9))
.value_(0.5)
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, -48, 48).round(0.01); //used to be round(1)
	if (~button_rev.value == 1,
		{~rateBus.set(pos.midiratio * -1);}, //negative rate when REV button enabled
		{~rateBus.set(pos.midiratio); //positive rate when REV button disabled
	} );
	 //change playback pitch!
	~numBox_rate.value_(pos); //update numBoxPitch value
} ) ;

~numBox_rate = NumberBox(~view_procControls1, Rect(308, 0, 48, 20))
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
	~slider_rate.value_(pos);
} );

~label_rate = StaticText(~view_procControls1, Rect(358, 4, 80, 10))
.string_("Rate(semi)")
.font_(Font("Monaco", 12) )
.align_(\left);


//PITCH SHIFT --
~slider_pitch = Slider(~view_procControls1, Rect(0, 22, 300, 20))
.background_(Color(0.0, 0.7, 0.9))
.value_(0.linlin(-48, 24, 0.0, 1.0))
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, -48, 24).round(0.01);
	~pitchBus.set(pos.midiratio);
	~numBox_pitch.value_(pos);
} );

~numBox_pitch = NumberBox(~view_procControls1, Rect(308, 22, 48, 20))
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
	~slider_pitch.value_(pos);
} );

~label_pitch = StaticText(~view_procControls1, Rect(358, 27, 80, 10))
.string_("Pitch(semi)")
.font_(Font("Monaco", 12) )
.align_(\left);


// PITCH SHIFT MIX --
~slider_pitchShiftMix = Slider(~view_procControls1, Rect(165, 44, 135, 15))
.background_(Color(0.0, 0.6, 0.8, 0.2))
.value_(0.0)
.action_( {
	arg obj;
	var mixAmount;
	mixAmount = obj.value.round(0.001);
	~pitchShiftMixValBus.set(mixAmount);
	//("sliderVal2PBus=" + mixAmount).postln;
	mixAmount = mixAmount.round(0.01);
	~numBox_pitchShiftMix.value_(mixAmount * 100);
} );

~numBox_pitchShiftMix = NumberBox(~view_procControls1, Rect(308, 44, 48, 20))
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
	~slider_pitchShiftMix.value_(mixVal);
} );

~label_pitchShiftMix = StaticText(~view_procControls1, Rect(358, 49, 135, 10))
.string_("PitchShiftMix")
.font_(Font("Monaco", 12) )
.align_(\left);
)