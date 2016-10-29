//Sonic Mirror - 00_Main:

//TODO:
//  • add new pitch tracker synth instrument feature:  freq of synth/sampler mimics or derived from audio feature extraction...
//• add DiskIn recording method from ~autoRec_random into alternate version of ~autoRec_soundTrig1 to avoid strict buffer.copy and .write methods and hopefully get rid of some funky bugs....

//Fix:
//• autoRec_soundTrig routine....works first time run,  but drops recPhaseStart polling in subsequent restarts and seems to record increasingly larger files from same start point
//      - also make it detect exact recPhaseFrame when all feature extractors aren't exceeding thresholds (when ~hearSound first = false;) and then calculate sampleStop time from this for tighter sample  durations....

//== Main Performance Doc ==

//---- refactor in progress ----

~dir = "/Users/Scott/Dropbox/DocSync/Project Docs/DigitalArt/SonicMirror/sonic-mirror_SC_git/dev/";

(~dir ++ "01_Startup.scd").load;           // Server Options and Startup
(~dir ++ "02_SynthDefs.scd").load;       // SynthDefs
(~dir ++ "03_Busses.scd").load;            // Busses

s.quit;  //convenience method (for cleanup)
s.plotTree; //for debugging
Buffer.freeAll; //for cleanup

( //INITIALIZE - Env Variables, Set Busses, Routine Defs, Func Defs?, GUI - #3 ============================

////GLOBAL VARIABLES
~audioBuf0_dur = 60.0;
~audioBuf0 = Buffer.alloc(s, s.sampleRate * ~audioBuf0_dur, 1);

~delayTime = 1.23;
~play2recOffset; //displacement of playhead pos from rec pos (in frames/samples)
~lastPlayPhasePos = 0; //for resume functionality - stores last pos (frame) of play head before playback disabled
~lastRecPhasePos = 0; //for resume functionality - stores last pos (frame) of rec head before recording disabled
~playPosLatchTrig = false;
~recPosLatchTrig = false;
~fixPlayRecOffset = false;

~loCutVal_in = 90; //<-----NEW initialization val for loCut (and also stores ongoing values?)
~loCutVal_out = 90; //<-----NEW ...for initialization

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
~inputStreamLevelBus.set(1);  //<---NEW
~fileOutputLevelBus.set(1);  //<---NEW

~outMainLevelBus.set(1);

~phaseBusMonPly.set(0);
~phaseBusMonRec.set(0);

~loCutBus_in.set(~loCutVal_in); //<---NEW
~loCutBus_out.set(~loCutVal_out); //<----NEW
//-----------------

// --------- SET UP SOME INITIAL SYNTHS? ------------
~mainOut = Synth.tail(s, \mainOut, [\in, ~outMainBus, \loCutoff, ~loCutBus_out.asMap, \amp, ~outMainLevelBus.asMap]);
//Synth(\pitchShift1)???

//
//

//-------------------

////
Window.closeAll;
w = Window.new("SonicMirror", Rect.new(470, 330, 780, 405))
.front
.alwaysOnTop_(true);

w.onClose_{s.freeAll; Buffer.freeAll(s); CmdPeriod.clearClocks; CmdPeriod.run;}; // clean up when window is closed


//------ Main In/Out Controls (Levels & Lo-Cut) -----------

//Main Input Level --
~slider_inMainLevel = Slider(w, Rect(684, 8, 17, 173) )
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

~numBox_inMainLevel = NumberBox(w, Rect(682, 183, 26, 15))
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

~label_inMainLevel = StaticText(w, Rect(687, 195, 12, 20) )
.string_("IN")
.font_(Font("Monaco", 10) )
.align_(\center);

//Main Out Level --
~slider_outMainLevel = Slider(w, Rect(733, 8, 17, 173) )
.background_(Color(0.0, 0.8, 0.2, 0.01))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~outMainLevelBus.set(val);
	~numBox_outMainLevel.value_(val);
} );

~numBox_outMainLevel = NumberBox(w, Rect(728, 183, 26, 15))
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

~label_outMainLevel = StaticText(w, Rect(730, 195, 20, 20) )
.string_("OUT")
.font_(Font("Monaco", 10) )
.align_(\center);

//Main In / Out Lo-Cuts --
~numBox_inMainLoCut = NumberBox(w, Rect(680, 216, 32, 14))//<---
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

~numBox_outMainLoCut= NumberBox(w, Rect(724, 216, 32, 14))//<---
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

~label_inoutMainLoCut = StaticText(w, Rect(693, 226, 48, 20) )//<---
.string_("LoCut-Hz")
.font_(Font("Monaco", 10) )
.align_(\left);
//------------

//----- AUDIO BUFFER --------

~button_audioBuf_0 = Button(w, Rect(400, 377, 85, 25)) //Activate / Deactivate audio buffer
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

~numBox_audioBuf0_dur = NumberBox(w, Rect(490, 377, 75, 25))
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

~label_audioBuf0_dur = StaticText(w, Rect(568, 380, 200, 20) )
.string_("Buf(sec)")
.font_(Font("Monaco", 12) )
.align_(\left);

//--------------------------------


//--------- Soundfile Rec / Playback ---------------

//--put these variables back w/ the rest of env variables at some point??--

~playBehavior = 0; //stores state of playback behavior

~currentSound = "silence"; //state of current heard sound (0 = silence, 1 = unpitched sound, 2 = pitched sound
~currentScene = "quiet"; //sound scene index (0 = quiet, 1 = sparse transient sounds, 2 = drone, 3 = noise

~playSamp = false; //<--- flag:  playing audio file from disk

~fileAudio_writeOut_nameNum = 0; //counter for writing/reading audio file names
~fileAudio_writeOut_lastPath = "~/Music/SCrecs/SncMir/SncMir-Out_"; //stores string of file path for last written audio file from disk
~fileAudio_writeIn_nameNum = 0; //counter for writing/reading audio file name
~fileAudio_writeIn_lastPath = "~/Music/SCrecs/SncMir/SncMir-In_"; //stores string of file path for last written audio file
~minNumFilesB4Playback = 1; // file # threshold before file playback routine commences
~fileAudio_writeIn_maxNum = 30; //max # of audio samples written per session (wrap-around & overwrite limit - inclusive of 0)
~fileAudio_writeOut_maxNum = 30;  //max # of audio out samples written per session (wrap-around & overwrite limit)

//---
~listenDur_noiseFloor = 5.0;
/*~senseNoiseFloor = Routine.new( {
	//sets ~loudnessThresh
} );  */

//s.plotTree;
//~listen.value(1, post: 1);
//~listen.value(0);
//~listen.value(1, rate: 1, post: 1);
//~bus_onsets.get({|val| val.postln;});
//~bus_onsets.set(0);

