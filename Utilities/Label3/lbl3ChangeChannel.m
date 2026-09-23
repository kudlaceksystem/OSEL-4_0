return
function lbl3ChangeChannel
    [filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
    savep = getSavep('Where to save modified label files');
    oldChannel = 67;
    newChannel = 1;
    
    hwb = waitbar(0, 'Getting class names...');
    now000 = now;
    nTimeEst = 20;
    timeToAllM = 1;
    % % % allLblDefClasses = [];
    % % % allLblSetClasses = [];
    for kf = 1 : length(filepn)
        %% Display progress
        waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        if kf == nTimeEst
            nowTimeEst = now;
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        
        %% Load lbl3 file and edit it
        load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
        lblSet.Channel(lblSet.Channel == oldChannel) = newChannel;

        %% Save new lbl3 file
        oldFilen = filen{kf};
        % % % % % % % ss = strsplit(oldFilen, '-');
        % % % % % % % if oldChannel ~= string(ss{1})
        % % % % % % %     error(['_jk oldSubject: ', char(oldChannel), ', file name: ', ss{1}])
        % % % % % % % end
        % % % % % % % ss{1} = char(newChannel);
        % % % % % % % newFilen = strjoin(ss, '-');
        newFilen = oldFilen;
        savepn = fullfile(savep, newFilen)
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

