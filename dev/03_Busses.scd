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

~loCutBus_in = Bus.control(s, 1);
~loCutBus_out = Bus.control(s, 1);
~inputSendBus = Bus.audio(s, 1);

~phaseBusPly = Bus.audio(s, 1);
~phaseBusMonPly = Bus.control(s, 1);
~play1LevelBus = Bus.control(s, 1); //to control level of audioPlayback ("playhead1")
~playOut1Bus = Bus.audio(s, 1);

~outMainLevelBus = Bus.control(s, 1);
~outMainBus = Bus.audio(s, 1);

// Busses for Feature Extractor Synths (from SCML) ---------------

~bus_loudness = Bus.control(s, 1);
~bus_rms = Bus.control(s, 1);
~bus_mfcc = Bus.control(s, 13);
~bus_pitch = Bus.control(s, 2);
~bus_pitch2 = Bus.control(s, 3);
~bus_specCent = Bus.control(s, 1);
~bus_specFlat = Bus.control(s, 1);
~bus_onsets = Bus.control(s, 1);

~bus_input1 = Bus.audio(s, 1);  //<---not sure if I need this at the moment....
);