//Sonic Mirror - 05_InitSM:

//== CONFIGURE & INITIALIZE SM ==

(
~init_SonicMirror = {

////GLOBAL VARIABLES
~fileAudio_writeIn_directory = "/Users/Scott/Music/SCrecs/Test/";  //<---CONFIGURE AUDIO SAMPLE FILEPATH (this will be unique to your system.....defines audio file write path)
~fileAudio_writeOut_directory = "/Users/Scott/Music/SCrecs/Test/";  //<---CONFIGURE AUDIO SAMPLE FILEPATH

~fileAudio_writeIn_fileName = "audio-in_"; //customize file name
//~fileAudio_writeIn_fileName = "Voxel-Experiment_2018-4-3_Rec_"; //<----customize file name
~fileAudio_writeOut_fileName = "audio-out_";
//~fileAudio_writeOut_fileName = "Voxel-Experiment_2018-4-3_BufSample_"; //<-----customize file name

~fileAudio_writeIn_nameNum = 0; //counter for writing/reading audio file names
~fileAudio_writeOut_nameNum = 0; //counter for writing/reading audio file names
~fileAudio_writeIn_lastPath = (~fileAudio_writeIn_directory ++ ~fileAudio_writeIn_fileName).standardizePath;
~fileAudio_writeOut_lastPath = (~fileAudio_writeOut_directory ++ ~fileAudio_writeOut_fileName).standardizePath;
~fileAudio_writeIn_lastFile = (~fileAudio_writeIn_lastPath ++ ~fileAudio_writeIn_nameNum ++ ".wav").standardizePath;
~fileAudio_writeOut_lastFile = (~fileAudio_writeOut_lastPath ++ ~fileAudio_writeOut_nameNum ++ ".wav").standardizePath;

//~fileAudio_writeIn_lastPath = "~/Music/SCrecs/SncMir/SncMir-In_"; //<---CONFIGURE AUDIO SAMPLE FILEPATH (this will be unique to your system.....defines audio input file write path)
//~fileAudio_writeOut_lastPath = "~/Music/SCrecs/SncMir/SncMir-Out_"; //<---CONFIGURE AUDIO SAMPLE FILEPATH (this will be unique to your system.....defines audio output file write path)
//~fileAudio_writeIn_lastFile = (~fileAudio_writeIn_lastPath ++ ~fileAudio_writeIn_nameNum ++ ".wav").standardizePath; //<--ORIG

~minNumFilesB4Playback = 1; // file # threshold before file playback routine commences
~fileAudio_writeIn_maxNum = 60; //max # of audio samples written per session (wrap-around & overwrite limit)
~fileAudio_writeOut_maxNum = 60;  //max # of audio out samples written per session (wrap-around & overwrite limit) <---only being used for 'recout' button. maybe not necessary???
~fileAudio_writeIn_maxNum_exceeded = false;

~sampBitDepth = "int24"; //alt = "int16"  (specify bit depth for all samples recorded)
~plotterEnabled = true; //set to false for RPi (or until I optimize plotter code, it's not efficient now.)

~audioBuf0_dur = 180.0; //<---configure main audio buffer duration in seconds   (changing here works fine, but changing bufDur w/ GUI causes errors, will fix bug later...)
~audioBuf0 = Buffer.alloc(s, s.sampleRate * ~audioBuf0_dur, 1);

~minRecDur = 1.0; //<-----min sec per recorded sample
~maxRecDur = 22.0; //<----max sec per recorded sample (shorten or don't use w/ autoRec_random)

~fileAudio_writeIn_lastFileDur; //<--------NEW (not currently being used)
~fileAudio_lastPlay; //<---NEW (not needed if using below array though)
~fileHistory_rec = Array.newClear(~fileAudio_writeIn_maxNum); //filename history of all samples recorded <--NEW
~fileHistory_play = Array.newClear(~fileAudio_writeIn_maxNum); //filename history of all samples played <--NEW

~soundMemory = []; //<-------NEW (init)
//~soundMemory = [["sound1Name", sound1timeIn, sound1timeOut, sound1dur, sus / transient, mean loudness, pitchiness, mean pitch], ["sound2Name", sound2timeIn, sound2timeOut, ....], ["sound3Name", ...], ["soundMaxNumName", ...]];


~delayTime = 1.23;
~play2recOffset; //displacement of playhead pos from rec pos (in frames/samples)

~mode_randProcLiveBuf = false; //<---NEW mode flag
~mode_autoRecPlay = false; //<---NEW mode flag

~lastPlayPhasePos = 0; //for resume functionality - stores last pos (frame) of play head before playback disabled
~lastRecPhasePos = 0; //for resume functionality - stores last pos (frame) of rec head before recording disabled
~playPosLatchTrig = false;
~recPosLatchTrig = false;
~syncRecPlayOffset = false;

~pitchShiftValPrev_rate = 0;
~pitchShiftValTarget_rate = 0;
~pitchInterp_rate = false;

~pitchShiftValPrev_freq = 0;
~pitchShiftValTarget_freq = 0;
~pitchInterp_freq = false;

~outMainLevVal_prev; //<--
~outMainLevVal_target; //<--not currently being used...could be useful in future though....
~outMainLevInterp = false; //<--not currently being monitored...

~reverseFlag = false; //currentlly using ~button_rev.value as flag, but is that a good long-term idea????
~randPlayPos_flag = false;

~time2NextRandom_rate = 0;
~time2NextRandom_freq = 0;
~time2NextRandom_pitchShiftMix = 0;

~pitchShiftMix_prev = 0;
~pitchShiftMix_target = 0; //<- not using right now
~pitchShiftMix_prevChangeTime = 0; //<-not being used
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
~inputStreamLevelBus.set(1); //<---SET TO -6db on INIT? <-----
~fileOutputLevelBus.set(1);
~outMainLevelBus.set(1);

~outMainPeakFreq_init = 1200;
~outMainPeakFreq.set(~outMainPeakFreq_init);
~outMainPeakQ_init = 1;
~outMainPeakQ.set(~outMainPeakQ_init); //technically reciprocal of Q...
~outMainPeakGain_init = 0;
~outMainPeakGain.set(~outMainPeakGain_init); //in db

~loCutVal_in = 110;
~loCutVal_out = 110;
~loCutBus_in.set(~loCutVal_in);
~loCutBus_out.set(~loCutVal_out);

~comp1thresh_init = -6.dbamp;
~comp1thresh.set(~comp1thresh_init); //<---NEW
~comp1ratio_init = 2;
~comp1ratio.set(~comp1ratio_init); //<---NEW
~comp1attack_init = 0.01;
~comp1attack.set(~comp1attack_init); //in seconds <---NEW
~comp1release_init = 0.3;
~comp1release.set(~comp1release_init ); //in seconds <---NEW
~comp1gain_init = 1;
~comp1gain.set(~comp1gain_init); //<---NEW

~phaseBusMonPly.set(0);
~phaseBusMonRec.set(0);
//-----------------

// --------- SET UP SOME INITIAL SYNTHS ------------
~mainOut = Synth.tail(s, \mainOut, [\in, ~outMainBus, \loCut, ~loCutBus_out.asMap, \loCutQ, 2, \amp, ~outMainLevelBus.asMap, \peak, ~outMainPeakFreq.asMap, \peakQ, ~outMainPeakQ.asMap, \peakGain, ~outMainPeakGain.asMap]);

~stream1 = Synth(\subMix, [\in, ~stream1sub, \out, ~outMainBus]).moveBefore(~mainOut); //<---NEW
~stream2 = Synth(\subMix, [\in, ~stream2sub, \out, ~outMainBus]).moveBefore(~mainOut); //<---NEW

//-------------------

////
Window.closeAll;
//w = Window.new("SonicMirror", Rect.new(250, 330, 780, 405))
w = Window.new("SonicMirror", Rect.new(335, 330, 818, 380), resizable: false)
.front
.alwaysOnTop_(true);

w.onClose_{s.freeAll; Buffer.freeAll(s); CmdPeriod.clearClocks; CmdPeriod.run;}; // clean up when window is closed

~view_main = CompositeView(w, Rect(3, 3, 819, 380));
~view_MainLevels = CompositeView(~view_main, Rect(625, 26, 135, 147));
~view_comp1 = CompositeView(~view_main, Rect(763, 28, 45, 100));
~view_altLevels = CompositeView(~view_main, Rect(693, 26, 68, 105));
~view_bufConfig = CompositeView(~view_main, Rect(625, 0, 160, 25));
~view_bufPlot = CompositeView(~view_main, Rect(0, 0, 620, 170)).background_(Color.gray).resize_(1);
~view_transport = CompositeView(~view_main, Rect(0, 172, 788, 95));
~view_perfButtons = CompositeView(~view_main, Rect(5, 268, 308, 52));
~view_sampButtons = CompositeView(~view_main, Rect(5, 320, 250, 45));
~view_procControls1 = CompositeView(~view_main, Rect(317, 268, 460, 65));

//---
~spec_slider_dB = ControlSpec(minval: 0.ampdb, maxval: 1.ampdb, warp: \db, default: 0, units: "dB"); //<-- NEW

//------ Main In/Out Controls (Levels & Lo-Cut) -----------

//Main Input Level --

~slider_inMainLevel = Slider(~view_MainLevels, Rect(8, 2, 15, 90)) //<---NEW
.background_(Color(0.9, 0.0, 0.0, 0.2))
//.value_(1.0)
.value_(~spec_slider_dB.unmap(0)) //<--
.action_({ |obj|
	var mapVal, val = obj.value.round(0.001);
	mapVal = ~spec_slider_dB.map(val).round(0.01); //convert linear amp to db scaling
	~inputLevelBus.set(mapVal.dbamp.round(0.001));  //set level control bus value
	~numBox_inMainLevel.value_(mapVal); //update numBox
});

~numBox_inMainLevel = NumberBox(~view_MainLevels, Rect(2, 92, 30, 15)) //<---NEW
.value_(0.0)
.clipLo_(-inf)
.clipHi_(0.0)
.decimals_(1)
.scroll_step_(0.1)
.font_(Font("Monaco", 8) )
.align_(\center)
.action_({|obj|
	var mapVal, val = obj.value.round(0.1);
	mapVal = ~spec_slider_db.unmap(val); //convert db num into linear amp scaling
	~inputLevelBus.set(mapVal.round(0.001));
	~slider_inMainLevel.value_(mapVal.round(0.01));
});

~label_inMainLevel = StaticText(~view_MainLevels, Rect(10, 103, 12, 20) )
.string_("IN")
.font_(Font("Monaco", 10) )
.align_(\center);

//Main Out Level --
~slider_outMainLevel = Slider(~view_MainLevels, Rect(40, 2, 15, 90) )
.background_(Color(0.0, 0.8, 0.2, 0.01))
//.value_(1.0)
.value_(~spec_slider_dB.unmap(0)) //<--
.action_( {|obj|
	var mapVal, val = obj.value.round(0.001);
	mapVal = ~spec_slider_dB.map(val).round(0.01); //convert linear amp to db scaling
	~outMainLevelBus.set(mapVal.dbamp.round(0.001)); //set level control bus value
	~numBox_outMainLevel.value_(mapVal); //update numBox
} );

~numBox_outMainLevel = NumberBox(~view_MainLevels, Rect(34, 92, 30, 15))
.value_(0.0)
.clipLo_(-inf)
.clipHi_(0.0)
.decimals_(1)
.scroll_step_(0.01)
.font_(Font("Monaco", 8) )
.align_(\center)
.action_( {|obj|
	var mapVal, val = obj.value.round(0.1);
	mapVal = ~spec_slider_db.unmap(val); //convert db num into linear amp scaling
	~outMainLevelBus.set(mapVal.round(0.001));
	~slider_outMainLevel.value_(mapVal.round(0.01));
} );

~label_outMainLevel = StaticText(~view_MainLevels, Rect(37, 103, 20, 20) )
.string_("OUT")
.font_(Font("Monaco", 10) )
.align_(\center);

//Main In / Out Lo-Cuts --
~numBox_inMainLoCut = NumberBox(~view_MainLevels, Rect(2, 120, 30, 14))//<---
.value_(~loCutVal_in)
.clipLo_(20)
.clipHi_(20000)
.font_(Font("Monaco", 8) )
.decimals_(1)
.action_( {
	arg obj;
	~loCutVal_in = obj.value.round(0.01);
	~loCutBus_in.set(~loCutVal_in);
	//~loCutBus_in.setSynchronous([~loCutVal_in]); //??????? for synchronous control? is this better?
	("***LoCutFreq_in=" ++ ~loCutVal_in ++ "Hz").postln;
} );

~numBox_outMainLoCut= NumberBox(~view_MainLevels, Rect(32, 120, 30, 14))//<---
.value_(~loCutVal_out)
.clipLo_(20)
.clipHi_(20000)
.font_(Font("Monaco", 8) )
.decimals_(1)
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

//Master Out Peak EQ	 --
~label_peakEQ = StaticText(~view_MainLevels, Rect(101, 106, 25, 38) )//<---
.string_("db
Peak
Q")
.font_(Font("Monaco", 10) )
.align_(\left);

~numBox_outMainPeak= NumberBox(~view_MainLevels, Rect(68, 118, 30, 14))//<--- NEW
.value_(~outMainPeakFreq_init)
.clipLo_(40)
.clipHi_(15000)
.font_(Font("Monaco", 8) )
.decimals_(0)
.align_(\center)
.action_({
	arg obj;
	~outMainPeakFreq.setSynchronous(obj.value.round(1));
});

~numBox_outMainPeakGain= NumberBox(~view_MainLevels, Rect(65, 104, 35, 14))//<--- NEW
.value_(~outMainPeakGain_init)
.clipLo_(-inf)
.clipHi_(12)
.font_(Font("Monaco", 8) )
.decimals_(2)
.align_(\center)
.action_({
	arg obj;
	~outMainPeakGain.setSynchronous(obj.value.round(0.01));
});

~numBox_outMainPeakQ = NumberBox(~view_MainLevels, Rect(68, 132, 30, 14))
.value_(~outMainPeakQ_init)
.clipLo_(0.1)
.clipHi_(100)
.font_(Font("Monaco", 8) )
.decimals_(1)
.align_(\center)
.action_( {
	arg obj;
	~outMainPeakQ.setSynchronous(obj.value.round(0.1));
} );


//Master Out Compressor --
~numBox_comp1thresh = NumberBox(~view_comp1, Rect(1, 1, 30, 14))//<--- NEW
.value_(~comp1thresh_init.ampdb.round(0.1)) //display db
.clipLo_(-inf)
.clipHi_(0)
.font_(Font("Monaco", 8) )
.scroll_step_(0.1)
.decimals_(1)
.align_(\center)
.action_({|obj|
	~comp1thresh.setSynchronous(obj.value.round(0.1).dbamp); //convert from db to linear amp before set cont bus
} );

~numBox_comp1ratio = NumberBox(~view_comp1, Rect(1, 15, 30, 14))//<--- NEW
.value_(~comp1ratio_init)
.clipLo_(1)
.clipHi_(20)
.font_(Font("Monaco", 8) )
.scroll_step_(0.1)
.decimals_(1)
.align_(\center)
.action_({|obj|
	~comp1ratio.setSynchronous(obj.value.round(0.1));
} );

~numBox_comp1attack = NumberBox(~view_comp1, Rect(1, 29, 30, 14))//<--- NEW
.value_((~comp1attack_init * 1000).round(1)) //displaying ms
.clipLo_(0)
.clipHi_(2000)
.font_(Font("Monaco", 8) )
.scroll_step_(1)
.decimals_(0)
.align_(\center)
.action_({|obj|
	var val = (obj.value/1000).round(0.001); //convert from ms to seconds
	~comp1attack.setSynchronous(val);
});

~numBox_comp1release = NumberBox(~view_comp1, Rect(1, 43, 30, 14))//<--- NEW
.value_((~comp1release_init * 1000).round(1)) //displaying ms
.clipLo_(0)
.clipHi_(2000)
.font_(Font("Monaco", 8) )
.scroll_step_(1)
.decimals_(0)
.align_(\center)
.action_({|obj|
	var val = (obj.value/1000).round(0.001); //convert from ms to seconds
	~comp1release.setSynchronous(val);
});

~numBox_comp1gain = NumberBox(~view_comp1, Rect(1, 57, 30, 14))//<--- NEW
.value_(~comp1gain_init.ampdb.round(0.1)) //display db
.clipLo_(-inf)
.clipHi_(6)
.font_(Font("Monaco", 8) )
.scroll_step_(0.5)
.decimals_(1)
.align_(\center)
.action_({|obj|
	var val = obj.value.round(0.1);
	if (val <= -80, {
		val = -inf;
		~numBox_comp1gain.value = -inf;
	});
	~comp1gain.setSynchronous(val.dbamp); //convert from db to linear amp before set cont bus
});

~label_comp1 = StaticText(~view_comp1, Rect(32, 1, 25, 68) )//<---
.string_("TH
:1
AT
RL
dB")
.font_(Font("Monaco", 10) )
.align_(\left);

~button_comp1 = Button(~view_comp1, Rect(0, 72, 33, 17)) //randomize rate and pitchShift over time
.states_( [
	["COMP", Color.black, Color(0.7, 0.3, 0.7, 0.3)] ,
	["COMP", Color.white, Color(0.8, 0.3, 0.8)]
] )
.font_(Font("Monaco", 12) )
.action_( {
	arg obj;
	if (
		obj.value == 1,
		{
			~comp1 = Synth(\comp1, [\bus, ~outMainBus, \thresh, ~comp1thresh.asMap, \ratio, ~comp1ratio.asMap, \attack, ~comp1attack.asMap, \release, ~comp1release.asMap, \amp, ~comp1gain.asMap]).moveBefore(~mainOut);
		},
		{
			~comp1.free;
		}
	);
} )
.value_(0);

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
			~recOutFrame = ~audioBuf0_dur * s.sampleRate - 1;
			~recOutPosBus.set(~recOutFrame);
			~playOutFrame = ~audioBuf0_dur * s.sampleRate - 1;
			~playOutPosBus.set(~playOutFrame);
		} , //else
		{~audioBuf0.close; ~audioBuf0.free;} //free(erase) buffer
	);
} );

