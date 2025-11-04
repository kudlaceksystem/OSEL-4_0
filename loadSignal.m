function sigTbl = loadSignal(filepn)
    [~, ~, ext] = fileparts(filepn);
    ext = lower(ext);
    %% Add your data format as a case in this switch and implement a loading method below
    bigFile = false;
    d = dir(filepn);
    if d.bytes > 50000000
        bigFile = true;
    end
    if bigFile
        hmsb = msgbox(['Loading ', filepn]);
    end
    switch ext
        case '.mat'
            l = load(filepn);
            if isfield(l, 's') && isfield(l, 'fs') && isfield(l, 'dateN') % WKJ mat-file
                sigTbl = loadWKJ(l, filepn);
            elseif isfield(l, 'sigTbl')
                sigTbl = l.sigTbl;
            elseif isfield(l, 'AntanDat')
                sigTbl = loadAntan(l, filepn);
            end
        case '.smr'
            sigTbl = loadSmr(filepn);
        case '.smrx'
            sigTbl = loadSmrx(filepn);
        case '.h5'
            sigTbl = loadH5(filepn);
        case '.rhd'
            sigTbl = loadRhd(filepn);
        case '.rhs'
            sigTbl = loadRhs(filepn);
    end
    if bigFile
        close(hmsb); delete(hmsb);
    end
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%% Functions for loading various data formats %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