~listen = { |active = 1, rate = 0.1, post = 0| //setup and trigger all automated feature extractors???
	if (active == 1, {//start feature extraction...
		if (~bufRecorder.isRunning, {
			//LOUDNESS monitor
			l = Synth(\Loudness, [\input, ~inputSendBus, \outBus, ~bus_loudness]).moveAfter(~bufRecorder);
			//PITCH tracker
			p = Synth(\Pitch, [\input, ~inputSendBus, \outBus, ~bus_pitch, \ampThresh, 0.02, \clar, 1]).moveAfter(l);
			//ONSET detector
			n = Synth(\onsets, [\input, ~inputSendBus, \outBus, ~bus_onsets, \threshold, 0.5, \trigtime, 0.25]).moveAfter(l);
			//etc....

			//fire off ~senseNoiseFloor routine....?

			~busSum_lop = ~sumFunc_xin.value([~bus_loudness, ~bus_onsets, ~bus_pitch]); //4 feats
			~transmit = ~streamFeatures.value(bus: ~busSum_lop, rate: rate, post: post); //<---here or in other routines???
			~deBounce = Routine({
				("debounce pause - 2 sec").postln;
				2.yield;
				SystemClock.play(~transmit);
				~bus_onsets.set(0);
				nil;
			});
			SystemClock.play(~deBounce);

			~listening = true;
			"LISTENING NOW...".postln;
		}, {
			"CAN'T LISTEN UNLESS BUF RECORDER ENABLED...".postln;
		} );
	}, {//if active == 0, stop feature extraction and clean up...
		if (~listening == true, { //only free synths and cleanup if we were listening in the first place, otherwise don't do anything and avoid server errors....
			~transmit.stop;
			~transmit.free;  //<---just added...necessary?
			~deBounce.stop;
			~deBounce.free;
			~sumSyn_xin.free;
			~busSum_lop.free;
			l.free;
			p.free;
			n.free;
			~listening = false;
			"STOPPED LISTENING...".postln;
		});
	} );
};

/*~listen = { |active = 1, rate = 0.1, post = 0| //setup and trigger all automated feature extractors???
	if (active == 1, {//start feature extraction...
		if (~bufRecorder.isRunning, {
			//LOUDNESS monitor
			l = Synth(\Loudness, [\input, ~inputSendBus, \outBus, ~bus_loudness]).moveAfter(~bufRecorder);
			//PITCH tracker
			p = Synth(\Pitch, [\input, ~inputSendBus, \outBus, ~bus_pitch, \ampThresh, 0.02, \clar, 1]).moveAfter(l);
			//ONSET detector
			n = Synth(\onsets, [\input, ~inputSendBus, \outBus, ~bus_onsets, \threshold, 0.5, \trigtime, 0.25]).moveAfter(l);
			//etc....

			//fire off ~senseNoiseFloor routine....?

			~busSum_lop = ~sumFunc_xin.value([~bus_loudness, ~bus_onsets, ~bus_pitch]); //4 feats
			~transmit = ~streamFeatures.value(bus: ~busSum_lop, rate: rate, post: post); //<---here or in other routines???
			SystemClock.play(~transmit);

			~listening = true;
			"LISTENING NOW...".postln;
		}, {
			"CAN'T LISTEN UNLESS BUF RECORDER ENABLED...".postln;
		} );
	}, {//if active == 0, stop feature extraction and clean up...
		if (~listening == true, { //only free synths and cleanup if we were listening in the first place, otherwise don't do anything and avoid server errors....
			~transmit.stop;
			~transmit.free;  //<---just added...necessary?
			~sumSyn_xin.free;
			~busSum_lop.free;
			l.free;
			p.free;
			n.free;
			~listening = false;
			"STOPPED LISTENING...".postln;
		});
	} );
}; */

~loudnessThresh = 5; //set w/ ~senseNoiseFloor
~pitchThresh = 0.55;

~hearSound = false; //<---NEW: for machine listening
~listening = false;  //flag indicates audio analysis activity

~minRecDur = 2.0; //<-----min sec per recorded sample (only being used w/ autoRec_random now...)
~maxRecDur = 6.0; //<----max sec per recorded sample (only being used w/ autoRec_random now...)

~recSamp_input = false; //<---NEW:  write audio file 2 disk flag....should I store this info in a contol bus?
~recSamp_output = false;
~recSamp_input_startFrame = 0;
~recSamp_input_stopFrame = 0;

~preRecDur = 0.2; //amount of time to sample from buffer prior to start of ~autoRec
~postRecSnip = 0.5; //amount of time to subtract from total dur of sampled sound (to cut silence at end of sample after ~autoRec finished and ~listenDur_intraSound pads end...)

~listenDur_intraSound = 1.5; //<----NEW: amount of time (sec) to continue listening for continuation of contiguous sound object between gaps of silence (e.g. seperation threshold for dividing sound objects)
~autoRec_rate = 0.1; //finest timing resolution of ~autoRec_soundTrig routine
~listenDur_stateChange = 0.2;  //not sure if I'm going to need/use this yet...
~yieldTime_autoRec = 0.1;  //val to be reassigned as routine runs...

~autoRecStartTrig = false; //flag triggered when ~autoRec routines initiated (used for debounce time when triggered via button press to avoid false sound detection)

