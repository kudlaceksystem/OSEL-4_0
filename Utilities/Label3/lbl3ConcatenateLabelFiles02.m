function lbl3ConcatenateLabelFiles02

% filep = 'N:\EEG conversion\MisaET3025\label nejedly test 03';
% filep = '\\neurodata\Lab Neurophysiology root\EEG Naty\Dead mice\mTOR MUT\NatySST_TdTET339\Labels Kudlajda';
% filep = 'n:\EEG Naty\Hotove\mTOR MUT\NatymTORET283\Labels Kudlajda\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG Naty\mTOR MUT\Naty SST_TdT ET 343\label Kudlajda\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG Naty\mTOR MUT\Naty SST_TdT ET 413\Labels Kudlajda\';
% subjnm = 'jc20190313_1';
% filep = ['k:\JK analysis\', subjnm, '\lbl3 sz emg ied 4\'];
% filep = 'n:\EEG conversion\JP000697\Label\';
%% For Premek for seizure onset patterns
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\CO006701\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\JK003911\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002288\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002287\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002390\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET430\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET490\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET929\Label\';
% filep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET534\Label\';
filep = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT II\Naty SST_TdT ET 343\label\';

d = dir(filep);
isname = ~[d.isdir];
filen = {d.name};
filen = filen(isname);
filepn = fullfile(filep, filen);
% return
% savep = ['k:\JK analysis\', subjnm, '\lbl3 sz one file\'];
% savep = 'n:\EEG conversion\JP000697\LabelConcatenated\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\CO006701\LabelConcatenated\';
% savep = getSavep('Where to save modified label files');
% lblClassName = "Sz_Nejedly01";
% minLblDurS = 10;


%% For Premek for seizure onset patterns
savep = [filep(1 : end-1), 'Concatenated\'];


hwb = waitbar(0, 'Concatenating labels...');
now000 = now;
nTimeEst = 20;
timeToAllM = 1;

% Load the first file
firstLbl = 1;
% firstLbl = 132;
% lastLbl = 57;
lastLbl = length(filepn);
load(filepn{firstLbl}, 'sigInfo', 'lblDef', 'lblSet')
lblSet.ClassName = string(lblSet.ClassName);
lblSet.Comment = string(lblSet.Comment);
lblSet.SignalFile = string(lblSet.SignalFile);
% sigInfo = sigInfo(1 : 5, :); % Because of Naty mice
for kf = firstLbl : lastLbl
    %% Display progress
    waitbar(kf/length(filepn), hwb, ['Concatenating labels, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    disp(kf)
    disp(filepn{kf})
    if kf == nTimeEst
        nowTimeEst = now;
        timeToTimeEst = nowTimeEst - now000;
        timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
        waitbar(kf/length(filepn), hwb, ['Concatenating labels, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    end
    
    %% Append to the first file
    l = load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet');
    % l.lblSet = l.lblSet(l.lblSet.ClassName == "SEIZURE" | l.lblSet.ClassName == "seizure", :);
%     l.sigInfo = l.sigInfo(1 : 5, :); % Because of Naty mice
    if size(sigInfo, 1) ~= size(l.sigInfo, 1)
        disp(sigInfo)
        disp(l.sigInfo)
        error('_jk Different numbers of channels')
    end
    if ~all(l.sigInfo.Subject == sigInfo.Subject)
        disp(sigInfo)
        disp(l.sigInfo)
        error('_jk Subjects do not correspond')
    end
    if ~all(l.sigInfo.ChName == sigInfo.ChName)
        disp(sigInfo)
        disp(l.sigInfo)
        error('_jk Channels do not correspond')
    end
    lblDef = [lblDef; l.lblDef(~ismember(l.lblDef.ClassName, lblDef.ClassName), :)]; %#ok<AGROW> % Append label classes which are so far not present in lblDef
    
    l.lblSet.ClassName = string(l.lblSet.ClassName);
    l.lblSet.Comment = string(l.lblSet.Comment);
    l.lblSet.SignalFile = string(l.lblSet.SignalFile);
    lblSet = [lblSet; l.lblSet]; %#ok<AGROW>
end
lblSet.ClassName = categorical(lblSet.ClassName);
lblSet.Comment = categorical(lblSet.Comment);
lblSet.SignalFile = categorical(lblSet.SignalFile);
% lblSet = lblSet(lblSet.ClassName == "SEIZURE" | lblSet.ClassName == "seizure", :);
lblSet = lblSet(lblSet.Channel ~= -1, :);
disp(lblSet)
[~, savenStart, savee] = fileparts(filen{firstLbl});
[~, savenEnd, ~] = fileparts(filen{lastLbl});
saven = ['___', savenStart, '---', savenEnd];
mkdir(savep);
savepne = [savep, saven, savee];
save(savepne, 'sigInfo', 'lblDef', 'lblSet')
delete(hwb)
disp('Finished')
disp('Resulting file is here:')
disp(savepne)
end

function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
    loadpath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
    if exist('startpath.mat', 'file')
        load('startpath.mat', 'loadpath');
    end
    [filen, filep] = uigetfile([loadpath '\*.' ext], prompt, 'MultiSelect', 'on');
    if ischar(filep)
        loadpath = filep;
        if exist('startpath.mat', 'file')
            save('startpath.mat', 'loadpath', '-append');
        else
            save('startpath.mat', 'loadpath');
        end
    end
    filepn = fullfile(filep, filen);
    if ~iscell(filepn) && ~iscell(filep) && ~iscell(filen)
        a{1} = filepn;
        b{1} = filep;
        c{1} = filen;
        clear filepn filep filen
        filepn = a;
        filep = b;
        filen = c;
    end
end
function savep = getSavep(prompt)
    savepath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
    if exist('startpath.mat', 'file')
        load('startpath.mat'); %#ok<LOAD>
    end
    savep = uigetdir(savepath, prompt);
    if ischar(savep)
        savepath = savep;
        save('startpath.mat', 'savepath', '-append');
    end
end
% function sigp = getSigp(prompt)
%     sigpath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
%     if exist('startpath.mat', 'file')
%         load('startpath.mat'); %#ok<LOAD>
%     end
%     sigp = uigetdir(sigpath, prompt);
%     if ischar(sigp)
%         sigpath = sigp;
%         save('startpath.mat', 'sigpath', '-append');
%     end
% end
% function [siglenS, fs] = getSiglenFs(sigpn)
%     mf = matfile(sigpn);
%     siglenS = size(mf.s, 2)/mf.fs;
%     fs = mf.fs;
% %     load(sigpn); %#ok<LOAD>
% %     siglenS = size(s, 2)/fs;
% end
% function sigpn = findCorrespondingSig(filepn, sigp)
%     pattern = regexp(filepn, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
%     d = dir(sigp);
%     d = d(~[d.isdir]);
%     signAll = {d.name};
%     sign = signAll{contains(signAll, pattern)};
%     sigpn = [sigp, '\', sign];
% end

