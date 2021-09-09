//Sonic Mirror - 03_Busses:


//== All Main Busses for one instance of SM ==

(//  MAIN AUDIO BUFFER REC / PLAYBACK / PROCESSING ------

//  Audio Input <----
~inputSendBus = Bus.audio(s, 1);
~inputLevelBus = Bus.control(s, 1);
//~bus_input1 = Bus.audio(s, 1);  //<---not sure if I need this at the moment....

//  Buffer Record Control --
~phaseBusRec = Bus.audio(s, 1);  //using phasor to index through audio buffer for recording ('rec head')
~phaseBusMonRec = Bus.control(s, 1);  //for monitoring buffer index position of 'rec head' phasor

~recInPosBus = Bus.control(s, 1); //REC In/Out Buffer Positions
~recOutPosBus = Bus.control(s, 1);

//  Buffer Playback Control --
~phaseBusPly = Bus.audio(s, 1);  //using phasor to index through audio buffer for playback ('play head')
~phaseBusMonPly = Bus.control(s, 1);  //for monitoring buffer index position of 'play head' phasor

~playInPosBus = Bus.control(s, 1);   //PLAYBACK In/Out Buffer Positions
~playOutPosBus = Bus.control(s, 1);

//  Playback Rate / Pitch Shift Control --
~rateBus = Bus.control(s, 1);
~revRateBusMon = Bus.control(s, 1);
~pitchBus = Bus.control(s, 1);
~pitchShiftMixValBus = Bus.control(s, 1); //mix % between orig and pitch-shifted signal

//  Audio Output <----
~play1LevelBus = Bus.control(s, 1); //output level of ~bufPlayer
~playOut1Bus = Bus.audio(s, 1);  //audio output bus of ~bufPlayer

~pitchShiftOut = Bus.audio(s, 1);  //audio output bus for ~pShift

~inputStreamLevelBus = Bus.control(s, 1);  //output level of ~pShiftMix synth (rename to stream1level?)

~fileOutputLevelBus = Bus.control(s, 1);  //output level of sample playback synths (rename to stream2level or sampPbackLevelBus?)


//  SUB BUSSES ('streams') ------

~stream1sub = Bus.audio(s, 1); //audio bus of live buffer processing output
~stream2sub = Bus.audio(s, 1); //audio bus of sample playback processing output
//<-
//<--
//<---
//<---- add more audio sub bus / 'stream' / processing for layered FX and sequencing?????


//  MASTER OUT ------

//  Level --
~outMainLevelBus = Bus.control(s, 1);
~outMainBus = Bus.audio(s, 1);

//  Filter --
~loCutBus_in = Bus.control(s, 1);
~loCutBus_out = Bus.control(s, 1);
~outMainPeakFreq = Bus.control(s, 1);
~outMainPeakQ = Bus.control(s, 1);
~outMainPeakGain = Bus.control(s, 1);

//  Compressor --
//control busses for master out compressor  (make this auto-generated only when compressor enabled)  <---
~comp1thresh = Bus.control(s, 1);
~comp1ratio = Bus.control(s, 1);
~comp1attack = Bus.control(s, 1);
~comp1release = Bus.control(s, 1);
~comp1gain = Bus.control(s, 1);


//  AUDIO ANALYSIS BUSSES ------
//  (again, only auto-generate when audio analysis for specific features is active) <---
~bus_loudness = Bus.control(s, 1);
~bus_rms = Bus.control(s, 1);
~bus_mfcc = Bus.control(s, 13);
~bus_pitch = Bus.control(s, 2);
~bus_pitch2 = Bus.control(s, 3);
~bus_specCent = Bus.control(s, 1);
~bus_specFlat = Bus.control(s, 1);
~bus_onsets = Bus.control(s, 1);
);