~autoRec_soundTrig1 =  {|featureBus, rate = 0.1, debounceTime = 1|
	Routine( { //<----model this after ~routine_wekiSynthControl1 from SCML --turn into a function....... ALSO use write2Disk synth method instead of buffer copying....?
		if (~recSamp_input == true,
			{
				// add if (~listening == true, {  }); <---yes or no?
				featureBus.get({|val| //get sum bus "lop" - 4 features: [Loudness, Onset, Freq, Pitch Measure]
					if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
					//if (( (val[0] >= ~loudnessThresh) || (val[3] >= ~pitchThresh) ),
						{//SOUND DETECTED
							~hearSound = true;
							//CONTINUE RECORDING / DO NOTHING....
							("-----=======-----").postln;
							("**Recording... SOUND DETECTED").postln;
							("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
							~yieldTime_autoRec = ~listenDur_intraSound;
							//~yieldTime_autoRec = rate.asFloat;  //<--- switch to this for more accurate sample stop time
						}, {//IF NO SOUND DETECTED...
							if (~hearSound == false, {//Sound Stop Confirmed - WRITE AUDIO SAMPLE (sound was stopped since last iteration)
								("--------++++++++-------").postln;
								("**Recording... SOUND STOP CONFIRMED").postln;
								("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

								~writeSampFromBufCopy_input.value();
								~yieldTime_autoRec = rate.asFloat;

								/*  ///ORIG....VVVVVVV
								//GET recHead phasor position and log "STOP  SAMPLE TIME"
								~phaseBusMonRec.get({|val| //<---move to false condition of this conditional for more accurate sample out time ------<<<<<<<<<<<<
									~recSamp_input_stopFrame = (val - (~postRecSnip * s.sampleRate)).round(1);
									if (~recSamp_input_stopFrame < 0, { //if presumed stopFrame is negative...
										~recSamp_input_stopFrame = ~audioBuf0.numFrames + ~recSamp_input_stopFrame; //wrap around buffer and log sound stop frame
									} );
									("--Sound Stop at (in get) = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;
									~writeSampFromBufCopy_input.value();  //<---this seems to be working here....test more.....
									//OR SET FLAG TO TRIGGER FOLLOWING CHUNKS OF CODE AFTER .YIELDANDRESET RE-EXECUTION OF ROUTINE....???
									~yieldTime_autoRec = rate.asFloat;
								});
								("--Sound Stop at (outside get) = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;
								*/

								//0.1.yield; //<---NOPE, CAN'T DO THIS HERE....but would it work if encapsulated inside a larger function?
								//~yieldTime_autoRec = rate.asFloat; <-- moving inside get
							}, {//else if ~hearSound == true (test to make sure sound has stopped but continue recording)
								("-------").postln;
								("**Recording...SOUND STOP? ... Testing...").postln;
								("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

								//GET recHead phasor position and log "STOP  SAMPLE TIME"
								~phaseBusMonRec.get({|val|
									~recSamp_input_stopFrame = (val - (~postRecSnip * s.sampleRate)).round(1);
									if (~recSamp_input_stopFrame < 0, { //if presumed stopFrame is negative...
										~recSamp_input_stopFrame = ~audioBuf0.numFrames + ~recSamp_input_stopFrame; //wrap around buffer and log sound stop frame
									} );
									("--Sound Stop (in get) = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;
									//~yieldTime_autoRec = rate.asFloat;
									~hearSound = false;
									~yieldTime_autoRec = ~listenDur_intraSound;
								});
								//("--Sound Stop at (outside get) = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;

								/*~hearSound = false; //////////------orig
								//could log sound stop time here for more accurate sample out pos <------!!!!!!
								("-------").postln;
								("**Recording...SOUND STOP? ... Testing...").postln;
								~yieldTime_autoRec = ~listenDur_intraSound; */
							});
					});
				});
			} ,
			{//else if ~recSamp_input == false
				if (~listening == false,
					{
						"***Can't record, not listening...***".postln;
						~yieldTime_autoRec = 1;
					},
					{//if ~listening == true...
						if (~playSamp == false,{ //don't record if playing back samples...
							if(~autoRecStartTrig == true, {
								~autoRecStartTrig = false;
								~hearSound = false;
								("Debounce =" + debounceTime + "sec").postln;
								debounceTime.yield;
							}); //debounce when routine first launched (avoids false sound detection from mouse click)
							//GET SUM BUS
							featureBus.get({|val|
								if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
									{//SOUND DETECTED
										("---").postln;
										("**HEAR SOUND**").postln;
										("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;

										if (~hearSound == false, //TEST SOUND START...  <---not sure if need test...just start rec????
											{
												~phaseBusMonRec.get({|val| //log recHead pos //<---here or after sound conf?
													~recSamp_input_startFrame = (val - (~preRecDur * s.sampleRate)).round(1);
													if (~recSamp_input_startFrame < 0, { //if presumed startFrame is negative...
														~recSamp_input_startFrame = ~audioBuf0.numFrames + ~recSamp_input_startFrame; //wrap around buffer and log sound start frame
													} );
													("---------").postln;
													("--> Sound START?: " ++( ~recSamp_input_startFrame/s.sampleRate)).postln;
													~hearSound = true; //<--- moved inside get
													~yieldTime_autoRec = rate.asFloat; //<--- moved inside get
												});
											},
											{//else ~hearSound == true
												("- - - - -").postln;
												("--> Sound START CONFIRMED:" + ( ~recSamp_input_startFrame/s.sampleRate)).postln;
												("--REC Sample Start").postln;
												//("--------").postln;
												~recSamp_input = true;
												{~button_recIn.value = 1;}.defer;

												//Log start time here or in previous iteration as above??
												//Index sumBus feature vals into ~soundMemory buffer??? //<---

												~yieldTime_autoRec = ~listenDur_intraSound; //LEAVING THIS SIDE OF ROUTINE
											}
										);
									},
									{//if NO SOUND DETECTED ........
										("--- NO SOUND ---").postln;
										("Ldns-Onst-pitMsr = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
										if (~hearSound == true, {
											~hearSound = false;
											("--> ...false alarm?...").postln;
											//~listenDur_intraSound.yieldAndReset; //<-- this or ~autoRec_rate ?
											//~listenDur_stateChange.yieldAndReset; //<-- this or ~autoRec_rate ?
											~yieldTime_autoRec = rate.asFloat; //routine's default quickest poll rate
										}, { //else if ~hearSound == false
											("-->...silence...").postln;
											~yieldTime_autoRec = rate.asFloat; //routine's default quickest poll rate
										});
								});
							});
						},
						{ //else if (~playSamp == true)
							~yieldTime_autoRec = 1;
						});
					}
				);
			}
		);

		0.02.yield;
		//	("~yieldTime_autoRec = " ++ ~yieldTime_autoRec).postln;
		~yieldTime_autoRec.yieldAndReset;
	} );
};

~autoRec_random = Routine.new( {
	if (~recSamp_input == true,
		{ //STOP RECORDING / WRITING AUDIO INPUT TO FILE
			//var yieldTime = rrand(5, 8).round(0.01);
			var yieldTime = rrand(8, 30).round(0.01);
			~recSamp_input = false;
			{~button_recIn.value = 0;}.defer;

			~writeIn2Disk.free; //stop recording to disk
			~audioBuf_inMainWrite.close; //close the buffer to finish writing the sound file (won't be readable otherwise)
			~audioBuf_inMainWrite.free;
			("AutoRecRand -- WROTE Samp-AUDIO-IN_" ++ ~fileAudio_writeIn_nameNum).postln;
			~fileAudio_writeIn_nameNum = ~fileAudio_writeIn_nameNum + 1; //increment file name suffix in prep for next rec file
			if (~fileAudio_writeIn_nameNum > ~fileAudio_writeIn_maxNum, //cap max file count...
				{~fileAudio_writeIn_nameNum = 0;}
			);

			("AutoRecRand -- Next Time to RandRec = " ++ yieldTime).postln;
			yieldTime.yieldAndReset;
		} ,
		{//else if ~recSamp_input == false
			if (~playSamp == false, {
				if (~bufRecorder.isRunning, {//BEGIN RECORDING AUDIO INPUT TO FILE
					var recTime = rrand(~minRecDur, ~maxRecDur).round(0.01);

					~recSamp_input = true;
					{~button_recIn.value = 1;}.defer;
					~audioBuf_inMainWrite = Buffer.alloc(s, 65536, 1); //allocate a disk i/o buffer (min rec frame size is 65536)
					~audioBuf_inMainWrite.write((~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath, "aiff", "int24", 0, 0, true); // create an output file for this buffer, leaving it "open" (not recording yet, just created file w/ format header)
					~writeIn2Disk = Synth.tail(nil, \write2Disk, [\buf, ~audioBuf_inMainWrite, \inBus, ~inputSendBus] ); //record audio from rec playhead (bufRead synth sends audio input to ~inputSendBus), and write an audio file to hard disk
					("AutoRecRand -- WRITING AUDIO-IN SAMP_" ++ ~fileAudio_writeIn_nameNum).postln;
					("AutoRecRand: -- recTime = " ++ recTime).postln;
					("---").postln;
					recTime.yieldAndReset;
				} , { //else if ~bufRecorder not running, don't record anything
					"AutoRecRand: -- NO RECORDING - BUF REC NOT ACTIVE".postln;
					8.yieldAndReset;
				});
			}, { //else if (~playSamp == true)
				5.yieldAndReset;
			} );
		}
	);
} );

~autoPlay_random = Routine.new( {  //<----- LIL BUGGY, almost there.... sample playback buffer getting lost somehow????
	if (~playSamp == true,
		{ //if already playing sound file, we can assume it's completed by the time this routine has stopped yielding based on commands when ~playSamp == false (see below code in 'else' of this conditional)...
			var time2yield, interpSynth;
			~playSamp = false;

			if (~bufPlayer.isRunning, {
				interpSynth = Synth(\LinInterp_num, [\startVal, 0.0, \stopVal, 1.0, \duration, 0.2, \out, ~inputStreamLevelBus]); //turn inStreamLevel back to 1.0 in 0.2 sec (++++\startVal should probs = variable storing current value of inputStreamLevel++++)
				{~slider_inFlow1_level.value = 1;}.defer;  //update GUI
				{~numBox_inFlow1_level.value = 1;}.defer; //update GUI
				//0.2.yield;  //not necessary, since sound's stopped by this point...
			});

			~audioBuf_play0.free;
			{~button_playSamp.value = 0;}.defer; //update GUI button

			time2yield = rrand(3, 5).round(0.01);
			//time2yield = rrand(12, 35); //<-----TIME RANGE - TRIGGER RATE (IN SEC).....
			("AutoPlayRand: -- time2nextPlay= " ++ time2yield ++ " sec").postln;
			time2yield.yieldAndReset;
		},
		{//if not playing a soundFile, ~playSamp == false
			if (~recSamp_input == false, //only play back sounds if not currently recording...
				{
					if (~fileAudio_writeIn_nameNum >= ~minNumFilesB4Playback, //if min # of files have been written
						{//.....currently triggers random sample every time routine is played...DEVELOP....

							//<---***CONDITION CHECKING TRIGGERING SAMPLE PLAYBACK GOES HERE****----
							//---e.g. routines checking machine listening ugen output control busses...

							//PLAYBACK AUDIO FILE FROM DISK
							//var readDiskSynth, interpSynth, readFileFunc, randFilePick, duration;
							var interpSynth, randFilePick, fileDir, duration;

							~playSamp = true; //set flag

							if (~bufPlayer.isRunning, { //if playing buffer audio, silence it for audio sample playback
								//get current signal flow/chain level val from ~inputStreamLevelBus and assign to local variable used for \startVal arg in interpSynth below...
								interpSynth = Synth(\LinInterp_num, [\startVal, 1.0, \stopVal, 0.0, \duration, 0.2, \out, ~inputStreamLevelBus]); //silence input stream in 0.2 sec (***startVal should probs = variable storing current value of inputStreamLevel***
								{~slider_inFlow1_level.value = 0;}.defer;  //update GUI
								{~numBox_inFlow1_level.value = 0;}.defer; //update GUI
								("~bufPlayer.isRunning - 0.2.yield").postln;
								0.2.yield;
							});
							("--after checking ~bufPlayer.isRunning").postln;

							randFilePick = rrand(0, (~fileAudio_writeIn_nameNum - 1)); //pick a random file to play (needs to be "current nameNum counter val - 1" b/c current counter value doesn't have a file associated w/ it yet due to counter incrementing after a new file has been written...)

							//<----***could alternatively insert other file picking behaviors or mappings here****

							//vvvvvv ---- make this into a reusable function for audio file playback ---- vvvvvv
							fileDir = (~fileAudio_writeIn_lastPath++randFilePick++".aiff").standardizePath;

							//PLAY SOUND FILE from disk
							~audioBuf_play0 = Buffer.read(s, fileDir, action: {arg buffer;
								//duration = buffer.numFrames/s.sampleRate;
								duration = buffer.numFrames/buffer.sampleRate;
								~samp0 = Synth(\bufRead_noLoop, [\buf, buffer, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]);
								//NodeWatcher.register(~samp0);

								("PLAYING BACK FILE:" + (~fileAudio_writeIn_lastPath++randFilePick++".aiff").standardizePath).postln;

							});
							{~button_playSamp.value = 1;}.defer; //update GUI
							("Pre-yield samp Dur = " ++ duration).postln;
							0.2.yield;  //<---UNFORTUNATE YIELD needed to update duration variable (probs doesn't need to be that lon, thought short yield times was causing a "Buffer UGen: buffer data" error, but testing seems to point elsewhere ...
							("Post-yield samp Dur = " ++ duration).postln;
							//duration.yieldAndReset; //<---might not be necessary to add 0.02 sec, experiment
							(duration + 0.2).round(0.01).yieldAndReset; //<---probs not necessary to add 0.2 sec, experiment
							//---------- ^^^^^^^^^^^^^^^^^^^ ---------------------------
						},
						{15.yieldAndReset;} //<------------ wait if not enough files have been written yet
					);
				},
				{5.yieldAndReset;} //else if (~recSoundInput == true)
			);
		}
	);
} );

~button_autoRecPlay = Button(w, Rect(215, 349, 25, 25))
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
			~autoRecStartTrig = true;
			~listen.value(1, post: 1); //start listening
			//~autoRecStart = ~autoRec_soundTrig1.value(featureBus: ~busSum_lop, rate: 0.1); //<--uncomment when done debugging
			//SystemClock.play(~autoRecStart);  //<--uncomment when done debugging

			//~autoRec_random.reset;
			//~autoPlay_random.reset;
			//SystemClock.play(~autoRec_random);
			//SystemClock.play(~autoPlay_random);
		},
		{
			//~autoRecStart.stop; //<--uncomment when done debugging
			//~autoRecStart.free; //<--uncomment when done debugging
			~listen.value(0); //stop listening
			//~autoRec_random.stop;
			//~autoPlay_random.stop;

			if (~recSamp_input == true, { //pertains to ~autoRec_soundTrig1
				if (~hearSound == true, {
					~phaseBusMonRec.get({|val|
						~recSamp_input_stopFrame = val.round(1);
						("--Sound Stop at = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;
						~writeSampFromBufCopy_input.value(); //writes sample, sets ~recSamp = false, updates GUI
					});
					~hearSound = false;
				});
				//~recSamp_input = false;
				//~button_recIn.value = 0;
			}, { //if ~recSamp_input == false
				~hearSound = false;
				~button_recIn.value = 0;
			});

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
				~audioBuf_play0.free;
				~playSamp = false;
				~button_playSamp.value = 0;
			} );

			/*
			if(~writeIn2Disk.isRunning, { //causes bugs if these env variables have never been created...
				~writeIn2Disk.free;
				~audioBuf_inMainWrite.close;
				~audioBuf_inMainWrite.free;
				~fileAudio_writeIn_nameNum = ~fileAudio_writeIn_nameNum + 1;
				~recSamp_input = false;
				~button_recIn.value = 0;
			});

			if (~samp0.isRunning, { //free sample playback synth and buffer if it's still running when this button is turned off / ~autoPlay_random routine is stopped.......
				~samp0.free;
				~audioBuf_play0.free;
				~playSamp = false;
				~button_playSamp.value = 0;
			}); */
		}
	);
} )
.value_(0);

