# sonic-mirror
---
super alpha!

### what?
* Sonic Mirror is an open-ended audio software (and hardware) system designed for autonomous embedded audio recording, analysis, and synthesis.

* Programmed with the SuperCollider language.  Project details and documentation online:  http://scott-tooby.com/sonic-mirror.html

### what do I need?
* At least a modern computer with a built-in soundcard, microphone, and speakers.

* SuperCollider: http://supercollider.github.io/

### how do I turn this thing on?
1. Startup the SuperCollider IDE, open “05_InitSM.scd” and configure the two file paths at the top to local directories on your system where you’d like the Sonic Mirror to write input and output audio files. Don’t forget to save after making any changes.

2. If you’d like to configure your audio hardware settings, open “01_Startup.scd” and make the changes here.  Otherwise, if you’re just running this off your laptop, leave as is (unless you want to change the sampling rate). Save this file if you’ve made any changes.

3. Open “00_AutoBoot.scd” and replace the directory at the top of the document with the file path to wherever you’ve installed the Sonic Mirror project folder on your computer. Save this file after making your changes. (If you want to configure a simple output test only, set “~outputTest = true”).

4. Click anywhere within the main brackets and evaluate the entire block of code to startup the SuperCollider server and launch the Sonic Mirror program.

### how do I run this thing?
* Press the 'REC' button to begin recording audio input to the buffer

* Press the 'PLAY' button to begin playing audio back from the buffer

* Click anywhere in the red or green tracks to move the record or playback transport positions, respectively.

* Press the "REV" button to play audio in reverse

* Enabling the "!", "!!", or "!!!" buttons will trigger various autonomous audio processing and playback modes.  Parameters like: rate, pitch, pitch shift mix, output volume, reverse, and playback position will be pseudo-randomly modulated over time.

* Pro tip: arranging your microphone and speaker(s) so they feed back on themselves can create some fantastic sounds when the Sonic Mirror's autonomous behavior buttons are enabled, or during manual control of various playback parameters.  Watch out for runaway feedback!

---
This is a work in progress...

It has been exhaustively tested and exhibited on Mac and Raspbian systems.  It can run for hours and hours, indefinitely, on a Raspberry Pi 3 without any issues.

Feel free to use, experiment, and contribute:  https://github.com/stooby/sonic-mirror

st, 2018