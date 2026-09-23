function lbl3GetClassNames
return
    [filepn, ~, ~] = getFilepnAllCell('Select label files', 'mat');
    
    hwb = waitbar(0, 'Getting class names...');
    now000 = now;
    nTimeEst = 20;
    timeToAllM = 1;
    allLblDefClasses = [];
    allLblSetClasses = [];
    for kf = 1 : length(filepn)
        %% Display progress
        waitbar(kf/length(filepn), hwb, ['Getting lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        if kf == nTimeEst
            nowTimeEst = now;
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Getting lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        
        %% Load lbl3 file
        load(filepn{kf}, 'lblDef', 'lblSet')
        dc = lblDef.ClassName; % Def Class
        if size(unique(dc)) ~= size(dc)
            disp(dc)
            error('_jk Duplicates in lblDef.ClassName')
        end
        sc = string(unique(lblSet.ClassName)); % Set Class
        if ~all(ismember(sc, dc))
            notContainedInDef = sc(~ismember(sc, dc));
            disp(notContainedInDef)
            error('_jk Contained in lblSet but not in lblDef.')
        end
        allLblDefClasses = [allLblDefClasses; sc]; %#ok<AGROW>
        allLblDefClasses = unique(allLblDefClasses);
        allLblSetClasses = [allLblSetClasses; sc]; %#ok<AGROW>
        allLblSetClasses = unique(allLblSetClasses);
    end
    delete(hwb)
    disp(['lblDef classNames (', num2str(length(allLblDefClasses)), '): '])
    disp(allLblDefClasses)
    disp(['lblSet classNames (', num2str(length(allLblSetClasses)), '): '])
    disp(allLblSetClasses)
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


