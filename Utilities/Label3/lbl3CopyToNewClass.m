function lbl3CopyToNewClass
    [filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
    savep = getSavep('Where to save modified label files');
    classToCopyFrom = "AdamK_SeizureDet_LATEST";
    classToCopyTo = "Seizure";
    ColorOfClassToCopyTo = "1 0 0";
    

    classToCopyFrom = string(classToCopyFrom);
    classToCopyTo = string(classToCopyTo);
    ColorOfClassToCopyTo = string(ColorOfClassToCopyTo);
    hwb = waitbar(0, 'Getting class names...');
    now000 = now; %#ok<TNOW1>
    nTimeEst = 20;
    timeToAllM = 1;
    for kf = 1 : length(filepn)
        %% Display progress
        waitbar(kf/length(filepn), hwb, ['Copying, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        if kf == nTimeEst
            nowTimeEst = now;
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Copying, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        
        %% Load lbl3 file
        load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
        
        %% lblDef
        dc = lblDef.ClassName; % Def Class
        if size(unique(dc)) ~= size(dc)
            disp(dc)
            error('_jk Duplicates in lblDef.ClassName')
        end
        if ~any(lblDef.ClassName == classToCopyTo) % If the class does not exist yet, create it
            ClassName = classToCopyTo;
            ChannelMode = lblDef.ChannelMode(lblDef.ClassName == classToCopyFrom);
            LabelType = lblDef.LabelType(lblDef.ClassName == classToCopyFrom);
            Color = ColorOfClassToCopyTo;
            T = table(ClassName, ChannelMode, LabelType, Color);
            lblDef = [lblDef; T]; %#ok<AGROW>
        end

        %% lblSet
        lsNew = lblSet(lblSet.ClassName == classToCopyFrom, :);
        lsNew.ClassName = repelem(classToCopyTo, height(lsNew), 1);
        lsNew.ClassName = categorical(lsNew.ClassName);
        lblSet.ClassName = categorical(lblSet.ClassName);
        lblSet = [lblSet; lsNew]; %#ok<AGROW>
        lblSet.ID = int64(1 : height(lblSet))';

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

