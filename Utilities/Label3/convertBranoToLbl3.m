% function convertBranoToLbl3
close all
clear
disp('convertBranoToLbl3')

% [xlsn, xlsp] = uigetfile('*.xls*', 'Browse Brano-excel table', 'MultiSelect', 'off');
xlsp = 'r:\SUDEP\Jan testing\';
xlsn = 'Amygdala chronic recordings TeNT rats - downloaded on 20231115.xlsx';
xlsBrano = readtable([xlsp, xlsn], 'Sheet', 1);
% sigp1 = getSigp('Where to look for smr files');
sigp1 = 'r:/SUDEP/Jan testing/';
% savep = getSavep('Where to save OSEL label files');
savep = 'r:/SUDEP/Jan testing/Label';

% Label definitions (same for all files)
ClassName = "Seizure";
ChannelMode = categorical("one"); ChannelMode = addcats(ChannelMode, ["one", "all"]); % one: the label is associated with a channel,
% all: the label is associated with animal's behavior, power-line glitch, lights on, etc.
LabelType = categorical("roi"); LabelType = addcats(LabelType, ["point", "roi"]);
Color = "1 0 0";
lblDef = table(ClassName, ChannelMode, LabelType, Color);

% Start working with the xls
folders = unique(xlsBrano{:, 2}); % In which folders to look for signal files
folders = folders(cellfun(@(x) ~isempty(x), folders));
for kfo = 1 : numel(folders)
    xlsFolder = xlsBrano(strcmp(xlsBrano{:, 2}, folders{kfo}), :);
    snlnum = unique(xlsFolder{:, 5});
    snlnum = snlnum(~isnan(snlnum));
    if isempty(snlnum)
        continue
    end
    for kn = 1 : numel(snlnum)
        snlNum = snlnum(kn);
        xls = xlsFolder(xlsFolder{:, 5} == snlNum, :);
        xls = xls(~isnan(xls{:, 8}), :);
        if isempty(xls)
            continue
        end
        
        %% Create sigInfo table
        snlNumStr = num2str(snlNum, '%03d');
        sigp = [sigp1, xls{1, 2}{1}];
        sigpn = findCorrespondingSig(snlNumStr, sigp);
        [snlp, snln, snle] = fileparts(sigpn);
        sbj = xls{1, 1};
        sigInfo = getSmrInfo(sigpn);
        % Get only channels which contain the desired subject
        subject = xls{1, 1}{1};
        if ~all(strcmpi(xls{:, 1}, subject))
            error('_jk Multiple subjects in the sheet')
        end
        sigInfo = sigInfo(sigInfo.Subject == subject, :);
        nSigCh = size(sigInfo, 1);
        
        %% Create lblSet
        numLbl = size(xls, 1);
        ClassName = repelem("Seizure", numLbl, 1);
        Channel = repelem(2, numLbl, 1);
        Start = sigInfo.SigStart(1) + seconds(xls{:, 8})
asdf = seconds(xls{:, 10})
        End = Start + seconds(xls{:, 10})
        Value = repelem(5, numLbl, 1);
        Comment = ["R" + string(xls{:, 9}) + "_A" + string(num2str(xls{:, 11}))];
        ID = (1 : numLbl)';
        SignalFile = repelem(string(snln), numLbl, 1);
        Selected = repelem(false, numLbl, 1);
        lblSet = table(ClassName, Channel, Start, End, Value, Comment, Selected, ID, SignalFile);
        lblSet.ClassName = categorical(lblSet.ClassName);
        lblSet.Comment = categorical(lblSet.Comment);
        lblSet.SignalFile = categorical(lblSet.SignalFile);
% snln
% datestr(sigInfo.SigStart(1), 'yymmdd_HHMMSS')
        saven = [sbj{1}, '-', datestr(sigInfo.SigStart(1), 'yymmdd_HHMMSS'), '-lbl3.mat'];
        savepne = [savep, '/', saven]
        sigInfo
        lblDef
        lblSet
        save(savepne, 'sigInfo', 'lblDef', 'lblSet')
        clear sigInfo lblSet
    end
end
delete(hwb)
disp('Finished')
% end

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
function sigp = getSigp(prompt)
    sigpath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
    if exist('startpath.mat', 'file')
        load('startpath.mat'); %#ok<LOAD>
    end
    sigp = uigetdir(sigpath, prompt);
    if ischar(sigp)
        sigpath = sigp;
        save('startpath.mat', 'sigpath', '-append');
    end
end
function [siglenS, fs] = getSiglenFs(sigpn)
    mf = matfile(sigpn);
    siglenS = size(mf.s, 2)/mf.fs;
    fs = mf.fs;
