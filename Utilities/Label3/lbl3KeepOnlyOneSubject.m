function lbl3KeepOnlyOneSubject
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
savep = getSavep('Where to save modified label files');
subject = "recID_725";

hwb = waitbar(0, 'Label conversion...');
now000 = now; %#ok<TNOW1>
nTimeEst = 20;
timeToAllM = 1;
for kf = 1 : length(filepn)
    %% Display progress
    waitbar(kf/length(filepn), hwb, ['Label conversion, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    disp(kf)
    disp(filepn{kf})
    if kf == nTimeEst
        nowTimeEst = now; %#ok<TNOW1>
        timeToTimeEst = nowTimeEst - now000;
        timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
        waitbar(kf/length(filepn), hwb, ['Label conversion, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    end
    
    %% Load lbl3 file
    load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
    ch = find(sigInfo.Subject == subject);
    sigInfo = sigInfo(ch, :);
    lblSet = lblSet(ismember(double(lblSet.Channel), double(ch)), :);
    for kch = 1 : length(ch)
        lblSet.Channel(lblSet.Channel == ch(kch)) = kch;
    end
    if isempty(lblSet)
        continue
    end
    [~, saven1, savee] = fileparts(filen{kf});
    dts = regexp(saven1, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
    saven = [char(subject), '-', dts{1}, '-lbl3'];
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
% function sigp = getSigp(prompt)
%     sigpath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
%     if exist('startpath.mat', 'file')
%         load('startpath.mat'); %#ok<LOAD>
%     end
%     sigp = uigetdir(sigpath, prompt);
%     if ischar(sigp)
%         sigpath = sigp;
%         save('startpath.mat', 'sigpath', '-append');
%     end
% end
% function [siglenS, fs] = getSiglenFs(sigpn)
%     mf = matfile(sigpn);
%     siglenS = size(mf.s, 2)/mf.fs;
%     fs = mf.fs;
% %     load(sigpn); %#ok<LOAD>
% %     siglenS = size(s, 2)/fs;
% end
% function sigpn = findCorrespondingSig(filepn, sigp)
%     pattern = regexp(filepn, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
%     d = dir(sigp);
%     d = d(~[d.isdir]);
%     signAll = {d.name};
%     sign = signAll{contains(signAll, pattern)};
%     sigpn = [sigp, '\', sign];
% end

