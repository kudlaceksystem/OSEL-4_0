function deleteLabelType
% Deletes the label type specified in the code as lblTypeToRemove. Does not
% change original lbl files, modified files are saved into new destination.
%%
try
    load path
catch
    path = '..';
end

% lblTypeToRemove = 'StepanConv';
lblTypeToRemove = 'IED_Janca60Hz5';
% lblTypeToRemove = 'SWKudlacek01'
[filepn, ~, filen] = getFilepnAllCell(path, 'Select label files', 'mat');
path = fileparts(filepn{1});

savePath = uigetdir(path, 'Where to save modified label files');
if savePath == 0
    return
end
path = fileparts(filepn{1});
save('path.mat', 'path')
%%
for kf = 1 : length(filepn)
    % kf
    l = load(filepn{kf});
    if isfield(l.label, lblTypeToRemove)
        l.label = rmfield(l.label, lblTypeToRemove);
    end
    save([savePath, '\', filen{kf}], '-struct', 'l')
end
disp('deleteLabelType finished')
end


function [filepn, filep, filen] = getFilepnAllCell(startAdress, prompt, ext)
[filen, filep] = uigetfile([startAdress, '\*.' ext], prompt, 'MultiSelect', 'on');
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