~button_recIn = Button(w, Rect(16, 352, 45, 20) ) //<------NEW
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
			~audioBuf_inMainWrite.write((~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath, "aiff", "int24", 0, 0, true); // create an output file for this buffer, leaving it "open" (not recording yet, just created file w/ format header)
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

~button_recOut = Button(w, Rect(16, 372, 45, 20) )
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
			~audioBuf_outMainWrite.write((~fileAudio_writeOut_lastPath++~fileAudio_writeOut_nameNum++".aiff").standardizePath, "aiff", "int24", 0, 0, true); // create an output file for this buffer, leaving it "open" (not recording yet, just created file w/ format header)
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

~button_recInOut = Button(w, Rect(62, 352, 70, 20))
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

~button_playSamp = Button(w, Rect(62, 372, 65, 20) )
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
					fileDir = (~fileAudio_writeIn_lastPath++randFilePick++".aiff").standardizePath;
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

~label_playSamp = StaticText(w, Rect(130, 373, 135, 20) )
.string_("FILENAMEFILENAME...")
.font_(Font("Monaco", 12) )
.align_(\left);


//++++ADD FILE SELECTOR INTERFACE (OPEN DIALOG?) FOR SAMPLE LOADING...

//++++ADD BUFFSCOPE FOR PLAYING / LOADED AUDIO FILE(s) (make into re-usable view for GUI of multi-channel & multi-sample playback)

//--------------------------


///---------- LEVELS ----------///

~slider_inFlow1_level = Slider(w, Rect(684, 242, 12, 73) )
.background_(Color(0.0, 0.5, 0.9))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~inputStreamLevelBus.set(val);
	~numBox_inFlow1_level.value_(val);
} );

