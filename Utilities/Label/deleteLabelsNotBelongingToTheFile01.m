function deleteLabelsNotBelongingToTheFile01
% Deletes labels of specified type (label class) which have fileDateN different from the date and time in the label file name. Does not
% change original lbl files, modified files are saved into new destination.

try
    load path
catch
    path = '..';
end

lblClass = 'SEIZURE';
% lblClass = 'RacineJK01';
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
%     [~, filen, ~] = fileparts(filepn{kf});
    if isfield(l.label, lblClass)
        chnm = {'ch01', 'ch02', 'ch03', 'ch04', 'chAll'};
        for kch = 1 : length(chnm)
            if isfield(l.label.(lblClass), chnm{kch})
                if isfield(l.label.(lblClass).(chnm{kch}), 'fileDateN')
                    dn = regexp(filen{kf}, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
                    dn = datenum(dn{1}, 'yymmdd_HHMMSS');
                    timeDiff = abs(dn - l.label.(lblClass).(chnm{kch}).fileDateN);
                    torem = timeDiff > 2/24/3600;
                    fieldnm = fieldnames(l.label.(lblClass).(chnm{kch}));
                    for k = 1 : length(fieldnm)
                        l.label.(lblClass).(chnm{kch}).(fieldnm{k})(torem) = [];
                    end
                else
                    l.label.(lblClass) = rmfield(l.label.(lblClass), chnm{kch});
                end
            end
        end
    end
    save([savePath, '\', filen{kf}], '-struct', 'l')
end
disp('deleteLabelsNotBelongingToTheFile finished')
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


