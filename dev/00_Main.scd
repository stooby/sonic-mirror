//Sonic Mirror - 00_Main:

//== Main Performance Doc ==

//execute below lines one at a time to launch

~dir = "/Users/Scott/Dropbox/DocSync/Project Docs/DigitalArt/SonicMirror/sonic-mirror_SC_git/dev/"; //input file path to SM code folder here

(~dir ++ "01_Startup.scd").load;           // Server Options and Startup
(~dir ++ "02_SynthDefs.scd").load;       // SynthDefs
(~dir ++ "03_Busses.scd").load;            // Busses
(~dir ++ "04_Functions.scd").load;        // Functions and Routines
(~dir ++ "05_InitSM.scd").load;            // Main SM Initialization Code
~init_SonicMirror.();                            //Launch

//////////////////
~writeSampFromBuf_name.(buffer: ~audioBuf0, in: (~playInFrame/s.sampleRate), out: (~playOutFrame/s.sampleRate), filePath: ~fileAudio_writeOut_lastFile); //execute this line to sample audio file from main buffer based on playhead in/out positions


/////////////testing junk
~audifyRout = ~audifyScene1.(~fileAudio_writeIn_lastPath, ampBus: ~fileOutputLevelBus.asMap, outBus: ~outMainBus, fileNum: 15, cycle: 2, rate: 24, pitch: -24, status: \audifyState);
SystemClock.play(~audifyRout);
~audifyRout.stop;
~audifyRout.reset;
///////////////