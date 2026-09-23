function addLabel3
% Have 2 ordered sets of files.
[srcpn, ~, ~] = getFilepnAllCell('Select source files whose marker type will be added', 'mat');
[mainpn, ~, mainn] = getFilepnAllCell('Select files to which new marker type will be added', 'mat');
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
savep = uigetdir(path, 'Where to save modified files');

for kf = 1 : length(srcpn)
    lsrc = load(srcpn{kf});
    lmain = load(mainpn{kf});
%     srcFieldnames = fieldnames(lsrc.label)
    for kfield = 1 : 1
        lmain.label.ThetaKudlacek01 = lsrc.label.ThetaKudlacek01;
    end
    label = lmain.label;
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