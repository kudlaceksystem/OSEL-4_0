function WKJtoSig01
    filepn = getFilepn('Browse smrx files', 'on');
%     savep = getSavep('Where to save mat files');
    savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\'
    if isnumeric(filepn) || isnumeric(savep)
        return
    end
    WKJtoSig0101(filepn, savep)
end

function WKJtoSig0101(filepn, savep)
    for kf = 1 : length(filepn)
disp(['File ', num2str(kf), '/', num2str(length(filepn)), ' (', filepn{kf}, ')'])
        load(filepn{kf})
        for kch = 1 : length(chanNames)
            Subject = string(subject);
            ChName = string(chanNames{kch});
            SigStart = datetime(dateN, 'ConvertFrom', 'datenum');
            SigEnd = datetime(dateN + size(s, 2)/fs/3600/24, 'ConvertFrom', 'datenum');
            Fs = fs;
            Data = {single(s(kch, :))};
            RecPosition = "";
            sigTbl(kch, :) = table(Subject, ChName, SigStart, SigEnd, Fs, Data, RecPosition);
        end
        mkdir(savep, char(subject));
        savepn = fullfile(savep, '\', subject, '\', [subject, '-', datestr(dateN, 'yymmdd_HHMMSS'), '-200Hz.mat']);
        save(savepn, 'sigTbl');
    end
end

function filepn = getFilepn(prompt, multisel)
    if exist('loadpath.mat', 'file')
        load('loadpath.mat', 'loadpath'); % Second argument: which variable from the file should be loaded
    else
        loadpath = '';
    end
    [fn, fp] = uigetfile([loadpath, '\*.*'], prompt, 'MultiSelect', multisel); % File names, file path
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
