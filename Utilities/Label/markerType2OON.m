function markerType2OON
[filepn, filep, filen] = getFilepnAllCell('Select OON mat-files', 'mat');
if isnumeric(filen{1})
    disp('No files selected');
    return
end
savePath = uigetdir;

for kF = 1 : length(filen)
    l = load(filepn{kF});
    OON = l.M.marker;
    save(fullfile(savePath, ['OON_' filen{kF}]), 'OON');
end
end


function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
[filen, filep] = uigetfile(['d\*.' ext], prompt, 'MultiSelect', 'on');
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