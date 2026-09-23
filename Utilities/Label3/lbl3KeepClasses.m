function lbl3KeepClasses
    [filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
    classNamesToKeep = ["IED_Janca"; "Channel_bullshit"; "Seizure"; "Seizure_RC"; "Seizure_H"; "Wave"];
    savep = getSavep('Where to save modified label files');
    
    hwb = waitbar(0, 'Getting class names...');
    now000 = now;
    nTimeEst = 20;
    timeToAllM = 1;
%     allLblDefClasses = [];
%     allLblSetClasses = [];
    for kf = 1 : length(filepn)
        %% Display progress
        if rem(kf, 100) == 0
            waitbar(kf/length(filepn), hwb, ['Label conversion, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        if kf == nTimeEst
            nowTimeEst = now;
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Label conversion, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end

        %% Load lbl3 file
        load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
        toKeep = ismember(string(lblSet.ClassName), classNamesToKeep);
        lblSet = lblSet(toKeep, :);
        toKeep = ismember(string(lblDef.ClassName), classNamesToKeep);
        lblDef = lblDef(toKeep, :);
        
%         [~, saven1, savee] = fileparts(filen{kf});
%         dts = regexp(saven1, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
%         saven = [char(subject), '-', dts{1}, '-lbl3'];
%         savepne = [savep, '\', saven, savee];
        save(fullfile(savep, filen{kf}), 'sigInfo', 'lblDef', 'lblSet')
    end
    delete(hwb)
% % % %     disp(['lblDef classNames (', num2str(length(allLblDefClasses)), '): '])
% % % %     disp(allLblDefClasses)
% % % %     disp(['lblSet classNames (', num2str(length(allLblSetClasses)), '): '])
% % % %     disp(allLblSetClasses)
% % % %     disp('Finished')
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

