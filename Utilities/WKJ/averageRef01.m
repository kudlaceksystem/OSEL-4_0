function averageRef01
[filepn, filep, filen] = getFilepnAllCell('Select source mat-files', 'mat');
if isa(filen, 'double')
    disp('No files selected');
    return
end

svp = uigetdir('d:\', 'Where to put output mat-files');
if svp == 0
    return
end

numFilesConverted = 0;

tic

% % % d = dir(matPath);
% % % d([d.isdir]) = [];
% % % d
hwb = waitbar(0, 'Average reference - processing files...')
for kf = 1 : length(filepn)
    waitbar(kf/length(filepn))
kf
    l = load(filepn{kf});
    avRef = mean(l.s);
    sb(1, :) = l.s(1, :) - avRef;
    sb(2, :) = l.s(2, :) - avRef;
    sb(3, :) = l.s(3, :) - avRef;
    sb(4, :) = l.s(4, :) - avRef;
    l.s = sb;
    save(fullfile(svp, filen{kf}), '-struct', 'l');
    clear l sb avRef
end
close(hwb)
'Hotovo'
toc
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