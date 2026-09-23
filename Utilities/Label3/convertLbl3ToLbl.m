function convertLbl3ToLbl
%% NOT FINISHED (NOT EVEN STARTED :-))
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
sigp = getSigp('Where to look for signal files');
savep = getSavep('Where to save modified label files');
hwb = waitbar(0, 'Label conversion...');
now000 = now;
nTimeEst = 20;
timeToAllM = 1;
for kf = 1 : length(filepn)
    %% Display progress
    waitbar(kf/length(filepn), hwb, ['Label conversion, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    disp(kf)
    disp(filepn{kf})
    if kf == nTimeEst
        nowTimeEst = now;
        timeToTimeEst = nowTimeEst - now000;
        timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
        waitbar(kf/length(filepn), hwb, ['Label conversion, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    end
    
    %% Load lbl3 file
    load(filepn{kf})
    lblnm = fieldnames(label); % Label class names
        
    %% Signal info table
    nSigCh = length(label.(lblnm{1}).chanNames);
    % Initialize the table
    sigInfo = table('Size', [nSigCh, 7],...
        'VariableTypes', {'string',       'string',       'string',       'string',       'datetime',  'datetime'  'double'},...
        'VariableNames', {'FileName',     'FilePath',     'Subject',      'ChName',       'SigStart',  'SigEnd',   'Fs'}); % Possible dropouts should be stored in a label class
    % Fill in the table. SigEnd and Fs are a bit tricky, we must go to the signal file.
    srcsigfile = label.(lblnm{1}).srcSigFile;
    if iscell(srcsigfile)
        srcsigfile = srcsigfile{1};
    end
    [sigFilep, sigFilen, sigFilee] =  fileparts(srcsigfile);
    sigInfo.FileName = repelem(string([sigFilen, sigFilee]), nSigCh)';
    sigInfo.FilePath = repelem(string(sigFilep)+"\", nSigCh)';
    sigInfo.Subject = repelem(string(label.(lblnm{1}).subject), nSigCh)';
    sigInfo.ChName = string(label.(lblnm{1}).chanNames(:));
    sigInfo.SigStart = repelem(datetime(regexp(sigInfo.FileName(1), '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match'), 'InputFormat', 'ddMMyy_HHmmss'), nSigCh)';
    sigpn = findCorrespondingSig(filepn{kf}, sigp);
    [siglenS, fs] = getSiglenFs(sigpn);
%     [siglenS, fs] = getSiglenFs(string([sigp, '\']) + sigInfo.FileName(1));
    sigInfo.SigEnd = sigInfo.SigStart + datenum(siglenS/3600/24);
    sigInfo.Fs = repelem(fs, nSigCh)';
    
    
    %% Label definitions and label set
    % Initialize the table (create a dummy one line table and then delete that line to get an empty table with the proper data types)
    ClassName = "Dummy";
    ChannelMode = categorical("one"); ChannelMode = addcats(ChannelMode, ["one", "all"]); % one: the label is associated with a channel,
    % all: the label is associated with animal's behavior, power-line glitch, lights on, etc.
    LabelType = categorical("point"); LabelType = addcats(LabelType, ["point", "roi"]);
    Color = "1 1 0";
    lblDef = table(ClassName, ChannelMode, LabelType, Color); % Dummy table. I was not able to declare the Color as 1x3 double array. 'double' creates only a scalar.
    lblDef(1, :) = [];
    
    % Initialize label set table, see comments below each column
    lblSet = table('Size', [0 9],...
        'VariableTypes', {'string',      'int16',    'datetime', 'datetime',   'double',      'string',  'logical',  'int64', 'string'},...
        'VariableNames', {'ClassName',   'Channel',  'Start',    'End',        'Value',       'Comment', 'Selected',   'ID',    'SignalFile'});
    %                     E.g. Seizure), Channel,    _______datetime_______,   User-defined,  Comment,   For delete,  Unique,  Signal filepn
    
    for klbl = 1 : length(lblnm)
        % Label definitions
        ClassName = string(lblnm{klbl});
        ChannelMode = categorical("one");
        if label.(lblnm{klbl}).instant
            LabelType = categorical("point");
        else
            LabelType = categorical("roi");
        end
        Color = string(label.(lblnm{klbl}).color);
        lblDef = [lblDef; table(ClassName, ChannelMode, LabelType, Color)]; %#ok<AGROW>
        
        % Label set
        chnm = fieldnames(label.(lblnm{klbl}));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
        for kch = 1 : length(chnm)
            ch = str2double(chnm{kch}(3 : end));
            if isnan(ch)
                ch = -1;
            end
            if isempty(label.(lblnm{klbl}).(chnm{kch}))
                continue
            end
            nlbl = length(label.(lblnm{klbl}).(chnm{kch}).posN);
            ClassName = repelem(string(lblnm{klbl}), nlbl)';
            Channel = repelem(ch, nlbl)';
            Start = datetime(label.(lblnm{klbl}).(chnm{kch}).posN(:), 'ConvertFrom', 'datenum');
            if ~isfield(label.(lblnm{klbl}).(chnm{kch}), 'durN')
                End = Start;
            else
                End = datetime(label.(lblnm{klbl}).(chnm{kch}).posN(:) + label.(lblnm{klbl}).(chnm{kch}).durN(:), 'ConvertFrom', 'datenum');
            end
            Value = label.(lblnm{klbl}).(chnm{kch}).value(:); if length(Value) > length(Start); Value = Value(1 : length(Start)); end
            Comment = repelem("", nlbl)';
            Selected = repelem(false, nlbl)';
            if isempty(lblSet.ID)
                ID = int64(1 : nlbl)';
            else
                ID = max(lblSet.ID) + int64(1 : nlbl)';
            end
            if isfield(label.(lblnm{klbl}), 'srcSigFile')
                if ischar(label.(lblnm{klbl}).srcSigFile)
                    SignalFile = repelem(string(label.(lblnm{klbl}).srcSigFile), nlbl)';
                elseif iscell(label.(lblnm{klbl}).srcSigFile)
                    SignalFile = repelem(string(label.(lblnm{klbl}).srcSigFile{1}), nlbl)';
                end
            else
                SignalFile = repelem(sigInfo.FileName(1), nlbl)';
            end
            lblSet = [lblSet; table(ClassName, Channel, Start, End, Value, Comment, Selected, ID, SignalFile)]; %#ok<AGROW>
        end
    end
    [~, saven, savee] = fileparts(filen{kf});
    savepne = [savep, '\', saven, '3', savee];
    save(savepne, 'sigInfo', 'lblDef', 'lblSet')
end
delete(hwb)
disp('Finished')
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
function sigpn = findCorrespondingSig(filepn, sigp)
    pattern = regexp(filepn, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
    d = dir(sigp);
    d = d(~[d.isdir]);
    signAll = {d.name};
    sign = signAll{contains(signAll, pattern)};
    sigpn = [sigp, '\', sign];
end

