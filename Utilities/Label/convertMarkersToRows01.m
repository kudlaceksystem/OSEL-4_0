function convertMarkersToRows01
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
savep = uigetdir(path, 'Where to save modified label files');

for kf = 1 : length(filepn)
kf
    load(filepn{kf})
    lblnm = fieldnames(label);
    for klbl = 1 : length(lblnm)
        chnm = fieldnames(label.(lblnm{klbl}));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
        for kch = 1 : length(chnm)
            if isempty(label.(lblnm{klbl}).(chnm{kch}))
                continue
            end
            propnm = fieldnames(label.(lblnm{klbl}).(chnm{kch}));
            for kp = 1 : length(propnm)
                x = label.(lblnm{klbl}).(chnm{kch}).(propnm{kp});
                x = x(:)';
                label.(lblnm{klbl}).(chnm{kch}).(propnm{kp}) = x;
            end
        end
    end
save([savep, '\', filen{kf}], 'label')
end
'Finished'
end

function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([path '\' ext], prompt, 'MultiSelect', 'on');
path = filep; save('path.mat', 'path');
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
path = filep;
end
