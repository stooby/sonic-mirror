//Sonic Mirror - 01_Startup:

//== Server Options and Hardware I/O Setup ==

(
o = Server.local.options;

o.sampleRate = 48000; //use w/ external USB mic "MiC"
o.blockSize = 256; //SC default
//s.latency = 0.05; //uncomment to adjust latency 0.2 is SC default

o.memSize = 16384;  // kilobytes of RAM allocated to the server

o.inDevice = nil; //select system default audio input
o.outDevice = nil; //select system default audio output

//o.inDevice = "Built-in Microph"; //built-in mic for MacBook
//o.outDevice = "Built-in Output"; //built-in speaker for MacBook

//o.inDevice = "iConnectAudio4+"; //external audio interface
//o.outDevice = "iConnectAudio4+";

//o.inDevice = "USB Audio Device"; //configure Sabrent USB Soundcard as input
//o.outDevice = "USB Audio Device"; //configure Sabrent USB Soundcard as output

//o.inDevice = "C-Media USB Audio Device";
//o.outDevice = "C-Media USB Audio Device";

s.boot;
);

//ServerOptions.devices; //uncomment and evaluate this line to see what audio input/output devices are available to your computer (if you want to customize your audio I/O)