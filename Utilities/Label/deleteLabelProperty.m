function deleteLabelProperty
% Deletes the label type specified in the code as lblTypeToRemove. Does not
% change original lbl files, modified files are saved into new destination.

try
    load path
catch
    path = '..';
end

lblPropToRemove = 'endDateN';
% lblPropToRemove = 'chanType';
[filepn, ~, filen] = getFilepnAllCell(path, 'Select label files', 'mat');
path = fileparts(filepn{1});

savePath = uigetdir(path, 'Where to save modified label files');
if savePath == 0
    return
end
path = fileparts(filepn{1});
save('path.mat', 'path')

for kf = 1 : length(filepn)
    kf
    l = load(filepn{kf});
    lblNames = fieldnames(l.label);
    for kn = 1 : length(lblNames)
        chNames = fieldnames(l.label.(lblNames{kn}));
        for kch = 1 : length(chNames)
            if isstruct(l.label.(lblNames{kn}).(chNames{kch}))
                if isfield(l.label.(lblNames{kn}).(chNames{kch}), lblPropToRemove)
                    l.label.(lblNames{kn}).(chNames{kch}) = rmfield(l.label.(lblNames{kn}).(chNames{kch}), lblPropToRemove);
                    disp([lblPropToRemove, ' removed'])
                end
            end
        end
    end
    save([savePath, '\', filen{kf}], '-struct', 'l')
end
'deleteLabelProperty finished'
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

