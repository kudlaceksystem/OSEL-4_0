function addComment01
    %% SETTINGS
    channels = [14 11 9]; % Must be row vecor
%     channels = 1 : 8;
    newComment = 'bk_20230816'; % Must be character array, i.e. in single quotation marks ' '
%     newComment = 'kl_20230809';
    
    %%
    filepn = getFilepn('Browse smr files', 'on');
%     savep = getSavep('Where to save new smrx files');
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
    chCom(filepn, channels, newComment)
    
    % Display finished
    disp('addComment01 finished')
end
function chCom(filepn, channels, newComment)
    for kf = 1 : length(filepn)
disp(['File ', num2str(kf), '/', num2str(length(filepn)), ' (', filepn{kf}, ')'])
        fhand = CEDS64Open(filepn{kf}, 0);
        for kch = channels
            CEDS64ChanComment(fhand, kch, newComment);
        end
        iOK = CEDS64Close(fhand);
        if iOK ~= 0; error(['_jk CEDS64Close could not close file ', filepn{kf}, 10, 'with handle fhand = ', num2str(fhand),'. iOK = ', num2str(iOK)]); end
    end
end
function filepn = getFilepn(prompt, multisel)
    if exist('loadpath.mat', 'file')
        load('loadpath.mat', 'loadpath'); % Second argument: which variable from the file should be loaded
    else
        loadpath = '';
    end
    [fn, fp] = uigetfile([loadpath, '\*.smr*'], prompt, 'MultiSelect', multisel); % File names, file path
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