~numBox_inFlow1_level = NumberBox(w, Rect(678, 315, 26, 15))
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

~label_inFlow1_level = StaticText(w, Rect(670, 332, 40, 8) )
.string_("IN+FX")
.font_(Font("Monaco", 10) )
.align_(\center);

~slider_sampOut_level = Slider(w, Rect(715, 242, 12, 73) )
.background_(Color(0.0, 0.8, 0.2))
.value_(1.0)
.action_( {
	arg obj;
	var val;
	val = obj.value.round(0.01);
	~fileOutputLevelBus.set(val);
	~numBox_sampOut_level.value_(val);
} );

~numBox_sampOut_level = NumberBox(w, Rect(709, 315, 26, 15))
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

~label_sampOut_level = StaticText(w, Rect(707, 332, 32, 8) )
.string_("FILE")
.font_(Font("Monaco", 10) )
.align_(\center);

//----------


//------ DELAY OFFSET -------
~numBox_delay = NumberBox(w, Rect(610, 349, 75, 25))  //WORKS but a little buggy....
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

~label_delayTime = StaticText(w, Rect(688, 352, 78, 20) )
.string_("Offset(sec)")
.font_(Font("Monaco", 12) )
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

~button_delaySync = Button(w, Rect(550, 349, 55, 25)) //Delay Offset Sync button --- WORKS but a little buggy....
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



//--------- GUI UPDATE ROUTINES ----------------
~updateGUI_rate = Routine.new ( {
	~rateBus.get( {
		arg val;
		var thisVal = val.abs; //in case "Reverse" enabled and rate is negative...   <-----
		AppClock.sched(0.0, { //this is necessary for some reason...
			//"pitchBusVal= ".post; val.ratiomidi.round(0.01).postln;
			//~slider_rate.value_(val.ratiomidi.linlin(-48, 48, 0, 1) );
			~slider_rate.value_(thisVal.ratiomidi.linlin(-48, 48, 0, 1) );
			//~numBox_rate.value_(val.ratiomidi.round(0.01));
			~numBox_rate.value_(thisVal.ratiomidi.round(0.01));
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
			~slider_pitch.value_(val.ratiomidi.linlin(-48, 24, 0, 1) );
			~numBox_pitch.value_(val.ratiomidi.round(0.01));
			nil;
		} );
	} );
	0.1.yieldAndReset;
} );

~updateGUI_pitchShiftMix = Routine.new ( {
	~pitchShiftMixValBus.get( {
		arg val;
		AppClock.sched(0.0, { //this is necessary for some reason...??????
			~slider_pitchShiftMix.value_(val);
			~numBox_pitchShiftMix.value_((val * 100).round(1));
			nil;
		} );
	} );
	0.1.yieldAndReset;
} );

~updateGUI_outMainLevel = Routine.new ( {
	~outMainLevelBus.get( {
		arg val;
		AppClock.sched(0.0, { //this is necessary for some reason...??????
			~slider_outMainLevel.value_(val);
			~numBox_outMainLevel.value_(val.round(0.01));
			nil;
		} );
	} );
	0.1.yieldAndReset;
} );

~updateGUI_counter_rateT2rand = Routine.new( { //crude somewhat inaccurate way to do this but good enough for now
	if (~time2NextRandom_rate <= 0, {~time2NextRandom_rate = 0;} );
	~numBox_counter_rateT2rand.value_(~time2NextRandom_rate);
	~time2NextRandom_rate = ~time2NextRandom_rate - 0.1;
	0.1.yieldAndReset;
} );
// ------------------