~numBox_audioBuf0_dur = NumberBox(~view_bufConfig, Rect(67, 0, 65, 25))
.value_(~audioBuf0_dur)
.clipLo_(10) //smallest possible length of buffer (in seconds)
.clipHi_(300) //longest possible length of buffer (in seconds)
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

//--put these variables back w/ the rest of env variables above at some point--
~playBehavior = 0; //stores state of playback behavior, not currently being used....

~currentSound = "silence"; //state of current heard sound (0 = silence, 1 = unpitched sound, 2 = pitched sound...?)
~currentScene = "quiet"; //sound scene index (0 = quiet, 1 = sparse transient sounds, 2 = drone, 3 = noise.........?)

~playSamp = false; //<--- flag:  playing audio file from disk
~playAudify = false; //flag: audify sound routine active...  <---NEW
~trigAudify = false; //flag: tracks whether or not audifyScene routine just triggered... <----NEW

//---
~listenDur_noiseFloor = 5.0; //<---not currently being used....
/*~senseNoiseFloor = Routine.new( {
	//sets ~loudnessThresh
} );  */

//~hearFeedback = false;
//~fdbackDetect = false;
~input_loud = 0; //consider integer scale: 0 = < min thresh | 1 = > lowThresh, < uprThresh, 2 = > uprThres
~input_loudSus = false;
~listen_input_loudness = false; //flag indicating activity of loudness monitoring function (active / disabled)

~hearSound = false;
~listening = false;  //flag indicates audio analysis activity

~recSamp_input = false;
~recSamp_output = false;
~recSamp_input_startFrame = 0;
~recSamp_input_stopFrame = 0;

//------- env variables and functions (routines) for ~autoRec_soundTrigAuto

~loudnessThresh = 5; //in sones - used by ~autoRec_soundTrigAuto routine
~pitchThresh = 0.55; //pitch ratio measure - used by ~autoRec_soundTrigAuto routine

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


//AUTO REC / AUTO PLAY ROUTINES (soundTrigAuto)----------

