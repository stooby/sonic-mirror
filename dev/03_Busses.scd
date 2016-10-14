//Sonic Mirror - 03_Busses:


(
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
);