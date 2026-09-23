function lbl3Sensitivity
    gsClass = "SEIZURE"; % Gold standard class name
    detClass = "Sz_Nejedly01"; % Class name of the tested detector
    toleranceS = 60;
    [filepn, ~, ~] = getFilepnAllCell('Select label files 1', 'mat');
    
    totalTime = 0; % Total tested time
    numEv = 0; % Number of true events (according to the gold standard)
    numTP = 0;
    %% Add second group to the label files from the first group
    for kf = 1 : length(filepn)
        load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet');
        totalTime = totalTime + days(sigInfo.SigEnd - sigInfo.SigStart);
        gsStart = lblSet.Start(lblSet.ClassName == gsClass);
        if isempty(gsStart)
            continue
        end
        numEv = numEv + numel(gsStart);
        detStart = lblSet.Start(lblSet.ClassName == detClass);
        if isempty(detStart)
            continue
        end
        for ke = 1 : numel(gsStart)
            if any(abs(seconds(detStart - gsStart(ke))) < toleranceS)
                numTP = numTP + 1;
            else
                disp(filepn{kf})
            end
        end
    end
    totalTime
    numEv
    numTP
    Sensitivity = numTP/numEv
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