~autoPlay_soundTrigAuto = {|post = 0| //<----NEW W/ PCONV
	Routine({
		if (~playSamp == true,
			{ //if already playing sound file, we can assume it's completed by the time this routine has stopped yielding based on commands when ~playSamp == false (see below code in 'else' of this conditional)...
				if (~playAudify == true, { //check flag to see if audification in progress <----NEW
					if (post == 1, {">>>>AUDIFY IN PROGRESS...<<<<".postln;});
					0.2.yieldAndReset;
				}, { //else if ~playAudify == false
					if (post == 1, {">>>>NO AUDIFICATION IN PROGRESS...<<<<".postln;});

					// if ~auto_partConvSamplesAutoLoop_StatusFlag == true {~partConv_samples_autoLoop.(0...)};

					~playSamp = false;
					~time_lastPlay_stop = Main.elapsedTime.round(0.001); //log sample playback stop time
					if (~trigAudify == true, //<---NEW (avoids error caused by freeing nonexistant ~audioBuf_play0 after ~audifyRout plays...
						{~trigAudify = false;},
						{if (~audioBuf_play0.bufnum != nil, {~audioBuf_play0.free;});} //only free buf if it exists <---NEW, similarly, this avoids error caused by freeing nonexistant buffer when other routines like autoPConv, etc. have operated instead of regular buffer processing effects....
					);


					{~button_playSamp.value = 0;}.defer; //update GUI button
					~autoRecPlay_state = 0; // (cycle state to trigger ~autoRec before next ~autoPlay)
					0.2.yieldAndReset;
				});
			},
			{//if not playing a soundFile or autoRecording...
				if (((~recSamp_input == false) && (~autoRecPlay_state == 1)), //only play back sounds if not recording...
					{
						//PLAYBACK AUDIO FILE FROM DISK
						var interpSynth, fileDir, file, duration, temp, /*rate, pitch, mix,*/ currentTime;

						//<---***CONDITION CHECKING TRIGGERING SAMPLE PLAYBACK GOES HERE****----
						//---e.g. routines checking machine listening ugen output control busses...

						~playSamp = true; //set flag

						//vvvvvv ---- make this into a reusable function for audio file playback ---- vvvvvv

						//>-----FILE SELECTION CONDITIONS --- (basics implemented, could be refined)
						///-----vvvvvvv---------NEW--------vvvvvv---------///////
						currentTime = Main.elapsedTime.round(0.001);
						if (currentTime <= (~time_lastRec_stop + 5),
							{//if just recorded new sound, play last recorded sound
								if (post == 1, {"---SOUND JUST RECORDED - PLAYING LAST SOUND".postln;});
								fileDir = ~fileAudio_writeIn_lastFile;
							},
							{//else if it's been awhile since last recorded sound
								var playCase, randNum = rrand(1.0, 10.0).round(0.01);
								if (post == 1, {"---LAST SOUND RECORDED > 5 SECONDS AGO....".postln;});

								playCase = case
								//{randNum == 0} {
								{randNum <= 7} { //70% of time, play last recorded file
									fileDir = ~fileAudio_writeIn_lastFile;
									if (post == 1, {("---->PLAYING LAST REC FILE (70%):" + ~fileAudio_writeIn_lastFile).postln;});
								}
								//{randNum == 0} {
								//{randNum <= 10} {
								{randNum > 7 && randNum <= 8.5} {//15% of time play recent rec file
									if (post == 1, {"---->PLAYING RECENT REC FILE (20%)".post;});
									if (0.75.coin == true,
										{//play second to last rec file
											fileDir = ~fileHistory_rec[1];
											if (post == 1, {" | second-to-last | ".post;});
										},
										{fileDir = ~fileHistory_rec[2];
											//" | third-to-last | ".post;
										} //or play third to last rec file
									);
									if (fileDir == nil, {//safe driving
										fileDir = ~fileAudio_writeIn_lastFile;
										if (post == 1, {".....safe-driving...playing last rec file".postln;});
									});
									if (post == 1, {("FILE:" + ~returnFileNameFromPath.(fileDir)).postln;});
								}
								//{randNum == 0} {
								{randNum > 8.5 && randNum <= 9} { //5% of time play older or random file....
									if (post == 1, {("---->PLAYING OLDER / RAND FILE (5%):").postln;});
									if (~fileAudio_writeIn_maxNum_exceeded == false,
										{
											var fileNum;
											if (post == 1, {("-----maxNumFiles NOT EXCEEDED-----").postln;});
											if (~fileAudio_writeIn_nameNum >= ~fileHistory_rec.size, //if rec mem is full
												{
													if (0.5.coin == true,
														{fileDir = ~fileHistory_rec[~fileHistory_rec.size - 1]}, //select oldest file in rec mem
														{fileDir = ~fileHistory_rec[~fileHistory_rec.size - 2]} //or select second-oldest file in rec mem
													);
													if (post == 1, {("---->REC MEM FULL - Playing:" + ~returnFileNameFromPath.(fileDir)).postln;});
												},
												{//else if rec mem is not full
													fileDir = ~fileHistory_rec[~fileAudio_writeIn_nameNum - 1]; //select older file...
													if (post == 1, {("---->REC MEM NOT FULL - Playing:" + ~returnFileNameFromPath.(fileDir)).postln;});
												}
											);
											if (fileDir == nil, {//safe driving
												fileDir = ~fileAudio_writeIn_lastFile;
												if (post == 1, {".....safe-driving...playing last rec file".postln;});
											});
										},
										{ //else if max files written > maxNum limit
											if (post == 1, {("-----maxNumFiles EXCEEDED-----").postln;});
											if (0.5.coin == true,
												{//play oldest or second-oldest file in rec mem
													if (0.5.coin == true,
														{
															fileDir = ~fileHistory_rec[~fileHistory_rec.size - 1]; //oldest file in rec mem
															if (post == 1, {("----> Playing OLDEST file in recMem:" + ~returnFileNameFromPath.(fileDir)).postln;});
														},
														{
															fileDir = ~fileHistory_rec[~fileHistory_rec.size - 2]; //second-oldest file in rMem
															if (post == 1, {("----> Playing SECOND OLDEST file in recMem:" + ~returnFileNameFromPath.(fileDir)).postln;});
														}
													);
												},
												{
													var randFile, selectFile;
													if (post == 1, {"---->RANDOM FILE SELECTION ----->".postln;});
													randFile = rrand(0, (~fileAudio_writeIn_maxNum - 1)).round(1);
													fileDir = (~fileAudio_writeIn_lastPath++randFile++".wav").standardizePath;
													if (post == 1, {("-----> PLAYING:" + ~returnFileNameFromPath.(fileDir)).postln;});
													/*selectFile = (~fileAudio_writeIn_lastPath++randFile++".wav").standardizePath;
													if (selectFile == ~fileHistory_rec[0], {
													"-----Selected File == last REC file...picking oldest file----".postln;

													}, {

													}); */
												}
											);
											if (fileDir == nil, {//safe driving
												fileDir = ~fileAudio_writeIn_lastFile;
												if (post == 1, {".....safe-driving...playing last rec file".postln;});
											});
										}
									);
								} //;
								//{randNum == 0} {
								//{randNum <= 10} {
								{randNum > 9} { //10% of time audify sound scene... <---NEW
									var fileNum, rate, cycle = 1;
									~trigAudify = true;
									if (~fileAudio_writeIn_maxNum_exceeded == false,
										{
											if (post == 1, {"[AUDIFY] -- files < maxNum: ".post;});
											fileNum = ~fileAudio_writeIn_nameNum;
											if (fileNum <= 15,
												{
													rate = rrand(12.0, 24.0).round(0.01);
													if (fileNum <= 6, {cycle = 2;});
													if (post == 1, {
														"fileNum <= 15 | ".post;
														("rate =" + rate).post;
														(" | cycle =" + cycle).postln;
													});
												},
												{
													rate = rrand(24.0, 36.0).round(0.01);
													if (post == 1, {
														"fileNum > 15 | ".post;
														("rate =" + rate).postln;
													});
												}
											);
											//~audifyRout = ~audifyScene1.(~fileAudio_writeIn_lastPath, ampBus: ~fileOutputLevelBus.asMap, outBus: ~outMainBus, fileNum: fileNum, cycle: cycle, rate: rate, pitch: rate.neg, status: \playAudify);
											~audifyRout = ~audifyScene1.(~fileAudio_writeIn_lastPath, ampBus: ~fileOutputLevelBus.asMap, outBus: ~stream2sub, fileNum: fileNum, cycle: cycle, rate: rate, pitch: rate.neg, status: \playAudify); //<---NEW outBus
										},
										{ //else if we have maximum # of samples saved...
											rate = rrand(28.0, 36.0).round(0.01);
											fileNum = ~fileAudio_writeIn_maxNum;
											//~audifyRout = ~audifyScene1.(~fileAudio_writeIn_lastPath, ampBus: ~fileOutputLevelBus.asMap, outBus: ~outMainBus, fileNum: fileNum, cycle: cycle, rate: rate, pitch: rate.neg, status: \playAudify);
											~audifyRout = ~audifyScene1.(~fileAudio_writeIn_lastPath, ampBus: ~fileOutputLevelBus.asMap, outBus: ~stream2sub, fileNum: fileNum, cycle: cycle, rate: rate, pitch: rate.neg, status: \playAudify); //<---NEW outBus
											if (post == 1, {"[AUDIFY] -- filesMax Exceeded: ".post; (" rate =" + rate).postln;});
										}
									);
									if (post == 1, {"[AUDIFY] -- STARTING... ".post;});
									SystemClock.play(~audifyRout);
									2.yieldAndReset;
								};

								//<--------ADD PCONV ROUTINE HERE? or just below? 10 - 15 - 25%??
							}
						);
						///-----^^^^^^^---------NEW--------^^^^^^^---------///////

						//fileDir = ~fileAudio_writeIn_lastFile; //<-------orig

						//OR ADD PCONV HERE AS PART OF LARGER CONDITIONAL W/ BELOW...... <---------
						if ((0.25.coin == true) && (~fileHistory_rec[1] != nil), //25% chance, and if recorded >= 2 samples
							{//PERFORM PCONV
								var target, ir, temp, attTime = 0.5, susTime = 3, relTime = 2.3, dur, rate = 1, pitch = 1, pitchMix = 0, transp, transpCase;

								if (post == 1, {"=== PCONV SELECTED ===".postln;});

								target = fileDir; //assign target and ir file paths
								if (target != ~fileHistory_rec[1],
									{ir = ~fileHistory_rec[1];}, //if target isn't 2nd-to-last rec, use 2nd-to-last rec as ir
									{//if target == ~fileHistory_rec[1] ...a.k.a. 2nd-to-last rec, use last rec or a random one for ir
										if (0.5.coin == true, {ir = ~fileHistory_rec[0];}, //50% chance use last rec as ir
											{//else pick random file to use for ir
												if (~fileAudio_writeIn_maxNum_exceeded == true,
													{ir = ~fileHistory_rec[rrand(2, (~fileAudio_writeIn_maxNum - 1))];},
													{//if we haven't written more than maxNum of permitted audio files, we gotta be careful to not select an invalid file path....
														ir = ~fileHistory_rec[rrand(2, (~fileAudio_writeIn_maxNum - 1))];
														if (ir == nil, {ir = ~fileHistory_rec[0];}); //use last rec as ir, in case no file picked (lazy method for now....)
													}
												);
											}
										);
									}
								);

								transp = rrand(1.0, 10.0).round(0.01);
								transpCase = case
								{transp <= 5} {//50% no transposition
									if (post == 1, {"[autoPconv] NO TRANSP".postln;});
								}
								{transp > 5 && transp <= 7.5} {//25% slight transposition
									if (post == 1, {"[autoPconv] slight TRANSP".postln;});

									if (0.5.coin == true, //increase rate
										{rate = rrand(2.0, 7.0).round(0.01);},
										{rate = rrand(-2.0, -7.0).round(0.01);} //else decrease rate
									);

									if (0.5.coin == true, { //50% of time also engage pitch shifting
										if (0.33.coin == true, //adjust pitch
											{pitch = (rate * (-1)).midiratio;}, //33% pitch exact inverse to rate
											{//66% else pitch transp inverse + offset to rate
												if (rate > 0,
													{pitch = rrand(-12.0, -2.0).round(0.01).midiratio;},
													{pitch = rrand(2.0, 12.0).round(0.01).midiratio;}
												);
											}
										);
										if (0.7.coin == true, //adjust pitch mix
											{pitchMix = 1;}, //70% chance, set pitchMix to 100%
											{pitchMix = rrand(0.5, 0.75).round(0.01);} //30% chance, set pitchMix 50 - 75%
										);
									});
								}
								{transp > 7.5} {//25% extreme transposition
									if (post == 1, {"[autoPconv] EXTREME TRANSP".postln;});
									if (0.5.coin == true, //50% increase rate
										{rate = rrand(5.0, 24.0).round(0.01);},
										{rate = rrand(-24.0, -5.0).round(0.01);} //50% else decrease rate
									);

									if (0.5.coin == true, { //50% of time also engage pitch shifting
										if (0.33.coin == true, //adjust pitch
											{pitch = (rate * (-1)).midiratio;}, //33% pitch exact inverse to rate
											{//66% else pitch transp inverse + offset to rate
												if (rate > 0,
													{pitch = rrand(-12.0, -2.0).round(0.01).midiratio;},
													{pitch = rrand(2.0, 12.0).round(0.01).midiratio;}
												);
											}
										);
										if (0.7.coin == true, //adjust pitch mix
											{pitchMix = 1;}, //70% chance, set pitchMix to 100%
											{pitchMix = rrand(0.5, 0.75).round(0.01);} //30% chance, set pitchMix 50 - 75%
										);
									});
								};
								rate = rate.midiratio;
								susTime = rrand(3.5, 7.75).round(0.01); //pick susTime
								dur = attTime + susTime + relTime; //calc total duration

								~partConv_samples_autoLoop.(1, post: post, targetFile: target, irFile: ir, targetBuf: \pcs_tBuf1, irBuf: \pcs_irBuf1, fftSize: 2048, routine: \pcs_rout1, synth: \pcs_syn1, ampBus: ~fileOutputLevelBus.asMap, ampLimit: 0.3, outBus: ~stream2sub, attTime: attTime, susTime: susTime, relTime: relTime, playRate: rate, pitch: pitch, pShiftMix: pitchMix, winSize: 0.1, pitchDisp: 0, timeDisp: 0.003);

								~time_lastPlay_start = Main.elapsedTime.round(0.001); //log sample play start time
								~fileAudio_lastPlay = fileDir;
								temp = ~fileHistory_play.shift(1, fileDir);
								~fileHistory_play = temp;
								{~button_playSamp.value = 1;}.defer; //update GUI

								if (post == 1, {("[autoPconv] PLAYING BACK PCONV SAMPLES: target=" + ~returnFileNameFromPath.(target) + "| IR=" + ~returnFileNameFromPath.(ir)).postln;});
								if (post == 1, {("[autoPconv] rate =" + rate + "| pitch =" + pitch + "| pitchMix =" + pitchMix + "|dur =" + dur).postln;});

								(dur + 0.1).yieldAndReset;
							},
							{//PLAY SOUND FILE FROM DISK....
								~audioBuf_play0 = Buffer.read(s, fileDir, action: {arg buffer;
									var rand, procSelect;
									//duration = buffer.numFrames/s.sampleRate;
									duration = buffer.numFrames/buffer.sampleRate; //<--orig

									//EVENTUALLY consider selecting proc behaviors based on features of analyzed audio <<<<
									rand = rrand(1.0, 10.0);

									procSelect = case
									//{rand == 0} {
									{rand <= 6.5} {//65% chance //<---RESET TO THIS
										if (post == 1, {"==randAudify==".postln;});
										//duration = ~sample_randAudify.value(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus, outBus: ~outMainBus, post: post);
										duration = ~sample_randAudify.value(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus.asMap, outBus: ~stream2sub, post: post); //<---NEW outBus
									}
									//{rand <= 10} {
									{rand > 6.5} {
										//{rand > 6.5 && rand <= 8.7} {//22% chance of modulated playback //<---RESET TO THIS
										//vvv--------NEW ----vvvvv
										if (duration <= 2, {//if short dur sound detected
											duration = ~trigRand_bufPlay_rateLFOsine.(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus.asMap, outBus: ~stream2sub, shortDurThresh: 2, loopDurMin: 3.0, loopDurMax: 6.0, post: post);
											//duration = duration + 0.1; //some padding to see if missing buffer errors stop....
										}, {//else if med - long dur sound > 2 seconds
											var randSel, randCase;
											randSel = rrand(1.0, 10.0).round(0.01);

											randCase = case
											{randSel <= 5} {//50% chance
												~trigRand_sineSineMod_bufPlay.(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus.asMap, outBus: ~stream2sub, shortDurThresh: 2, post: post); //triggers synth based on sound duration and random probs, also return mod duration when looping short sounds
											}
											{randSel > 5 && randSel <= 7} {//20% chance
												~trigRand_noiseSineMod_bufPlay.(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus.asMap, outBus: ~stream2sub, shortDurThresh: 2, post: post);
											}
											{randSel > 7} {//30% chance
												//noiseNoiseMod
												~trigRand_noise3Mod_bufPlay.(buffer: buffer, duration: duration, ampBus: ~fileOutputLevelBus.asMap, outBus: ~stream2sub, post: post);
											};
										});
										//^^^^--------NEW --------^^^^
									};

									//NodeWatcher.register(~samp0);
									~time_lastPlay_start = Main.elapsedTime.round(0.001); //log sample play start time
									if (post == 1, {("PLAYING BACK FILE:" + fileDir).postln;});

									~fileAudio_lastPlay = fileDir; //<---NEW - to keep track of last played sample (not needed if using below array for playback memory)

									temp = ~fileHistory_play.shift(1, fileDir); //<---NEW - longer-term playback memory
									~fileHistory_play = temp; //<---NEW - longer-term playback memory
								});

								{~button_playSamp.value = 1;}.defer; //update GUI
								if (post == 1, {("Pre-yield samp Dur = " ++ duration).postln;});

								s.sync; //<------USING THIS INSTEAD OF YIELD, FIXES RPI ISSUE AND NO MORE NEED FOR YIELD!!

								if (post == 1, {("Post-yield samp Dur = " ++ duration).postln;});

								(duration + 0.02).round(0.01).yieldAndReset; //<--maybe not necessary to add more time
								//---------- ^^^^^^^^^^^^^^^^^^^ ---------------------------
							}
						);
					},
					{0.25.yieldAndReset;} //else if (~recSoundInput == true)
				);
			}
		);
	});
};

