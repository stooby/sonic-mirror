# TODO
---
sonic-mirror To-DO.  Big and small things, loosely ordered in priority from top to bottom and not always coherently formulated.

#todo

* Enable playback of saved audio samples w/ "PLAY FILE" button
* Complete ~soundRoutine_autoRec and add to "^v" ~buttonRandAutoRecPlayFiles button

* Integrate machine listening classes to render continuous state of detected events in audio buffer:
      • Loudness  (and amplitude for RMS?)
      • DetectSilence
      • Pitch
      • MFCC
      • SpecCentroid
      • Onsets
      • BeatTrack2
      • KeyTrack?
* Revisit and refine sample auto-save/playback routine (use machine listening classes to more accurately discern discrete sound events)
* Automatic classification and labeling of sampled audio based on ML audio feature extraction

* GUI Plotter visualization of waveform of entire buffer.

* Setup OSC transmission to/from Wekinator??? (for machine learning classification of sound events and behavior triggering)
* Sound scene monitoring (long-term audio event analysis based on polling ML classes at different time scales)

* Develop more interactive performance behaviors:
      • Autoharmonize
      • Slicer/Looper
      • Rhythmic scrubber
      • Sync Sample
* Streamline creation process of performance behaviors ("behavior template" ... routines enclosed w/in function(s)?)

* Debug delay time offset slider & num box input
* Implement digital audio feedback control???
* Preset saving

* Implement real-time (seconds) AND beat-based (BPM) scheduling of events
* Test and minimize system audio latency
* REFACTOR, REFACTOR, REFACTOR !!!
* GUI cleanup and refactor.  (Implement GridLayout and possibly FlowLayout for responsive GUI.)