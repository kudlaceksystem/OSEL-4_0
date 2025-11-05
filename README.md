# OSEL-4_0 Open Signal Explorer and Labeller

OSEL (Czech word for donkey) is Matlab-based signal viewer developed at Second Faculty of Medicine, Charles University in Prague. It was developed mostly for viewing and annotating long-term intracranial EEG or local field potential (LFP) recordings from experimental mice. It can play synchronized video. We believe it can serve many applications even outside the field of biomedical research.

## What you can do in OSEL:
- Show multi-channel signals (even if the channels have different sample rates)
	- Scroll
	- Zoom
	- Navigate between many hundreds of sequential data files
	- Select channels
	- Filter the signal
	- Perform basic mathematical operations such as computing average reference
- Label various patterns and transients 
	- You define label classes (e.g. "Sleep", "Noise", "Seizure")
	- Each label has a value which may have any meaning you assign to it (e.g. sleep stage, severity of the seizure or how much confident you are it really is a seizure)
	- You specify colors for the labels, the value is coded by brightness
	- You can easily move label's start and end even after it is created or delete it
	- OSEL is designed for easy visualization and editting of labels created by an automated detector, especially deleting false positive detections
	- The labels are stored in a separate mat-file named according to the signal file so that they can be automatically paired
	- You can export labels in a xlsx-file
- Play synchronized video
	- You can easily change the playing speed by + and - keys
	- You can easily change the brightness of the video (e.g. if night videos are to dark)
- You can load various data types and OSEL converts them to proprietary (but easy to use) Matlab table which you can save a mat-file
	- smr and smrx files (Cambridge Electronic Design, recorded by Spike2)
	- rhd and rhs files (Intan Technologies)
	- h5 files if they are in a required format
	- mat-file formats we use in our lab
- It is easy to add a function for loading any other data file

## What you cannot do in OSEL but there is a plan to implement it:
- Load edf files
- Compute longitudinal and transversal bipolar derivations for 10-20 EEG montage
- Show current source density in the background of the LFP signals
- Enable easy choice between 50 Hz and 60 Hz notch filter (now it is hard-coded)
- Sonification of the signal (in the longer future)

## What OSEL is not intended for:
- Automatic signal analysis and labeling. You are suppossed to run detectors using others scripts (hopefully provided soon by our team). OSEL will then allow you to view and refine the labels.


## Requirements
- Matlab
- Signal Processing Toolbox