~autoRec_soundTrigAuto =  {|featureBus, rate = 0.1, debounceDur = 0.5, post = 0|
	Routine( {
		if (~recSamp_input == true,
			{
				// add if (~listening == true, {  }); <---yes or no?
				var currentTime = Main.elapsedTime.round(0.001);
				if (currentTime <= ~time_minRec,
					{
						if (post == 1, {
							("----------").postln;
							("RECORDING.....").postln;
							("currentTime:" + currentTime + "< ~time_minRec:" + ~time_minRec).postln;
						});
					},
					{
						featureBus.get({|val| //get sum bus "lop" - 4 features: [Loudness, Onset, Freq, Pitch Measure]
							if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
								{//SOUND DETECTED
									~hearSound = true;
									//CONTINUE RECORDING / DO NOTHING....
									if (post == 1, {
										("-----=======-----").postln;
										("**Recording... SOUND DETECTED").postln;
										("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
									});

									//anti-troll / runaway recording measure...
									if (currentTime >= ~time_recTimeOut, //terminate recording if we've exceeded recTimeOut
										{
											if (post == 1, {("===MAX RECORD DUR EXCEEDED - STOP RECORDING===" ).postln;});
											~recSamp_input_stopFrame = ~lastRecPhasePos;
											~writeSampFromBufCopy_input.(); //sets GUI and ~recSamp_input = false
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
													if (post == 1, {
														("--------++++++++-------").postln;
														("**Recording... SOUND STOP CONFIRMED").postln;
														("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
													});
													~writeSampFromBufCopy_input.value(); //sets GUI and ~recSamp_input = false

													~autoRecPlay_state = 1; //advance state to trigger ~autoPlay before next ~autoRec
													if (post == 1, {
														("~autoRecPlay_state = 1 | ~autoPlay ONLY").postln;
														("---.....---").postln;
													});

													//Analyze written audio file for features (avg loudness, pitchiness, MFCCs, etc)
													//Add sound file's extracted feature summary to a ~soundMemory buffer for future analysis and behavior triggering based on past history of sound events...
												},
												{//if currentTime < ~time_listenTimeOut....sound may not have stopped yet....
													if (post == 1, {
														("----").postln;
														("**Testing for sound stop...** - Current Time:" + currentTime).postln;
														("---Terminate Test at:" + ~time_listenTimeOut).postln;
													});
												}
											);
										},
										{//else if ~hearSound == true (test to make sure sound has stopped but continue recording)
											//~time_listenTimeOut = ~listenDur_intraSound + Main.elapsedTime.round(0.001);
											~time_listenTimeOut = ~listenDur_intraSound + currentTime; //<---
											if (post == 1, {
												("-------").postln;
												("**Recording...SOUND STOP? ... Testing until: " + ~time_listenTimeOut).postln;
												("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
											});

											//GET recHead phasor position and log "STOP  SAMPLE TIME"
											~phaseBusMonRec.get({|val|
												~recSamp_input_stopFrame = (val - (~postRecSnip * s.sampleRate)).round(1);
												if (~recSamp_input_stopFrame < 0, { //if presumed stopFrame is negative...
													~recSamp_input_stopFrame = ~audioBuf0.numFrames + ~recSamp_input_stopFrame; //wrap around buffer and log sound stop frame
												} );
												if (post == 1, {("--Sound Stop (in get) = " ++ (~recSamp_input_stopFrame / s.sampleRate)).postln;});

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
									if (post == 1, {("Debounce =" + debounceDur + "sec").postln;});
									debounceDur.yield;
								});

								//GET SUM BUS
								featureBus.get({|val|  //<----- MOVE THIS TO ~listen_sound function?  < -----<--!!!!
									if (( (val[0] >= ~loudnessThresh) || (val[1] == 1) || (val[3] >= ~pitchThresh) ),
										{//SOUND DETECTED
											if (post == 1, {
												("---").postln;
												("**HEAR SOUND**").postln;
												("Ldns-Onst-PitchM = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
											});

											if (~hearSound == false, //TEST SOUND START...
												{
													~phaseBusMonRec.get({|val| //log recHead pos
														~recSamp_input_startFrame = (val - (~preRecDur * s.sampleRate)).round(1);
														if (~recSamp_input_startFrame < 0, { //if startFrame is negative...
															~recSamp_input_startFrame = ~audioBuf0.numFrames + ~recSamp_input_startFrame; //wrap around buffer and log sound start frame
														});
														if (post == 1, {
															("---------").postln;
															("--> Sound START?: " ++( ~recSamp_input_startFrame/s.sampleRate)).postln;
														});
														~hearSound = true; //<--- moved inside get
													});
												},
												{//else ~hearSound == true
													var currentTime = Main.elapsedTime.round(0.001);
													~time_minRec = currentTime + ~minRecDur; //minimum time to stop recording

													~time_lastRec_start = currentTime - rate; //<---NEW - subtract rate b/c sound detected in previous cycle of routine
													~time_recTimeOut = ~time_lastRec_start + ~maxRecDur; //<--NEW - prevent runaway recordings and trolls

													if (post == 1, {
														("- - - - -").postln;
														("--> Sound START CONFIRMED:" + ( ~recSamp_input_startFrame/s.sampleRate)).postln;
														("--REC Sample Start").postln;
													});
													~recSamp_input = true; //causes us to LEAVE THIS SIDE OF ROUTINE
													{~button_recIn.value = 1;}.defer;
												}
											);
										},
										{//if NO SOUND DETECTED ........
											if (post == 1, {
												("--- NO SOUND ---").postln;
												("Ldns-Onst-pitMsr = [" ++ val[0] ++ ", " ++ val[1] ++ ", " ++ val[3] ++ "]").postln;
											});
											if (~hearSound == true,
												{
													~hearSound = false;
													if (post == 1, {("--> ...false alarm?...").postln;});
												},
												{ //else if ~hearSound == false
													if (post == 1, {("-->...silence...").postln;});

													if (~fileHistory_play[0] != nil, {//if recorded & played @ least 1 sound
														var currentTime = Main.elapsedTime.round(0.001);
														if (currentTime >= (~time_lastPlay_stop + ~listenDur_soundPatience),
															{
																~autoRecPlay_state = 1;
																//adjust ~listenDur_soundPatience based on timespan since ~time_lastRec_stop; ? <--------CONSIDER DOING THIS ----------------<<<<<<<<<<
																~listenDur_soundPatience = rrand(6.0, 20.0).round(0.01); //temporary
																//~listenDur_soundPatience = 3; //for testing
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

/*
s.plotTree;

//RMSdb >= -10 to -6 == strong clipping and apparent feedback <-----
//RMSdb >= -15 to -12 == light clipping...

~listen_loudness.(active: 1,
	input: ~inputSendBus,
	outBus: \bus_inputdb,
	featSynth: \rms1,
	loudFlag: \inputSendLoud,
	loudSusFlag: \inputSendLoudSus,
	lowThresh: -35, uprThresh: -15, threshDur: 1,
	//lowThresh: -45, uprThresh: -25, threshDur: 1,
	lastThreshTime: \inputSendThreshTime,
	monRoutine: \inputSendMon,
	rate: 0.5,
	post: 1
);

~smoothBusOutputKR.(active: 1, inBus: ~bus_inputdb, outBus: \smoothBus_inputdb, synth: \smooth_inputdb, synthMoveAfter: ~rms1, avgDur: 6);

~smoothBus_inputdb.getSynchronous;

~updateFeatureMemory.(active: 1, featureBus: ~smoothBus_inputdb, array: \mem_inputdb, arraySize: 10, routine: \updateMem_inputdb, rate: 6, post: 1, postLabel: "==> MEM_inputdb:");

~updateFeatureMemory.(active: 0, routine: \updateMem_inputdb);
~smoothBusOutputKR.(active: 0, outBus: \smoothBus_inputdb, synth: \smooth_inputdb);
(
~listen_loudness.(active: 0,
	outBus: \bus_inputdb,
	featSynth: \rms1,
	loudFlag: \inputSendLoud,
	loudSusFlag: \inputSendLoudSus,
	monRoutine: \inputSendMon
);
)
~inputSendLoudSus
~inputSendLoud

~listen_loudness_post.(active: 1, input: ~inputSendBus, outBus: \busSum_loud, sumSynth: \sumSyn_loud, post: 1);
~listen_loudness_post.(active: 0, outBus: \busSum_loud, sumSynth: \sumSyn_loud);
*/

~listen_loudness_post = { |active = 1, input, outBus, sumSynth, rate = 0.1, post = 1| //for testing
	if (active == 1, {//start feature extraction...
		if (~bufRecorder.isRunning, {
			//LOUDNESS monitor
			l = Synth(\Loudness, [\input, input, \outBus, ~bus_loudness]).moveAfter(~bufRecorder);
			//RMS
			r = Synth(\RMSdb, [\input, input, \outBus, ~bus_rms]).moveAfter(l);

			outBus.envirPut(~sumFunc_xin.([~bus_loudness, ~bus_rms], sumSynth)); //assign bus and resulting summing synth to new env vars

			if (post == 1, { //only run this routine to monitor features w/ post window...
				//===THIS IS WHERE ~transmit feature via OSC routine from SCML could live if needed
				~listenPost = ~streamFeatures.value(bus: outBus.envirGet, rate: rate, post: post);
				SystemClock.play(~listenPost);
			});
			"====LISTENING NOW====".postln;
		}, {
			"===CAN'T LISTEN UNLESS BUF RECORDER ENABLED===".postln;
		} );
	}, {//if active == 0, stop feature extraction and clean up...
		~listenPost.stop; ~listenPost.free; //this cleanup only needed if post==1
		sumSynth.envirGet.free;
		outBus.envirGet.free;
		l.free;
		r.free;
		"====STOPPED LISTENING====".postln;
	} );
};

~listen_loudness = {|active = 1, input, outBus, featSynth, loudFlag, loudSusFlag, lowThresh = -12, uprThresh = -6, threshDur = 0.4, lastThreshTime, rate = 0.1, post = 0, monRoutine|
	if (active == 1, {//start detecting feedback
		if (~bufRecorder.isRunning, {
			var thisOutBus;

			//RMS monitor
			outBus.envirPut(Bus.control(s, 1));
			thisOutBus = outBus.envirGet;

			//lastThreshTime.envirPut(nil); //<---not necessary

			featSynth.envirPut(Synth(\RMSdb, [\input, input, \outBus, thisOutBus]).moveAfter(~bufRecorder));
			NodeWatcher.register(featSynth.envirGet);
			//RMSdb >= -10 to -6 == strong clipping and apparent feedback <-----
			//RMSdb >= -15 to -12 == light clipping...

			/*if (post == 1, { //only run this routine to monitor features w/ post window... CAUTION: can't .get from single bus using two different routines....will eventually cause one routine's get requests to fail, that's why this is commented out for now, since below monRoutine also has debug post feature...
				~listenPost = ~streamFeatures.value(bus: thisOutBus, rate: rate, post: post);
				SystemClock.play(~listenPost);
			}); */

			loudFlag.envirPut(0); //loudFlag indicates instantaneous loudness level: 0 = no loudness, 1 = lower loudness threshold exceeded, 2 = upper loudness threshold exceeded
			loudSusFlag.envirPut(false); //loudSusFlag indicates presence of ongoing loud sound / feedback (e.g. if loudFlag = 1, but loudSusFlag = false, no on-going loudness has been confirmed by monitor_loudness routine)

			//START LOUDNESS MONITOR ROUTINE
			monRoutine.envirPut(~monitor_loudness.(input: thisOutBus, loudFlag: loudFlag, loudSusFlag: loudSusFlag, lowThresh: lowThresh, uprThresh: uprThresh, threshDur: threshDur, lastThreshTime: lastThreshTime, rate: rate, post: post));
			SystemClock.play(monRoutine.envirGet);

			"====LOUDNESS/FEEDBACK DETECTION ACTIVE====".postln;
		}, {
			"===CAN'T DETECT LOUDNESS/FEEDBACK UNLESS BUF RECORDER ACTIVE===".postln;
		} );
	}, {//if active == 0, stop feature extraction and clean up...
		//if (~listenPost != nil, {~listenPost.stop; ~listenPost.free;}); //this cleanup only needed if post==1

		//STOP LOUDNESS/FEEDBACK MONITOR ROUTINE
		monRoutine.envirGet.stop;
		monRoutine.envirGet.free; //<--this doesn't free routine....set to nil?
		outBus.envirGet.free; //free RMS feature extractor output bus
		featSynth.envirGet.free; //free RMS feature extractor synth
		loudFlag.envirPut(0);
		loudSusFlag.envirPut(false);

		"====LOUDNESS/FEEDBACK DETECTION DISABLED====".postln;
	} );
};

~monitor_loudness = {|input, loudFlag, loudSusFlag, lowThresh = -12, uprThresh = -6, threshDur = 0.4,  lastThreshTime, rate = 0.1, post = 0|  //<---REVISE THIS: change threshDur and lastThreshTime to onsetDur and lastOnsetTime | add releaseDur or loudTrigHysteresis | maybe add boolean args to trigger autolevel / anti-feedback routines as a quick and easy method, but would rather avoid in long term and have autolevel / anti-feedback routines stand-alone and continuously check ~monitor_loudness flags continuously...
	Routine({
		var x, cond = Condition.new; //<---NEW
		if (post == 1, {"[MON LOUDNESS]--------".postln;});
		input.get({|val|
			x = case
			{(val >= lowThresh) && (val < uprThresh)} {//if current db is between lower and upper loudness thresh
				if (post == 1, {("-->LOUD SIG > (low thresh): input db =" + val.round(0.01)).postln;});

				if (loudFlag.envirGet == 0,
					{
						loudFlag.envirPut(1);

						if (loudSusFlag.envirGet == false,
							{
								var currentTime = Main.elapsedTime.round(0.001);
								lastThreshTime.envirPut(currentTime); //log time of threshold transition from loudFlag = 0 to 1
								if (post == 1, {("---> TRANS from loudFlag = 0: loudFlag = 1 | LOUDNESS STARTING??? | lastThreshTime =" + lastThreshTime.envirGet).postln;});
							},
							{//else if loudSusFlag already == true, must have been a false/transient quiet during loudness
								if (post == 1, {("---> TRANS from loudFlag = 0: loudFlag = 1 | LOUDNESS ONGOING").postln;});

								//<---DO ANYTHING MORE??? ADJUST ANTI-FEEDBACK ROUTINES?????<----------
							}
						);
					},
					{//else if loudFlag already == 1 or 2
						if (loudFlag.envirGet == 1,
							{
								if (loudSusFlag.envirGet == false,
									{
										var currentTime = Main.elapsedTime.round(0.001);
										if ((currentTime - lastThreshTime.envirGet) >= threshDur,
											{
												loudSusFlag.envirPut(true);
												if (post == 1, {("-->LOUD SOUND SUS CONFIRMED! (low thresh): input db =" + val.round(0.01)).postln;});
												//<----TRIGGER ANTI-FEEDBACK ROUTINES - ADJUST LEVELS ??? <--------

												//trigger long-term loudness monitoring timer and corrseponding autoActions here instead OR w/in ~updateFeatureMemory routine?
											},
											{
												if (post == 1, {("-->LOUD SOUND SUS TEST...... (low thresh): input db =" + val.round(0.01)).postln;});
											}
										);
									},
									{//else if loudSusFlag already == true
										if (post == 1, {("-->LOUD SOUND SUS continues... (low thresh): input db =" + val.round(0.01)).postln;});
											//<----INTENSIFY ANTI-FEEDBACK / ADJUST LEVELS MORE ??? <--------
									}
								);
							},
							{//else if loudFlag == 2
								loudFlag.envirPut(1);

								if (loudSusFlag.envirGet == false,
									{
										var currentTime = Main.elapsedTime.round(0.001);
										if ((currentTime - lastThreshTime.envirGet) >= threshDur,
											{
												loudSusFlag.envirPut(true);
												if (post == 1, {("-->TRANS from loudFlag = 2: loudFlag = 1 | LOUD SOUND SUS CONFIRMED! (low thresh): input db =" + val.round(0.01)).postln;});
												//<----TRIGGER ANTI-FEEDBACK ROUTINES - ADJUST LEVELS ??? <--------
											},
											{
												if (post == 1, {("---> TRANS from loudFlag = 2: loudFlag = 1 | LOUD SOUND SUS TEST...(low thresh): input db =" + val.round(0.01) + "| lastThreshTime =" + lastThreshTime.envirGet).postln;});
											}
										);
									},
									{//else if loudSusFlag already == true
										if (post == 1, {("-->LOUD SOUND SUS diminished from loudFlag = 2, but continues... (low thresh): input db =" + val.round(0.01)).postln;});
										//<----ADJUST LEVELS / ANTI-FEEDBACK ROUTINES ??? <--------
									}
								);
							}
						);
					}
				);
			}
			{val >= uprThresh} { //else if current db >= upper loudness threshold -----------------<<<<<
				if (loudFlag.envirGet < 2,
					{
						if (post == 1, {("-->VERY LOUD SIG: input db =" + val.round(0.01)).postln;});

						if (loudFlag.envirGet == 1,
							{
								loudFlag.envirPut(2);

								if (loudSusFlag.envirGet == false,
									{//we must have transitioned from loudFlag = 1 to loudFlag = 2 between two consec iterations of routine without triggering loudSusFlag...therefore, don't reset lastThreshTime, since it was previously set when loudFlag set to = 1
										var currentTime = Main.elapsedTime.round(0.001);
										if (post == 1, {("---DIRECT TRANS FROM: loudFlag = 1 to loudFlag = 2 B4 loudSusFlag set---").postln;});
										if ((currentTime - lastThreshTime.envirGet) >= threshDur, //<--- or >= rate*2 or rate*3
											{
												loudSusFlag.envirPut(true);
												if (post == 1, {("--->LOUD SOUND SUS CONFIRMED! (UPR thresh): input db =" + val.round(0.01)).postln;});
												//<------TRIGGER ANTI-FEEDBACK ROUTINES AND ADJUST LEVELS <-----?
											},
											{
												if (post == 1, {("--->LOUD SOUND SUS TEST.... (UPR thresh): input db =" + val.round(0.01)).postln;});
												//<------DO NOTHING.. WAIT AND SEE..?... NO ADJUST LEVELS IMMEDIATELY  <---
											}
										);
									},
									{//else if loudSusFlag == true
										if (post == 1, {("--->TRANS FROM: loudFlag = 1 to loudFlag = 2 --- loudSusFlag already = true").postln;});

										//<----TRIGGER MORE EXTREME ANTI-FEEDBACK ROUTINES / SET LEVEL TO -inf ????
									}
								);
							},
							{//else if transitioning from loudFlag == 0
								loudFlag.envirPut(2);

								if (loudSusFlag.envirGet == false,
									{
										var currentTime = Main.elapsedTime.round(0.001);
										lastThreshTime.envirPut(currentTime);
										if (post == 1, {("---> TRANS from 0: loudFlag = 2 | lastThreshTime =" + lastThreshTime.envirGet).postln;});
									},
									{//else if loudSusFlag already == true
										if (post == 1, {("FALSE / SHORT QUIET - LOUDNESS CONTINUING...").postln;});

										//<----TRIGGER MORE EXTREME ANTI-FEEDBACK ROUTINES / SET LEVEL TO -inf ????
									}
								);
							}
						);
					},
					{ //if loudFlag == 2 (a.k.a. if rmsBusVal already >= uprThresh)
						if (loudSusFlag.envirGet == false,
							{
								var currentTime = Main.elapsedTime.round(0.001);
								if ((currentTime - lastThreshTime.envirGet) >= (rate * 2), { //if the routine's cycled twice
									loudSusFlag.envirPut(true);
									if (post == 1, {("-->VERY LOUD SOUND SUS CONFRMD (upr thresh): input db =" + val.round(0.01)).postln;});

									//<------TRIGGER ANTI-FEEDBACK ROUTINES AND ADJUST LEVELS <-----?
								}, {
									if (post == 1, {("-->VERY LOUD SOUND SUS TEST...... (upr thresh): input db =" + val.round(0.01)).postln;});
								});
							},
							{//else if loudSusFlag == true
								if (post == 1, {("-->VERY LOUD SOUND SUS continues... (upr thresh): input db =" + val.round(0.01)).postln;});

								//<----TRIGGER MORE EXTREME ANTI-FEEDBACK ROUTINES / SET LEVEL TO -inf ????
							}
						);
					}
				);
			}
			{val < lowThresh} { //else if current db < lower loudness threshold -------------
				if (post == 1, {("-->QUIET SIG < lowThresh: input db =" + val.round(0.01)).postln;});
				if (loudFlag.envirGet > 0,
					{
						loudFlag.envirPut(0);
						if (loudSusFlag.envirGet == false,
							{
								if (post == 1, {("FALSE/TRANSIENT LOUD TRIG - loudSusFlag = false").postln;});
							},
							{//else if loudSusFlag == true, we're transitioning from loudness, test to see if it's ongoing
								var currentTime = Main.elapsedTime.round(0.001);
								lastThreshTime.envirPut(currentTime); //log time of transition from loudFlag > 0 to 0
								if (post == 1, {("--->TRANS FROM loudFlag > 0 to loudFlag = 0 | lastThreshTime =" + lastThreshTime.envirGet + "| loudSusFlag = true | LOUDNESS PREV OCCURRING...").postln;});
							}
						);
					},
					{//else if loudFlag already == 0
						if (loudSusFlag.envirGet == false,
							{
								//do nothing...no loudness or feedback has been occurring......
								if (post == 1, {("--->NO LOUDNESS...cont...").postln;});
							},
							{//else if loudSusFlag == true, test to see if loudness has stopped...
								var currentTime = Main.elapsedTime.round(0.001);
								if ((currentTime - lastThreshTime.envirGet) >= threshDur, //or set to >= (rate*3) ??? <---
									{
										loudSusFlag.envirPut(false);
										if (post == 1, {("--->NO LOUDNESS CONFIRMED | loudSusFlag = false...").postln;});

										//TERMINATE ANTI-FEEDBACK ROUTINES <--------
										//RESET LEVELS TO NORMAL, ETC...  <--------
									},
									{//else if (currentTime - lastThreshTime < threshDur)
										if (post == 1, {("--->TESTING FOR END OF LOUDNESS...").postln;});
									}
								);
							}
						);
					}
				);
			};
			cond.unhang; //<----THIS OR .getSync
		});
		cond.hang;
		rate.yieldAndReset;
	});
};

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
			~mode_autoRecPlay = true; //<---NEW mode flag
			//~listen_sound.value(active: 1, input: ~inputSendBus, post: 0); //start listening
			~listen_sound.value(active: 1, input: ~inputSendBus, outBus: \busSum_lop, sumSynth: \sumSyn_1, post: 0); //start listening
			~autoRecStartTrig = true; //enables debounce when ~autoRecStart initialized

			~autoRecStart = ~autoRec_soundTrigAuto.(featureBus: ~busSum_lop, rate: 0.1, debounceDur: 0.5, post: 0);
			SystemClock.play(~autoRecStart);

			//~autoPlay_soundTrigAuto.reset;
			//SystemClock.play(~autoPlay_soundTrigAuto);
			~autoPlayRout = ~autoPlay_soundTrigAuto.(post: 1);
			SystemClock.play(~autoPlayRout);
		},
		{
			~mode_autoRecPlay = false; //<---NEW mode flag
			~autoRecStart.stop;
			~autoRecStart.free;  //doesn't do anything...

			//~autoPlay_soundTrigAuto.stop;
			~autoPlayRout.stop;
			~autoPlayRout.free; //doesn't do anything...

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

			if (~playSamp == true, {
				~samp0.free;
				~audioBuf_play0.close; //<---not needed...?
				~audioBuf_play0.free;
				~playSamp = false;
				~button_playSamp.value = 0;
				~autoRecPlay_state = 0; //<----- NEW

				if (~pcs_syn1 != nil, { //end pConv routine if active (checking for its synth)....<----NEW
					if (~pcs_syn1.isRunning, {
						~partConv_samples_autoLoop.(0, post: 1, targetBuf: \pcs_tBuf1, irBuf: \pcs_irBuf1, routine: \pcs_rout1, synth: \pcs_syn1);
					});
				});

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
						//~samp0 = Synth(\bufRead_noLoop, [\buf, buffer, \amp, ~fileOutputLevelBus.asMap, \out, ~outMainBus]);
						~samp0 = Synth(\bufRead_noLoop, [\buf, buffer, \amp, ~fileOutputLevelBus.asMap, \out, ~stream2sub]); //<---NEW outBus
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

/*~label_playSamp = StaticText(~view_sampButtons, Rect(113, 23, 135, 20))
.string_("/PATH/../FILENAME")
.font_(Font("Monaco", 12) )
.align_(\left); */


//++++ADD FILE SELECTOR INTERFACE (OPEN DIALOG?) FOR SAMPLE LOADING...

//++++ADD BUFFSCOPE FOR PLAYING / LOADED AUDIO FILE(s) (make into re-usable view for GUI of multi-channel & multi-sample playback)

//--------------------------


///---------- LEVELS ----------///

~slider_inFlow1_level = Slider(~view_altLevels, Rect(9, 2, 12, 73))
.background_(Color(0.0, 0.5, 0.9))
//.value_(1.0)
.value_(~spec_slider_dB.unmap(0)) //<--
.action_({|obj|
	var mapVal, val = obj.value.round(0.001);
	mapVal = ~spec_slider_dB.map(val).round(0.01); //convert linear amp to db scaling
	~inputStreamLevelBus.set(mapVal.dbamp.round(0.001));
	~numBox_inFlow1_level.value_(mapVal);
} );

~numBox_inFlow1_level = NumberBox(~view_altLevels, Rect(2, 75, 30, 15))
.value_(0.0)
.clipLo_(-inf)
.clipHi_(0.0)
.decimals_(1)
.scroll_step_(0.1)
.font_(Font("Monaco", 8) )
.align_(\center)
.action_({|obj|
	var mapVal, val = obj.value.round(0.1);
	mapVal = ~spec_slider_db.unmap(val); //convert db num into linear amp scaling
	~inputStreamLevelBus.set(mapVal.round(0.001));
	~slider_inFlow1_level.value_(mapVal.round(0.01));
} );

/*~slider_inFlow1_level = Slider(~view_altLevels, Rect(9, 2, 12, 73))
.background_(Color(0.0, 0.5, 0.9))
.value_(1.0)
.action_({
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
} ); */

~label_inFlow1_level = StaticText(~view_altLevels, Rect(0, 94, 30, 8))
.string_("S1-IN")
.font_(Font("Monaco", 10) )
.align_(\center);

~slider_sampOut_level = Slider(~view_altLevels, Rect(44, 2, 12, 73))
.background_(Color(0.0, 0.8, 0.2))
//.value_(1.0)
.value_(~spec_slider_dB.unmap(0)) //<--
.action_({|obj|
	var mapVal, val = obj.value.round(0.001);
	mapVal = ~spec_slider_dB.map(val).round(0.01); //convert linear amp to db scaling
	~fileOutputLevelBus.set(mapVal.dbamp.round(0.001));  //set level control bus value
	~numBox_sampOut_level.value_(mapVal);
} );

~numBox_sampOut_level = NumberBox(~view_altLevels, Rect(37, 75, 30, 15))
.value_(0.0)
.clipLo_(-inf)
.clipHi_(0.0)
.decimals_(1)
.scroll_step_(0.1)
.font_(Font("Monaco", 8) )
.align_(\center)
.action_({|obj|
	var mapVal, val = obj.value.round(0.1);
	mapVal = ~spec_slider_db.unmap(val); //convert db num into linear amp scaling
	~fileOutputLevelBus.set(mapVal.round(0.001));
	~slider_sampOut_level.value_(mapVal.round(0.01));
} );

/*~slider_sampOut_level = Slider(~view_altLevels, Rect(44, 2, 12, 73))
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
} );  */

~label_sampOut_level = StaticText(~view_altLevels, Rect(35, 94, 30, 8) )
.string_("S2-SP")
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
if (~plotterEnabled == true, {
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
});


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

			~a2k_rec = Synth(\a2k_patch, [\in, ~phaseBusRec, \out, ~phaseBusMonRec] ).moveAfter(~phasor_rec); //<--don't fully understand why this allows me to monitor phasor value and why I can't do so by .get-ting value of ~phaseBusRec (doing so always outputs 1)...

			~bufRecorder = Synth(\bufRec, [\phaseBus, ~phaseBusRec, \buf, ~audioBuf0, \sendBus, ~inputSendBus, \loCut, ~loCutBus_in.asMap, \loCutQ, 2, \mul, ~inputLevelBus.asMap] ).moveAfter(~a2k_rec);

			NodeWatcher.register(~bufRecorder); //this ensures all synths associated w/ buf play back are positioned after all these buf recording synths in the node-tree, no matter when they're created

			//~lastRecPhasePos.value.postln;

			//START REC SLIDER UPDATE ROUTINE...
			~getBus_updateGUI_recPhase.reset;
			AppClock.play(~getBus_updateGUI_recPhase);

			//////PLOTTER ----------
			if (~plotterEnabled == true, {
				~updateBufPlot.reset;
				AppClock.play(~updateBufPlot);
			});

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

			if (~plotterEnabled == true, {~updateBufPlot.stop;});  //PLOTTER
			if (~syncRecPlayOffset == true, {~syncRecPlayOffset = false; ~button_delaySync.value = 0;}); //disable sync
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
			if (~syncRecPlayOffset == true, {~recPlayDelayOffset.(offset: ~delayTime);}); //sync playhead if SYNC enabled
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

			NodeWatcher.register(~bufPlayer);

			~pShift = Synth(\pitchShifter,
				[\inBus, ~playOut1Bus, \outBus, ~pitchShiftOut, \pitchRatio, ~pitchBus.asMap]).moveAfter(~bufPlayer);

			~pShiftMix = Synth(\XFade, [
				\in1, ~playOut1Bus,
				\in2, ~pitchShiftOut,
				//\out, ~outMainBus,
				\out, ~stream1sub, //<---NEW
				\amountControlBus, ~pitchShiftMixValBus.asMap,
				\amp, ~inputStreamLevelBus.asMap
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
			~rateBus.get({
				arg val;
				if (val > 0, {
					var newRate = -1 * val;
					//("newRate=" + newRate).postln;
					~rateBus.set(newRate);
				} );
			} );
			~revRateBusMon.set(-1);
			//~reverseFlag = true;
			if (~syncRecPlayOffset == true, {~syncRecPlayOffset = false; ~button_delaySync.value = 0;}); //disable sync
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
~button_delaySync = Button(~view_perfButtons, Rect(160, 0, 55, 25))
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
			var currentRate, currentRev;
			~syncRecPlayOffset = true;

			currentRate = ~rateBus.getSynchronous.round(0.01);
			if (currentRate != 1,
				{
					~rateBus.set(1);
					~slider_rate.value_(0.5);
					~numBox_rate.value_(0);
				}
			);

			currentRev = ~revRateBusMon.getSynchronous;
			if (currentRev == -1,
				{
					~revRateBusMon.set(1);
					~button_rev.value = 0;
				}
			);

			~recPlayDelayOffset.(offset: ~delayTime);

		},
		{ //when button disabled
			~syncRecPlayOffset= false;
		}
	);
} )
.value_(0);

~numBox_delay = NumberBox(~view_perfButtons, Rect(217, 0, 55, 25))
.value_(~delayTime)
.clipLo_(0)
.clipHi_(~audioBuf0_dur - 0.01)
.font_(Font("Monaco", 14) )
.decimals_(2)
.scroll_step_(0.01)
.step_(0.01)
.action_( {|obj|
	~delayTime = obj.value.round(0.01);
	if (~syncRecPlayOffset == true, {~recPlayDelayOffset.(offset: ~delayTime);}); //sync playhead if SYNC enabled
} );

~label_delayTime = StaticText(~view_perfButtons, Rect(275, 2, 78, 20) )
//~label_delayTime = StaticText(w, Rect(720, 157, 78, 20) )
.string_("Offset
(sec)")
.font_(Font("Monaco", 8) )
.align_(\left);

//--------------------

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

//-------------- BEHAVIOR BUTTONS ------------

~button_Behavior1 = Button(~view_perfButtons, Rect(0, 25, 55, 25)) //randomize rate and pitchShift over time
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
			~mode_randProcLiveBuf = true; //<---NEW mode flag

			~randomRoutine_rate.reset;
			~randomRoutine_freq.reset;
			~randomRoutine_pitchShiftMix.reset;
			~randomRoutine_reverse.reset;
			~randomRoutine_playHeadBehavior.reset;

			AppClock.play(~randomRoutine_rate);
			AppClock.play(~randomRoutine_freq);
			AppClock.play(~randomRoutine_pitchShiftMix);
			AppClock.play(~randomRoutine_reverse);
			AppClock.play(~randomRoutine_playHeadBehavior); //<---spruce this routine up to be consistent w/ above
		},
		{ //when randomize button disabled
			~mode_randProcLiveBuf = false; //<---NEW mode flag

			~randomRoutine_rate.stop;
			~updateGUI_rate.stop;

			~randomRoutine_freq.stop;
			~updateGUI_freq.stop;

			~randomRoutine_pitchShiftMix.stop;
			~updateGUI_pitchShiftMix.stop;

			~randomRoutine_reverse.stop;
			~randomRoutine_playHeadBehavior.stop;
			~playHeadFollowRecHead.stop;
		}
	);
} )
.value_(0);

~button_Behavior2 = Button(~view_perfButtons, Rect(55, 25, 30, 25)) //Randomize pitch shift, pitch shift mix, and output level control
.states_( [
	["!!", Color.black, Color(0.0, 0.3, 0.9, 0.3)] ,
	["!!", Color.white, Color(0.8, 0.3, 0.8)]
] )
.font_(Font("Monaco", 18) )
.action_( {
	arg obj;
	if (
		obj.value == 1, // when button enabled
		{

		},
		{ //when button disabled

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
		obj.value == 1, // when button enabled
		{
			~listen_sound.value(active: 1, input: ~inputSendBus, outBus: \busSum_lop, sumSynth: \sumSyn_1, post: 0); //START ~listen_sound ROUTINE <-----------------

			~autoConvolveSequence_1.(1,
					initFlag: \autoConvSeqInit,
					impulseFlag: \autoConvSeqImpulse,
					routine: \autoConvSeqRout,
					impulseAmount: 1,
					repeatLimit: 11,
					impulse1: 0,
					impulse2: 1,
					impulse3: 0.1,
					post: 1
			);

			/*~autoConvolveSequence_voxelBot2.(1,
					initFlag: \autoConvSeqInit,
					impulseFlag: \autoConvSeqImpulse,
					routine: \autoConvSeqRout,
					post: 1
			); */

			~autoConvolve1A.(1, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, synth1: \autoS1, preRecPad: 0.1, postRecPad: 0, impulse: 1, freq1: 400, freq2: 3000, attTime: 5, susTime: 3, relTime: 6, impPostDel: 0.5, timeStretch: true, timeStretchRate: 0.75, post: 1); //<---solo laptop preset

			//~autoConvolve1A.(1, featureBus: ~busSum_lop, outBus: ~outMainBus, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, synth1: \autoS1, preRecPad: 0.2, postRecPad: 1, impulse: 3, impPostDel: 0, timeStretch: true, timeStretchRate: 0.67, post: 1); //<---adjust pre and post pads to accommodate reverb tail of performance space and audio content (e.g. speech vs. claps, etc...) ---LIGHT LAB SETTINGS <-------

			//~autoConvolve1A.(1, filePath: ~fileAudio_writeIn_lastFile, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, synth1: \autoS1, preRecPad: 0, postRecPad: 0, impulse: 0, freq1: 600, freq2: 606, attTime: 0.5, susTime: 2.5, relTime: 2, impPostDel: 0.4, timeStretch: true, timeStretchRate: 0.75, post: 1); //<---FOR VOXELS

			//~autoConvolve2_repLim_voxels.(1, filePath: ~fileAudio_writeIn_lastFile, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, repeatLimit: 7, synth1: \autoS1, preRecPad: 0, postRecPad: 0, impulse: 0, freq1: 600, freq2: 606, attTime: 0.5, susTime: 3.5, relTime: 2.5, impPostDel: 0.4, timeStretch: true, timeStretchRate: 0.75, post: 1); //<---FOR VOXELS _ 0

			//~autoConvolve2_repLim_voxels.(1, filePath: ~fileAudio_writeIn_lastFile, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, repeatLimit: 8, synth1: \autoS1, preRecPad: 0, postRecPad: 0, impulse: 2, freq1: 100, freq2: 20000, susTime: 0.5, impPostDel: 0, timeStretch: true, timeStretchRate: 0.6, post: 1); //<---FOR VOXELS _ 1

			//~autoConvolve2_repLim_voxels.(1, filePath: ~fileAudio_writeIn_lastFile, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, re peatLimit: 4, synth1: \autoS1, preRecPad: 0, postRecPad: 0, impulse: 1.1, freq1: 250, freq2: 1000, attTime: 1.67, susTime: 2.24, relTime: 3.87, impPostDel: 0, timeStretch: true, timeStretchRate: 0.6, post: 1); //<---FOR VOXELS _ 2

			//~autoConvolve2_repLim_voxels.(1, filePath: ~fileAudio_writeIn_lastFile, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, repeatLimit: 7, synth1: \autoS1, preRecPad: 0, postRecPad: 0, impulse: 1.2, freq1: 180, freq2: 850,/* attTime: 1.67, susTime: 3.59, relTime: 3.87,*/ impPostDel: 0, timeStretch: true, timeStretchRate: 0.6, post: 1); //<---FOR VOXELS _ 3

			//~autoConvolve1A.(1, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, synth1: \autoS1, preRecPad: 0.2, postRecPad: 0.2, impulse: 3, impPostDel: 0.4, timeStretch: true, timeStretchRate: 0.75, post: 1); //<---piezo live sound settings
			//~autoConvolve2_repLim_selfTerminate.(1, activeFlag: \autoConvActive, filePath: ~fileAudio_writeIn_lastFile, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, repeatLimit: 3, selfTerminate: true, synth1: \autoS1, preRecPad: 0, postRecPad: 0, impulse: 0, attTime: 0.5, susTime: 3.5, relTime: 2.5, impPostDel: 0.2, timeStretch: true, timeStretchRate: 0.75, post: 1); //<---FOR VOXELS _ 0
			//~autoConvolve2_repLim_selfTerminate.(1, activeFlag: \autoConvActive, filePath: ~fileAudio_writeIn_lastFile, featureBus: ~busSum_lop, outBus: ~stream2sub, ampBus: ~fileOutputLevelBus.asMap, rout1: \autoC1, rout2: \autoC2, initFlag: \autoC1state, repeatCounter: \autoCnt1, repeatLimit: 3, selfTerminate: false, synth1: \autoS1, preRecPad: 0, postRecPad: 0, impulse: 1.1, freq1: 300, freq2: 850, impPostDel: 0, timeStretch: true, timeStretchRate: 0.65, post: 1);
		},
		{ //when button disabled
			~listen_sound.value(active: 0, outBus: \busSum_lop, sumSynth: \sumSyn_1);

			//~autoConvolveSequence_1.(0, routine: \autoConvSeqRout, post: 1);

			//~autoConvolveSequence_voxelBot2.(0, routine: \autoConvSeqRout, post: 1);

			~autoConvolve1A.(0, rout1: \autoC1, rout2: \autoC2, synth1: \autoS1); //this will throw error if envName isn't provided for rout1 arg......

			//~autoConvolve2_repLim_voxels.(0, rout1: \autoC1, rout2: \autoC2, synth1: \autoS1);

			//~autoConvolve2_repLim_selfTerminate.(0, rout1: \autoC1, rout2: \autoC2, synth1: \autoS1);
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
			~phasor_rec.set (\resetPos, pos, \trig, 1);
			if (~syncRecPlayOffset == true, {{~recPlayDelayOffset.(offset: ~delayTime)}.defer(0.01);}); //sync playhead if SYNC enabled (defer is perhaps not elegant, but necessary b/c otherwise ~recPlayDelayOffset uses current/old/nonupdated rec phase bus position when ~phaseBusMonRec.getSynch call is made...
		},
		{//update phasor pos when not actively recording to buffer
			~phaseBusMonRec.set(pos); //<--- update control bus too, which other funcs and routines use
			~lastRecPhasePos = pos;
		}
	);

	~numBox_recPos.value = (pos/s.sampleRate).round(0.01); //convert frames to seconds and display

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
			~phasor_play.set(\resetPos, pos, \trig, 1);
			if (~syncRecPlayOffset == true, {~syncRecPlayOffset = false; ~button_delaySync.value = 0;}); //disable sync
		},
		{//update phasor pos when not actively playing from buffer
			~phaseBusMonPly.set(pos); //<--- update control bus too, which other funcs and routines use
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
.action_({|obj|
	var rateTransp = obj.value.linlin(0, 1, -48, 48).round(0.01);
	if (~button_rev.value == 1,
		{~rateBus.set(rateTransp.midiratio * -1);}, //negative rate when REV button enabled
		{~rateBus.set(rateTransp.midiratio);} //positive rate when REV button disabled
	);
	~numBox_rate.value_(rateTransp); //update numBoxPitch value
	~pitchShiftValPrev_rate = rateTransp; //<---NEW, to support ~randomRoutine_reverse
	if (rateTransp != 0, {
		if (~syncRecPlayOffset == true, {~syncRecPlayOffset = false; ~button_delaySync.value = 0;}); //disable sync
	});
});

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
	if (~button_rev.value == 1,
		{~rateBus.set(semiToneVal.midiratio * -1);}, //negative rate when REV button enabled
		{~rateBus.set(semiToneVal.midiratio);} //positive rate when REV button disabled
	);
	pos = obj.value.clip(-48, 48).linlin(-48, 48, 0, 1).round(0.001);
	~slider_rate.value_(pos);
	~pitchShiftValPrev_rate = semiToneVal; //<---NEW, to support ~randomRoutine_reverse
	if (semiToneVal != 0, {
		if (~syncRecPlayOffset == true, {~syncRecPlayOffset = false; ~button_delaySync.value = 0;}); //disable sync
	});
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
	~pitchShiftValPrev_freq = pos; //<---new, to support ~randomRoutine_pitchShiftMix
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
	~pitchShiftValPrev_freq = semiToneVal; //<---new, to support ~randomRoutine_pitchShiftMix
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
	//("mixValIn=" + mixVal).post;
	mixVal = mixVal/100;
	//(" | mixValToPbus=" + mixVal).postln;
	~pitchShiftMixValBus.set(mixVal); //change pitch (in semi tones)
	~slider_pitchShiftMix.value_(mixVal);
} );

~label_pitchShiftMix = StaticText(~view_procControls1, Rect(358, 49, 135, 10))
.string_("PitchShiftMix")
.font_(Font("Monaco", 12) )
.align_(\left);
};
);