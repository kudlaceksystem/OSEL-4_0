function addFileDateN
[mainpn, ~, mainn] = getFilepnAllCell('Select files to which new marker type will be added', 'mat');
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
savep = uigetdir(path, 'Where to save modified files');

srcName = 'SeizVojta1';
mkTypeNm = 'elSeizInduction';
for kf = 1 : length(mainpn)
kf
    load(mainpn{kf})
    if isfield(label, mkTypeNm)
        if isfield(label.(mkTypeNm), 'posN')
            if ~isempty(label.(mkTypeNm).posN)
                label.(mkTypeNm).fileDateN = label.(srcName).chAll.fileDateN;
            else
                label = rmfield(label, mkTypeNm);
            end
        else
            label = rmfield(label, mkTypeNm);
        end
        save([savep, '\', mainn{kf}], 'label')
    end
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
