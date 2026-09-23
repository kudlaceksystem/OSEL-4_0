function kudlajdization1
%KUDLAJDIZATION1 Convert data from Radek Janca to Kudlajda format
filep = uigetdir('d:\', 'Select folder with mat files');
svp = uigetdir(filep);
if filep == 0
    return
end
d = dir(filep);
d([d.isdir]) = [];

for kF = 1 : length(d)
kF
[filep, filen, ext] = fileparts(fullfile(filep, d(kF).name));
if ~strcmp(ext, '.mat')
    continue
end
kudl1(filep, filen, ext, svp, kF)
end
disp('Finished')
end

function kudl1(filep, filen, ext, svp, kF)
    load(fullfile(filep, [filen, ext]))
    s = double(d');
    spl = strsplit(filen, '_');
    subject = spl{1};
    if exist('tabs')
        dateN = tabs(1);
    else
        dateN = kF;
    end
    if ~exist('fs')
        dt = diff(t);
        fs = 1/median(dt);
    end
    dateStrName = datestr(dateN, 'yymmdd_HHMMSS')
    dateStr = datestr(dateN)
    chnum = mat2cell((1 : size(s, 1))', ones(size(s, 1), 1), 1);
    chanNames = cellfun(@(x) num2str(x, '%03d'), chnum, 'UniformOutput', false);
    [svp, '\', subject, '-', dateStrName, '-XX-her-999.mat']
    save([svp, '\', subject, '-', dateStrName, '-XX-her-999.mat'], 's', 'fs', 'subject', 'dateN', 'dateStr', 'chanNames');
end




