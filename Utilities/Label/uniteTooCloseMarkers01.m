function uniteTooCloseMarkers01
close all
clear

minDistS = 1; % Vector in seconds
lblnm = {'SEIZURE'}; % Cell array

[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
savep = uigetdir(startpath, 'Where to save modified label files');
startpath = savep;
save('startpath.mat', 'startpath');

hwb = waitbar(0, 'Unite too closes markers...');
for kf = 1 : length(filepn)
waitbar(kf/length(filepn))
% kf
% filepn{kf}
    load(filepn{kf})
    for klbl = 1 : length(lblnm)
        chnm = fieldnames(label.(lblnm{klbl}));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
        for kch = 1 : length(chnm)
            if isempty(label.(lblnm{klbl}).(chnm{kch}))
                continue
            end
            if isempty(label.(lblnm{klbl}).(chnm{kch}).posN)
                continue
            end
            onN = label.(lblnm{klbl}).(chnm{kch}).posN;
            ofN = label.(lblnm{klbl}).(chnm{kch}).posN + label.(lblnm{klbl}).(chnm{kch}).durN;
            iei = onN(2 : end) - ofN(1 : end-1);
            toRemove = find(iei < minDistS/24/3600) + 1;
            propnm = fieldnames(label.(lblnm{klbl}).(chnm{kch}));
            for kp = 1 : length(propnm)
                if strcmp(propnm{kp}, 'durN')
                    label.(lblnm{klbl}).(chnm{kch}).(propnm{kp})(toRemove - 1) = [];
                else
                    propnm{kp}
                    label.(lblnm{klbl}).(chnm{kch}).(propnm{kp})(toRemove) = [];
                end
            end
        end
    end
save([savep, '\', filen{kf}], 'label')
end
delete(hwb)
'Finished'
end



function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([startpath '\' ext], prompt, 'MultiSelect', 'on');
startpath = filep; save('startpath.mat', 'startpath');
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
startpath = filep;
end



