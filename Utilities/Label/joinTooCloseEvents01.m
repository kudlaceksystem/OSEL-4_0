function joinTooCloseEvents01
%JOINTOOCLOSEEVENTS01 Summary of this function goes here
%   Detailed explanation goes here
% lblnm = 'SEIZURE';
lblnm = 'seizure';
minIIPS = 120/3600/24; % Minimum inter-ictal period in days
close all
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
try
    load('startpath.mat'); %#ok<LOAD>
catch
    startpath = 'D:\Kudlacek\*.';
end
savep = uigetdir(startpath, 'Where to save modified label files');
% savep = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - complete first 14 days EEG - seizures present-labels marked\lbl avRef sz ied - work3'

for kf = 1 : length(filepn)
    load(filepn{kf})
    if isfield(label, lblnm)
        chnm = fieldnames(label.(lblnm));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
%         chnm = {'chAll'};
        for kch = 1 : length(chnm)
            nummk = length(label.(lblnm).(chnm{kch}).posN); % number of markers
            if nummk < 2
                continue
            end
            km = 0;
            while km < nummk - 1 && nummk > 1
                km = km + 1;
% (label.(lblnm).(chnm{kch}).posN(km+1) - (label.(lblnm).(chnm{kch}).posN(km) + label.(lblnm).(chnm{kch}).durN(km)))*24*3600
% pause
                if label.(lblnm).(chnm{kch}).posN(km+1) - (label.(lblnm).(chnm{kch}).posN(km) + label.(lblnm).(chnm{kch}).durN(km)) < minIIPS
% 'Kratsi'
% pause
                    propnm = fieldnames(label.(lblnm).(chnm{kch}));
                    for kp = 1 : length(propnm)
                        if length(label.(lblnm).(chnm{kch}).(propnm{kp})) == nummk
                            if strcmp(propnm{kp}, 'durN')
                                firstSeizDur = label.(lblnm).(chnm{kch}).(propnm{kp})(km);
                                label.(lblnm).(chnm{kch}).(propnm{kp})(km+1) = firstSeizDur + label.(lblnm).(chnm{kch}).(propnm{kp})(km+1);
                                label.(lblnm).(chnm{kch}).(propnm{kp})(km) = [];
                            else
                                label.(lblnm).(chnm{kch}).(propnm{kp})(km+1) = [];
                            end
                        end
                    end
                    nummk = nummk - 1;
                    km = km - 1;
                end
            end
        end
    end
    save([savep, '\JoinedTooClose', filen{kf}], 'label')
end
disp('Finished')
end


function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('startpath.mat'); %#ok<LOAD>
catch
    startpath = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([startpath '\' ext], prompt, 'MultiSelect', 'on');
startpath = filep; save('startpath.mat', 'startpath'); %#ok<NASGU>
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
startpath = filep; %#ok<NASGU>
end
