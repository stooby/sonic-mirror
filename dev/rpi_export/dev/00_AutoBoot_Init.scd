(
s.waitForBoot({

	~startup = Routine({
		~dir = "/home/pi/Desktop/dev/";
		0.25.yield;
		(~dir ++ "02_SynthDefs.scd").load;       // SynthDefs
		0.25.yield;
		(~dir ++ "03_Busses.scd").load;            // Busses
		0.25.yield;
		(~dir ++ "04_Functions.scd").load;        // Functions and Routines
		0.25.yield;
		(~dir ++ "01_AutoBoot_Launch.scd").load;
		0.25.yield;
		AppClock.play(~initSMpreset_1);
	});

	AppClock.play(~startup);
	//maybe use Task instead??
});
)