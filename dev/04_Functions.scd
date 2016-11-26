//Sonic Mirror - 04_Functions:

// --> functions and routines

(

//====== FUNCTIONS ========

~sumFunc_xin = {arg busArray;  //bus val concat function for variable size arg array of feat busses
	var numCh = 0, busCol, outArray, outBus;
	busArray.do({|item| numCh = numCh + item.numChannels}); //calculate total # bus channels
	outBus = Bus.control(s, numCh);
	busCol = Array.newClear(busArray.size);

	~sumSyn_xin = SynthDef(\sumSyn_xin, {
		busArray.do({|item, i| busCol[i] = In.kr(item, item.numChannels); }); //input bus vals to var array
		busCol.do({|item| //concat all bus vals into single out array
			if (item.numChannels == 1,
				{outArray = outArray ++ [item]},
				{outArray = outArray ++ (item.numChannels.collect( {|i| item[i]} ))}
			);
		});
		Out.kr(outBus, outArray);
	}).play(addAction: \addToTail);

	outBus; //return new bus w/ concat values of all input busses in arg array
};

~get_busSum = {|bus, post = 1|
	var numCh = bus.numChannels;
	bus.get( {arg val; //<---changing to getSynchronous prevents OSC output for some reason...?
		if (post == 1, {//monitor feature vals in SC post window
			switch (bus,
				~busSum_ldns_mfcc, {
					("Loudness:" + val[0].round(0.0001)).postln;
					("MFCC:" + val[1..13].round(0.0001)).postln;
					("-------").postln;
				},
				~busSum_ldns_sFlat_sCent, {
					("Loudness:" + val[0].round(0.0001)).postln;
					("Flatness:" + val[1].round(0.0001)).postln;
					("Centroid:" + val[2].round(0.0001)).postln;
					("-------").postln;
				},
				~busSum_ldns_pitch, {
					("Loudness:" + val[0].round(0.0001)).postln;
					("Pitch-freq:" + val[1].round(0.01)).postln;
					("Pitch-hasFreq?:" + val[2]).postln;
					("Pitch-MIDInote:" + val[3]).postln;
					("-------").postln;
				},
				~busSum_ldns_sFlat_onset, {
					("Loudness:" + val[0].round(0.0001)).postln;
					("Flatness:" + val[1].round(0.0001)).postln;
					("Onset Detected:" + val[2]).postln;
					("-------").postln;
				},
				{//all other busses (cases)
					if (numCh > 1,
						{
							numCh.do({arg item; ("Feature_" ++ (item + 1) ++ ":" + val[item].round(0.0001)).postln;});
							("-------").postln;
						},
						{("Feature_1:" + val.round(0.0001)).postln;} //else
					);
				}
			);
		});

		//INSERT SWITCH CASE HERE FOR EACH DIFFERENT SUM BUS
		//....W/ NESTED CONDITIONALS SETTING ~currentSound based on extracted audio...


		//push ~currentSound into "sound memory array / buffer" periodically  <--put this in ~autoRec routine?
		//update ~currentScene based on "sound memory array" periodically <--put this in ~autoRec routine?

	});
};

~streamFeatures = {
	|bus, rate = 0.1, post = 1|
	Routine ( {
		~get_busSum.value(bus, post);
		rate.yieldAndReset;
	} );
};

~writeSampFromBufCopy_input = {
	("-----...........------").postln;
	(">>>SAMPLING ~audioBuf0......<<<").postln;

	if (~recSamp_input_startFrame < ~recSamp_input_stopFrame,
		{//SIMPLE BUF WRITE

			var recFrames = (~recSamp_input_stopFrame - ~recSamp_input_startFrame) + 1; //+1 to include stopFrame in frame count

			~audioBuf0.write((~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath, "aiff", "int24", startFrame: ~recSamp_input_startFrame, numFrames: recFrames); // write sampled buffer to audio file - directly from original buffer...

			//~fileAudio_writeIn_lastFile = (~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath; //<---------- NEW (keeps track of last written file name)

			("--SIMPLE Write--").postln;
			("--WROTE Sample: " ++ ~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").postln;
			("--sampled from sec: " ++ (~recSamp_input_startFrame / s.sampleRate) ++ " - " ++ (~recSamp_input_stopFrame / s.sampleRate) ++ " (dur = " ++ (recFrames/s.sampleRate) ++ " sec)").postln;
		}, { //else if ~recSamp_input_startFrame > stopFrame, we've wrapped around the buffer and will need to copy from it in 2 steps before writing an audio file...
			var recFrames, bufChunk1frames, bufChunk2frames;
			bufChunk1frames = ~audioBuf0.numFrames - ~recSamp_input_startFrame; //inclusive frame count from "startFrame" to last frame in buffer
			bufChunk2frames = ~recSamp_input_stopFrame + 1; //inclusive frame count (b/c buffers start at frame 0)
			recFrames = bufChunk1frames + bufChunk2frames; //total # of frames to sample

			~audioBuf_inMainWrite = Buffer.alloc(s, recFrames, 1);

			//copy chunk 1 to new buf from ~recSamp_startFrame to last frame of ~audioBuf0
			~audioBuf0.copyData(~audioBuf_inMainWrite, dstStartAt: 0, srcStartAt: ~recSamp_input_startFrame, numSamples: bufChunk1frames); //<---if "NO BUF data" errors thrown, try reducing bufChunk1frames by 1, not sure if this method counts samples inclusive or exclusive of start frame

			//copy chunk 2 to new buf from first frame of ~audioBuf0 to ~recSamp_stopFrame
			~audioBuf0.copyData(~audioBuf_inMainWrite, dstStartAt: (bufChunk1frames - 1), srcStartAt: 0, numSamples: bufChunk2frames);

			//write ~audioBuf_inMainWrite to an audio file
			~audioBuf_inMainWrite.write((~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath, "aiff", "int24");

			//~fileAudio_writeIn_lastFile = (~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath; //<---------- NEW (keeps track of last written file name)

			("--WRAP AROUND 2-STEP WRITE--").postln;
			("--WROTE Sample: " ++ ~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").postln;
			("--WRAP-AROUND--sampled from sec: " ++ (~recSamp_input_startFrame / s.sampleRate) ++ " - " ++ (~recSamp_input_stopFrame / s.sampleRate) ++ " (dur = " ++ (recFrames/s.sampleRate) ++ " sec)").postln;
			~audioBuf_inMainWrite.free;
	});

	~recSamp_input = false; //EXIT THIS HALF OF ROUTINE, resume listening for sound...
	{~button_recIn.value = 0}.defer; //update GUI

	~fileAudio_writeIn_lastFile = (~fileAudio_writeIn_lastPath++~fileAudio_writeIn_nameNum++".aiff").standardizePath; //<---------- NEW (keeps track of last written file name)
	~autoRecPlay_state = 1; //<------NEW --- (advance state to trigger ~autoPlay before next ~autoRec)
	("~autoRecPlay_state = 1 | ~autoPlay ONLY").postln;

	~fileAudio_writeIn_nameNum = ~fileAudio_writeIn_nameNum + 1; //increment file counter
	if (~fileAudio_writeIn_nameNum > ~fileAudio_writeIn_maxNum, { //cap max file count...
		~fileAudio_writeIn_nameNum = 0;
	});

	(">>>RECORDING COMPLETE<<<").postln;
	("---.....---").postln;
};


//====== ROUTINES ==========================

//--------- BUS GET / GUI UPDATE ROUTINES ---------
~getBus_updateGUI_playPhase = Routine({
	~phaseBusMonPly.get({|val|
		~lastPlayPhasePos = val.round(1);
		{
			//(val / (s.sampleRate * ~audioBuf0_dur)).postln; //uncomment to view sliderPlayPos from 0-1 (debugging)
			~slider_playPos.value = val / (s.sampleRate * ~audioBuf0_dur); //update slider position
			~numBox_playPos.value = (val.round(1)/s.sampleRate).round(0.01); //convert frames to seconds and display
		}.defer;
	} );

	if (~playPosLatchTrig == true,
		{
			~playPosLatchTrig = false;
			{
				~phasor_play.set(\start, ~playInPosBus.asMap); //reset phasor start to ~playInPos after initalizing at ~lastPlayPhasePos (permits resuming playback from last read pos in buffer)
			}.defer(0.15); //<----NOTE TO SELF: in the unlikely event the user stops playing and then later resumes from within less than 0.15 seconds of the ~playOutPosBus value, this may cause the play phasor to jump back to its start position initalized at ~lastPlayPhasePos when this routine starts. Haven't test enough. Low priority....
		} ,
		{ //else
			~phasor_play.get(\trig, {|trigval| if (trigval > 0, {~phasor_play.set(\trig, 0);}); }); //reset trigger val to 0 if prev triggered
		}
	);
	0.1.yieldAndReset;
});


~getBus_updateGUI_recPhase = Routine({
	//(">>>updateRecSliderRoutine: outside get -" + Main.elapsedTime.round(0.01)).postln;
	~phaseBusMonRec.get({|val|
		~lastRecPhasePos = val.round(1); //log phase pos in env variable <----NEW
		{
			//(">>>>updateRecSliderRoutine: inside get -" + Main.elapsedTime.round(0.01)).postln;
			//(val / (s.sampleRate * ~audioBuf0_dur)).postln; //uncomment to view sliderPlayPos from 0-1
			~slider_recPos.value = val / (s.sampleRate * ~audioBuf0_dur); //update slider position
			~numBox_recPos.value = (val.round(1)/s.sampleRate).round(0.01) ; //convert frames to seconds and display
		}.defer;
	});

	if (~recPosLatchTrig == true,
		{
			~recPosLatchTrig = false;
			{
				~phasor_rec.set(\start, ~recInPosBus.asMap);  //reset phasor start to ~recInPos after initially starting phasor synth (permits resuming recording from last read pos in buffer)
			//("---reset phasor startPos to recInPosBus:" + Main.elapsedTime.round(0.01)).postln;
			}.defer(0.15); //<----NOTE TO SELF: in the unlikely event the user stops recording and then later resumes from within less than 0.15 seconds of the ~recOutPosBus value, this may cause the rec phasor to jump back to its start position initalized at ~lastRecPhasePos when this routine starts. Haven't test enough. Low priority....
		},
		{//else
			~phasor_rec.get(\trig, {|trigval| if (trigval > 0, {~phasor_rec.set(\trig, 0);}); }); //reset trigger val to 0 if prev triggered by slider .action (i.e. clicked transport slider)
		}
	);
	0.1.yieldAndReset;
});


~updateGUI_rate = Routine.new ( {
	~rateBus.get( {
		arg val;
		var thisVal = val.abs; //in case "Reverse" enabled and rate is negative...   <-----
		AppClock.sched(0.0, { //this is necessary for some reason... I think can be replaced by .defer
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


//----- RANDOMIZE ROUTINES -----
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
//------------------


//----- AUTO REC / PLAY ROUTINES -----
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


);