function lbl3CheckSubjectName01
    [filepn, ~, ~] = getFilepnAllCell('Select label files', 'mat');
    savep = getSavep('Where to save the resulting table');
    FilePathName = string(filepn)';
    FileNumber = (1 : numel(filepn))';
    Subject = strings(numel(filepn), 1);
    fileSubjectTbl = table(FilePathName, FileNumber, Subject);
    
    hwb = waitbar(0, 'Getting class names...');
    now000 = now; %#ok<TNOW1>
    nTimeEst = 20;
    timeToAllM = 1;
    for kf = 1 : length(filepn)
        %% Display progress
        waitbar(kf/length(filepn), hwb, ['Checking files for subjects, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        if kf == nTimeEst
            nowTimeEst = now; %#ok<TNOW1>
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Checking files for subjects, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        
        %% Load and edit signal file
        load(filepn{kf}, 'sigInfo');
        if all(sigInfo.Subject == sigInfo.Subject(1))
            fileSubjectTbl{kf, 3} = sigInfo.Subject(1);
        else
            kf_ = kf
            filepnkf_ = filepn{kf}
            error('_jk Multiple subjects in one file.')
        end
    end
    delete(hwb)
    savepn = fullfile(savep, 'labelFileSubjectTbl.xlsx')
    writetable(fileSubjectTbl, savepn)

    disp(unique(fileSubjectTbl.Subject))

    if all(fileSubjectTbl.Subject == fileSubjectTbl.Subject(1))
        disp('All files contain only subject:')
        disp(fileSubjectTbl.Subject(1))
    end

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

