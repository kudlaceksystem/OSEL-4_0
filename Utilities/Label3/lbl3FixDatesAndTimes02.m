function lbl3FixDatesAndTimes02
Not finished, use lbl3FixDatesAndTimes01
    format compact
    [filepn, filep, filen] = getFilepnAllCell('Select label files', 'mat');
    savep = getSavep('Where to save modified label files');
    
    invalidNumber = [];
    invalidFilepn = {};
    hwb = waitbar(0, 'Getting class names...');
    now000 = now;
    nTimeEst = 20;
    timeToAllM = 1;
    for kf = 1 : length(filepn)
        disp(kf)
        %% Display progress
        waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        if kf == nTimeEst
            nowTimeEst = now;
            timeToTimeEst = nowTimeEst - now000;
            timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
            waitbar(kf/length(filepn), hwb, ['Renaming lbl3 classes, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        end
        
        %% Load lbl3 file and edit it
        % Get datetime from the filename
        dateStrFilen = regexp(filen{kf}, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D', 'match');
        dateStrFilen = dateStrFilen{1}(2 : end-1);
        dateTFilen = datetime(dateStrFilen, 'InputFormat', 'uuMMdd_HHmmss', 'Format', 'uuuu-MM-dd HH:mm:ss');
        if dateTFilen.Year < 1000
            dateTFilen.Year = dateTFilen.Year + 2000;
        end

        load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
        % % % % % % % % sigInfo
        % % % % % % % % if isempty(sigInfo)
        % % % % % % % %     if ~exist(snlp, "var")
        % % % % % % % %         snlp = uigetdir(filep, 'Where to search for signal files');
        % % % % % % % %         sigTbl = loadCorrespondingSignalFile(snlp, dateStrFilen)
        % % % % % % % %         pause
        % % % % % % % %     end
        % % % % % % % % end


        % Check if labels in all channels are created from the same signal file
        if any(sigInfo.FileName ~= sigInfo.FileName(1))
            disp(filen{kf})
            disp(sigInfo)
            warning('_jk sigInfo.FileName inconsistent')
            invalidNumber(end+1, 1) = kf; %#ok<AGROW>
            invalidFilepn{end+1, 1} = filepn{kf}; %#ok<AGROW>
            % pause
        end
        
        % Get datetime from the source signal file name
        dateStrSnl = regexp(sigInfo.FileName(1), '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D', 'match');
        dateStrSnl = dateStrSnl{1}(2 : end-1);
        dateTSnl = datetime(dateStrSnl, 'InputFormat', 'uuMMdd_HHmmss', 'Format', 'uuuu-MM-dd HH:mm:ss');
        if dateTSnl.Year < 1000
            dateTSnl.Year = dateTSnl.Year + 2000;
        end

        % Check if all SigStarts are the same
        if any(sigInfo.SigStart ~= sigInfo.SigStart(1))
            disp(filen{kf})
            disp(sigInfo)
            warning('_jk sigInfo.SigStart inconsistent')
            invalidNumber(end+1, 1) = kf; %#ok<AGROW>
            invalidFilepn{end+1, 1} = filepn{kf}; %#ok<AGROW>
            % pause
        end

        % Compare file name and the signal file name
        if dateTFilen ~= dateTSnl
            disp(filen{kf})
            disp(sigInfo)
            disp(dateTFilen)
            disp(dateTSnl)
            warning('_jk File name and signal file name are inconsistent')
            invalidNumber(end+1, 1) = kf; %#ok<AGROW>
            invalidFilepn{end+1, 1} = filepn{kf}; %#ok<AGROW>
            pause
        end

       % Compare file name and SigStart
        if abs(seconds(dateTFilen - sigInfo.SigStart(1))) > 10
            disp(filen{kf})
            disp(sigInfo)
            disp(dateTFilen)
            disp(sigInfo.SigStart(1))
            warning('_jk File name and SigStart are inconsistent')
            invalidNumber(end+1, 1) = kf; %#ok<AGROW>
            invalidFilepn{end+1, 1} = filepn{kf}; %#ok<AGROW>
            pause
        else % If the difference is not too big, fix it
            sigDur = sigInfo.SigEnd - sigInfo.SigStart;
            sigDurS = seconds(sigDur);
            if any(abs(sigDurS - sigDurS(1)) > 60)
                error('_jk Signal durations differ by more than 60 seconds.')
            end
            if (abs(seconds(dateTFilen - sigInfo.SigStart(1))) > 0.5)
                disp(['dateTFilen - SigStart = ', num2str(seconds(dateTFilen - sigInfo.SigStart(1)))])
                lblSet.Start = lblSet.Start + repelem(dateTFilen - sigInfo.SigStart(1), height(lblSet), 1);
                lblSet.End = lblSet.End + repelem(dateTFilen - sigInfo.SigStart(1), height(lblSet), 1);
                sigInfo.SigStart = repelem(dateTFilen, height(sigInfo), 1);
                sigInfo.SigEnd = sigInfo.SigStart + sigDur;
            end
        end
        
        % Check if all markers fall within SigStart and SigEnd
        if ~all(lblSet.Start > sigInfo.SigStart(1) & lblSet.End < sigInfo.SigEnd(1))
            disp(filen{kf})
            disp(sigInfo)
            disp(dateTFilen)
            disp(dateTSnl)
            disp(lblSet)
            warning('_jk Markers found outside SigStart and SigEnd. This is not going to be fixed now.')
            invalidNumber(end+1, 1) = kf; %#ok<AGROW>
            invalidFilepn{end+1, 1} = filepn{kf}; %#ok<AGROW>
            pause
        end
        
        %% Save new lbl3 file
        savepn = fullfile(savep, filen{kf});
        save(savepn, 'sigInfo', 'lblDef', 'lblSet')
    end
    invalidTable = table(invalidNumber, invalidFilepn);
    writetable(invalidTable, 'invalidTable.xlsx');
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
% % % % % % % % % function sigTbl = loadCorrespondingSignalFile(snlp, dateStrFilen)
% % % % % % % % %     snlp
% % % % % % % % %     dateStrFilen
% % % % % % % % %     sigTbl = []
% % % % % % % % % end
