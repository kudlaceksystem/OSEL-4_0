function lbl3RenameClass
    [filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
    savep = getSavep('Where to save modified label files');
    oldName = 's';
    newName = 'Seizure';
    
    hwb = waitbar(0, 'Getting class names...');
    now000 = now;
    nTimeEst = 20;
    timeToAllM = 1;
    allLblDefClasses = [];
    allLblSetClasses = [];
    for kf = 1 : length(filepn)
        %% Display progress
        waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        if kf == nTimeEst
            nowTimeEst = now;
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        
        %% Load lbl3 file
        load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
        
        %% lblDef
        dc = lblDef.ClassName; % Def Class
        if size(unique(dc)) ~= size(dc)
            disp(dc)
            error('_jk Duplicates in lblDef.ClassName')
        end
        dNewNmInd = strcmp(dc, newName);
        dOldNmInd = ~cellfun('isempty', regexp(dc, oldName, 'forceCellOutput'));
        if any(dNewNmInd) % If the class with the newName exists in the file, use it
            lblDef(dOldNmInd & ~dNewNmInd, :) = [];
        else % If the class with the newName does not exist, rename the first of the classes with oldName to the newName and use it
            lblDef.ClassName(find(dOldNmInd, 1)) = newName;
            dOldNmInd(find(dOldNmInd, 1)) = false; % Flip the first true in the dOldNmInd vector to false
            lblDef(dOldNmInd, :) = [];
        end
        
        %% lblSet
        sc = string(lblSet.ClassName); % Set Class
        sOldNmInd = ~cellfun('isempty', regexp(sc, oldName, 'forceCellOutput'));
        lblSet.ClassName(sOldNmInd) = newName;
        
        %% Save new lbl3 file
        savepn = fullfile(savep, filen{kf});
        save(savepn, 'sigInfo', 'lblDef', 'lblSet')
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