//----- RANDOMIZE ROUTINES -------
~randomRoutine_rate = Routine.new ( { //Automatically randomize playback rate and adjust playHead
	var time2nextRandomize, randNum4transp, newPitch, pitchCase, pitchInterp, interpTime;

	~rateBus.get( {
		arg val;
		//("*****currentRate=" + val).post;
			~pitchShiftValPrev_rate = val.ratiomidi;
			//("---prevPitch=" + ~pitchShiftValPrev_rate).postln;
	} );

	0.1.yield; //<<<<<works, but not ideal b/c of added latency...  HOW CAN I ENABLE THIS ROUTINE TO FUNCTION W/OUT SLIGHT TIME YIELD HERE?

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
		if (~button_rev.value == 1, { //when REVERSE mode enabled  <-----worked, but not during interp-------
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

~randomRoutine_pitchShiftMix = Routine.new ( {
	var time2nextRandomize, randNum, mixCase, interpMix, interpTime;

	~pitchShiftMixValBus.get( {
		arg val;
		~pitchShiftMix_prev = val;
	} );

	//!!!!!CONSIDER ALSO GETTING CURRENT pitchShift value....if == 0 make mixVal = 0

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


~randomRoutine_outputLevel = Routine.new ( {  //randomly adjust main output level
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
			//~slider_outMainLevel.value_(1);
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
	if (~button_rev.value == 0, { //if REVERSE disabled
		if (thisRandomNum <= 3.2, { //32% chance REVERSE enabled
			~button_rev.valueAction_(1);
			//~revRateBusMon.set(-1); // <--DO THIS instead of valueAction !!!!!!!!!!
			//~button_rev.value_(1); // <--DO THIS instead of valueAction !!!!!!!!!!!!
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
			~button_rev.valueAction_(0); //90% chance REVERSE disabled
			//~revRateBusMon.set(1); // <--DO THIS instead of valueAction !!!!!!!!!!
			//~button_rev.value_(0); // <--DO THIS instead of valueAction !!!!!!!!!!!!

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


~randomRoutine_playHeadBehavior = Routine.new ( { //Randomize playHead behavior (Following or Random)

//CONSIDER AUGMENTING EVENTUALLY to be aware of current rate and pitchShift values (so it can avoid feedback if randomRate or randomPitch routines not enabled by disabling playRecOffset if this is the case, for example) AAAANNDD ALSO BE AWARE OF previous and current playBehavior states to more intelligently govern probability of transitioning to new state (e.g. if previously was at randomState, increase the chances of reverting back to followPlayhead state upon next state change)

	var time2nextRandomize, thisRandomNum, selectedBehavior, behaviorCase, newPos, offsetSec, minOffsetSec = 12, maxOffsetSec = 55;

	thisRandomNum = rrand(1.0, 10.0);
	if (((~randPlayPos_flag == false) && (thisRandomNum <= 8)) || (~randPlayPos_flag == true), { //80% chance playHead will follow recHead if randomPos not previously active
		~randPlayPos_flag = false; //reset flag to remember randomPos no longer active after routine reset
		~playHeadFollowRecHead.reset;
		AppClock.play(~playHeadFollowRecHead);
		time2nextRandomize = rrand(12, 20);
		("***FOLLOW RECHEAD behavior running for " + time2nextRandomize + " secs...").postln;
		time2nextRandomize.yieldAndReset;
	}, { //else 25% chance playHead moved to random position...
		//("***RANDOM POSITION***").postln;
		~randPlayPos_flag = true;  //set flag to remember randomPos triggered after this routine is reset
		~playHeadFollowRecHead.stop;

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
				if (newPos < 0, {newPos = (~audioBuf0.numFrames - 1) + newPos;} ); //wrap around if newPos initially less than 0
				//("lastPlayPhaseFrame=" + ~lastPlayPhasePos + " | lastPlaySec=" + (~lastPlayPhasePos/s.sampleRate) ).postln;
				//("newPos=" + newPos + " | " + (newPos/s.sampleRate) + "sec").postln;
			},
			{ //50% chance playHead offset forwards in time
				//newPos = rrand(~lastPlayPhasePos, ~audioBuf0.numFrames - 1);

				//("--FORWARDS--").postln;
				newPos = ~lastPlayPhasePos + (offsetSec * s.sampleRate);
				if (newPos > (~audioBuf0.numFrames - 1), {newPos = (newPos % ~audioBuf0.numFrames) - 1;} ); //wrap around if newPos greater than buffer length

				if ( ((~lastRecPhasePos - newPos) <= (2 * s.sampleRate) ) && ((~lastRecPhasePos - newPos) >= 0), {
					//("---AVOIDING FEEDBACK---").postln;
					//("lastRecHeadPos =" + (~lastRecPhasePos/s.sampleRate) + " | ").post;
					//("newPos WAS: " + (newPos/s.sampleRate).round(0.01) + "sec").postln;
					newPos = ~lastRecPhasePos + (1.5 * s.sampleRate); //reset newPos to 1.5 seconds AFTER recHead to avoid inducing rapid feedback (only would happen if rate and pitch shift == 0)
					if (newPos > (~audioBuf0.numFrames - 1), {newPos = (newPos % ~audioBuf0.numFrames) - 1;} ); //wrap around if newPos greater than buffer length
					//("newPos IS NOW: " + (newPos/s.sampleRate).round(0.01) + "sec").postln;
				} ); //to avoid landing too close to recHead and causing rapid audio feedback

				//("lastPlayPhaseFrame=" + ~lastPlayPhasePos + " | lastPlaySec=" + (~lastPlayPhasePos/s.sampleRate) ).postln;
				//("newPos=" + newPos + " | " + (newPos/s.sampleRate) + "sec").postln;
			}
		);
		~phasor_play.set(\resetPos, newPos, \trig, 1); //set new position of playPhase (move playHead)
		time2nextRandomize = rrand(4.5, 10.0).round(0.01);
		("***RANDOM POSITION behavior running for " + time2nextRandomize + " secs...").postln;
		time2nextRandomize.yieldAndReset;
	} );



/*	behaviorCase = case  //<------REINCORPORATE
	{~playBehavior == 0} { //"follow recHead" behavior
		~playHeadFollowRecHead.reset;
		AppClock.play(~playHeadFollowRecHead);
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

~playHeadFollowRecHead = Routine.new( {  //set playhead based on current RecHead-PlayHead offset AND playback Rate value --- used in ~randomRoutine_playHeadBehavior
	//"**playRecOffsetIsGoing**  ".post;
	//("revFlag=" + ~reverseFlag).postln;
	if ((~pitchInterp_rate == false) && (~button_rev.value == 0) /*&& (~pitchInterp_freq == false) */, { //<---ADDED reverse & pitchInterp detection---
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
			{currentTimeOffset = ( (~playOutFrame - ~playInFrame) - (~lastPlayPhasePos - ~lastRecPhasePos) ) / (s.sampleRate); } ,
			{currentTimeOffset = (~lastRecPhasePos - ~lastPlayPhasePos)/(s.sampleRate); } //else measure offset if no wrap around has occured (will happen most of the time)
		);
		currentTimeOffset = currentTimeOffset.round(0.01);
		//("!!!currentTimeOffset=" + currentTimeOffset).postln;

		pitchCase = case
		{~pitchShiftValTarget_rate > 0} {
			if ( (currentTimeOffset <= 0.3) || (currentTimeOffset >= 6.5), { //MAINTAIN fixed PlayHead offset range BEHIND RecHead if ~pitchShiftValTarget_rate > 0 --- not too far behind, never surpassing
				newOffsetAmount = rrand(2.7, 4.0); //generate random offset amount (in seconds)
				newOffsetPos = ~lastRecPhasePos - ((newOffsetAmount * s.sampleRate).round(1)); //deduce new playPhase position based on newOffsetAmount (converted to frames)

				/*if (newOffsetPos < 0, //orig simple safe driving
				{newOffsetPos = (~audioBuf0.numFrames - 1) + newOffsetPos;} //wrap around buffer if negative position generated
				); */

				if ( (~playInFrame == 0) && (newOffsetPos < 0), { //safe driving: case 1
					newOffsetPos = ~playOutFrame + newOffsetPos; //wrap around buffer if negative position generated
					if (newOffsetPos < 0, {
						/*newOffsetPos = 0;*/ //think this could potentially cause issues if current recPos = 0 too...
						newOffsetPos = ~lastRecPhasePos + 1000;} ); //to avoid never ending loop if result is still < 0
				} );

				if ( (~playInFrame > 0) && (newOffsetPos < ~playInFrame), { //safe driving: case 2
					newOffsetPos = newOffsetPos + (~playOutFrame - ~playInFrame);
					if (newOffsetPos < ~playInFrame, {newOffsetPos = ~lastRecPhasePos + 1000;}); //to avoid never-ending loop
				} );

				~phasor_play.set(\resetPos, newOffsetPos, \trig, 1); //set new position of playPhase (move playHead)
			} );
		}
		{~pitchShiftValTarget_rate <= 0} {
			if ( (currentTimeOffset >= 6.0) || (currentTimeOffset <= 0.3),
			{//MAINTAIN fixed PlayHead offset range BEHIND RecHead if ~pitchShiftValTarget_rate <= 0 --- not too far behind, never surpassing
				newOffsetAmount = rrand(0.5, 2.75); //generate random offset amount (in seconds)
				newOffsetPos = ~lastRecPhasePos - ((newOffsetAmount * s.sampleRate).round(1)); //deduce new playPhase position based on newOffsetAmount (convert to frames)

				if ( (~playInFrame == 0) && (newOffsetPos < 0), { //safe driving: case 1
					newOffsetPos = ~playOutFrame + newOffsetPos; //wrap around buffer if negative position generated
					if (newOffsetPos < 0, {
						/*newOffsetPos = 0;*/ //think this could potentially cause issues if current recPos = 0 too...
						newOffsetPos = ~lastRecPhasePos + 1000;} ); //to avoid never ending loop if result is still < 0
				} );

				if ( (~playInFrame > 0) && (newOffsetPos < ~playInFrame), { //safe driving: case 2
					newOffsetPos = newOffsetPos + (~playOutFrame - ~playInFrame);
					if (newOffsetPos < ~playInFrame, {newOffsetPos = ~lastRecPhasePos + 1000;}); //to avoid never-ending loop
				} );

				~phasor_play.set(\resetPos, newOffsetPos, \trig, 1); //set new position of playPhase (move playHead)
			} );
		};
	} );

	2.0.yieldAndReset;
} );

//-------------- BEHAVIOR BUTTONS ------------

~button_Behavior1 = Button(w, Rect(314, 349, 55, 25)) //randomize rate control
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
			~updateGUI_counter_rateT2rand.reset;
			~updateGUI_rate.reset;
			AppClock.play(~randomRoutine_rate);
			AppClock.play(~updateGUI_counter_rateT2rand);
		},
		{ //when randomize button disabled
			~randomRoutine_rate.stop;
			~updateGUI_counter_rateT2rand.stop;
			//~playHeadFollowRecHead.stop;
			~updateGUI_rate.stop;
			~numBox_counter_rateT2rand.value_(0.0);
		}
	);
} )
.value_(0);

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
//


~button_Behavior2 = Button(w, Rect(271, 349, 40, 25)) //Randomize pitch shift, pitch shift mix, and output level control
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
			~randomRoutine_outputLevel.reset;
			//~updateGUI_counter_rateT2rand.reset;
			//~playHeadFollowRecHead.reset;
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
			//~numBox_counter_rateT2rand.value_(0.0);
		}
	);
} )
.value_(0);

