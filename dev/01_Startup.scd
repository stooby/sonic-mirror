//Sonic Mirror - 01_Startup:

//== Server Options and Hardware I/O Setup ==


//ServerOptions.devices; //uncomment and evaluate this to see what audio input/output devices are available (if you want to customize your audio I/O configuration)
(
o = Server.local.options;
o.sampleRate = 44100;
//o.sampleRate = 48000; //use w/ external USB mic "MiC"
o.blockSize = 512;
s.latency = 0.05; //0.2 is SC default

o.inDevice = nil; //use system default audio input (change value to manually configure input)
o.outDevice = nil; //use system default audio output (change value to manually configure output)

//o.inDevice = "MiC";  //external USB mic
//o.outDevice = "iConnectAudio4+"; //external audio interface

s.boot;
);