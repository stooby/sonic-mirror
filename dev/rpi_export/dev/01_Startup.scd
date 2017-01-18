//Sonic Mirror - 01_Startup:

//== Server Options and Hardware I/O Setup ==

//ServerOptions.devices; //uncomment and evaluate this to see what audio input/output devices are available (if you want to customize your audio I/O configuration)
(
o = Server.local.options;
//o.sampleRate = 44100;
o.sampleRate = 44100; //use w/ external USB mic "MiC"
o.blockSize = 1024;
//o.blockSize = 64; //SC default
s.latency = 0.2; //0.2 is SC default

//o.inDevice = "Built-in Microph";
//o.inDevice = "iConnectAudio4+";
//o.outDevice = "Built-in Output";

//o.inDevice = "MiC";  //external USB mic

o.inDevice = nil; //use system default audio input (change value to manually configure input)
o.outDevice = nil; //use system default audio output (change value to manually configure output)

//o.inDevice = "C-Media USB Headphone Set";
//o.outDevice = "C-Media USB Headphone Set";



//o.outDevice = "iConnectAudio4+"; //external audio interface

s.boot;
);