~button_Behavior3 = Button(w, Rect(243, 349, 25, 25)) //randomize Reverse and PlayHead Behavior control
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


//------- SCOPE VIEW (AUDIO BUF0) ------------

~scopeView = ScopeView(w.view, Rect(15, 10, 665, 170) );
~scopeView.server_(s);
~scopeView.xZoom = 1.0;  //changing these values doesn't seem to effect display
~scopeView.x = 0;  //changing these values doesn't seem to effect display
~scopeView.yZoom = 1.0;


//PLOTTER//

/*
~bufPlot = Plotter.new("Buffer", Rect(15, 10, 665, 170), w); //CREATE PLOTTER
~bufPlot.value = 0; //initialize w/ value of 0
//~bufPlot.value = ~audioBuf0;
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
//----------

/*~phaseBusMonRec.get({|val| (val/s.sampleRate).postln;});  //junk for monitoring
~phaseBusMonRec.get({|val| val.postln;});
~phaseBusMonPly.get({|val| (val/s.sampleRate).postln;});  //<----this is where to get phasor value....
~phasor_play.get(\end, {|val| val.postln;});
~phasor_rec.get(\end, {|val| val.postln;});
~phasor_rec.get(\start, {|val| (val/s.sampleRate).postln;}); */


////---------------RECORD TO BUFFER BUTTON--------------////
~button_recBuf = Button(w, Rect(372, 349, 55, 25)) //REC BUTTON: activate / deactivate recording to buffer
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

			~a2k_rec = Synth(\a2k_patch, [\in, ~phaseBusRec, \out, ~phaseBusMonRec] ).moveAfter(~phasor_rec);

			~bufRecorder = Synth(\bufRec, [\phaseBus, ~phaseBusRec, \buf, ~audioBuf0, \sendBus, ~inputSendBus, \loCutoff, ~loCutBus_in.asMap, \mul, ~inputLevelBus.asMap] ).moveAfter(~a2k_rec);

			NodeWatcher.register(~bufRecorder); //this ensures all synths associated w/ buf play back are positioned after all these buf recording synths in the node-tree, no matter when they're created

			//~lastRecPhasePos.value.postln;

			//////////////SCOPE

			~scopeBuf_audioBuf0 = Buffer.alloc(s, ~audioBuf0.numFrames, 1); //create additional buffer for displaying contents of audio buffer...is this the only way to do this?? what happens if I 'scopeOut' to ~audioBuf0?
			~scopeView.bufnum = ~scopeBuf_audioBuf0.bufnum; //<----
			~scopeOut = Synth.tail(s, \scopeOut, [\inBus, ~inputSendBus, \buf, ~scopeBuf_audioBuf0]); //<----
			~scopeView.start; //<----
			//note to self: check out ScopeBuffer as a way to scope entire buffer

			//////////
		},
		{ //when REC button disabled (when recording stops)
			~phaseBusMonRec.get( {arg val; ~lastRecPhasePos = val;} ); //store last pos of recPhase
			~phasor_rec.free;
			~a2k_rec.free;
			~bufRecorder.free; //stop recording to buffer and free RecBuf_loop synth

			 ///FOR SCOPE
			~scopeView.stop; //<----
			~scopeOut.free; //<----
			~scopeBuf_audioBuf0.free; //<----

		}
	);
} );
//--------------

////------------ PLAY FROM BUFFER BUTTON -----------////

~button_playBuf = Button(w, Rect(430, 349, 55, 25)) //activate / deactivate playback output
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

			if (~bufRecorder.isRunning, {~phasor_play.moveAfter(~bufRecorder);}); //safer node-tree order

			~a2k_play = Synth(\a2k_patch, [\in, ~phaseBusPly, \out, ~phaseBusMonPly]).moveAfter(~phasor_play); //converting phaseBus values at ar to kr and sending to phaseBusMon so sliderPlayPos can receive current value of phasor

			~bufPlayer = Synth(\bufRead, [\amp, ~play1LevelBus.asMap, \out, ~playOut1Bus, \phaseBus, ~phaseBusPly, \buf, ~audioBuf0] ).moveAfter(~a2k_play);
			NodeWatcher.register(~bufPlayer);

			~pShift = Synth(\pitchShifter,
				[\inBus, ~playOut1Bus, \outBus, ~pitchShiftOut, \pitchRatio, ~pitchBus.asMap]).moveAfter(~bufPlayer);

			~pShiftMix = Synth(\XFade, [
			\in1, ~playOut1Bus,
			\in2, ~pitchShiftOut,
			\out, ~outMainBus,
			\amountControlBus, ~pitchShiftMixValBus.asMap,
			\amp, ~inputStreamLevelBus.asMap //<--NEW
			] ).moveAfter(~pShift);

			//~mainOut = Synth.tail(s, \mainOut, [\in, ~outMainBus, \loCutoff, ~loCutBus_out.asMap, \amp, ~outMainLevelBus.asMap]);  //<----MOVE THIS OUTTA HERE.... init on startup......
		} ,
		{
			//"-PlayBackOff-".postln;
			~phaseBusMonPly.get( {|val| ~lastPlayPhasePos = val;} );
			~phasor_play.free;
			~a2k_play.free;
			~bufPlayer.free;
			//~slider_playPos.value_(0.0);

			~pShift.free;
			~pShiftMix.free;
			//~mainOut.free;
		} );
} );

//--------REVERSE BUTTON ---------

~button_rev = Button(w, Rect(490, 349, 45, 25)) //Reverse playback
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

// ------------- REC HEAD / PLAY HEAD ----------

~slider_recPos = Slider(w, Rect(15, 212, 470, 20))
.background_(Color(0.95, 0.0, 0.0))
.action_( {
	arg obj;
	var pos;
	//pos = obj.value.linlin(0, 1, 0, ((s.sampleRate * ~audioBuf0_dur) - 1)).round(1); //convert slider value to frame
	pos = obj.value.linlin(0, 1, 0, ~audioBuf0.numFrames - 1); //convert slider value to frame
	~phasor_rec.set ( //update ~phasor_rec phasor synth position....
		\resetPos, pos,
		\trig, 1
	);
	//~numBox_recPos.value_(pos/s.sampleRate).round(0.1); //convert frames to seconds and display
	~numBox_recPos.value = (pos/s.sampleRate).round(0.01); //convert frames to seconds and display

	//SYNC functionality----------------
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
} )
.value_(0.0);

