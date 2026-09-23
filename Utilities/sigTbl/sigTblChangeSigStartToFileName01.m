function sigTblChangeSigStartToFileName01
    [filepn, ~, filen] = getFilepnAllCell('Select signal files', 'mat');
    savep = getSavep('Where to save modified signal files');
    
    hwb = waitbar(0, 'Getting class names...');
    now000 = now; %#ok<TNOW1>
    nTimeEst = 20;
    timeToAllM = 1;
    for kf = 1 : length(filepn)
        %% Display progress
        waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        if kf == nTimeEst
            nowTimeEst = now; %#ok<TNOW1>
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        
        %% Load and edit signal file
        dateStr = regexp(filen{kf}, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D', 'match');
        dateStr = dateStr{1}(2 : end-1);
        dateT = datetime(dateStr, 'InputFormat', 'uuMMdd_HHmmss', 'Format', 'uuuu-MM-dd HH:mm:ss');
        if dateT.Year < 1000
            dateT.Year = dateT.Year + 2000;
        end
        load(filepn{kf}, 'sigTbl')
        
        if any(abs(seconds(sigTbl.SigStart - sigTbl.SigStart(1))) > 60)
            error('_jk SigStarts differ by more than 60 seconds.')
        end
        sigDur = sigTbl.SigEnd - sigTbl.SigStart;
        sigDurS = seconds(sigDur);
        if any(abs(sigDurS - sigDurS(1)) > 60)
            error('_jk Signal durations differ by more than 60 seconds.')
        end
        if (abs(seconds(dateT - sigTbl.SigStart(1))) > 0.5)
            disp(['dateT - SigStart = ', num2str(seconds(dateT - sigTbl.SigStart(1)))])
            sigTbl.SigStart = repelem(dateT, height(sigTbl), 1);
            sigTbl.SigEnd = sigTbl.SigStart + sigDur;
        end

        %% Save new lbl3 file
        savepn = fullfile(savep, filen{kf});
        save(savepn, 'sigTbl')
    end
    delete(hwb)
    disp('Finished')
end


%% %%%%%%%%% %%
%% FUNCTIONS %%
%% %%%%%%%%% %%
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