function sigTbl = loadWKJ(l, filepn)
    % Subject
    if isfield(l, 'subject')
        if isstring(l.subject)
            if length(l.subject) == size(l.s, 1)
                Subject = l.subject(:);
            elseif length(l.subject) == 1
                Subject = repelem(l.subject, size(l.s, 1))';
            end
        elseif iscell(l.subject)
            if length(l.subject) == size(l.s, 1)
                Subject = string(l.subject(:));
            elseif length(l.subject) == 1
                Subject = string(repelem(l.subject, size(l.s, 1))');
            end
        elseif ischar(l.subject)
            Subject = repelem(string(l.subject), size(l.s, 1))';
        else
            error(['_jk size(s) = ', num2str(size(s)), ' but subject = ', l.subject])
        end
    else
        [~, filen, ~] = fileparts(filepn);
        ss = strsplit(filen, '-');
        Subject = repelem(string(ss{1}), size(l.s, 1))';
    end
    
    % Channel names
    ChName = string(l.chanNames')';
    ChName = ChName(:);
    
    % Sampling rate
    if length(l.fs) == size(l.s, 1)
        Fs = l.fs(:);
    elseif length(l.fs) == 1
        Fs = ones(size(l.s, 1), 1) * l.fs;
    else
        error(['_jk size(s) = ', num2str(size(s)), ' but size(fs) = ', num2str(size(fs))])
    end
    
    % Signal start in datenum format
    SigStart = datetime( ones(size(l.s, 1), 1) * l.dateN, 'ConvertFrom', 'datenum' );
    
    % Signal end in datenum format
    SigEnd = SigStart  +  size(l.s, 2)./Fs/3600/24;
        
    % Signal proper
    for kch = 1 : size(l.s, 1)
        Data{kch, 1} = l.s(kch, :); %#ok<AGROW>
    end
    
    % Create table
    sigTbl = table(Subject, ChName, SigStart, SigEnd, Fs, Data);
end
function sigTbl = loadAntan(l, filepn)
    [~, filen, ~] = fileparts(filepn);
    ss = strsplit(filen, '-');
    
    % Subject
    if isfield(l, 'sub_name')
        Subject = repelem(string(l.sub_name), size(l.AntanDat, 1))';
    else
        Subject = repelem(string(ss{1}), size(l.AntanDat, 1))';
    end
    
    % Channel names
    ChName = string(l.ch_names')';
    ChName = ChName(:); %#ok<NASGU>
    if size(l.AntanDat, 1) == 4
        chanNames = {'DHippR'; 'DHippR2'; 'DHippL'; 'DHippL2'};
    elseif size(l.AntanDat, 1) == 8
        chanNames = {'DHippR'; 'DHippR2'; 'MCxR'; 'MCxR2'; 'DHippL'; 'DHippL2'; 'MCxL'; 'MCxL2'};
    end
    ChName = string(chanNames);
    
    % Sampling rate
    Fs = repelem(double(l.FileInfo(2, 1)), size(l.AntanDat, 1), 1);
    
    % Signal start
    SigStart = repelem(datetime(ss{2}, "InputFormat", "uuMMdd_HHmmss"), size(l.AntanDat, 1), 1);
    SigStartIn = repelem(datetime(l.FileInfo(3 : 8, 2)'), size(l.AntanDat, 1), 1);
    if ~all(SigStart == SigStartIn)
        warning('_jk Date written in the file differs from the date in the file name.')
    end
    
    % Signal end
    SigEnd = SigStart  +  size(l.AntanDat, 2)./Fs(1)/3600/24;
        
    % Signal proper
    if size(l.AntanDat, 1) == 4
        s = l.AntanDat([3, 4, 2, 1], :);
    elseif size(l.AntanDat, 1) == 8
        jkOrder = [3, 4, 5, 6, 2, 1, 8, 7];
        % jkOrder = [1 : 8];
        % Corrections for reversed headstages and wrong implanted animals
        subject = char(Subject(1));
        if strcmpi(subject, 'jk20151030_3')
            jkOrder = [7, 8, 1, 2, 6, 5, 4, 3];
        end
        if strcmpi(subject, 'jk20151030_1') && SigStart(1) < datetime('2015-11-09 09:20:00', 'InputFormat', 'uuuu-MM-dd HH:mm:ss')
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
        % ChName = ChName(jkOrder)
        s = l.AntanDat(jkOrder, :);
    end
    clear l
    % if ~isa(s, 'double') && ~isa(s, 'single')
    %     s = 0.195/1000*(single(s) - 32768);
    % end
    Data = cell(size(s, 1), 1);
    for kch = 1 : size(s, 1)
        Data{kch, 1} = s(kch, :);
    end
    clear s
    for kch = 1 : numel(Data)
        Data{kch, 1} = 0.195/1000*(single(Data{kch, 1}) - 32768);
    end
    % Create table
    sigTbl = table(Subject, ChName, SigStart, SigEnd, Fs, Data);
end
function sigTbl = loadSmrBrano(filepn) %#ok<DEFNU>
    [~, filen, ~] = fileparts(filepn);
    
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
    if all(subject ~= "")
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
%         s = smr.smrLoadChannel(filepn, smrChN(kch));
        Data{kch, 1} = smr.smrLoadChannel(filepn, smrChN(kch)); %#ok<AGROW>
        SigEnd(kch, 1) = SigStart(kch, 1) + seconds(size(Data{kch, 1}, 2)/Fs(kch)); %#ok<AGROW>
    end
% Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition
    sigTbl = table(Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition);
end
function sigTbl = loadSmr(filepn)
    [~, filen, ~] = fileparts(filepn);
    
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
    if all(subject ~= "")
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
%         s = smr.smrLoadChannel(filepn, smrChN(kch));
        Data{kch, 1} = smr.smrLoadChannel(filepn, smrChN(kch)); %#ok<AGROW>
        SigEnd(kch, 1) = SigStart(kch, 1) + seconds(size(Data{kch, 1}, 2)/Fs(kch)); %#ok<AGROW>
    end
% Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition
    sigTbl = table(Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition);
end
function sigTbl = loadSmrx(filepn)
    % Jan Emsik Chvojka 2020
    % Modified by Jan Kudlacek 2022
    [filep, filen, ~] = fileparts(filepn);
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

    % Keep only ADC channels
    for k = 1 : length(nch)
        typ(k) = CEDS64ChanType(fhand, nch(k)); %#ok<AGROW> % Get channels type (ADC, Marker, etc.)
    end
    chnm = chnm(typ == 1);
    
    % Find what type of recording it is
    recType = 'general';
    for k = 1 : length(chnm)
        r = regexpi(chnm{k}, '\w\w?-[ABCD]-\w+', 'start');
        if r == 1
            recType = 'prahaMotolChronic';
            break
        end
    end
    
    % Run appropriate nested function
    switch recType
        case 'prahaMotolChronic'
            loadPrahaMotolChronic;
        case 'general'
            loadGeneral;
    end
    
    % Nested functions
    function loadPrahaMotolChronic
        % Process the channels
        for kch2 = 1 : length(chnm)
            disp(['Loading channel ', num2str(kch2)])
            str = chnm{kch2};
            r = regexpi(str, '\w\w?-[ABCD]-\w+', 'match');
%             r = regexpi(str, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
            if ~isempty(r)
                s = strsplit(r{1}, '-');
                ChName = string(str);
                RecPosition = string(s{2});
                Subject = string(['recID_', s{3}]);
%                 RecPosition = 'BranoAparatus';
%                 Subject = 'BranoTheRat';
            else
                r = regexpi(str, '\w\w?-[ABCD]', 'match');
                if ~isempty(r)
                    s = strsplit(r{1}, '-');
                    ChName = string(str);
                    RecPosition = string(s{2});
                    Subject = ""; % Will be filled in later
                elseif startsWith(str, 'Rhd')
                    ChName = string(str);
                    RecPosition = string(str(4));
                    Subject = ""; % Will be filled in later
                else
                    ChName = string(str);
                    RecPosition = "";
                    Subject = ""; % Will not be filled in since RecPosition is empty as well
                end
            end
            [durS] = CEDS64TicksToSecs(fhand, CEDS64ChanMaxTime(fhand, chn(kch2)));
            % [~, td]  = CEDS64TimeDate(fhand);
            r = regexp(filen, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
            dt = r{1};
            SigStart = datetime(dt, 'InputFormat', 'yyMMdd_HHmmss');
            % SigStart = datetime(fliplr(td(2 : end)));
            SigEnd = datetime(datenum(SigStart(end)) + durS/3600/24, 'ConvertFrom', 'datenum');
            maxpoints = CEDS64MaxTime(fhand) + 2;
            [iRead, shortvals, ~] = CEDS64ReadWaveS(fhand, chn(kch2), maxpoints, 0);
            y = single(shortvals);
            [~, scale] = CEDS64ChanScale(fhand, chn(kch2));
            [~, offset] = CEDS64ChanOffset(fhand, chn(kch2));
            Data = {single(y*scale/6553.6 + offset)'};
            Fs = double(CEDS64IdealRate(fhand, chn(kch2)));
            if Fs == 0 || iRead < 0
                Fs = NaN;
                Data = {NaN};
            end
            sigTbl(kch2, :) = table(Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition);
        end
        
        % Pair subject names with recording positions
        subjects = [];
        for kch2 = 1 : size(sigTbl, 1)
            if ~(sigTbl.Subject(kch2) == "")
                subjects{end+1, 1} = sigTbl.Subject(kch2); %#ok<AGROW>
                subjects{end, 2} = sigTbl.RecPosition(kch2);
            end
        end
%         subjects
%         sigTbl.RecPosition
        % Fill in subject names
        for kch2 = 1 : size(sigTbl, 1)
            if ~(sigTbl.RecPosition(kch2) == "")
                if ~isempty(subjects([subjects{:, 2}] == sigTbl.RecPosition(kch2), 1))
                    sigTbl.Subject(kch2) = subjects([subjects{:, 2}] == sigTbl.RecPosition(kch2), 1);
                end
            end
        end
        
        sigTbl = sigTbl(~isnan(sigTbl.Fs), :);
        unloadlibrary ceds64int;
    end
    function loadGeneral
        % Process the channels
        for kch = 1 : length(chnm) %#ok<FXUP>
            disp(['Loading channel ', num2str(kch)])
            [~, filen, ~] = fileparts(filepn);
            stsp = strsplit(filen, '-');
            Subject = string(stsp{1});
            ChName = string(chnm{kch});
            % Load signal proper
            [durS] = CEDS64TicksToSecs(fhand, CEDS64ChanMaxTime(fhand, kch));
            [~, td]  = CEDS64TimeDate(fhand);
% SigStart = datetime(stsp{2}, 'InputFormat', 'yyMMdd_HHmmss'); % Needs to be tested (not sure about the capitals in 'InputFormat')
            SigStart = datetime(fliplr(td(2 : end)));
            SigEnd = datetime(datenum(SigStart(end)) + durS/3600/24, 'ConvertFrom', 'datenum');
            maxpoints = CEDS64MaxTime(fhand) + 2;
            [~, shortvals, ~] = CEDS64ReadWaveS(fhand, kch, maxpoints, 0);
            y = double(shortvals);
            [~, scale] = CEDS64ChanScale(fhand, kch);
            [~, offset] = CEDS64ChanOffset(fhand, kch);
            Data = {double(y*scale/6553.6 + offset)'};
            Fs = double(CEDS64IdealRate(fhand, kch));
            if Fs == 0
                Fs = NaN;
                Data = {NaN};
            end
            sigTbl(kch, :) = table(Subject, ChName, SigStart, SigEnd, Fs, Data);
        end
        
        sigTbl = sigTbl(~isnan(sigTbl.Fs), :);
        unloadlibrary ceds64int;
    end
end
function sigTbl = loadH5(filepn)
    [filep, filen, ~] = fileparts(filepn);
    if 0 %contains(filen, '-')
        stsp = strsplit(filen, '-');
        subjNm = string(stsp{1});
        SigStart = datetime(stsp{2}, 'InputFormat', 'yyMMdd_HHmmss'); % Needs to be tested (not sure about the capitals in 'InputFormat')
    else
        SigStart = [];
        try
            stsp = strsplit(filep, '\');
            filepSubj = stsp{end};
            subjN = regexp(filepSubj, '\D\d\d\d\D', 'match');
            subjN = subjN{1}(2 : end-1);
            subjNm = string(['ET', num2str(subjN)]);
        catch
            subjNm = 'UnknownSubject';
        end
    end

    info = h5info(filepn);
    grpNm = {info.Groups.Name};
    grpNmInd = contains(grpNm, 'sweep');
    grpNmSub = find(grpNmInd);
    
    s = [];
    for k = 1 : numel(grpNmSub)
%         datasetNm = [grpNm{find(grpNmInd, 1, 'first')}, '/', info.Groups(grpNmSub(k)).Datasets(1).Name]
        datasetNm = [grpNm{grpNmSub(k)}, '/', info.Groups(grpNmSub(k)).Datasets(1).Name];
        s1 = h5read(filepn, datasetNm)';
        s = [s, s1]; %#ok<AGROW>
    end
    % Subject
    Subject = repelem(string(subjNm), size(s, 1))';
    % Channel names
    try
        chnm = h5read(filepn, '/header/AllChannelNames');
        for kch = 1 : size(s, 1)
            ChName(kch, 1) = string(chnm{kch}); %#ok<AGROW>
        end
    catch
        for kch = 1 : size(s, 1)
            ChName(kch, 1) = string(num2str(kch));
        end
    end
    % Sampling rate
    fs = h5read(filepn, '/header/AcquisitionSampleRate');
    if length(fs) == size(s, 1)
        Fs = double(fs(:));
    elseif length(fs) == 1
        Fs = double(ones(size(s, 1), 1) * fs);
    else
        error(['_jk size(s) = ', num2str(size(s)), ' but size(fs) = ', num2str(size(fs))])
    end
    
    % Signal start in datenum format
    if isempty(SigStart)
        sigstart = h5read(filepn, '/header/ClockAtRunStart');
        SigStart = datetime(sigstart, 'Format', 'HH:mm:ss');
        SigStart = repelem(SigStart, size(s, 1))';
    end
    
    % Signal end in datenum format
    SigEnd = SigStart  +  size(s, 2)./Fs/3600/24;
        
    % Signal proper
    for kch = 1 : size(s, 1)
        Data{kch, 1} = single(s(kch, :)); %#ok<AGROW>
    end
    
    % Create table
    sigTbl = table(Subject, ChName, SigStart, SigEnd, Fs, Data);
end
function sigTbl = loadRhd(filepn)
    [~, filen, ~] = fileparts(filepn);
    [chnm, signalData, fs, digitalIn] = read_Intan_RHD2000_file(filepn);
    for kch2 = 1 : numel(chnm)
        str = char(chnm(kch2));
        r = regexpi(str, '\w\w?-[ABCD]-\w+', 'match');
        if ~isempty(r)
            s = strsplit(r{1}, '-');
            ChName = string(str);
            RecPosition = string(s{2});
            Subject = string(s{3});
        else
            r = regexpi(str, '\w\w?-[ABCD]', 'match');
            if ~isempty(r)
                s = strsplit(r{1}, '-');
                ChName = string(str);
                RecPosition = string(s{2});
                Subject = ""; % Will be filled in later
            elseif startsWith(str, 'Rhd')
                ChName = string(str);
                RecPosition = string(str(4));
                Subject = ""; % Will be filled in later
            else
                ChName = string(str);
                RecPosition = "";
                Subject = ""; % Will not be filled in since RecPosition is empty as well
            end
        end
        r = regexp(filen, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
        dt = r{1};
        SigStart = datetime(dt, 'InputFormat', 'yyMMdd_HHmmss'); % Needs to be tested (not sure about the capitals in 'InputFormat')
        durS = size(signalData, 2)/fs;
        SigEnd = datetime(datenum(SigStart(end)) + durS/3600/24, 'ConvertFrom', 'datenum');
        Data = {single(signalData(kch2, :))};
        Fs = double(fs);
        sigTbl(kch2, :) = table(Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition);
    end
    
    % Add Digital In data
    subjects = unique(sigTbl.Subject);
    subjects = subjects(subjects ~= "");
    for ks = 1 : numel(subjects)
        for kd = 1 : size(digitalIn, 1)
            sigTblDI0 = sigTbl(sigTbl.Subject == subjects{ks}, :);
            sigTblDI0.Subject = "";
            ss = strsplit(sigTblDI0.ChName, '-');
            chnm = "DI" + string(num2str(kd)) + "-" + ss{2};
            sigTblDI0.ChName = chnm;
            sigTblDI0.Data = {digitalIn(kd, :)};
            sigTbl = [sigTbl; sigTblDI0]; %#ok<AGROW>
        end
    end
    
    % Pair subject names with recording positions
    subjects = [];
    for kch2 = 1 : size(sigTbl, 1)
        if ~(sigTbl.Subject(kch2) == "")
            subjects{end+1, 1} = sigTbl.Subject(kch2); %#ok<AGROW>
            subjects{end, 2} = sigTbl.RecPosition(kch2);
        end
    end
    % Fill in subject names
    for kch2 = 1 : size(sigTbl, 1)
        if ~(sigTbl.RecPosition(kch2) == "")
            if ~isempty(subjects([subjects{:, 2}] == sigTbl.RecPosition(kch2), 1))
                sigTbl.Subject(kch2) = subjects([subjects{:, 2}] == sigTbl.RecPosition(kch2), 1);
            end
        end
    end
    sigTbl = sortrows(sigTbl, "RecPosition");
    % % % % sigTbl = sigTbl(~isnan(sigTbl.Fs), :);
    disp('_jk Loaded RHS')
end
function sigTbl = loadRhs(filepn)
    [~, filen, ~] = fileparts(filepn);
    [chnm, signalData, fs, digitalIn] = read_Intan_RHS2000_file(filepn);
    for kch2 = 1 : numel(chnm)
        str = char(chnm(kch2));
        r = regexpi(str, '\w\w?-[ABCD]-\w+', 'match');
        if ~isempty(r)
            s = strsplit(r{1}, '-');
            ChName = string(str);
            RecPosition = string(s{2});
            Subject = string(s{3});
        else
            r = regexpi(str, '\w\w?-[ABCD]', 'match');
            if ~isempty(r)
                s = strsplit(r{1}, '-');
                ChName = string(str);
                RecPosition = string(s{2});
                Subject = ""; % Will be filled in later
            elseif startsWith(str, 'Rhd')
                ChName = string(str);
                RecPosition = string(str(4));
                Subject = ""; % Will be filled in later
            else
                ChName = string(str);
                RecPosition = "";
                Subject = ""; % Will not be filled in since RecPosition is empty as well
            end
        end
        r = regexp(filen, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
        dt = r{1};
        SigStart = datetime(dt, 'InputFormat', 'yyMMdd_HHmmss'); % Needs to be tested (not sure about the capitals in 'InputFormat')
        durS = size(signalData, 2)/fs;
        SigEnd = datetime(datenum(SigStart(end)) + durS/3600/24, 'ConvertFrom', 'datenum');
        Data = {single(signalData(kch2, :))};
        Fs = double(fs);
        sigTbl(kch2, :) = table(Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition);
    end

    % Add Digital In data
    subjects = unique(sigTbl.Subject);
    subjects = subjects(subjects ~= "");
    for ks = 1 : numel(subjects)
        for kd = 1 : size(digitalIn, 1)
            sigTblDI0 = sigTbl(sigTbl.Subject == subjects{ks}, :);
            sigTblDI0.Subject = "";
            ss = strsplit(sigTblDI0.ChName, '-');
            chnm = "DI" + string(num2str(kd)) + "-" + ss{2};
            sigTblDI0.ChName = chnm;
            sigTblDI0.Data = {digitalIn(kd, :)};
            sigTbl = [sigTbl; sigTblDI0]; %#ok<AGROW>
        end
    end
    
    % Pair subject names with recording positions
    subjects = [];
    for kch2 = 1 : size(sigTbl, 1)
        if ~(sigTbl.Subject(kch2) == "")
            subjects{end+1, 1} = sigTbl.Subject(kch2); %#ok<AGROW>
            subjects{end, 2} = sigTbl.RecPosition(kch2);
        end
    end

% % % % % % % % % % % % % sigTbl = sigTbl([1 3], :)
% % % % % % % % % % % % % subjects = subjects([1 3], :)



    % Fill in subject names
    for kch2 = 1 : size(sigTbl, 1)
        if ~(sigTbl.RecPosition(kch2) == "")
            if ~isempty(subjects([subjects{:, 2}] == sigTbl.RecPosition(kch2), 1))
                sigTbl.Subject(kch2) = subjects([subjects{:, 2}] == sigTbl.RecPosition(kch2), 1);
            end
        end
    end
    sigTbl = sortrows(sigTbl, "RecPosition");
    % % % % 
    % % % % sigTbl = sigTbl(~isnan(sigTbl.Fs), :);
    % % % %     unloadlibrary ceds64int;end
    disp('_jk Loaded RHS')
end

%% Intan functions
function [channelNames, signalData, fs, digitalInData] = read_Intan_RHD2000_file(filepn)
    % read_Intan_RHD2000_file
    %
    % Version 3.0, 8 February 2021
    %
    % Reads Intan Technologies RHD data file generated by Intan USB interface
    % board or Intan Recording Controller.  Data are parsed and placed into
    % variables that appear in the base MATLAB workspace.  Therefore, it is
    % recommended to execute a 'clear' command before running this program to
    % clear all other variables from the base workspace.
    %
    % Example:
    % >> clear
    % >> read_Intan_RHD2000_file
    % >> whos
    % >> amplifier_channels(1)
    % >> plot(t_amplifier, amplifier_data(1,:))
    
    % % % % % % % % % % [file, path, filterindex] = ...
    % % % % % % % % % %     uigetfile('*.rhd', 'Select an RHD2000 Data File', 'MultiSelect', 'off');
    % % % % % % % % % % 
    % % % % % % % % % % if (file == 0)
    % % % % % % % % % %     return;
    % % % % % % % % % % end
    % % % % % % % % % % 
    % % % % % % % % % % tic;
    % % % % % % % % % % filename = [path,file];
    % % % % % % % % % % fid = fopen(filename, 'r');
    % % % % % % % % % % 
    % % % % % % % % % % s = dir(filename);
    % % % % % % % % % % filesize = s.bytes;
    % % % % [file, path, filterindex] = ...
    % % % %     uigetfile('*.rhd', 'Select an RHD2000 Data File', 'MultiSelect', 'off');




    % Read most recent file automatically.
    %path = 'C:\Users\Reid\Documents\RHD2132\testing\';
    %d = dir([path '*.rhd']);
    %file = d(end).name;


    fid = fopen(filepn, 'r');
    [path, file] = fileparts(filepn);

    s = dir(filepn);
    filesize = s.bytes;

    % % % % 
    % % % % tic;
    % % % % filename = [path,file];
    % % % % fid = fopen(filename, 'r');
    % % % % 
    % % % % s = dir(filename);
    % % % % filesize = s.bytes;    % Check 'magic number' at beginning of file to make sure this is an Intan


    % Technologies RHD2000 data file.
    magic_number = fread(fid, 1, 'uint32');
    if magic_number ~= hex2dec('c6912702')
        error('Unrecognized file type.');
    end
    
    % Read version number.
    data_file_main_version_number = fread(fid, 1, 'int16');
    data_file_secondary_version_number = fread(fid, 1, 'int16');
    
    fprintf(1, '\n');
    fprintf(1, 'Reading Intan Technologies RHD2000 Data File, Version %d.%d\n', ...
        data_file_main_version_number, data_file_secondary_version_number);
    fprintf(1, '\n');
    
    if (data_file_main_version_number == 1)
        num_samples_per_data_block = 60;
    else
        num_samples_per_data_block = 128;
    end
    
    % Read information of sampling rate and amplifier frequency settings.
    sample_rate = fread(fid, 1, 'single');
    dsp_enabled = fread(fid, 1, 'int16');
    actual_dsp_cutoff_frequency = fread(fid, 1, 'single');
    actual_lower_bandwidth = fread(fid, 1, 'single');
    actual_upper_bandwidth = fread(fid, 1, 'single');
    
    desired_dsp_cutoff_frequency = fread(fid, 1, 'single');
    desired_lower_bandwidth = fread(fid, 1, 'single');
    desired_upper_bandwidth = fread(fid, 1, 'single');
    
    % This tells us if a software 50/60 Hz notch filter was enabled during
    % the data acquisition.
    notch_filter_mode = fread(fid, 1, 'int16');
    notch_filter_frequency = 0;
    if (notch_filter_mode == 1)
        notch_filter_frequency = 50;
    elseif (notch_filter_mode == 2)
        notch_filter_frequency = 60;
    end
    
    desired_impedance_test_frequency = fread(fid, 1, 'single');
    actual_impedance_test_frequency = fread(fid, 1, 'single');
    
    % Place notes in data strucure
    notes = struct( ...
        'note1', fread_QString(fid), ...
        'note2', fread_QString(fid), ...
        'note3', fread_QString(fid) );
        
    % If data file is from GUI v1.1 or later, see if temperature sensor data
    % was saved.
    num_temp_sensor_channels = 0;
    if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 1) ...
        || (data_file_main_version_number > 1))
        num_temp_sensor_channels = fread(fid, 1, 'int16');
    end
    
    % If data file is from GUI v1.3 or later, load board mode.
    board_mode = 0;
    if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 3) ...
        || (data_file_main_version_number > 1))
        board_mode = fread(fid, 1, 'int16');
    end
    
    % If data file is from v2.0 or later (Intan Recording Controller),
    % load name of digital reference channel.
    if (data_file_main_version_number > 1)
        reference_channel = fread_QString(fid);
    end
    
    % Place frequency-related information in data structure.
    frequency_parameters = struct( ...
        'amplifier_sample_rate', sample_rate, ...
        'aux_input_sample_rate', sample_rate / 4, ...
        'supply_voltage_sample_rate', sample_rate / num_samples_per_data_block, ...
        'board_adc_sample_rate', sample_rate, ...
        'board_dig_in_sample_rate', sample_rate, ...
        'desired_dsp_cutoff_frequency', desired_dsp_cutoff_frequency, ...
        'actual_dsp_cutoff_frequency', actual_dsp_cutoff_frequency, ...
        'dsp_enabled', dsp_enabled, ...
        'desired_lower_bandwidth', desired_lower_bandwidth, ...
        'actual_lower_bandwidth', actual_lower_bandwidth, ...
        'desired_upper_bandwidth', desired_upper_bandwidth, ...
        'actual_upper_bandwidth', actual_upper_bandwidth, ...
        'notch_filter_frequency', notch_filter_frequency, ...
        'desired_impedance_test_frequency', desired_impedance_test_frequency, ...
        'actual_impedance_test_frequency', actual_impedance_test_frequency );
    
    % Define data structure for spike trigger settings.
    spike_trigger_struct = struct( ...
        'voltage_trigger_mode', {}, ...
        'voltage_threshold', {}, ...
        'digital_trigger_channel', {}, ...
        'digital_edge_polarity', {} );
    
    new_trigger_channel = struct(spike_trigger_struct);
    spike_triggers = struct(spike_trigger_struct);
    
    % Define data structure for data channels.
    channel_struct = struct( ...
        'native_channel_name', {}, ...
        'custom_channel_name', {}, ...
        'native_order', {}, ...
        'custom_order', {}, ...
        'board_stream', {}, ...
        'chip_channel', {}, ...
        'port_name', {}, ...
        'port_prefix', {}, ...
        'port_number', {}, ...
        'electrode_impedance_magnitude', {}, ...
        'electrode_impedance_phase', {} );
    
    new_channel = struct(channel_struct);
    
    % Create structure arrays for each type of data channel.
    amplifier_channels = struct(channel_struct);
    aux_input_channels = struct(channel_struct);
    supply_voltage_channels = struct(channel_struct);
    board_adc_channels = struct(channel_struct);
    board_dig_in_channels = struct(channel_struct);
    board_dig_out_channels = struct(channel_struct);
    
    amplifier_index = 1;
    aux_input_index = 1;
    supply_voltage_index = 1;
    board_adc_index = 1;
    board_dig_in_index = 1;
    board_dig_out_index = 1;
    
    % Read signal summary from data file header.
    
    number_of_signal_groups = fread(fid, 1, 'int16');
    
    for signal_group = 1:number_of_signal_groups
        signal_group_name = fread_QString(fid);
        signal_group_prefix = fread_QString(fid);
        signal_group_enabled = fread(fid, 1, 'int16');
        signal_group_num_channels = fread(fid, 1, 'int16');
        signal_group_num_amp_channels = fread(fid, 1, 'int16');
    
        if (signal_group_num_channels > 0 && signal_group_enabled > 0)
            new_channel(1).port_name = signal_group_name;
            new_channel(1).port_prefix = signal_group_prefix;
            new_channel(1).port_number = signal_group;
            for signal_channel = 1:signal_group_num_channels
                new_channel(1).native_channel_name = fread_QString(fid);
                new_channel(1).custom_channel_name = fread_QString(fid);
                new_channel(1).native_order = fread(fid, 1, 'int16');
                new_channel(1).custom_order = fread(fid, 1, 'int16');
                signal_type = fread(fid, 1, 'int16');
                channel_enabled = fread(fid, 1, 'int16');
                new_channel(1).chip_channel = fread(fid, 1, 'int16');
                new_channel(1).board_stream = fread(fid, 1, 'int16');
                new_trigger_channel(1).voltage_trigger_mode = fread(fid, 1, 'int16');
                new_trigger_channel(1).voltage_threshold = fread(fid, 1, 'int16');
                new_trigger_channel(1).digital_trigger_channel = fread(fid, 1, 'int16');
                new_trigger_channel(1).digital_edge_polarity = fread(fid, 1, 'int16');
                new_channel(1).electrode_impedance_magnitude = fread(fid, 1, 'single');
                new_channel(1).electrode_impedance_phase = fread(fid, 1, 'single');
                
                if (channel_enabled)
                    switch (signal_type)
                        case 0
                            amplifier_channels(amplifier_index) = new_channel;
                            spike_triggers(amplifier_index) = new_trigger_channel;
                            amplifier_index = amplifier_index + 1;
                        case 1
                            aux_input_channels(aux_input_index) = new_channel;
                            aux_input_index = aux_input_index + 1;
                        case 2
                            supply_voltage_channels(supply_voltage_index) = new_channel;
                            supply_voltage_index = supply_voltage_index + 1;
                        case 3
                            board_adc_channels(board_adc_index) = new_channel;
                            board_adc_index = board_adc_index + 1;
                        case 4
                            board_dig_in_channels(board_dig_in_index) = new_channel;
                            board_dig_in_index = board_dig_in_index + 1;
                        case 5
                            board_dig_out_channels(board_dig_out_index) = new_channel;
                            board_dig_out_index = board_dig_out_index + 1;
                        otherwise
                            error('Unknown channel type');
                    end
                end
                
            end
        end
    end
    
    % Summarize contents of data file.
    num_amplifier_channels = amplifier_index - 1;
    num_aux_input_channels = aux_input_index - 1;
    num_supply_voltage_channels = supply_voltage_index - 1;
    num_board_adc_channels = board_adc_index - 1;
    num_board_dig_in_channels = board_dig_in_index - 1;
    num_board_dig_out_channels = board_dig_out_index - 1;
    
    % fprintf(1, 'Found %d amplifier channel%s.\n', ...
    %     num_amplifier_channels, plural(num_amplifier_channels));
    % fprintf(1, 'Found %d auxiliary input channel%s.\n', ...
    %     num_aux_input_channels, plural(num_aux_input_channels));
    % fprintf(1, 'Found %d supply voltage channel%s.\n', ...
    %     num_supply_voltage_channels, plural(num_supply_voltage_channels));
    % fprintf(1, 'Found %d board ADC channel%s.\n', ...
    %     num_board_adc_channels, plural(num_board_adc_channels));
    % fprintf(1, 'Found %d board digital input channel%s.\n', ...
    %     num_board_dig_in_channels, plural(num_board_dig_in_channels));
    % fprintf(1, 'Found %d board digital output channel%s.\n', ...
    %     num_board_dig_out_channels, plural(num_board_dig_out_channels));
    % fprintf(1, 'Found %d temperature sensor channel%s.\n', ...
    %     num_temp_sensor_channels, plural(num_temp_sensor_channels));
    % fprintf(1, '\n');
    
    % Determine how many samples the data file contains.
    
    % Each data block contains num_samples_per_data_block amplifier samples.
    bytes_per_block = num_samples_per_data_block * 4;  % timestamp data
    bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_amplifier_channels;
    % Auxiliary inputs are sampled 4x slower than amplifiers
    bytes_per_block = bytes_per_block + (num_samples_per_data_block / 4) * 2 * num_aux_input_channels;
    % Supply voltage is sampled once per data block
    bytes_per_block = bytes_per_block + 1 * 2 * num_supply_voltage_channels;
    % Board analog inputs are sampled at same rate as amplifiers
    bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_board_adc_channels;
    % Board digital inputs are sampled at same rate as amplifiers
    if (num_board_dig_in_channels > 0)
        bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
    end
    % Board digital outputs are sampled at same rate as amplifiers
    if (num_board_dig_out_channels > 0)
        bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
    end
    % Temp sensor is sampled once per data block
    if (num_temp_sensor_channels > 0)
       bytes_per_block = bytes_per_block + 1 * 2 * num_temp_sensor_channels; 
    end
    
    % How many data blocks remain in this file?
    data_present = 0;
    bytes_remaining = filesize - ftell(fid);
    if (bytes_remaining > 0)
        data_present = 1;
    end
    
    num_data_blocks = bytes_remaining / bytes_per_block;
    
    num_amplifier_samples = num_samples_per_data_block * num_data_blocks;
    num_aux_input_samples = (num_samples_per_data_block / 4) * num_data_blocks;
    num_supply_voltage_samples = 1 * num_data_blocks;
    num_board_adc_samples = num_samples_per_data_block * num_data_blocks;
    num_board_dig_in_samples = num_samples_per_data_block * num_data_blocks;
    num_board_dig_out_samples = num_samples_per_data_block * num_data_blocks;
    
    % record_time = num_amplifier_samples / sample_rate;
    
    % if (data_present)
    %     fprintf(1, 'File contains %0.3f seconds of data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
    %         record_time, sample_rate / 1000);
    %     fprintf(1, '\n');
    % else
    %     fprintf(1, 'Header file contains no data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
    %         sample_rate / 1000);
    %     fprintf(1, '\n');
    % end
    
    if (data_present)
        
        % Pre-allocate memory for data.
        % fprintf(1, 'Allocating memory for data...\n');
    
        t_amplifier = zeros(1, num_amplifier_samples);
    
        amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
        aux_input_data = zeros(num_aux_input_channels, num_aux_input_samples);
        supply_voltage_data = zeros(num_supply_voltage_channels, num_supply_voltage_samples);
        temp_sensor_data = zeros(num_temp_sensor_channels, num_supply_voltage_samples);
        board_adc_data = zeros(num_board_adc_channels, num_board_adc_samples);
        board_dig_in_data = zeros(num_board_dig_in_channels, num_board_dig_in_samples);
        board_dig_in_raw = zeros(1, num_board_dig_in_samples);
        board_dig_out_data = zeros(num_board_dig_out_channels, num_board_dig_out_samples);
        board_dig_out_raw = zeros(1, num_board_dig_out_samples);
    
        % Read sampled data from file.
        % fprintf(1, 'Reading data from file...\n');
    
        amplifier_index = 1;
        aux_input_index = 1;
        supply_voltage_index = 1;
        board_adc_index = 1;
        board_dig_in_index = 1;
        board_dig_out_index = 1;
    
        print_increment = 10;
        percent_done = print_increment;
        for i=1:num_data_blocks
            % In version 1.2, we moved from saving timestamps as unsigned
            % integeters to signed integers to accomidate negative (adjusted)
            % timestamps for pretrigger data.
            if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 2) ...
            || (data_file_main_version_number > 1))
                t_amplifier(amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'int32');
            else
                t_amplifier(amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint32');
            end
            if (num_amplifier_channels > 0)
                amplifier_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
            end
            if (num_aux_input_channels > 0)
                aux_input_data(:, aux_input_index:(aux_input_index + (num_samples_per_data_block / 4) - 1)) = fread(fid, [(num_samples_per_data_block / 4), num_aux_input_channels], 'uint16')';
            end
            if (num_supply_voltage_channels > 0)
                supply_voltage_data(:, supply_voltage_index) = fread(fid, [1, num_supply_voltage_channels], 'uint16')';
            end
            if (num_temp_sensor_channels > 0)
                temp_sensor_data(:, supply_voltage_index) = fread(fid, [1, num_temp_sensor_channels], 'int16')';
            end
            if (num_board_adc_channels > 0)
                board_adc_data(:, board_adc_index:(board_adc_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_board_adc_channels], 'uint16')';
            end
            if (num_board_dig_in_channels > 0)
                board_dig_in_raw(board_dig_in_index:(board_dig_in_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
            end
            if (num_board_dig_out_channels > 0)
                board_dig_out_raw(board_dig_out_index:(board_dig_out_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
            end
    
            amplifier_index = amplifier_index + num_samples_per_data_block;
            aux_input_index = aux_input_index + (num_samples_per_data_block / 4);
            supply_voltage_index = supply_voltage_index + 1;
            board_adc_index = board_adc_index + num_samples_per_data_block;
            board_dig_in_index = board_dig_in_index + num_samples_per_data_block;
            board_dig_out_index = board_dig_out_index + num_samples_per_data_block;
    
            fraction_done = 100 * (i / num_data_blocks);
            if (fraction_done >= percent_done)
                % fprintf(1, '%d%% done...\n', percent_done);
                percent_done = percent_done + print_increment;
            end
        end
    
        % Make sure we have read exactly the right amount of data.
        bytes_remaining = filesize - ftell(fid);
        if (bytes_remaining ~= 0)
            %error('Error: End of file not reached.');
        end
    
    end
    
    % Close data file.
    fclose(fid);
    
    if (data_present)
        
        % fprintf(1, 'Parsing data...\n');
    
        % Extract digital input channels to separate variables.
        for i=1:num_board_dig_in_channels
           mask = 2^(board_dig_in_channels(i).native_order) * ones(size(board_dig_in_raw));
           board_dig_in_data(i, :) = (bitand(board_dig_in_raw, mask) > 0);
        end
        for i=1:num_board_dig_out_channels
           mask = 2^(board_dig_out_channels(i).native_order) * ones(size(board_dig_out_raw));
           board_dig_out_data(i, :) = (bitand(board_dig_out_raw, mask) > 0);
        end
    
        % Scale voltage levels appropriately.
        amplifier_data = 0.195 * (amplifier_data - 32768); % units = microvolts
        aux_input_data = 37.4e-6 * aux_input_data; % units = volts
        supply_voltage_data = 74.8e-6 * supply_voltage_data; % units = volts
        if (board_mode == 1)
            board_adc_data = 152.59e-6 * (board_adc_data - 32768); % units = volts
        elseif (board_mode == 13) % Intan Recording Controller
            board_adc_data = 312.5e-6 * (board_adc_data - 32768); % units = volts    
        else
            board_adc_data = 50.354e-6 * board_adc_data; % units = volts
        end
        temp_sensor_data = temp_sensor_data / 100; % units = deg C
    
        % Check for gaps in timestamps.
        num_gaps = sum(diff(t_amplifier) ~= 1);
        % if (num_gaps == 0)
        %     fprintf(1, 'No missing timestamps in data.\n');
        % else
        %     fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
        %         num_gaps);
        % end
    
        % Scale time steps (units = seconds).
        t_amplifier = t_amplifier / sample_rate;
        t_aux_input = t_amplifier(1:4:end);
        t_supply_voltage = t_amplifier(1:num_samples_per_data_block:end);
        t_board_adc = t_amplifier;
        t_dig = t_amplifier;
        t_temp_sensor = t_supply_voltage;
    
        % If the software notch filter was selected during the recording, apply the
        % same notch filter to amplifier data here.  But don't do this for v3.0+ 
        % files (from Intan RHX software) because RHX saves notch-filtered data.
        if (notch_filter_frequency > 0 && data_file_main_version_number < 3)
            % fprintf(1, 'Applying notch filter...\n');
    
            print_increment = 10;
            percent_done = print_increment;
            for i=1:num_amplifier_channels
                amplifier_data(i,:) = ...
                    notch_filter(amplifier_data(i,:), sample_rate, notch_filter_frequency, 10);
    
                fraction_done = 100 * (i / num_amplifier_channels);
                if (fraction_done >= percent_done)
                    % fprintf(1, '%d%% done...\n', percent_done);
                    percent_done = percent_done + print_increment;
                end
    
            end
        end
    
    end
    
    % Move variables to base workspace.
    
    % new for version 2.01: move filename info to base workspace
    filename = file;
    move_to_base_workspace(filename);
    move_to_base_workspace(path);
    
    move_to_base_workspace(notes);
    move_to_base_workspace(frequency_parameters);
    if (data_file_main_version_number > 1)
        move_to_base_workspace(reference_channel);
    end
    
    if (num_amplifier_channels > 0)
        move_to_base_workspace(amplifier_channels);
        if (data_present)
            move_to_base_workspace(amplifier_data);
            move_to_base_workspace(t_amplifier);
        end
        move_to_base_workspace(spike_triggers);
    end
    if (num_aux_input_channels > 0)
        move_to_base_workspace(aux_input_channels);
        if (data_present)
            move_to_base_workspace(aux_input_data);
            move_to_base_workspace(t_aux_input);
        end
    end
    if (num_supply_voltage_channels > 0)
        move_to_base_workspace(supply_voltage_channels);
        if (data_present)
            move_to_base_workspace(supply_voltage_data);
            move_to_base_workspace(t_supply_voltage);
        end
    end
    if (num_board_adc_channels > 0)
        move_to_base_workspace(board_adc_channels);
        if (data_present)
            move_to_base_workspace(board_adc_data);
            move_to_base_workspace(t_board_adc);
        end
    end
    if (num_board_dig_in_channels > 0)
        move_to_base_workspace(board_dig_in_channels);
        if (data_present)
            move_to_base_workspace(board_dig_in_data);
            move_to_base_workspace(t_dig);
        end
    end
    if (num_board_dig_out_channels > 0)
        move_to_base_workspace(board_dig_out_channels);
        if (data_present)
            move_to_base_workspace(board_dig_out_data);
            move_to_base_workspace(t_dig);
        end
    end
    if (num_temp_sensor_channels > 0)
        if (data_present)
            move_to_base_workspace(temp_sensor_data);
            move_to_base_workspace(t_temp_sensor);
        end
    end
    
    % fprintf(1, 'Done!  Elapsed time: %0.1f seconds\n', toc);
    % if (data_present)
    %     fprintf(1, 'Extracted data are now available in the MATLAB workspace.\n');
    % else
    %     fprintf(1, 'Extracted waveform information is now available in the MATLAB workspace.\n');
    % end
    % fprintf(1, 'Type ''whos'' to see variables.\n');
    % fprintf(1, '\n');
    channelNames = string({amplifier_channels.custom_channel_name})';
    nativeChannelNames = string({amplifier_channels.native_channel_name})';
    signalData = amplifier_data;
    digitalInData = board_dig_in_data;
    fs = frequency_parameters.amplifier_sample_rate;
    return
end    
function [channelNames, signalData, fs, digitalInData] = read_Intan_RHS2000_file(filepn)
    % read_Intan_RHS2000_file
    %
    % Version 3.0, 8 February 2021
    %
    % Reads Intan Technologies RHS data file generated by Intan Stimulation /
    % Recording Controller.  Data are parsed and placed into variables that
    % appear in the base MATLAB workspace.  Therefore, it is recommended to
    % execute a 'clear' command before running this program to clear all other
    % variables from the base workspace.
    %
    % % Example:
    % % >> clear
    % % >> read_Intan_RHS2000_file
    % % >> whos
    % % >> amplifier_channels(1)
    % % >> plot(t, amplifier_data(1,:))
    % 
    % [file, path, filterindex] = ...
    %     uigetfile('*.rhs', 'Select an RHS2000 Data File', 'MultiSelect', 'off');
    % 
    % if (file == 0)
    %     return;
    % end
    
    % % % tic;
    % % % filename = [path,file];
    fid = fopen(filepn, 'r');
    
    s = dir(filepn);
    filesize = s.bytes;
    
    % Check 'magic number' at beginning of file to make sure this is an Intan
    % Technologies RHS2000 data file.
    magic_number = fread(fid, 1, 'uint32');
    if magic_number ~= hex2dec('d69127ac')
        error('Unrecognized file type.');
    end
    
    % Read version number.
    data_file_main_version_number = fread(fid, 1, 'int16');
    data_file_secondary_version_number = fread(fid, 1, 'int16');
    
    % fprintf(1, '\n');
    % fprintf(1, 'Reading Intan Technologies RHS2000 Data File, Version %d.%d\n', ...
    %     data_file_main_version_number, data_file_secondary_version_number);
    % fprintf(1, '\n');
    
    num_samples_per_data_block = 128;
    
    % Read information of sampling rate and amplifier frequency settings.
    sample_rate = fread(fid, 1, 'single');
    dsp_enabled = fread(fid, 1, 'int16');
    actual_dsp_cutoff_frequency = fread(fid, 1, 'single');
    actual_lower_bandwidth = fread(fid, 1, 'single');
    actual_lower_settle_bandwidth = fread(fid, 1, 'single');
    actual_upper_bandwidth = fread(fid, 1, 'single');
    
    desired_dsp_cutoff_frequency = fread(fid, 1, 'single');
    desired_lower_bandwidth = fread(fid, 1, 'single');
    desired_lower_settle_bandwidth = fread(fid, 1, 'single');
    desired_upper_bandwidth = fread(fid, 1, 'single');
    
    % This tells us if a software 50/60 Hz notch filter was enabled during
    % the data acquisition.
    notch_filter_mode = fread(fid, 1, 'int16');
    notch_filter_frequency = 0;
    if (notch_filter_mode == 1)
        notch_filter_frequency = 50;
    elseif (notch_filter_mode == 2)
        notch_filter_frequency = 60;
    end
    
    desired_impedance_test_frequency = fread(fid, 1, 'single');
    actual_impedance_test_frequency = fread(fid, 1, 'single');
    
    amp_settle_mode = fread(fid, 1, 'int16');
    charge_recovery_mode = fread(fid, 1, 'int16');
    
    stim_step_size = fread(fid, 1, 'single');
    charge_recovery_current_limit = fread(fid, 1, 'single');
    charge_recovery_target_voltage = fread(fid, 1, 'single');
    
    % Place notes in data strucure
    notes = struct( ...
        'note1', fread_QString(fid), ...
        'note2', fread_QString(fid), ...
        'note3', fread_QString(fid) );
        
    % See if dc amplifier data was saved
    dc_amp_data_saved = fread(fid, 1, 'int16');
    
    % Load board mode.
    board_mode = fread(fid, 1, 'int16');
    
    reference_channel = fread_QString(fid);
    
    % Place frequency-related information in data structure.
    frequency_parameters = struct( ...
        'amplifier_sample_rate', sample_rate, ...
        'board_adc_sample_rate', sample_rate, ...
        'board_dig_in_sample_rate', sample_rate, ...
        'desired_dsp_cutoff_frequency', desired_dsp_cutoff_frequency, ...
        'actual_dsp_cutoff_frequency', actual_dsp_cutoff_frequency, ...
        'dsp_enabled', dsp_enabled, ...
        'desired_lower_bandwidth', desired_lower_bandwidth, ...
        'desired_lower_settle_bandwidth', desired_lower_settle_bandwidth, ...
        'actual_lower_bandwidth', actual_lower_bandwidth, ...
        'actual_lower_settle_bandwidth', actual_lower_settle_bandwidth, ...
        'desired_upper_bandwidth', desired_upper_bandwidth, ...
        'actual_upper_bandwidth', actual_upper_bandwidth, ...
        'notch_filter_frequency', notch_filter_frequency, ...
        'desired_impedance_test_frequency', desired_impedance_test_frequency, ...
        'actual_impedance_test_frequency', actual_impedance_test_frequency );
    
    stim_parameters = struct( ...
        'stim_step_size', stim_step_size, ...
        'charge_recovery_current_limit', charge_recovery_current_limit, ...
        'charge_recovery_target_voltage', charge_recovery_target_voltage, ...
        'amp_settle_mode', amp_settle_mode, ...
        'charge_recovery_mode', charge_recovery_mode );
    
    % Define data structure for spike trigger settings.
    spike_trigger_struct = struct( ...
        'voltage_trigger_mode', {}, ...
        'voltage_threshold', {}, ...
        'digital_trigger_channel', {}, ...
        'digital_edge_polarity', {} );
    
    new_trigger_channel = struct(spike_trigger_struct);
    spike_triggers = struct(spike_trigger_struct);
    
    % Define data structure for data channels.
    channel_struct = struct( ...
        'native_channel_name', {}, ...
        'custom_channel_name', {}, ...
        'native_order', {}, ...
        'custom_order', {}, ...
        'board_stream', {}, ...
        'chip_channel', {}, ...
        'port_name', {}, ...
        'port_prefix', {}, ...
        'port_number', {}, ...
        'electrode_impedance_magnitude', {}, ...
        'electrode_impedance_phase', {} );
    
    new_channel = struct(channel_struct);
    
    % Create structure arrays for each type of data channel.
    amplifier_channels = struct(channel_struct);
    board_adc_channels = struct(channel_struct);
    board_dac_channels = struct(channel_struct);
    board_dig_in_channels = struct(channel_struct);
    board_dig_out_channels = struct(channel_struct);
    
    amplifier_index = 1;
    board_adc_index = 1;
    board_dac_index = 1;
    board_dig_in_index = 1;
    board_dig_out_index = 1;
    
    % Read signal summary from data file header.
    
    number_of_signal_groups = fread(fid, 1, 'int16');
    
    for signal_group = 1:number_of_signal_groups
        signal_group_name = fread_QString(fid);
        signal_group_prefix = fread_QString(fid);
        signal_group_enabled = fread(fid, 1, 'int16');
        signal_group_num_channels = fread(fid, 1, 'int16');
        signal_group_num_amp_channels = fread(fid, 1, 'int16');
    
        if (signal_group_num_channels > 0 && signal_group_enabled > 0)
            new_channel(1).port_name = signal_group_name;
            new_channel(1).port_prefix = signal_group_prefix;
            new_channel(1).port_number = signal_group;
            for signal_channel = 1:signal_group_num_channels
                new_channel(1).native_channel_name = fread_QString(fid);
                new_channel(1).custom_channel_name = fread_QString(fid);
                new_channel(1).native_order = fread(fid, 1, 'int16');
                new_channel(1).custom_order = fread(fid, 1, 'int16');
                signal_type = fread(fid, 1, 'int16');
                channel_enabled = fread(fid, 1, 'int16');
                new_channel(1).chip_channel = fread(fid, 1, 'int16');
                fread(fid, 1, 'int16');  % ignore command_stream
                new_channel(1).board_stream = fread(fid, 1, 'int16');
                new_trigger_channel(1).voltage_trigger_mode = fread(fid, 1, 'int16');
                new_trigger_channel(1).voltage_threshold = fread(fid, 1, 'int16');
                new_trigger_channel(1).digital_trigger_channel = fread(fid, 1, 'int16');
                new_trigger_channel(1).digital_edge_polarity = fread(fid, 1, 'int16');
                new_channel(1).electrode_impedance_magnitude = fread(fid, 1, 'single');
                new_channel(1).electrode_impedance_phase = fread(fid, 1, 'single');
                
                if (channel_enabled)
                    switch (signal_type)
                        case 0
                            amplifier_channels(amplifier_index) = new_channel;
                            spike_triggers(amplifier_index) = new_trigger_channel;
                            amplifier_index = amplifier_index + 1;
                        case 1
                            % aux inputs; not used in RHS2000 system
                        case 2
                            % supply voltage; not used in RHS2000 system
                        case 3
                            board_adc_channels(board_adc_index) = new_channel;
                            board_adc_index = board_adc_index + 1;
                        case 4
                            board_dac_channels(board_dac_index) = new_channel;
                            board_dac_index = board_dac_index + 1;
                        case 5
                            board_dig_in_channels(board_dig_in_index) = new_channel;
                            board_dig_in_index = board_dig_in_index + 1;
                        case 6
                            board_dig_out_channels(board_dig_out_index) = new_channel;
                            board_dig_out_index = board_dig_out_index + 1;
                        otherwise
                            error('Unknown channel type');
                    end
                end
                
            end
        end
    end
    
    % Summarize contents of data file.
    num_amplifier_channels = amplifier_index - 1;
    num_board_adc_channels = board_adc_index - 1;
    num_board_dac_channels = board_dac_index - 1;
    num_board_dig_in_channels = board_dig_in_index - 1;
    num_board_dig_out_channels = board_dig_out_index - 1;
    
    fprintf(1, 'Found %d amplifier channel%s.\n', ...
        num_amplifier_channels, plural(num_amplifier_channels));
    if (dc_amp_data_saved ~= 0)
        fprintf(1, 'Found %d DC amplifier channel%s.\n', ...
            num_amplifier_channels, plural(num_amplifier_channels));
    end
    fprintf(1, 'Found %d board ADC channel%s.\n', ...
        num_board_adc_channels, plural(num_board_adc_channels));
    fprintf(1, 'Found %d board DAC channel%s.\n', ...
        num_board_dac_channels, plural(num_board_dac_channels));
    fprintf(1, 'Found %d board digital input channel%s.\n', ...
        num_board_dig_in_channels, plural(num_board_dig_in_channels));
    fprintf(1, 'Found %d board digital output channel%s.\n', ...
        num_board_dig_out_channels, plural(num_board_dig_out_channels));
    fprintf(1, '\n');
    
    % Determine how many samples the data file contains.
    
    % Each data block contains num_samples_per_data_block amplifier samples.
    bytes_per_block = num_samples_per_data_block * 4;  % timestamp data
    if (dc_amp_data_saved ~= 0)
        bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2 + 2) * num_amplifier_channels;
    else
        bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2) * num_amplifier_channels;    
    end
    % Board analog inputs are sampled at same rate as amplifiers
    bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_board_adc_channels;
    % Board analog outputs are sampled at same rate as amplifiers
    bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_board_dac_channels;
    % Board digital inputs are sampled at same rate as amplifiers
    if (num_board_dig_in_channels > 0)
        bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
    end
    % Board digital outputs are sampled at same rate as amplifiers
    if (num_board_dig_out_channels > 0)
        bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
    end
    
    % How many data blocks remain in this file?
    data_present = 0;
    bytes_remaining = filesize - ftell(fid);
    if (bytes_remaining > 0)
        data_present = 1;
    end
    
    num_data_blocks = bytes_remaining / bytes_per_block;
    
    num_amplifier_samples = num_samples_per_data_block * num_data_blocks;
    num_board_adc_samples = num_samples_per_data_block * num_data_blocks;
    num_board_dac_samples = num_samples_per_data_block * num_data_blocks;
    num_board_dig_in_samples = num_samples_per_data_block * num_data_blocks;
    num_board_dig_out_samples = num_samples_per_data_block * num_data_blocks;
    
    record_time = num_amplifier_samples / sample_rate;
    
    if (data_present)
        fprintf(1, 'File contains %0.3f seconds of data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
            record_time, sample_rate / 1000);
        fprintf(1, '\n');
    else
        fprintf(1, 'Header file contains no data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
            sample_rate / 1000);
        fprintf(1, '\n');
    end
    
    if (data_present)
        
        % Pre-allocate memory for data.
        fprintf(1, 'Allocating memory for data...\n');
    
        t = zeros(1, num_amplifier_samples);
    
        amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
        if (dc_amp_data_saved ~= 0)
            dc_amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
        end
        stim_data = zeros(num_amplifier_channels, num_amplifier_samples);
        amp_settle_data = zeros(num_amplifier_channels, num_amplifier_samples);
        charge_recovery_data = zeros(num_amplifier_channels, num_amplifier_samples);
        compliance_limit_data = zeros(num_amplifier_channels, num_amplifier_samples);
        board_adc_data = zeros(num_board_adc_channels, num_board_adc_samples);
        board_dac_data = zeros(num_board_dac_channels, num_board_dac_samples);
        board_dig_in_data = zeros(num_board_dig_in_channels, num_board_dig_in_samples);
        board_dig_in_raw = zeros(1, num_board_dig_in_samples);
        board_dig_out_data = zeros(num_board_dig_out_channels, num_board_dig_out_samples);
        board_dig_out_raw = zeros(1, num_board_dig_out_samples);
    
        % Read sampled data from file.
        fprintf(1, 'Reading data from file...\n');
    
        amplifier_index = 1;
        board_adc_index = 1;
        board_dac_index = 1;
        board_dig_in_index = 1;
        board_dig_out_index = 1;
    
        print_increment = 10;
        percent_done = print_increment;
        for i=1:num_data_blocks
            t(amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'int32');
            if (num_amplifier_channels > 0)
                amplifier_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
                if (dc_amp_data_saved ~= 0)
                    dc_amplifier_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
                end
                stim_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
            end
            if (num_board_adc_channels > 0)
                board_adc_data(:, board_adc_index:(board_adc_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_board_adc_channels], 'uint16')';
            end
            if (num_board_dac_channels > 0)
                board_dac_data(:, board_dac_index:(board_dac_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_board_dac_channels], 'uint16')';
            end
            if (num_board_dig_in_channels > 0)
                board_dig_in_raw(board_dig_in_index:(board_dig_in_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
            end
            if (num_board_dig_out_channels > 0)
                board_dig_out_raw(board_dig_out_index:(board_dig_out_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
            end
    
            amplifier_index = amplifier_index + num_samples_per_data_block;
            board_adc_index = board_adc_index + num_samples_per_data_block;
            board_dac_index = board_dac_index + num_samples_per_data_block;
            board_dig_in_index = board_dig_in_index + num_samples_per_data_block;
            board_dig_out_index = board_dig_out_index + num_samples_per_data_block;
    
            fraction_done = 100 * (i / num_data_blocks);
            if (fraction_done >= percent_done)
                fprintf(1, '%d%% done...\n', percent_done);
                percent_done = percent_done + print_increment;
            end
        end
    
        % Make sure we have read exactly the right amount of data.
        bytes_remaining = filesize - ftell(fid);
        if (bytes_remaining ~= 0)
            %error('Error: End of file not reached.');
        end
    
    end
    
    % Close data file.
    fclose(fid);
    
    if (data_present)
        
        fprintf(1, 'Parsing data...\n');
    
        % Extract digital input channels to separate variables.
        for i=1:num_board_dig_in_channels
           mask = 2^(board_dig_in_channels(i).native_order) * ones(size(board_dig_in_raw));
           board_dig_in_data(i, :) = (bitand(board_dig_in_raw, mask) > 0);
        end
        for i=1:num_board_dig_out_channels
           mask = 2^(board_dig_out_channels(i).native_order) * ones(size(board_dig_out_raw));
           board_dig_out_data(i, :) = (bitand(board_dig_out_raw, mask) > 0);
        end
    
        % Scale voltage levels appropriately.
        amplifier_data = 0.195 * (amplifier_data - 32768); % units = microvolts
        if (dc_amp_data_saved ~= 0)
            dc_amplifier_data = -0.01923 * (dc_amplifier_data - 512); % units = volts
        end
        compliance_limit_data = stim_data >= 2^15;
        stim_data = stim_data - (compliance_limit_data * 2^15);
        charge_recovery_data = stim_data >= 2^14;
        stim_data = stim_data - (charge_recovery_data * 2^14);
        amp_settle_data = stim_data >= 2^13;
        stim_data = stim_data - (amp_settle_data * 2^13);
        stim_polarity = stim_data >= 2^8;
        stim_data = stim_data - (stim_polarity * 2^8);
        stim_polarity = 1 - 2 * stim_polarity; % convert (0 = pos, 1 = neg) to +/-1
        stim_data = stim_data .* stim_polarity;
        stim_data = stim_parameters.stim_step_size * stim_data / 1.0e-6; % units = microamps
        board_adc_data = 312.5e-6 * (board_adc_data - 32768); % units = volts
        board_dac_data = 312.5e-6 * (board_dac_data - 32768); % units = volts
    
        % Check for gaps in timestamps.
        num_gaps = sum(diff(t) ~= 1);
        if (num_gaps == 0)
            fprintf(1, 'No missing timestamps in data.\n');
        else
            fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
                num_gaps);
        end
    
        % Scale time steps (units = seconds).
        t = t / sample_rate;
    
        % If the software notch filter was selected during the recording, apply the
        % same notch filter to amplifier data here.  But don't do this for v3.0+ 
        % files (from Intan RHX software) because RHX saves notch-filtered data.
        if (notch_filter_frequency > 0 && data_file_main_version_number < 3)
            fprintf(1, 'Applying notch filter...\n');
    
            print_increment = 10;
            percent_done = print_increment;
            for i=1:num_amplifier_channels
                amplifier_data(i,:) = ...
                    notch_filter(amplifier_data(i,:), sample_rate, notch_filter_frequency, 10);
    
                fraction_done = 100 * (i / num_amplifier_channels);
                if (fraction_done >= percent_done)
                    fprintf(1, '%d%% done...\n', percent_done);
                    percent_done = percent_done + print_increment;
                end
    
            end
        end
    channelNames = string({amplifier_channels.custom_channel_name})';
    nativeChannelNames = string({amplifier_channels.native_channel_name})';
    signalData = amplifier_data;
    digitalInData = board_dig_in_data;
    fs = frequency_parameters.amplifier_sample_rate;
end
end
function a = fread_QString(fid)
    
    % a = read_QString(fid)
    %
    % Read Qt style QString.  The first 32-bit unsigned number indicates
    % the length of the string (in bytes).  If this number equals 0xFFFFFFFF,
    % the string is null.
    
    a = '';
    length = fread(fid, 1, 'uint32');
    if length == hex2num('ffffffff')
        return;
    end
    % convert length from bytes to 16-bit Unicode words
    length = length / 2;
    
    for i=1:length
        a(i) = fread(fid, 1, 'uint16');
    end
    
    return
end    
function s = plural(n)
    
    % s = plural(n)
    % 
    % Utility function to optionally plurailze words based on the value
    % of n.
    
    if (n == 1)
        s = '';
    else
        s = 's';
    end
    
    return
end    
function out = notch_filter(in, fSample, fNotch, Bandwidth)
    % out = notch_filter(in, fSample, fNotch, Bandwidth)
    %
    % Implements a notch filter (e.g., for 50 or 60 Hz) on vector 'in'.
    % fSample = sample rate of data (in Hz or Samples/sec)
    % fNotch = filter notch frequency (in Hz)
    % Bandwidth = notch 3-dB bandwidth (in Hz).  A bandwidth of 10 Hz is
    %   recommended for 50 or 60 Hz notch filters; narrower bandwidths lead to
    %   poor time-domain properties with an extended ringing response to
    %   transient disturbances.
    %
    % Example:  If neural data was sampled at 30 kSamples/sec
    % and you wish to implement a 60 Hz notch filter:
    %
    % out = notch_filter(in, 30000, 60, 10);
    
    tstep = 1/fSample;
    Fc = fNotch*tstep;
    
    L = length(in);
    
    % Calculate IIR filter parameters
    d = exp(-2*pi*(Bandwidth/2)*tstep);
    b = (1 + d*d)*cos(2*pi*Fc);
    a0 = 1;
    a1 = -b;
    a2 = d*d;
    a = (1 + d*d)/2;
    b0 = 1;
    b1 = -2*cos(2*pi*Fc);
    b2 = 1;
    
    out = zeros(size(in));
    out(1) = in(1);  
    out(2) = in(2);
    % (If filtering a continuous data stream, change out(1) and out(2) to the
    %  previous final two values of out.)
    
    % Run filter
    for i=3:L
        out(i) = (a*b2*in(i-2) + a*b1*in(i-1) + a*b0*in(i) - a2*out(i-2) - a1*out(i-1))/a0;
    end
    
    return
end
function move_to_base_workspace(variable)
    
    % move_to_base_workspace(variable)
    %
    % Move variable from function workspace to base MATLAB workspace so
    % user will have access to it after the program ends.
    
    variable_name = inputname(1);
    assignin('base', variable_name, variable);
    
    return;
end    

% 
% function [channelNames, signalData, fs] = read_Intan_RHD2000_file(filepn)
% 
%     % read_Intan_RHD2000_file
%     %
%     % Version 1.3, 10 December 2013
%     %
%     % Reads Intan Technologies RHD2000 data file generated by evaluation board
%     % GUI.  Data are parsed and placed into variables that appear in the base
%     % MATLAB workspace.  Therefore, it is recommended to execute a 'clear'
%     % command before running this program to clear all other variables from the
%     % base workspace.
%     %
%     % Example:
%     % >> clear
%     % >> read_Intan_RHD200_file
%     % >> whos
%     % >> amplifier_channels(1)
%     % >> plot(t_amplifier, amplifier_data(1,:))
% 
%     % % % % [file, path, filterindex] = ...
%     % % % %     uigetfile('*.rhd', 'Select an RHD2000 Data File', 'MultiSelect', 'off');
% 
%     % Read most recent file automatically.
%     %path = 'C:\Users\Reid\Documents\RHD2132\testing\';
%     %d = dir([path '*.rhd']);
%     %file = d(end).name;
% 
% 
%     fid = fopen(filepn, 'r');
% 
%     s = dir(filepn);
%     filesize = s.bytes;
% 
%     % % % % 
%     % % % % tic;
%     % % % % filename = [path,file];
%     % % % % fid = fopen(filename, 'r');
%     % % % % 
%     % % % % s = dir(filename);
%     % % % % filesize = s.bytes;
% 
%     % Check 'magic number' at beginning of file to make sure this is an Intan
%     % Technologies RHD2000 data file.
%     magic_number = fread(fid, 1, 'uint32');
%     if magic_number ~= hex2dec('c6912702')
%         error('Unrecognized file type.');
%     end
% 
%     % Read version number.
%     data_file_main_version_number = fread(fid, 1, 'int16');
%     data_file_secondary_version_number = fread(fid, 1, 'int16');
% 
%     fprintf(1, '\n');
%     fprintf(1, 'Reading Intan Technologies RHD2000 Data File, Version %d.%d\n', ...
%         data_file_main_version_number, data_file_secondary_version_number);
%     fprintf(1, '\n');
% 
%     % Read information of sampling rate and amplifier frequency settings.
%     sample_rate = fread(fid, 1, 'single');
%     dsp_enabled = fread(fid, 1, 'int16');
%     actual_dsp_cutoff_frequency = fread(fid, 1, 'single');
%     actual_lower_bandwidth = fread(fid, 1, 'single');
%     actual_upper_bandwidth = fread(fid, 1, 'single');
% 
%     desired_dsp_cutoff_frequency = fread(fid, 1, 'single');
%     desired_lower_bandwidth = fread(fid, 1, 'single');
%     desired_upper_bandwidth = fread(fid, 1, 'single');
% 
%     % This tells us if a software 50/60 Hz notch filter was enabled during
%     % the data acquisition.
%     notch_filter_mode = fread(fid, 1, 'int16');
%     notch_filter_frequency = 0;
%     if (notch_filter_mode == 1)
%         notch_filter_frequency = 50;
%     elseif (notch_filter_mode == 2)
%         notch_filter_frequency = 60;
%     end
% 
%     desired_impedance_test_frequency = fread(fid, 1, 'single');
%     actual_impedance_test_frequency = fread(fid, 1, 'single');
% 
%     % Place notes in data strucure
%     notes = struct( ...
%         'note1', fread_QString(fid), ...
%         'note2', fread_QString(fid), ...
%         'note3', fread_QString(fid) );
% 
%     % If data file is from GUI v1.1 or later, see if temperature sensor data
%     % was saved.
%     num_temp_sensor_channels = 0;
%     if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 1) ...
%         || (data_file_main_version_number > 1))
%         num_temp_sensor_channels = fread(fid, 1, 'int16');
%     end
% 
%     % If data file is from GUI v1.3 or later, load eval board mode.
%     eval_board_mode = 0;
%     if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 3) ...
%         || (data_file_main_version_number > 1))
%         eval_board_mode = fread(fid, 1, 'int16');
%     end
% 
%     % Place frequency-related information in data structure.
%     frequency_parameters = struct( ...
%         'amplifier_sample_rate', sample_rate, ...
%         'aux_input_sample_rate', sample_rate / 4, ...
%         'supply_voltage_sample_rate', sample_rate / 60, ...
%         'board_adc_sample_rate', sample_rate, ...
%         'board_dig_in_sample_rate', sample_rate, ...
%         'desired_dsp_cutoff_frequency', desired_dsp_cutoff_frequency, ...
%         'actual_dsp_cutoff_frequency', actual_dsp_cutoff_frequency, ...
%         'dsp_enabled', dsp_enabled, ...
%         'desired_lower_bandwidth', desired_lower_bandwidth, ...
%         'actual_lower_bandwidth', actual_lower_bandwidth, ...
%         'desired_upper_bandwidth', desired_upper_bandwidth, ...
%         'actual_upper_bandwidth', actual_upper_bandwidth, ...
%         'notch_filter_frequency', notch_filter_frequency, ...
%         'desired_impedance_test_frequency', desired_impedance_test_frequency, ...
%         'actual_impedance_test_frequency', actual_impedance_test_frequency );
% 
%     % Define data structure for spike trigger settings.
%     spike_trigger_struct = struct( ...
%         'voltage_trigger_mode', {}, ...
%         'voltage_threshold', {}, ...
%         'digital_trigger_channel', {}, ...
%         'digital_edge_polarity', {} );
% 
%     new_trigger_channel = struct(spike_trigger_struct);
%     spike_triggers = struct(spike_trigger_struct);
% 
%     % Define data structure for data channels.
%     channel_struct = struct( ...
%         'native_channel_name', {}, ...
%         'custom_channel_name', {}, ...
%         'native_order', {}, ...
%         'custom_order', {}, ...
%         'board_stream', {}, ...
%         'chip_channel', {}, ...
%         'port_name', {}, ...
%         'port_prefix', {}, ...
%         'port_number', {}, ...
%         'electrode_impedance_magnitude', {}, ...
%         'electrode_impedance_phase', {} );
% 
%     new_channel = struct(channel_struct);
% 
%     % Create structure arrays for each type of data channel.
%     amplifier_channels = struct(channel_struct);
%     aux_input_channels = struct(channel_struct);
%     supply_voltage_channels = struct(channel_struct);
%     board_adc_channels = struct(channel_struct);
%     board_dig_in_channels = struct(channel_struct);
%     board_dig_out_channels = struct(channel_struct);
% 
%     amplifier_index = 1;
%     aux_input_index = 1;
%     supply_voltage_index = 1;
%     board_adc_index = 1;
%     board_dig_in_index = 1;
%     board_dig_out_index = 1;
% 
%     % Read signal summary from data file header.
% 
%     number_of_signal_groups = fread(fid, 1, 'int16');
% 
%     for signal_group = 1:number_of_signal_groups
%         signal_group_name = fread_QString(fid);
%         signal_group_prefix = fread_QString(fid);
%         signal_group_enabled = fread(fid, 1, 'int16');
%         signal_group_num_channels = fread(fid, 1, 'int16');
%         signal_group_num_amp_channels = fread(fid, 1, 'int16');
% 
%         if (signal_group_num_channels > 0 && signal_group_enabled > 0)
%             new_channel(1).port_name = signal_group_name;
%             new_channel(1).port_prefix = signal_group_prefix;
%             new_channel(1).port_number = signal_group;
%             for signal_channel = 1:signal_group_num_channels
% signal_channel_ = signal_channel
%                 new_channel(1).native_channel_name = fread_QString(fid);
%                 new_channel(1).custom_channel_name = fread_QString(fid);
%                 new_channel(1).native_order = fread(fid, 1, 'int16');
%                 new_channel(1).custom_order = fread(fid, 1, 'int16');
%                 signal_type = fread(fid, 1, 'int16');
%                 channel_enabled = fread(fid, 1, 'int16');
%                 new_channel(1).chip_channel = fread(fid, 1, 'int16');
%                 new_channel(1).board_stream = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).voltage_trigger_mode = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).voltage_threshold = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).digital_trigger_channel = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).digital_edge_polarity = fread(fid, 1, 'int16');
%                 new_channel(1).electrode_impedance_magnitude = fread(fid, 1, 'single');
%                 new_channel(1).electrode_impedance_phase = fread(fid, 1, 'single');
% 
%                 if (channel_enabled)
%                     switch (signal_type)
%                         case 0
%                             amplifier_channels(amplifier_index) = new_channel;
%                             spike_triggers(amplifier_index) = new_trigger_channel;
%                             amplifier_index = amplifier_index + 1;
%                         case 1
%                             aux_input_channels(aux_input_index) = new_channel;
%                             aux_input_index = aux_input_index + 1;
%                         case 2
%                             supply_voltage_channels(supply_voltage_index) = new_channel;
%                             supply_voltage_index = supply_voltage_index + 1;
%                         case 3
%                             board_adc_channels(board_adc_index) = new_channel;
%                             board_adc_index = board_adc_index + 1;
%                         case 4
%                             board_dig_in_channels(board_dig_in_index) = new_channel;
%                             board_dig_in_index = board_dig_in_index + 1;
%                         case 5
%                             board_dig_out_channels(board_dig_out_index) = new_channel;
%                             board_dig_out_index = board_dig_out_index + 1;
%                         otherwise
%                             error('Unknown channel type');
%                     end
%                 end
% 
%             end
%         end
%     end
% 
%     % Summarize contents of data file.
%     num_amplifier_channels = amplifier_index - 1;
%     num_aux_input_channels = aux_input_index - 1;
%     num_supply_voltage_channels = supply_voltage_index - 1;
%     num_board_adc_channels = board_adc_index - 1;
%     num_board_dig_in_channels = board_dig_in_index - 1;
%     num_board_dig_out_channels = board_dig_out_index - 1;
% 
%     fprintf(1, 'Found %d amplifier channel%s.\n', ...
%         num_amplifier_channels, plural(num_amplifier_channels));
%     fprintf(1, 'Found %d auxiliary input channel%s.\n', ...
%         num_aux_input_channels, plural(num_aux_input_channels));
%     fprintf(1, 'Found %d supply voltage channel%s.\n', ...
%         num_supply_voltage_channels, plural(num_supply_voltage_channels));
%     fprintf(1, 'Found %d board ADC channel%s.\n', ...
%         num_board_adc_channels, plural(num_board_adc_channels));
%     fprintf(1, 'Found %d board digital input channel%s.\n', ...
%         num_board_dig_in_channels, plural(num_board_dig_in_channels));
%     fprintf(1, 'Found %d board digital output channel%s.\n', ...
%         num_board_dig_out_channels, plural(num_board_dig_out_channels));
%     fprintf(1, 'Found %d temperature sensors channel%s.\n', ...
%         num_temp_sensor_channels, plural(num_temp_sensor_channels));
%     fprintf(1, '\n');
% 
%     % Determine how many samples the data file contains.
% 
%     % Each data block contains 60 amplifier samples.
%     bytes_per_block = 60 * 4;  % timestamp data
%     bytes_per_block = bytes_per_block + 60 * 2 * num_amplifier_channels;
%     % Auxiliary inputs are sampled 4x slower than amplifiers
%     bytes_per_block = bytes_per_block + 15 * 2 * num_aux_input_channels;
%     % Supply voltage is sampled 60x slower than amplifiers
%     bytes_per_block = bytes_per_block + 1 * 2 * num_supply_voltage_channels;
%     % Board analog inputs are sampled at same rate as amplifiers
%     bytes_per_block = bytes_per_block + 60 * 2 * num_board_adc_channels;
%     % Board digital inputs are sampled at same rate as amplifiers
%     if (num_board_dig_in_channels > 0)
%         bytes_per_block = bytes_per_block + 60 * 2;
%     end
%     % Board digital outputs are sampled at same rate as amplifiers
%     if (num_board_dig_out_channels > 0)
%         bytes_per_block = bytes_per_block + 60 * 2;
%     end
%     % Temp sensor is sampled 60x slower than amplifiers
%     if (num_temp_sensor_channels > 0)
%        bytes_per_block = bytes_per_block + 1 * 2 * num_temp_sensor_channels; 
%     end
% 
%     % How many data blocks remain in this file?
%     data_present = 0;
%     bytes_remaining = filesize - ftell(fid);
%     if (bytes_remaining > 0)
%         data_present = 1;
%     end
% 
%     num_data_blocks = bytes_remaining / bytes_per_block;
% 
%     num_amplifier_samples = 60 * num_data_blocks;
%     num_aux_input_samples = 15 * num_data_blocks;
%     num_supply_voltage_samples = 1 * num_data_blocks;
%     num_board_adc_samples = 60 * num_data_blocks;
%     num_board_dig_in_samples = 60 * num_data_blocks;
%     num_board_dig_out_samples = 60 * num_data_blocks;
% 
%     record_time = num_amplifier_samples / sample_rate;
% 
%     if (data_present)
%         fprintf(1, 'File contains %0.3f seconds of data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
%             record_time, sample_rate / 1000);
%         fprintf(1, '\n');
%     else
%         fprintf(1, 'Header file contains no data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
%             sample_rate / 1000);
%         fprintf(1, '\n');
%     end
% 
%     if (data_present)
% 
%         % Pre-allocate memory for data.
%         fprintf(1, 'Allocating memory for data...\n');
% 
%         t_amplifier = zeros(1, num_amplifier_samples);
% 
%         amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
%         aux_input_data = zeros(num_aux_input_channels, num_aux_input_samples);
%         supply_voltage_data = zeros(num_supply_voltage_channels, num_supply_voltage_samples);
%         temp_sensor_data = zeros(num_temp_sensor_channels, num_supply_voltage_samples);
%         board_adc_data = zeros(num_board_adc_channels, num_board_adc_samples);
%         board_dig_in_data = zeros(num_board_dig_in_channels, num_board_dig_in_samples);
%         board_dig_in_raw = zeros(1, num_board_dig_in_samples);
%         board_dig_out_data = zeros(num_board_dig_out_channels, num_board_dig_out_samples);
%         board_dig_out_raw = zeros(1, num_board_dig_out_samples);
% 
%         % Read sampled data from file.
%         fprintf(1, 'Reading data from file...\n');
% 
%         amplifier_index = 1;
%         aux_input_index = 1;
%         supply_voltage_index = 1;
%         board_adc_index = 1;
%         board_dig_in_index = 1;
%         board_dig_out_index = 1;
% 
%         print_increment = 10;
%         percent_done = print_increment;
%         for i=1:num_data_blocks
%             % In version 1.2, we moved from saving timestamps as unsigned
%             % integeters to signed integers to accomidate negative (adjusted)
%             % timestamps for pretrigger data.
%             if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 2) ...
%             || (data_file_main_version_number > 1))
%                 t_amplifier(amplifier_index:(amplifier_index+59)) = fread(fid, 60, 'int32');
%             else
%                 t_amplifier(amplifier_index:(amplifier_index+59)) = fread(fid, 60, 'uint32');
%             end
%             if (num_amplifier_channels > 0)
%                 amplifier_data(:, amplifier_index:(amplifier_index+59)) = fread(fid, [60, num_amplifier_channels], 'uint16')';
%             end
%             if (num_aux_input_channels > 0)
%                 aux_input_data(:, aux_input_index:(aux_input_index+14)) = fread(fid, [15, num_aux_input_channels], 'uint16')';
%             end
%             if (num_supply_voltage_channels > 0)
%                 supply_voltage_data(:, supply_voltage_index) = fread(fid, [1, num_supply_voltage_channels], 'uint16')';
%             end
%             if (num_temp_sensor_channels > 0)
%                 temp_sensor_data(:, supply_voltage_index) = fread(fid, [1, num_temp_sensor_channels], 'int16')';
%             end
%             if (num_board_adc_channels > 0)
%                 board_adc_data(:, board_adc_index:(board_adc_index+59)) = fread(fid, [60, num_board_adc_channels], 'uint16')';
%             end
%             if (num_board_dig_in_channels > 0)
%                 board_dig_in_raw(board_dig_in_index:(board_dig_in_index+59)) = fread(fid, 60, 'uint16');
%             end
%             if (num_board_dig_out_channels > 0)
%                 board_dig_out_raw(board_dig_out_index:(board_dig_out_index+59)) = fread(fid, 60, 'uint16');
%             end
% 
%             amplifier_index = amplifier_index + 60;
%             aux_input_index = aux_input_index + 15;
%             supply_voltage_index = supply_voltage_index + 1;
%             board_adc_index = board_adc_index + 60;
%             board_dig_in_index = board_dig_in_index + 60;
%             board_dig_out_index = board_dig_out_index + 60;
% 
%             fraction_done = 100 * (i / num_data_blocks);
%             if (fraction_done >= percent_done)
%                 fprintf(1, '%d%% done...\n', percent_done);
%                 percent_done = percent_done + print_increment;
%             end
%         end
% 
%         % Make sure we have read exactly the right amount of data.
%         bytes_remaining = filesize - ftell(fid);
%         if (bytes_remaining ~= 0)
%             %error('Error: End of file not reached.');
%         end
% 
%     end
% 
%     % Close data file.
%     fclose(fid);
% 
%     if (data_present)
% 
%         fprintf(1, 'Parsing data...\n');
% 
%         % Extract digital input channels to separate variables.
%         for i=1:num_board_dig_in_channels
%            mask = 2^(board_dig_in_channels(i).native_order) * ones(size(board_dig_in_raw));
%            board_dig_in_data(i, :) = (bitand(board_dig_in_raw, mask) > 0);
%         end
%         for i=1:num_board_dig_out_channels
%            mask = 2^(board_dig_out_channels(i).native_order) * ones(size(board_dig_out_raw));
%            board_dig_out_data(i, :) = (bitand(board_dig_out_raw, mask) > 0);
%         end
% 
%         % Scale voltage levels appropriately.
%         amplifier_data = 0.195 * (amplifier_data - 32768); % units = microvolts
%         aux_input_data = 37.4e-6 * aux_input_data; % units = volts
%         supply_voltage_data = 74.8e-6 * supply_voltage_data; % units = volts
%         if (eval_board_mode == 1)
%             board_adc_data = 152.59e-6 * (board_adc_data - 32768); % units = volts    
%         else
%             board_adc_data = 50.354e-6 * board_adc_data; % units = volts
%         end
%         temp_sensor_data = temp_sensor_data / 100; % units = deg C
% 
%         % Check for gaps in timestamps.
%         num_gaps = sum(diff(t_amplifier) ~= 1);
%         if (num_gaps == 0)
%             fprintf(1, 'No missing timestamps in data.\n');
%         else
%             fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
%                 num_gaps);
%         end
% 
%         % Scale time steps (units = seconds).
%         t_amplifier = t_amplifier / sample_rate;
%         t_aux_input = t_amplifier(1:4:end);
%         t_supply_voltage = t_amplifier(1:60:end);
%         t_board_adc = t_amplifier;
%         t_dig = t_amplifier;
%         t_temp_sensor = t_supply_voltage;
% 
%         % If the software notch filter was selected during the recording, apply the
%         % same notch filter to amplifier data here.
%         if (notch_filter_frequency > 0)
%             fprintf(1, 'Applying notch filter...\n');
% 
%             print_increment = 10;
%             percent_done = print_increment;
%             for i=1:num_amplifier_channels
%                 amplifier_data(i,:) = ...
%                     notch_filter(amplifier_data(i,:), sample_rate, notch_filter_frequency, 10);
% 
%                 fraction_done = 100 * (i / num_amplifier_channels);
%                 if (fraction_done >= percent_done)
%                     fprintf(1, '%d%% done...\n', percent_done);
%                     percent_done = percent_done + print_increment;
%                 end
% 
%             end
%         end
% 
%     end
% 
%     % Move variables to base workspace.
% 
%     move_to_base_workspace(notes);
%     move_to_base_workspace(frequency_parameters);
% 
%     if (num_amplifier_channels > 0)
%         move_to_base_workspace(amplifier_channels);
%         if (data_present)
%             move_to_base_workspace(amplifier_data);
%             move_to_base_workspace(t_amplifier);
%         end
%         move_to_base_workspace(spike_triggers);
%     end
%     if (num_aux_input_channels > 0)
%         move_to_base_workspace(aux_input_channels);
%         if (data_present)
%             move_to_base_workspace(aux_input_data);
%             move_to_base_workspace(t_aux_input);
%         end
%     end
%     if (num_supply_voltage_channels > 0)
%         move_to_base_workspace(supply_voltage_channels);
%         if (data_present)
%             move_to_base_workspace(supply_voltage_data);
%             move_to_base_workspace(t_supply_voltage);
%         end
%     end
%     if (num_board_adc_channels > 0)
%         move_to_base_workspace(board_adc_channels);
%         if (data_present)
%             move_to_base_workspace(board_adc_data);
%             move_to_base_workspace(t_board_adc);
%         end
%     end
%     if (num_board_dig_in_channels > 0)
%         move_to_base_workspace(board_dig_in_channels);
%         if (data_present)
%             move_to_base_workspace(board_dig_in_data);
%             move_to_base_workspace(t_dig);
%         end
%     end
%     if (num_board_dig_out_channels > 0)
%         move_to_base_workspace(board_dig_out_channels);
%         if (data_present)
%             move_to_base_workspace(board_dig_out_data);
%             move_to_base_workspace(t_dig);
%         end
%     end
%     if (num_temp_sensor_channels > 0)
%         if (data_present)
%             move_to_base_workspace(temp_sensor_data);
%             move_to_base_workspace(t_temp_sensor);
%         end
%     end
% 
% 
% 
%     % % % % % % % % % % % % % % % % fprintf(1, 'Done!  Elapsed time: %0.1f seconds\n', toc);
%     % % % % % % % % % % % % % % % % if (data_present)
%     % % % % % % % % % % % % % % % %     fprintf(1, 'Extracted data are now available in the MATLAB workspace.\n');
%     % % % % % % % % % % % % % % % % else
%     % % % % % % % % % % % % % % % %     fprintf(1, 'Extracted waveform information is now available in the MATLAB workspace.\n');
%     % % % % % % % % % % % % % % % % end
%     % % % % % % % % % % % % % % % % fprintf(1, 'Type ''whos'' to see variables.\n');
%     % % % % % % % % % % % % % % % % fprintf(1, '\n');
% 
% 
% 
%     channelNames = string({amplifier_channels.custom_channel_name})';
%     nativeChannelNames = string({amplifier_channels.native_channel_name})';
%     signalData = amplifier_data;
%     fs = frequency_parameters.amplifier_sample_rate;
% end
% 
% 
% function a = fread_QString(fid)
% 
%     % a = read_QString(fid)
%     %
%     % Read Qt style QString.  The first 32-bit unsigned number indicates
%     % the length of the string (in bytes).  If this number equals 0xFFFFFFFF,
%     % the string is null.
% 
%     a = '';
%     length = fread(fid, 1, 'uint32');
%     if length == hex2num('ffffffff')
%         return;
%     end
%     % convert length from bytes to 16-bit Unicode words
%     length = length / 2;
% 
%     for i=1:length
%         a(i) = fread(fid, 1, 'uint16');
%     end
% end
% 
% 
% 
% 
% 
% function [channelNames, signalData, fs] = read_Intan_RHS2000_file(filepn)
%     % read_Intan_RHS2000_file
%     %
%     % Version 3.0, 8 February 2021
%     %
%     % Reads Intan Technologies RHS data file generated by Intan Stimulation /
%     % Recording Controller.  Data are parsed and placed into variables that
%     % appear in the base MATLAB workspace.  Therefore, it is recommended to
%     % execute a 'clear' command before running this program to clear all other
%     % variables from the base workspace.
%     %
%     % % Example:
%     % % >> clear
%     % % >> read_Intan_RHS2000_file
%     % % >> whos
%     % % >> amplifier_channels(1)
%     % % >> plot(t, amplifier_data(1,:))
%     % 
%     % [file, path, filterindex] = ...
%     %     uigetfile('*.rhs', 'Select an RHS2000 Data File', 'MultiSelect', 'off');
%     % 
%     % if (file == 0)
%     %     return;
%     % end
% 
%     % % % tic;
%     % % % filename = [path,file];
%     fid = fopen(filepn, 'r');
% 
%     s = dir(filepn);
%     filesize = s.bytes;
% 
%     % Check 'magic number' at beginning of file to make sure this is an Intan
%     % Technologies RHS2000 data file.
%     magic_number = fread(fid, 1, 'uint32');
%     if magic_number ~= hex2dec('d69127ac')
%         error('Unrecognized file type.');
%     end
% 
%     % Read version number.
%     data_file_main_version_number = fread(fid, 1, 'int16');
%     data_file_secondary_version_number = fread(fid, 1, 'int16');
% 
%     fprintf(1, '\n');
%     fprintf(1, 'Reading Intan Technologies RHS2000 Data File, Version %d.%d\n', ...
%         data_file_main_version_number, data_file_secondary_version_number);
%     fprintf(1, '\n');
% 
%     num_samples_per_data_block = 128;
% 
%     % Read information of sampling rate and amplifier frequency settings.
%     sample_rate = fread(fid, 1, 'single');
%     dsp_enabled = fread(fid, 1, 'int16');
%     actual_dsp_cutoff_frequency = fread(fid, 1, 'single');
%     actual_lower_bandwidth = fread(fid, 1, 'single');
%     actual_lower_settle_bandwidth = fread(fid, 1, 'single');
%     actual_upper_bandwidth = fread(fid, 1, 'single');
% 
%     desired_dsp_cutoff_frequency = fread(fid, 1, 'single');
%     desired_lower_bandwidth = fread(fid, 1, 'single');
%     desired_lower_settle_bandwidth = fread(fid, 1, 'single');
%     desired_upper_bandwidth = fread(fid, 1, 'single');
% 
%     % This tells us if a software 50/60 Hz notch filter was enabled during
%     % the data acquisition.
%     notch_filter_mode = fread(fid, 1, 'int16');
%     notch_filter_frequency = 0;
%     if (notch_filter_mode == 1)
%         notch_filter_frequency = 50;
%     elseif (notch_filter_mode == 2)
%         notch_filter_frequency = 60;
%     end
% 
%     desired_impedance_test_frequency = fread(fid, 1, 'single');
%     actual_impedance_test_frequency = fread(fid, 1, 'single');
% 
%     amp_settle_mode = fread(fid, 1, 'int16');
%     charge_recovery_mode = fread(fid, 1, 'int16');
% 
%     stim_step_size = fread(fid, 1, 'single');
%     charge_recovery_current_limit = fread(fid, 1, 'single');
%     charge_recovery_target_voltage = fread(fid, 1, 'single');
% 
%     % Place notes in data strucure
%     notes = struct( ...
%         'note1', fread_QString(fid), ...
%         'note2', fread_QString(fid), ...
%         'note3', fread_QString(fid) );
% 
%     % See if dc amplifier data was saved
%     dc_amp_data_saved = fread(fid, 1, 'int16');
% 
%     % Load board mode.
%     board_mode = fread(fid, 1, 'int16');
% 
%     reference_channel = fread_QString(fid);
% 
%     % Place frequency-related information in data structure.
%     frequency_parameters = struct( ...
%         'amplifier_sample_rate', sample_rate, ...
%         'board_adc_sample_rate', sample_rate, ...
%         'board_dig_in_sample_rate', sample_rate, ...
%         'desired_dsp_cutoff_frequency', desired_dsp_cutoff_frequency, ...
%         'actual_dsp_cutoff_frequency', actual_dsp_cutoff_frequency, ...
%         'dsp_enabled', dsp_enabled, ...
%         'desired_lower_bandwidth', desired_lower_bandwidth, ...
%         'desired_lower_settle_bandwidth', desired_lower_settle_bandwidth, ...
%         'actual_lower_bandwidth', actual_lower_bandwidth, ...
%         'actual_lower_settle_bandwidth', actual_lower_settle_bandwidth, ...
%         'desired_upper_bandwidth', desired_upper_bandwidth, ...
%         'actual_upper_bandwidth', actual_upper_bandwidth, ...
%         'notch_filter_frequency', notch_filter_frequency, ...
%         'desired_impedance_test_frequency', desired_impedance_test_frequency, ...
%         'actual_impedance_test_frequency', actual_impedance_test_frequency );
% 
%     stim_parameters = struct( ...
%         'stim_step_size', stim_step_size, ...
%         'charge_recovery_current_limit', charge_recovery_current_limit, ...
%         'charge_recovery_target_voltage', charge_recovery_target_voltage, ...
%         'amp_settle_mode', amp_settle_mode, ...
%         'charge_recovery_mode', charge_recovery_mode );
% 
%     % Define data structure for spike trigger settings.
%     spike_trigger_struct = struct( ...
%         'voltage_trigger_mode', {}, ...
%         'voltage_threshold', {}, ...
%         'digital_trigger_channel', {}, ...
%         'digital_edge_polarity', {} );
% 
%     new_trigger_channel = struct(spike_trigger_struct);
%     spike_triggers = struct(spike_trigger_struct);
% 
%     % Define data structure for data channels.
%     channel_struct = struct( ...
%         'native_channel_name', {}, ...
%         'custom_channel_name', {}, ...
%         'native_order', {}, ...
%         'custom_order', {}, ...
%         'board_stream', {}, ...
%         'chip_channel', {}, ...
%         'port_name', {}, ...
%         'port_prefix', {}, ...
%         'port_number', {}, ...
%         'electrode_impedance_magnitude', {}, ...
%         'electrode_impedance_phase', {} );
% 
%     new_channel = struct(channel_struct);
% 
%     % Create structure arrays for each type of data channel.
%     amplifier_channels = struct(channel_struct);
%     board_adc_channels = struct(channel_struct);
%     board_dac_channels = struct(channel_struct);
%     board_dig_in_channels = struct(channel_struct);
%     board_dig_out_channels = struct(channel_struct);
% 
%     amplifier_index = 1;
%     board_adc_index = 1;
%     board_dac_index = 1;
%     board_dig_in_index = 1;
%     board_dig_out_index = 1;
% 
%     % Read signal summary from data file header.
% 
%     number_of_signal_groups = fread(fid, 1, 'int16');
% 
%     for signal_group = 1:number_of_signal_groups
%         signal_group_name = fread_QString(fid);
%         signal_group_prefix = fread_QString(fid);
%         signal_group_enabled = fread(fid, 1, 'int16');
%         signal_group_num_channels = fread(fid, 1, 'int16');
%         signal_group_num_amp_channels = fread(fid, 1, 'int16');
% 
%         if (signal_group_num_channels > 0 && signal_group_enabled > 0)
%             new_channel(1).port_name = signal_group_name;
%             new_channel(1).port_prefix = signal_group_prefix;
%             new_channel(1).port_number = signal_group;
%             for signal_channel = 1:signal_group_num_channels
%                 new_channel(1).native_channel_name = fread_QString(fid);
%                 new_channel(1).custom_channel_name = fread_QString(fid);
%                 new_channel(1).native_order = fread(fid, 1, 'int16');
%                 new_channel(1).custom_order = fread(fid, 1, 'int16');
%                 signal_type = fread(fid, 1, 'int16');
%                 channel_enabled = fread(fid, 1, 'int16');
%                 new_channel(1).chip_channel = fread(fid, 1, 'int16');
%                 fread(fid, 1, 'int16');  % ignore command_stream
%                 new_channel(1).board_stream = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).voltage_trigger_mode = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).voltage_threshold = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).digital_trigger_channel = fread(fid, 1, 'int16');
%                 new_trigger_channel(1).digital_edge_polarity = fread(fid, 1, 'int16');
%                 new_channel(1).electrode_impedance_magnitude = fread(fid, 1, 'single');
%                 new_channel(1).electrode_impedance_phase = fread(fid, 1, 'single');
% 
%                 if (channel_enabled)
%                     switch (signal_type)
%                         case 0
%                             amplifier_channels(amplifier_index) = new_channel;
%                             spike_triggers(amplifier_index) = new_trigger_channel;
%                             amplifier_index = amplifier_index + 1;
%                         case 1
%                             % aux inputs; not used in RHS2000 system
%                         case 2
%                             % supply voltage; not used in RHS2000 system
%                         case 3
%                             board_adc_channels(board_adc_index) = new_channel;
%                             board_adc_index = board_adc_index + 1;
%                         case 4
%                             board_dac_channels(board_dac_index) = new_channel;
%                             board_dac_index = board_dac_index + 1;
%                         case 5
%                             board_dig_in_channels(board_dig_in_index) = new_channel;
%                             board_dig_in_index = board_dig_in_index + 1;
%                         case 6
%                             board_dig_out_channels(board_dig_out_index) = new_channel;
%                             board_dig_out_index = board_dig_out_index + 1;
%                         otherwise
%                             error('Unknown channel type');
%                     end
%                 end
% 
%             end
%         end
%     end
% 
%     % Summarize contents of data file.
%     num_amplifier_channels = amplifier_index - 1;
%     num_board_adc_channels = board_adc_index - 1;
%     num_board_dac_channels = board_dac_index - 1;
%     num_board_dig_in_channels = board_dig_in_index - 1;
%     num_board_dig_out_channels = board_dig_out_index - 1;
% 
%     fprintf(1, 'Found %d amplifier channel%s.\n', ...
%         num_amplifier_channels, plural(num_amplifier_channels));
%     if (dc_amp_data_saved ~= 0)
%         fprintf(1, 'Found %d DC amplifier channel%s.\n', ...
%             num_amplifier_channels, plural(num_amplifier_channels));
%     end
%     fprintf(1, 'Found %d board ADC channel%s.\n', ...
%         num_board_adc_channels, plural(num_board_adc_channels));
%     fprintf(1, 'Found %d board DAC channel%s.\n', ...
%         num_board_dac_channels, plural(num_board_dac_channels));
%     fprintf(1, 'Found %d board digital input channel%s.\n', ...
%         num_board_dig_in_channels, plural(num_board_dig_in_channels));
%     fprintf(1, 'Found %d board digital output channel%s.\n', ...
%         num_board_dig_out_channels, plural(num_board_dig_out_channels));
%     fprintf(1, '\n');
% 
%     % Determine how many samples the data file contains.
% 
%     % Each data block contains num_samples_per_data_block amplifier samples.
%     bytes_per_block = num_samples_per_data_block * 4;  % timestamp data
%     if (dc_amp_data_saved ~= 0)
%         bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2 + 2) * num_amplifier_channels;
%     else
%         bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2) * num_amplifier_channels;    
%     end
%     % Board analog inputs are sampled at same rate as amplifiers
%     bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_board_adc_channels;
%     % Board analog outputs are sampled at same rate as amplifiers
%     bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_board_dac_channels;
%     % Board digital inputs are sampled at same rate as amplifiers
%     if (num_board_dig_in_channels > 0)
%         bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
%     end
%     % Board digital outputs are sampled at same rate as amplifiers
%     if (num_board_dig_out_channels > 0)
%         bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
%     end
% 
%     % How many data blocks remain in this file?
%     data_present = 0;
%     bytes_remaining = filesize - ftell(fid);
%     if (bytes_remaining > 0)
%         data_present = 1;
%     end
% 
%     num_data_blocks = bytes_remaining / bytes_per_block;
% 
%     num_amplifier_samples = num_samples_per_data_block * num_data_blocks;
%     num_board_adc_samples = num_samples_per_data_block * num_data_blocks;
%     num_board_dac_samples = num_samples_per_data_block * num_data_blocks;
%     num_board_dig_in_samples = num_samples_per_data_block * num_data_blocks;
%     num_board_dig_out_samples = num_samples_per_data_block * num_data_blocks;
% 
%     record_time = num_amplifier_samples / sample_rate;
% 
%     if (data_present)
%         fprintf(1, 'File contains %0.3f seconds of data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
%             record_time, sample_rate / 1000);
%         fprintf(1, '\n');
%     else
%         fprintf(1, 'Header file contains no data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
%             sample_rate / 1000);
%         fprintf(1, '\n');
%     end
% 
%     if (data_present)
% 
%         % Pre-allocate memory for data.
%         fprintf(1, 'Allocating memory for data...\n');
% 
%         t = zeros(1, num_amplifier_samples);
% 
%         amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
%         if (dc_amp_data_saved ~= 0)
%             dc_amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
%         end
%         stim_data = zeros(num_amplifier_channels, num_amplifier_samples);
%         amp_settle_data = zeros(num_amplifier_channels, num_amplifier_samples);
%         charge_recovery_data = zeros(num_amplifier_channels, num_amplifier_samples);
%         compliance_limit_data = zeros(num_amplifier_channels, num_amplifier_samples);
%         board_adc_data = zeros(num_board_adc_channels, num_board_adc_samples);
%         board_dac_data = zeros(num_board_dac_channels, num_board_dac_samples);
%         board_dig_in_data = zeros(num_board_dig_in_channels, num_board_dig_in_samples);
%         board_dig_in_raw = zeros(1, num_board_dig_in_samples);
%         board_dig_out_data = zeros(num_board_dig_out_channels, num_board_dig_out_samples);
%         board_dig_out_raw = zeros(1, num_board_dig_out_samples);
% 
%         % Read sampled data from file.
%         fprintf(1, 'Reading data from file...\n');
% 
%         amplifier_index = 1;
%         board_adc_index = 1;
%         board_dac_index = 1;
%         board_dig_in_index = 1;
%         board_dig_out_index = 1;
% 
%         print_increment = 10;
%         percent_done = print_increment;
%         for i=1:num_data_blocks
%             t(amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'int32');
%             if (num_amplifier_channels > 0)
%                 amplifier_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
%                 if (dc_amp_data_saved ~= 0)
%                     dc_amplifier_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
%                 end
%                 stim_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
%             end
%             if (num_board_adc_channels > 0)
%                 board_adc_data(:, board_adc_index:(board_adc_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_board_adc_channels], 'uint16')';
%             end
%             if (num_board_dac_channels > 0)
%                 board_dac_data(:, board_dac_index:(board_dac_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_board_dac_channels], 'uint16')';
%             end
%             if (num_board_dig_in_channels > 0)
%                 board_dig_in_raw(board_dig_in_index:(board_dig_in_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
%             end
%             if (num_board_dig_out_channels > 0)
%                 board_dig_out_raw(board_dig_out_index:(board_dig_out_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
%             end
% 
%             amplifier_index = amplifier_index + num_samples_per_data_block;
%             board_adc_index = board_adc_index + num_samples_per_data_block;
%             board_dac_index = board_dac_index + num_samples_per_data_block;
%             board_dig_in_index = board_dig_in_index + num_samples_per_data_block;
%             board_dig_out_index = board_dig_out_index + num_samples_per_data_block;
% 
%             fraction_done = 100 * (i / num_data_blocks);
%             if (fraction_done >= percent_done)
%                 fprintf(1, '%d%% done...\n', percent_done);
%                 percent_done = percent_done + print_increment;
%             end
%         end
% 
%         % Make sure we have read exactly the right amount of data.
%         bytes_remaining = filesize - ftell(fid);
%         if (bytes_remaining ~= 0)
%             %error('Error: End of file not reached.');
%         end
% 
%     end
% 
%     % Close data file.
%     fclose(fid);
% 
%     if (data_present)
% 
%         fprintf(1, 'Parsing data...\n');
% 
%         % Extract digital input channels to separate variables.
%         for i=1:num_board_dig_in_channels
%            mask = 2^(board_dig_in_channels(i).native_order) * ones(size(board_dig_in_raw));
%            board_dig_in_data(i, :) = (bitand(board_dig_in_raw, mask) > 0);
%         end
%         for i=1:num_board_dig_out_channels
%            mask = 2^(board_dig_out_channels(i).native_order) * ones(size(board_dig_out_raw));
%            board_dig_out_data(i, :) = (bitand(board_dig_out_raw, mask) > 0);
%         end
% 
%         % Scale voltage levels appropriately.
%         amplifier_data = 0.195 * (amplifier_data - 32768); % units = microvolts
%         if (dc_amp_data_saved ~= 0)
%             dc_amplifier_data = -0.01923 * (dc_amplifier_data - 512); % units = volts
%         end
%         compliance_limit_data = stim_data >= 2^15;
%         stim_data = stim_data - (compliance_limit_data * 2^15);
%         charge_recovery_data = stim_data >= 2^14;
%         stim_data = stim_data - (charge_recovery_data * 2^14);
%         amp_settle_data = stim_data >= 2^13;
%         stim_data = stim_data - (amp_settle_data * 2^13);
%         stim_polarity = stim_data >= 2^8;
%         stim_data = stim_data - (stim_polarity * 2^8);
%         stim_polarity = 1 - 2 * stim_polarity; % convert (0 = pos, 1 = neg) to +/-1
%         stim_data = stim_data .* stim_polarity;
%         stim_data = stim_parameters.stim_step_size * stim_data / 1.0e-6; % units = microamps
%         board_adc_data = 312.5e-6 * (board_adc_data - 32768); % units = volts
%         board_dac_data = 312.5e-6 * (board_dac_data - 32768); % units = volts
% 
%         % Check for gaps in timestamps.
%         num_gaps = sum(diff(t) ~= 1);
%         if (num_gaps == 0)
%             fprintf(1, 'No missing timestamps in data.\n');
%         else
%             fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
%                 num_gaps);
%         end
% 
%         % Scale time steps (units = seconds).
%         t = t / sample_rate;
% 
%         % If the software notch filter was selected during the recording, apply the
%         % same notch filter to amplifier data here.  But don't do this for v3.0+ 
%         % files (from Intan RHX software) because RHX saves notch-filtered data.
%         if (notch_filter_frequency > 0 && data_file_main_version_number < 3)
%             fprintf(1, 'Applying notch filter...\n');
% 
%             print_increment = 10;
%             percent_done = print_increment;
%             for i=1:num_amplifier_channels
%                 amplifier_data(i,:) = ...
%                     notch_filter(amplifier_data(i,:), sample_rate, notch_filter_frequency, 10);
% 
%                 fraction_done = 100 * (i / num_amplifier_channels);
%                 if (fraction_done >= percent_done)
%                     fprintf(1, '%d%% done...\n', percent_done);
%                     percent_done = percent_done + print_increment;
%                 end
% 
%             end
%         end
%     channelNames = string({amplifier_channels.custom_channel_name})';
%     nativeChannelNames = string({amplifier_channels.native_channel_name})';
%     signalData = amplifier_data;
%     fs = frequency_parameters.amplifier_sample_rate;
%     end
% end
% % % % % % function a = fread_QString(fid)
% % % % % % 
% % % % % %     % a = read_QString(fid)
% % % % % %     %
% % % % % %     % Read Qt style QString.  The first 32-bit unsigned number indicates
% % % % % %     % the length of the string (in bytes).  If this number equals 0xFFFFFFFF,
% % % % % %     % the string is null.
% % % % % % 
% % % % % %     a = '';
% % % % % %     length = fread(fid, 1, 'uint32');
% % % % % %     if length == hex2num('ffffffff')
% % % % % %         return;
% % % % % %     end
% % % % % %     % convert length from bytes to 16-bit Unicode words
% % % % % %     length = length / 2;
% % % % % % 
% % % % % %     for i=1:length
% % % % % %         a(i) = fread(fid, 1, 'uint16');
% % % % % %     end
% % % % % % end
% function s = plural(n)
%     % s = plural(n)
%     % 
%     % Utility function to optionally plurailze words based on the value
%     % of n.
% 
%     if (n == 1)
%         s = '';
%     else
%         s = 's';
%     end
% end
% function out = notch_filter(in, fSample, fNotch, Bandwidth)
%     % out = notch_filter(in, fSample, fNotch, Bandwidth)
%     %
%     % Implements a notch filter (e.g., for 50 or 60 Hz) on vector 'in'.
%     % fSample = sample rate of data (in Hz or Samples/sec)
%     % fNotch = filter notch frequency (in Hz)
%     % Bandwidth = notch 3-dB bandwidth (in Hz).  A bandwidth of 10 Hz is
%     %   recommended for 50 or 60 Hz notch filters; narrower bandwidths lead to
%     %   poor time-domain properties with an extended ringing response to
%     %   transient disturbances.
%     %
%     % Example:  If neural data was sampled at 30 kSamples/sec
%     % and you wish to implement a 60 Hz notch filter:
%     %
%     % out = notch_filter(in, 30000, 60, 10);
% 
%     tstep = 1/fSample;
%     Fc = fNotch*tstep;
% 
%     L = length(in);
% 
%     % Calculate IIR filter parameters
%     d = exp(-2*pi*(Bandwidth/2)*tstep);
%     b = (1 + d*d)*cos(2*pi*Fc);
%     a0 = 1;
%     a1 = -b;
%     a2 = d*d;
%     a = (1 + d*d)/2;
%     b0 = 1;
%     b1 = -2*cos(2*pi*Fc);
%     b2 = 1;
% 
%     out = zeros(size(in));
%     out(1) = in(1);  
%     out(2) = in(2);
%     % (If filtering a continuous data stream, change out(1) and out(2) to the
%     %  previous final two values of out.)
% 
%     % Run filter
%     for i=3:L
%         out(i) = (a*b2*in(i-2) + a*b1*in(i-1) + a*b0*in(i) - a2*out(i-2) - a1*out(i-1))/a0;
%     end
% end