~numBox_recPos = NumberBox(w, Rect(490, 208, 75, 25)) //numBox PlayPos
.value_(0)
.clipLo_(0)
//.clipHi_(~audioBuf0_dur) //HOW COME UNCOMMENTING THIS MESSES UP THE GUI??????
.font_(Font("Monaco", 14) )
.decimals_(2);
//.action_( {
	//arg obj;
	//~slider_recPos.valueAction = obj.value / ~audioBuf0_dur; //<---
//} );

~label_recPos = StaticText(w, Rect(568, 182, 100, 80) )
.string_("RecPos(sec)")
.font_(Font("Monaco", 10) )
.align_(\left);


~slider_playPos = Slider(w, Rect(15, 237, 470, 20))
.background_(Color(0, 0.8, 0.2))
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, 0, ~audioBuf0.numFrames - 1).round(1); //convert slider value to frame
	~phasor_play.set (\resetPos, pos, \trig, 1);
	~numBox_playPos.value = (pos/s.sampleRate).round(0.01); //convert frames to seconds and display
} )
.value_(0.0);


~numBox_playPos = NumberBox(w, Rect(490, 234, 75, 25))
.value_(0)
.clipLo_(0)
//.clipHi_(~audioBuf0.numFrames-1)
.font_(Font("Monaco", 14) )
.decimals_(2);

~label_playPos = StaticText(w, Rect(568, 207, 100, 80) )
.string_("PlayPos(sec)")
.font_(Font("Monaco", 10) )
.align_(\left);

~slider_recInOut = RangeSlider(w, Rect(15, 187, 470, 20)) //SLIDER => Play In/Out
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

~numBox_recIn = NumberBox(w, Rect(490, 187, 46, 20))
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

~numBox_recOut = NumberBox(w, Rect(535, 187, 46, 20))
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

~label_recInOut = StaticText(w, Rect(582, 189, 90, 20) )
.string_("In/Out-Rec")
.font_(Font("Monaco", 10) )
.align_(\left);

~slider_playInOut = RangeSlider(w, Rect(15, 259, 470, 20)) //SLIDER => Play In/Out
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

~label_playInOut = StaticText(w, Rect(584, 259, 90, 20) )
.string_("In/Out-Play")
.font_(Font("Monaco", 10) )
.align_(\left);

~numBox_playIn = NumberBox(w, Rect(490, 260, 46, 20))
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

~numBox_playOut = NumberBox(w, Rect(535, 260, 46, 20))
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

//-----------

// ------- OTHER PLAYBACK CONTROLS ------

//RATE --
~slider_rate = Slider(w, Rect(15, 280, 470, 20))
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

~numBox_rate = NumberBox(w, Rect(490, 280, 48, 20))
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

~label_rate = StaticText(w, Rect(541, 270, 135, 40) )
.string_("Rate(semi)")
.font_(Font("Monaco", 12) )
.align_(\left);


//PITCH SHIFT --
~slider_pitch = Slider(w, Rect(15, 301, 470, 20))
.background_(Color(0.0, 0.7, 0.9))
.value_(0.linlin(-48, 24, 0.0, 1.0))
.action_( {
	arg obj;
	var pos;
	pos = obj.value.linlin(0, 1, -48, 24).round(0.01);
	~pitchBus.set(pos.midiratio);
	~numBox_pitch.value_(pos);
} );

~numBox_pitch = NumberBox(w, Rect(490, 301, 48, 20))
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

~label_pitch = StaticText(w, Rect(541, 290, 135, 40) )
.string_("Pitch(semi)")
.font_(Font("Monaco", 12) )
.align_(\left);


// PITCH SHIFT MIX --
~slider_pitchShiftMix = Slider(w, Rect(350, 322, 135, 15))
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

~numBox_pitchShiftMix = NumberBox(w, Rect(490, 322, 48, 20))
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

~label_pitchShiftMix = StaticText(w, Rect(541, 326, 135, 10) )
.string_("PitchShiftMix")
.font_(Font("Monaco", 12) )
.align_(\left);

//----------

//--------- GUI UPDATER (turn into routine?) ---------------

AppClock.sched(0.0, { //AppClock scheduler increments slider positions...
	//THIS DOUBLE APPCLOCK ENCAPS IS NECESSARY FOR SOME REASON (otherwise errors thrown)
	~phaseBusMonPly.get( {
		arg val;
		AppClock.sched(0.0, { //<--1111111BBBBBB??????????????????
			//(val / (s.sampleRate * ~audioBuf0_dur)).postln; //uncomment to view sliderPlayPos from 0-1 (debugging)
			~slider_playPos.value = val / (s.sampleRate * ~audioBuf0_dur); //update slider position
			~numBox_playPos.value = (val.round(1)/s.sampleRate).round(0.1); //convert frames to seconds and display
			nil;
		} );
	} );

	~phaseBusMonRec.get( {
		arg val;
		AppClock.sched(0.0, { //<--errors thrown w/out this but still functions properly for some reason...why?
			//(val / (s.sampleRate * ~audioBuf0_dur)).postln; //uncomment to view sliderPlayPos from 0-1
			~slider_recPos.value = val / (s.sampleRate * ~audioBuf0_dur); //update slider position
			~numBox_recPos.value = (val.round(1)/s.sampleRate).round(0.01) ; //convert frames to seconds and display

			/* PLOTTER UPDATE CODE IN PROGRESS.........<<<<<<<<<<<<!!!!!!!!!!#########!!!!!!!!!!###########!!!!!!!!

			//~audioBuf0.getToFloatArray(wait:0.01, action: {arg array; a = array; ~bufPlot.value = a; ~bufPlot.refresh;} );
			if (~button_audioBuf_0.value == 1, {
				//var bufCurrent;
				AppClock.sched(0.0, {
					~audioBuf0.get(val, {
						|bufVal|
						~bufPlot.value = (0..(~audioBuf0.numFrames - 1)).normalize(0, rrand(2,50)).sin;
						//~bufPlot.value = bufVal.(0..(~audioBuf0.numFrames - 1)).normalize;
						~bufPlot.refresh;
					} ); //<----------??????
					nil;
				} );
			} );
			//~bufPlot.value = ~audioBuf0.read;
			//~bufPlot.refresh;
			*/
			//<<<<<<<<<<<<!!!!!!!!!!#########!!!!!!!!!!###########!!!!!!!!

			nil;
		} );
	} );

	if (~button_playBuf.value == 1, {
		if (~playPosLatchTrig == true,
			{
				~phasor_play.set(\start, ~playInPosBus.asMap); //reset phasor \start to ~playInPosBus.asMap after initalizing at ~lastPlayPhasePos (permits resuming playback from last read pos in buffer when playHead still w/in play In/Out range after buff playback turned off)
				~playPosLatchTrig = false;
			} , { //else
				~phasor_play.get(\trig, { |trigval| if (trigval > 0) {~phasor_play.set(\trig, 0) ;} } ); //reset trigger val to 0 if prev triggered
			}
		);
	} );

	if (~button_recBuf.value == 1, {
		if (~recPosLatchTrig == true,
			{
				~phasor_rec.set(\start, ~recInPosBus.asMap);  //reset phasor start to ~recInPos after initially starting phasor synth (permits resuming recording from last read pos in buffer)
				~recPosLatchTrig = false;
			} ,
			{ //else
				~phasor_rec.get(\trig, { |trigval| if (trigval > 0) {~phasor_rec.set(\trig, 0) ;} } ); //reset trigger val to 0 if prev triggered
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

	//d = ~slider_recPos.value - ~slider_playPos.value; //to check jitter distance between playheads (fairly consistent)
	//d.postln;
	0.1;
});

)