# OSEL-4_0 Open Signal Explorer and Labeller

OSEL (Czech word for donkey) is Matlab-based signal viewer developed at Second Faculty of Medicine, Charles University in Prague. It was developed mostly for viewing and annotating long-term intracranial EEG or local field potential (LFP) recordings from experimental mice. It can play synchronized video. We believe it can serve many applications even outside the field of biomedical research.

## Requirements
- Matlab (tested on Matlab 2024b)
- Signal Processing Toolbox

## How to run OSEL
Open Matlab and locate the OSEL folder in the Matlab's Files window. Open main.m and run it. The basic operation should be quite intuitive. There is a simple user guide EEG LABELING.docx (credit our student Jana Populová) in the folder. I have a plan to write a full reference manual with a complete description of all features. Let me know if you need it urgently.

OSEL works best if files are named according to the following convention:
subject-yymmdd_HHMMSS-info.ext, where
- subject ... name (code) of the subject or the computer used to record the data (in case multiple subjects are recorded on one computer)
- yymmdd_HHMMSS ... date and time, it is important to have _ and not - between the date and the time
- info ... any additional info you wish to have in the file name
- ext ... extension (e.g. h5)
Example: Donald-251105_145033-downsampled.h5

The label files are automatically saved (and searched for) with the same file name with appended -lbl3 and an extension .mat.
Example: Donald-251105_145033-downsampled-lbl3.mat
If OSEL cannot find the exact same name, it will try to match the date and time. This may happen if you have recorded multiple subjects on a computer (say PC01), then processed the data sorted out to individual subjects and labelled them and now you want to see the labels in the unprocessed data. So e.g. PC01-251105_145033.smrx will match with the label file Donald-251105_145033-downsampled-lbl3.mat. This will, however, only work if you use the correct format of the date and time. Also, if there are different number of channels, it is not guaranteed that the labels will be displayed correctly (I will try to work this out in the near future).

## What you can do in OSEL
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
- View spectrogram and current source density for linear electrode arrays
	- Use a built-in application Neuro Signal Studio for a more detailed analysis of a portion of signal
- You can load various data types and OSEL converts them to proprietary (but easy to use) Matlab table which you can save a mat-file
	- smr and smrx files (Cambridge Electronic Design, recorded by Spike2)
	- rhd and rhs files (Intan Technologies)
	- h5 files if they are in a required format
	- mat-file formats we use in our lab
- It is easy to add a function for loading any other data file

## What you cannot do in OSEL but there is a plan to implement it
- Load edf files
- Compute longitudinal and transversal bipolar derivations for 10-20 EEG montage
- Show current source density in the background of the LFP signals
- Enable easy choice between 50 Hz and 60 Hz notch filter (now it is hard-coded)
- Sonification of the signal (in the longer future)

## What OSEL is not intended for
- Signal analysis, feature extraction
	- You can extract features (e.g. signal power) in a sliding window and add it to the signal file as a new signal, possibly at a lower sample rate (according to the window shift). OSEL can then be used e.g. to show the raw signal and the feature underneath.
- Automatic signal labeling
	- You can run detectors using others scripts (hopefully provided soon by our team). OSEL will then allow you to view and refine the labels.
- Our team will soon provide a set of utilities which can be used to manipulate signal files and label files (e.g. concatenation, deleting unwanted channels, renaming channels, etc.)


## Technical description
OSEL is written using object programming in multiple classes. I am not an expert in programming so I welcome any suggestions (just drop me an email on kudlaceksystem@gmail.com). There are multiple classes and few folders with additional functions and resources.

### Classes

#### controlWindow.m
This class creates the main figure with the user interface. It also takes care of user actions and implements callbacks. Some of the callbacks call methods in other classes. In many cases I was unsure if a given operation should be implemented directly in the controlWindow class or in the respective other class (e.g. signal). Feedback from experienced programers will be appreciated :smile:

controlWindow stores also paths and names of all "loaded" files. They are not loaded in the RAM but the user can easily jump from one file to another using buttons at the top of the window, keyboard (PgDn and PgUp, or V and Z) or by typing the file number in the number box at the top of the window.

#### loadSignal.m
This class implements reading of the signal file (mat, smr, smrx, h5, rhd, rhs) into sigTbl variable with a standardized format which OSEL then works with. It is easy it add a function for loading any file type.

#### signal.m
This class creates axes and plots the signal. It also implements scrolling, zooming, filtering and calculation of other montages.

#### loadLabel.m
Now can only load -lbl3.mat label files. But you are free to implement loading from any other formats (csv, edf, xls, ...).

#### label.m
Creates the label window. It is separate so that one can possibly move it to another screen or wherever it is convenient. It takes care of plotting the labels and the user actions related to labelling.

#### video.m
Takes care of reading the video files.

#### videoShow.m
Takes care of actually showing the videos in a separate window (again, one can move it freely).

#### stgs.m
Stores settings (mostly window sizes).

#### keyShortTbl.m
Table of keyboard shortcuts. Note how many of them there are.

### Folders
#### @smr
Downloaded and adopted from CED (Cambridge Electronic Design). Functions for loading smr files.

#### CEDMATLAB
Downloaded and adopted from CED (Cambridge Electronic Design). Functions for loading smrx files.

#### pics
Pictures shown in the welcome screen or in easter eggs.

#### resource
Here one can store anything. We have there channels order for Neuronexus multichannels probes.

#### RHD
The original m-file for reading Intan's RHD files. Not used in the runtime of OSEL but useful for developers.

#### testing data
Some sample data (4-channel EEG and labels) of a mouse with epilepsy due to focal cortical dysplasia. Use it for trying out OSEL and debuging.


# The OSEL team
OSEL is being developed by </br>
Nedime Karakallukcu </br>
Anna Svobodová </br>
Jan Kudláček </br>

We are happy to help you adopt it and use it.
Email:
kudlaceksystem@gmail.com



