(
~dir = "/home/pi/Desktop/dev/";
(~dir ++ "01_Startup.scd").load;
s.waitForBoot({
	~startup = Routine({
		(~dir ++ "02_SynthDefs.scd").load;// SynthDefs
		0.25.yield;
		(~dir ++ "03_Busses.scd").load;// Busses
		0.25.yield;
		(~dir ++ "04_Functions.scd").load;// Functions and Routines
		0.25.yield;
		(~dir ++ "01_AutoBoot_Launch.scd").load; //initialize env variables, GUI, and all the rest...
		0.25.yield;
		AppClock.play(~initSMpreset_voxelBot1); //initiate autoConvolution processes.....
	});
	AppClock.play(~startup);
});
);