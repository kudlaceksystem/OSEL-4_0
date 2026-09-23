function removeTooShort01
close all
lblnm = 'SEIZURE';
mindur = 6/3600/24; % In days
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
try
    load('path.mat'); %#ok<LOAD>
catch
    path = 'D:\Kudlacek\*.'; %#ok<NASGU>
end
% savep = uigetdir(path, 'Where to save modified label files');
savep = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - complete first 14 days EEG - seizures present-labels marked\lbl avRef sz ied - work3';

hwb = waitbar(0, 'Removing too short seizure markers...');
for kf = 1 : length(filepn)
    waitbar(kf/length(filepn))
    disp(kf)
    disp(filepn{kf})
    load(filepn{kf})
    if isfield(label, lblnm)
        chnm = fieldnames(label.(lblnm));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
        for kch = 1 : length(chnm)
            if isempty(label.(lblnm).(chnm{kch}))
                continue
            end
            if isempty(label.(lblnm).(chnm{kch}).posN)
                continue
            end
            nummrks = length(label.(lblnm).(chnm{kch}).posN);
            toKeep = label.(lblnm).(chnm{kch}).durN >= mindur;
            propnm = fieldnames(label.(lblnm).(chnm{kch}));
            for kp = 1 : length(propnm)
                if length(label.(lblnm).(chnm{kch}).(propnm{kp})) == nummrks
                    label.(lblnm).(chnm{kch}).(propnm{kp}) = label.(lblnm).(chnm{kch}).(propnm{kp})(toKeep);
                end
            end
        end
    end
save([savep, '\', filen{kf}], 'label')
end
delete(hwb)
disp('Finished')
end

function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('path.mat'); %#ok<LOAD>
catch
    path = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([path '\' ext], prompt, 'MultiSelect', 'on');
path = filep; save('path.mat', 'path'); %#ok<NASGU>
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
path = filep; %#ok<NASGU>
end
