function fileRename01
    filepn = getFilepn('Browse smrx files', 'on');
    savep = getSavep('Where to save new smrx files');
    computerName = 'Vochomurka';
%     savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\'
    if isnumeric(filepn)
        return
    end
    if isempty(getenv('CEDS64ML'))
        setenv('CEDS64ML', [cd, '\CEDMATLAB\CEDS64ML']);
    end
    
    % Load the library
    if isempty(getenv('CEDS64ML'))
        setenv('CEDS64ML', [cd, '\CEDMATLAB\CEDS64ML']);
    end
    cedpath = getenv('CEDS64ML');
    addpath(cedpath);
    CEDS64LoadLib(cedpath);
    
    % Run the executive function
    fileRnm(filepn, computerName, savep)
    
    % Display finished
    disp('channelRename01 finished')
end
function fileRnm(filepn, computerName, savep)
    for kf = 1 : length(filepn)
        disp(['File ', num2str(kf), '/', num2str(length(filepn)), ' (', filepn{kf}, ')'])
        fhand = CEDS64Open(filepn{kf}, 0);
        [iOK, TimeDateOut] = CEDS64TimeDate(fhand);
        if iOK ~= 0; warning(['_jk CEDS64Close could not read TimeDate ', filepn{kf}, 10, 'with handle fhand = ', num2str(fhand),'. iOK = ', num2str(iOK)]); end
        iOK = CEDS64Close(fhand);
        if iOK ~= 0; error(['_jk CEDS64Close could not close file ', filepn{kf}, 10, 'with handle fhand = ', num2str(fhand),'. iOK = ', num2str(iOK)]); end
        fileDt = datetime(fliplr(TimeDateOut(2 : end)), 'Format', 'yyMMdd_HHmmss');
        saven = [computerName, '-', char(fileDt), '.smrx'];
        newFilepn = [savep, '/', saven];
        movefile(filepn{kf}, newFilepn)
    end
end
function [filepn, filep] = getFilepn(prompt, multisel)
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
    [fp] = uigetdir(loadpath, prompt); % File names, file path
    if isa(fp, 'double')
        savep = [];
        return
    end
    savep = fp;
    loadpath = savep;
    save('loadpath.mat', 'loadpath')
end