(
s.waitForBoot({

	~startup = Routine({
		~dir = "/Users/Scott/Dropbox/DocSync/Project Docs/DigitalArt/SonicMirror/sonic-mirror_SC_git/dev/";
		0.25.yield;
		(~dir ++ "02_SynthDefs.scd").load;       // SynthDefs
		0.25.yield;
		(~dir ++ "03_Busses.scd").load;            // Busses
		0.25.yield;
		(~dir ++ "04_Functions.scd").load;        // Functions and Routines
		0.25.yield;
		(~dir ++ "/autoboot_test/01_AutoBoot_Launch.scd").load;
		0.25.yield;
		//AppClock.play(~initSMpreset_2); //these presets live in "04_Functions.scd" now
		AppClock.play(~initSMpreset_voxelBot1);
	});

	AppClock.play(~startup);
});
)