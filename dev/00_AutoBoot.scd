//Sonic Mirror AutoBoot

(//evaluate to launch and configure SM automatically
s.waitForBoot({

	~startup = Routine({
		~dir = "/Users/Scott/Dropbox/DocSync/Project Docs/DigitalArt/SonicMirror/sonic-mirror_SC_git/dev/";
		0.25.yield;
		(~dir ++ "02_SynthDefs.scd").load;       // SynthDefs
		0.25.yield;
		(~dir ++ "03_Busses.scd").load;            // Busses
		0.25.yield;
		(~dir ++ "04_Functions.scd").load;        // Functions and Routines
		(~dir ++ "05_InitSM.scd").load;            // Main SM Initialization Code
		0.25.yield;
		~init_SonicMirror.();                            //Launch
		0.25.yield;
		AppClock.play(~initSMpreset_2); //configure preset settings (these presets live in "04_Functions.scd")
	});

	AppClock.play(~startup);
});
)