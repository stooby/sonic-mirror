//Sonic Mirror AutoBoot

(//evaluate to launch and configure SM automatically
s.waitForBoot({

	~startup = Routine({
		//change the filepath below to match the enclosing directory on your system of this Sonic Mirror repo
		~dir = "/Users/Scott/Dropbox/DocSync/Project Docs/DigitalArt/SonicMirror/sonic-mirror_SC_git/dev/";
		~outputTest = true; //set this to 'true' to perform a simple looping output test
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

		//configure preset settings (these presets live in "04_Functions.scd")
		if (~outputTest == true,
			{AppClock.play(~initSMpreset_test);}, //if test mode enabled
			{AppClock.play(~initSMpreset_2);} //else run regular SM preset
		);
	});

	AppClock.play(~startup);
});
)