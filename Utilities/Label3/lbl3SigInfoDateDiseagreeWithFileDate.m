function lbl3SigInfoDateDiseagreeWithFileDate
% Writes file name's date and time to sigInfo.SigStart and corrects all other data in the lbl3 file accordingly
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
savep = getSavep('Where to save modified label files');

hwb = waitbar(0, 'Checking labels...');
now000 = now;
nTimeEst = 20;
timeToAllM = 1;
for kf = 1 : length(filepn)
    %% Display progress
    waitbar(kf/length(filepn), hwb, ['Checking labels, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
%     disp(kf)
%     disp(filepn{kf})
    if kf == nTimeEst
        nowTimeEst = now;
        timeToTimeEst = nowTimeEst - now000;
        timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
        waitbar(kf/length(filepn), hwb, ['Checking labels, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
    end
    
    %% Load lbl3 file
    load(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
    ssd = sigInfo.SigStart;
    if all(ssd == ssd(1))
        ssd = ssd(1);
    else
        error('_jk Different SigStart values');
    end
    fnd = regexp(filen{kf}, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
    fnd = fnd{1};
    fnd = datetime(fnd, 'InputFormat', 'yyMMdd_HHmmss');
    
    if fnd ~= ssd
        dif = ssd - fnd;
        sigInfo.SigStart = sigInfo.SigStart - dif;
        sigInfo.SigEnd = sigInfo.SigEnd - dif;
        lblSet.Start = lblSet.Start - dif;
        lblSet.End = lblSet.End - dif;
        lblSet.SignalFile = repelem("unknown", size(lblSet, 1), 1);
        sigInfo.FileName = repelem("unknown", size(sigInfo, 1), 1);
filen{kf}
        [~, saven, savee] = fileparts(filen{kf});
        savepne = [savep, '\', saven, savee];
        save(savepne, 'sigInfo', 'lblDef', 'lblSet')
    end
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

