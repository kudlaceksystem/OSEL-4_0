function lbl3ChannelAny01
% Joins given label classes in all channels in the "any" manner and saves it in the specified channel.
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
savep = getSavep('Where to save modified label files');
clnm = "seizure"; % Class names
chToWrite = 1; % To which channel the result will be written. Must be scalar

hwb = waitbar(0, 'Label editting...');
now000 = now;
nTimeEst = 20;
timeToAllM = 1;
for kf = 1 : length(filepn)
    %% Display progress
    waitbar(kf/length(filepn), hwb, ['Label editting, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    disp(kf)
    disp(filepn{kf})
    if kf == nTimeEst
        nowTimeEst = now;
        timeToTimeEst = nowTimeEst - now000;
        timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
        waitbar(kf/length(filepn), hwb, ['Label editting, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    end
    
    %% Load lbl3 file
    load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
    lblSetNew = lblSet(~ismember(lblSet.ClassName, clnm), :);
    for kc = 1 : numel(clnm)
        lblSetCl = lblSet(lblSet.ClassName == clnm(kc), :);
        if ~(numel(unique(lblSetCl.ID)) == numel(lblSetCl.ID))
            error('_jk IDs not unique')
        end
        if ~isempty(lblSetCl)
            lblSetCl = sortrows(lblSetCl, "Start");
            st = [datenum(lblSetCl.Start), ones(size(lblSetCl.Start)), lblSetCl.ID];
            en = [datenum(lblSetCl.End), -ones(size(lblSetCl.End)), lblSetCl.ID];
            x = [st; en];
            x = sortrows(x, 1);
            csx = cumsum(x(:, 2));
            mrkEnds = find(csx == 0);
            mrkStarts = [1; mrkEnds(1 : end-1) + 1];
            for km = 1 : numel(mrkStarts)
                id = unique(x(mrkStarts(km) : mrkEnds(km), 3));
                lblSetMrk = lblSetCl(ismember(lblSetCl.ID, id), :);
                lblSetClNew(km, :) = lblSetMrk(1, :); %#ok<AGROW>
                lblSetClNew.Start = min(lblSetCl.Start);
                lblSetClNew.End = max(lblSetCl.End);
                lblSetClNew.Value = max(lblSetCl.Value);
                lblSetClNew.Channel = chToWrite;
                % Comment is not preserved if there was any
            end
            lblSetNew = [lblSetClNew; lblSetNew]; %#ok<AGROW>
        end
    end
    lblSet = lblSetNew;
    [~, saven, savee] = fileparts(filen{kf});
    savepne = [savep, '\', saven, savee];
    save(savepne, 'sigInfo', 'lblDef', 'lblSet')
end
delete(hwb)
disp('Finished')
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