%     load(sigpn); %#ok<LOAD>
%     siglenS = size(s, 2)/fs;
end
function sigpn = findCorrespondingSig(fileNum, sigp)
%     pattern = regexp(filepn, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
%     pattern = regexp(filepn, '_\d\d\d.smr', 'match');
    pattern = [fileNum, '.smr'];
    d = dir([sigp, '/*.smr*']);
    d = d(~[d.isdir]);
    signAll = {d.name}';
    sign = signAll{contains(signAll, pattern)};
    sigpn = [sigp, '/', sign];
end
function [ChName, sigDur] = getSmrxInfo(filepn) % ChName ... cell array, sigDur ... duration scalar
    % Jan Emsik Chvojka 2020
    % Modified by Jan Kudlacek 2022
    if isempty(getenv('CEDS64ML'))
        setenv('CEDS64ML', [cd, '\CEDMATLAB\CEDS64ML']);
    end
    cedpath = getenv('CEDS64ML');
    addpath(cedpath);
    CEDS64LoadLib(cedpath);
    fhand = CEDS64Open(filepn);
    if (fhand <= 0);  warning(['_jk Could not load ', filepn]); CEDS64ErrorMessage(fhand); unloadlibrary ceds64int; return; end

    % Get channel names and number of channels
    nch = [];
    chnm = [];
    chn = [];
    for kch = 1 : 1000
        [iOK, nm] = CEDS64ChanTitle(fhand, kch);
        if iOK == 0
            nch(end+1) = kch; %#ok<AGROW>
            chnm{end+1} = nm; %#ok<AGROW>
            chn(end+1) = kch;
        end
    end
    chnm = chnm(cellfun(@(x) ~isempty(x), chnm, 'UniformOutput', true)); % Keep only channels with non-empty names


% chchnmnm = chnm(cellfun(@(x)~isempty{x}, chnm))
    % Keep only ADC channels
    for k = 1 : length(nch)
        typ(k) = CEDS64ChanType(fhand, nch(k)); %#ok<AGROW> % Get channels type (ADC, Marker, etc.)
    end
    chnm = chnm(typ == 1)
    
    % Process the channels
    for kch2 = 1 : length(chnm)
        str = chnm{kch2};
        r = regexpi(str, '\w\w?-[ABCD]-\w+', 'match');
        if ~isempty(r)
            s = strsplit(r{1}, '-');
            ChName{kch2} = string(str);
            RecPosition = string(s{2});
            Subject = string(['recID_', s{3}]);
%             RecPosition = 'BranoAparatus';
%             Subject = 'BranoTheRat';
        else
            r = regexpi(str, '\w\w?-[ABCD]', 'match');
            if ~isempty(r)
                s = strsplit(r{1}, '-');
                ChName{kch2} = string(str);
                RecPosition = string(s{2});
                Subject = ""; % Will be filled in later
            end
            [sigDurS] = CEDS64TicksToSecs(fhand, CEDS64ChanMaxTime(fhand, chn(kch2)));
            Fs = double(CEDS64IdealRate(fhand, chn(kch2)));
            if Fs == 0
                Fs = NaN;
            end
        end
        unloadlibrary ceds64int;
    end
    sigDur = seconds(sigDurS);
end
function sigInfo = getSmrInfo(filepn)
    [filep, filen, ~] = fileparts(filepn);
    
    % Channel info
    [chanNames, ~, smrChN, comments] = smr.smrLoadChanNames(filepn);
    numch = length(chanNames);
    
    % Subject name
    for k = 1 : numel(comments)
        r = regexpi(comments{k}, '\D+_?\d\d\d\d\d+_?\d*', 'match');
        if ~isempty(r)
            subject(k, 1) = string(r); %#ok<AGROW>
        else
            subject(k, 1) = ""; %#ok<AGROW>
        end
    end
    if any(subject ~= "")
        Subject = subject;
    elseif ~exist('Subject', 'var')
        if contains(filen, '-')
            ss = strsplit(filen, '-');
            subject = ss{1};
            r = regexpi(filen, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
            if strcmp(ss, r)
                subject = ss{2};
            end
            Subject = repelem(string(subject), numch, 1);
        else
            r = regexpi(filen, '\d\d\d\d\d\d_\d\d\d\d\d\d');
            subject = filen(1 : r - 1);
            Subject = repelem(string(subject), numch, 1);
        end
    end
    
    % Signal start time
    r = regexpi(filen, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
    if isempty(r)
        r = inputdlg('Input date and time in the format yymmdd_HHMMSS');
    end
    dateStr = r{1};
    SigStart = repelem(datetime(dateStr, 'InputFormat', 'yyMMdd_HHmmss'), numch, 1);
    RecPosition = repelem("Unknown", numch, 1);
    ChName = string(chanNames);
    
    % Loop over channels
    for kch = 1 : length(chanNames)
        Fs(kch, 1) = smr.smrLoadFs(filepn, smrChN(kch)); %#ok<AGROW>
        SigEnd(kch, 1) = SigStart(kch, 1) + seconds(smr.smrGetSignalLength(filepn)); %#ok<AGROW>
    end
    
    FileName = repelem(string(filen), numch, 1);
    FilePath = repelem(string(filep), numch, 1);
    sigInfo = table(FileName, FilePath, Subject, ChName, SigStart, SigEnd, Fs);
end



