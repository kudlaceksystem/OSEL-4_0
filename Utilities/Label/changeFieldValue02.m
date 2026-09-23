function changeFieldValue02
[mainpn, ~, mainn] = getFilepnAllCell('Select files to which new marker type will be added', 'mat');
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
savep = uigetdir(path, 'Where to save modified files');

fieldnm = 'srcSigFile';
% newValue = 'jk20151109_2';
for kf = 1 : length(mainpn)
kf
    load(mainpn{kf})
    if ~exist('label')
        continue
    end
    mkTypeNm = fieldnames(label);
    for kn = 1 : length(mkTypeNm)
        if iscell(label.(mkTypeNm{kn}).(fieldnm))
            label.(mkTypeNm{kn}).(fieldnm) = label.(mkTypeNm{kn}).(fieldnm){1};
        end
%         label.(mkTypeNm{kn}).(fieldnm) = newValue;
    end
    save([savep, '\', mainn{kf}], 'label')
end
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
