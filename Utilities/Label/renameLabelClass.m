function renameLabelClass
[filepn, ~, filen] = getFilepnAllCell('Select files to which new marker type will be added', 'mat');
try
    load('path.mat'); %#ok<LOAD>
catch
    path = 'D:\Kudlacek\*.';
end
savep = uigetdir(path, 'Where to save modified files');

oldClass = 'seizure';
newClass = 'SEIZURE';

for kf = 1 : length(filepn)
    disp(['File ', num2str(kf), '/', num2str(length(filepn))]);
    load(filepn{kf})
%     if ~exist('label')
%         continue
%     end
    if isfield(label, oldClass)
        label.(newClass) = label.(oldClass);
        label = rmfield(label, oldClass);
    end
    save([savep, '\', filen{kf}], 'label');
end
end

function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('path.mat'); %#ok<LOAD>
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
path = filep; %#ok<NASGU>
end
