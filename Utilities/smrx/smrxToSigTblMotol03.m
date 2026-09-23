%% Use this for the new mice which are registered in SoftMouse.net
function smrxToSigTblMotol03
    filepn = getFilepn('Browse smrx files', 'on');
    savep = '\\neurodata\Lab Neurophysiology root\EEG conversion';
%     savep = getSavep('Where to save mat files');
    if isnumeric(filepn) || isnumeric(savep)
        return
    end
    smrxToSigTblMotol0101(filepn, savep);
    [txtp, ~, ~] = fileparts(filepn{1});
    txtfp = fullfile(txtp, '_Conversion report.txt');
    fid = fopen(txtfp, 'a');    
    fprintf(fid, ['Conversion finished on ', datestr(now)]);
    fclose(fid);
    disp(['Smrx files in ', txtp, ' were decimated and saved as mat in ', savep])
    disp('smrxToSigTblMotol01 finished')
end
function smrxToSigTblMotol0101(filepn, savep)
%     monitoringTable = readtable('\\neurodata\Common stuff\Video-EEG monitoring\subject__monitoringID.xlsx');
    
    for kf = 1 : length(filepn)
disp(['File ', num2str(kf), '/', num2str(length(filepn)), ' (', filepn{kf}, ')'])
        [sigT, dateS, subjNm] = loadSmrx(filepn{kf});
        % Convert monitoring IDs (rec_ID) to ear tags (ET)
        for ks = 1 : length(subjNm)
            subjnm = char(subjNm{ks});
%             subjnm = ['XX', subjnm(7:end)];
            subjNm{ks} = subjnm;
        end
        for ks = 1 : length(sigT)
            sigTbl = sigT{ks};
            mkdir(savep, char(subjNm{ks}));
            savepn = fullfile(savep, '\', subjNm{ks}, '\', [subjNm{ks}, '-', dateS{ks}, '-dec.mat']);
            save(savepn, 'sigTbl');
        end
    end
end
function [sigT, dateS, subjNm] = loadSmrx(filepn)
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
    
    % Keep only ADC channels
    for k = 1 : length(nch)
        typ(k) = CEDS64ChanType(fhand, nch(k)); %#ok<AGROW> % Get channels type (ADC, Marker, etc.)
    end
    chnm = chnm(typ == 1);
    chn = chn(typ == 1);
    
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
            if ~isempty(r)
                s = strsplit(r{1}, '-');
                ChName = string(str);
                RecPosition = string(s{2});
                Subject = string(['recID_', s{3}]);
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
            [filep, filen, ~] = fileparts(filepn);
            computers = {'Vochomurka', 'Ferda', 'Bobik', 'Amalka', 'Myspulin', 'PD', 'PS', 'NRD', 'NRM'};
            r = regexpi(filep, computers);
            iComputer = cellfun(@(x) ~isempty(x), r);
            RecPosition = string(computers(iComputer)) + RecPosition;
            RecPosition = RecPosition(1);
            
            [durS] = CEDS64TicksToSecs(fhand, CEDS64ChanMaxTime(fhand, chn(kch2)));
%             [~, td]  = CEDS64TimeDate(fhand);
%             SigStart = datetime(fliplr(td(2 : end)));
            dt = regexp(filen, '-\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
            dt = dt{1}(2 : end);
            SigStart = datetime(dt, 'InputFormat', 'yyMMdd_HHmmss');
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
                subjects{end, 2} = sigTbl.RecPosition(kch2)
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
        % Change subject names
        for kch2 = 1 : size(sigTbl, 1)
            subj = char(sigTbl.Subject(kch2));
            subj = subj(7:end);
            if contains(subj, '0056')
                subj = ['PM0', subj];
            elseif contains(subj, '377') || contains(subj, '378')
                subj = ['BH0', subj];
            elseif contains(subj, '645') || contains(subj, '652') || contains(subj, '914') || contains(subj, '918')
                subj = ['SK0', subj];
            else
                subjectt = subj
                error('_jk Unknown mouse owner')
            end
            sigTbl.Subject(kch2) = string(subj);
        end
        for ksu = 1 : size(subjects, 1)
            subj = char(subjects{ksu, 1});
            subj = subj(7:end);
            if contains(subj, '0056')
                subj = ['PM0', subj];
            elseif contains(subj, '377') || contains(subj, '378')
                subj = ['BH0', subj];
            elseif contains(subj, '645') || contains(subj, '652') || contains(subj, '914') || contains(subj, '918')
                subj = ['SK0', subj]
            else
                subjecttt = subj
                error('_jk Unknown mouse owner')
            end
            subjects{ksu, 1} = subj;
        end
        
        sigTbl = sigTbl(~isnan(sigTbl.Fs), :);
        unloadlibrary ceds64int;
        
        %% Sort out
        for ks = 1 : size(subjects, 1)
            sigT{ks} = sigTbl(sigTbl.Subject == subjects{ks, 1}, :);
            
            % Resample to 250 Hz
            for kch = 1 : size(sigT{ks}, 1)
                s = single(resample(double(sigT{ks}.Data{kch}), 250, sigT{ks}.Fs(kch)));
                sigT{ks}.Data(kch, 1) = {s};
                sigT{ks}.Fs(kch, 1) = 250;
            end
            clear s
            
%             % Average reference
%             eegChannelIdx = find(startsWith(sigT{ks}.ChName, {'FL', 'FR', 'L', 'C', 'PL'}));
%             s = cell2mat(sigT{ks}.Data(eegChannelIdx));
%             s = s - ones(size(s, 1), 1)*mean(s);
%             for ke = 1 : length(eegChannelIdx)
%                 sigT{ks}.Data(eegChannelIdx(ke)) = {s(ke, :)};
%             end
%             clear s
            
            if all((sigTbl.SigStart - sigTbl.SigStart(1)) < 0.001)
                dateStr = datestr(sigTbl.SigStart(1), 'yymmdd_HHMMSS');
            end
            dateS{ks} = dateStr;
            subjNm{ks} = subjects{ks, 1};
        end
    end
end
function filepn = getFilepn(prompt, multisel)
    if exist('loadpath.mat', 'file')
        load('loadpath.mat', 'loadpath'); % Second argument: which variable from the file should be loaded
    else
        loadpath = '';
    end
    [fn, fp] = uigetfile([loadpath, '\*.smrx'], prompt, 'MultiSelect', multisel); % File names, file path
    if isa(fn, 'double')
        filepn = [];
        return
    end
    % If the user selected only one file, it is returned as a char array. Let's put it in a cell for consistency.
    if ~iscell(fn)
        filen{1} = fn;
    else
        filen = fn;
    end
    filep = fp;
    filepn = fullfile(filep, filen);
    loadpath = filep;
    save('loadpath.mat', 'loadpath')
end
function savep = getSavep(prompt)
    if exist('loadpath.mat', 'file')
        load('loadpath.mat', 'loadpath'); % Second argument: which variable from the file should be loaded
    else
        loadpath = '';
    end
    [fp] = uigetdir([loadpath], prompt); % File names, file path
    if isa(fp, 'double')
        savep = [];
        return
    end
    savep = fp;
    loadpath = savep;
    save('loadpath.mat', 'loadpath')
end