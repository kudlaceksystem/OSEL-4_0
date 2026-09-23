function subject = AntanMatToWKJ

% chanNames = {'DHippR'; 'DHippR2'; 'DHippL'; 'DHippL2'};
% chanNames = {'DHippR'; 'DHippR2'; 'MCxR'; 'MCxR2'; 'DHippL'; 'DHippL2'; 'MCxL'; 'MCxL2'};
chanNames = {'Breath'; 'Ground'; 'ECG R'; 'ECG L'; 'DHippR1'; 'DHippR2'; 'DHippL1'; 'DHippL2'};
increaseAmplitudeOfCh01Ch02 = 1;

saveDecimatedSignal = 0;
saveOrigFs = 1; % If one, non-decimated signal is saved. This is useful to convert


o = getFilepnAll;

%% Folder to save decimated signal
if saveDecimatedSignal
    dPath = uigetdir('g:\_Kudlacek\', 'Where to put decimated signal files');
end

%% Folder to save orig fs signal
if saveOrigFs
    oPath = uigetdir('g:\_Kudlacek\', 'Where to put orig fs signal files');
end

%% Main loop
for kF = 1 : length(o)
disp(kF)
disp(o{kF})

[fpat, fnam, exte] = fileparts(o{kF});

if strcmp(exte, '.smr')
    [chanNames, ~, smrChN] = smr.loadChanNames(o{kF});
    s = [];
    for kL = 1 : length(chanNames)
        sss = smr.loadChannel(o{kF}, smrChN(kL));
        if ~isempty(s)
            if length(sss) > length(s)
                sss = sss(1, 1 : length(s));
            elseif length(sss) < length(s)
                sss = [sss, sss(1, end)]; %#ok<AGROW>
            end
        end
        s(kL, :) = sss; %#ok<AGROW>
    end
    fsO = smr.loadFs(o{kF}, smrChN(1));

    % Subject and date
    if fnam(1) == '-' || ismember(double(fnam(1)), 48 : 57)
        c = strsplit(fpat, '\');
        subject = c{end};
        c = strsplit(fnam, '-');
        if fnam(1) == '-'
            dateS = c{2};
        else
            dateS = c{1};
        end
    else
        c = strsplit(fnam, '-');
        subject = c{1};
        dateS = c{2};
    end
    dateV = datevec(['20' dateS(1:6)], 'yyyymmdd');
    dateV(4) = str2double(dateS(8:9)); dateV(5) = str2double(dateS(10:11)); dateV(6) = str2double(dateS(12:13));
    dateN = datenum(dateV);
    dateStr = datestr(dateN);
    
    %% mat
    elseif strcmp(exte, '.mat')
        try
            l = load(o{kF});
        catch
            warning(['jk File ' o{kF} ' was skipped. It may be corrupt.'])
            continue
        end
    %% Antan
    if isfield(l, 'AntanDat')
        % Get date and time
        dateV = l.FileInfo(3:8, 2)';
        dateN = datenum(double(dateV));
        dateStr = datestr(dateN);
        dateS = [num2str(dateV(1) - 2000, '%02d'), num2str(dateV(2), '%02d'), num2str(dateV(3), '%02d'), '_',...
            num2str(dateV(4), '%02d'), num2str(dateV(5), '%02d'), num2str(dateV(6), '%02d')];
    %             subject = l.sub_name;
        ccc = strsplit(fnam, '-');
        subject = ccc{1};
        fsO = l.FileInfo(2, 1);

        if size(l.AntanDat, 1) == 32
            s = l.AntanDat([15, 16, 2, 1], :);
        elseif size(l.AntanDat, 1) == 4;
            s = l.AntanDat([3, 4, 2, 1], :);
        elseif size(l.AntanDat, 1) == 8;
            jkOrder = [3, 4, 5, 6, 2, 1, 8, 7];
jkOrder = [1 : 8];
            
            % Corrections for reversed headstages and wrong implanted
            % animals
% % % subject
            if strcmpi(subject, 'jk20151030_3')
                jkOrder = [7, 8, 1, 2, 6, 5, 4, 3];
            end
% % % dateN < datenum('2015-11-09 09:20:00', 'yyyy-mm-dd HH:MM:SS')
            if strcmpi(subject, 'jk20151030_1') || dateN < datenum('2015-11-09 09:20:00', 'yyyy-mm-dd HH:MM:SS')
                jkOrder = [7, 8, 1, 2, 6, 5, 4, 3];
            end
            if strcmpi(subject, 'jk20151109_2')
                jkOrder = [3, 4, 2, 1, 5, 6, 8, 7];
            end
            if strcmpi(subject, 'sj20160616_1')
                jkOrder = [1, 2, 3, 4];
            end
            if strcmpi(subject, 'sj20160616_2')
                jkOrder = [3, 4, 1, 2];
            end
            if strcmpi(subject, 'sj20160616_3')
                jkOrder = [3, 4, 1, 2];
            end

            s = l.AntanDat(jkOrder, :);
        end
    %% WKJ
    elseif isfield(l, 's')
        s = l.s;
        dateN = l.dateN;
        dateStr = l.dateStr;
        chanNames = l.chanNames;
        ccc = strsplit(fnam, '-');
        subject = ccc{1};
        fsO = l.fs;
        dateV = datevec(dateN);
        dateS = [num2str(dateV(1) - 2000, '%02d'), num2str(dateV(2), '%02d'), num2str(dateV(3), '%02d'), '_',...
            num2str(dateV(4), '%02d'), num2str(dateV(5), '%02d'), num2str(dateV(6), '%02d')];
    end
    if ~isa(s, 'double') && ~isa(s, 'single')
        s = 0.195/1000*(double(s) - 32768);
    elseif ~isa(s, 'single')
        s = double(s);
    end
if increaseAmplitudeOfCh01Ch02
s([1, 2], :) = s([1, 2], :)*10;
end
else
    continue
end

%% Downsample
% Downsample to 5000 if needed
sOrig = s;
dF = double(fsO/5000);
if dF > 1
'Resampling'
    fsO = fsO/dF;
    s = resample(s', 1, dF)';
end
% Downsample to 200
fsdd = 200;
ddF = double(fsO/fsdd);
sdd = resample(s', 1, ddF)';
s = sdd;
fs = fsdd;



inFName = fnam;
cellInFName = strsplit(inFName, '-');
if length(cellInFName) == 5
    outFName = [cellInFName{1}, '-', cellInFName{2}, '-', cellInFName{3}, '-', 'd', '-', cellInFName{5}];
end


if saveOrigFs
    mkdir(oPath);
    sDec = s;
    fsDec = fs;
    s = sOrig;
    fs = double(fsO);
    save([oPath '\' outFName '.mat'], 's', 'fs', 'chanNames', 'subject', 'dateN', 'dateStr')
    s = sDec;
    fs = fsDec;
end
if saveDecimatedSignal
    mkdir(dPath);
    save([dPath '\' outFName '.mat'], 's', 'fs', 'chanNames', 'subject', 'dateN', 'dateStr')
end        

fclose all;
clear mf sdd s dateStr dateN
end
% assignin('base', 'dRHD', dRHD);

fclose all
'Hotovo'

% function writeLabel() % Nested function
% % Remove short seizures
% minSeizDur = 6;
% lSeizOn = size(OOS, 1);
% if isempty(OOS)
%     lSeizOn = 0;
% end
% k = 0;
% uk = 0;
% % uOOS = [];
% while k < lSeizOn
%     k = k + 1;
%     if OOS(k, 2) - OOS(k, 1) < minSeizDur
%         uk = uk + 1;
% %         uOOS(uk, :) = OOS(k, :);
%         OOS(k, :) = [];
%         lSeizOn = lSeizOn - 1;
%         k = k - 1;
%     end
% end
% 
% 
% label.(['Seiz' detName]).name       = ['Seiz' detName];
% label.(['Seiz' detName]).color      = detColor;
% label.(['Seiz' detName]).instant    = detInstant;
% label.(['Seiz' detName]).subject    = subject;
% label.(['Seiz' detName]).chanNames  = chanNames;
% label.(['Seiz' detName]).srcSigFile = {[fnam, exte]};
% if ~isempty(OOS)
%     label.(['Seiz' detName]).(['ch', num2str(kch, '%02d')]).posN        = OOS(:, 1)'/3600/24 + dateN;
%     label.(['Seiz' detName]).(['ch', num2str(kch, '%02d')]).durN        = (OOS(:, 2) - OOS(:, 1))'/3600/24;
%     label.(['Seiz' detName]).(['ch', num2str(kch, '%02d')]).value       = ones(1, size(OOS, 1))*5;
%     label.(['Seiz' detName]).(['ch', num2str(kch, '%02d')]).chanName    = chanNames{kch};
% end
% end
end


function o = getFilepnAll
[matn, matp] = uigetfile('g:\_Kudlacek\*.*', 'Select files', 'MultiSelect', 'on');
if isa(matn, 'double')
    disp('No files selected');
    o = [];
    return
end
o = fullfile(matp, matn);
if ~iscell(o)
    o = {o};
end
end
% 
% function lb = loadCorrespondingLabelFile(ol, currentfn)
% curr = currentfn;
% currentdtInd = regexpi(currentfn, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D') + 1;
% currentdt = currentfn(currentdtInd : currentdtInd + 12);
% kL = find(~cellfun(@isempty, regexp(ol, currentdt)));
% if isempty(ol(kL))
%     return;
% end
% currl = ol{kL};
% lb = load(ol{kL});
% end
