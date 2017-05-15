//Sonic Mirror - 01_Startup:

//== Server Options and Hardware I/O Setup ==


//ServerOptions.devices; //uncomment and evaluate this to see what audio input/output devices are available (if you want to customize your audio I/O configuration)
(
o = Server.local.options;
//o.sampleRate = 44100;
o.sampleRate = 48000; //use w/ external USB mic "MiC"
//o.sampleRate = 96000;
//o.blockSize = 512;
o.blockSize = 256; //SC default
//s.latency = 0.05; //0.2 is SC default

o.memSize = 16384;

//o.inDevice = "Built-in Microph";
//o.outDevice = "Built-in Output";

//o.inDevice = "Generic USB Audio Device";
//o.inDevice = "USB Audio Device";
//o.outDevice = "USB Audio Device";

o.inDevice = "iConnectAudio4+";
o.outDevice = "iConnectAudio4+"; //external audio interface

//o.inDevice = "USB PnP Sound Device";

//o.inDevice = "MiC";  //external USB mic

//o.inDevice = nil; //use system default audio input (change value to manually configure input)
//o.outDevice = nil; //use system default audio output (change value to manually configure output)

//o.inDevice = "C-Media USB Audio Device";
//o.outDevice = "C-Media USB Audio Device";
//o.inDevice = "C-Media USB Headphone Set";
//o.outDevice = "C-Media USB Headphone Set";

s.boot;
);