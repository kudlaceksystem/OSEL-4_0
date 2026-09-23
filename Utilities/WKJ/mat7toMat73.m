function mat7toMat73
% Get rhd-file names
[filepn, filep, filen] = getFilepnAllCell('Select mat 7 files', 'mat');
if isa(filen, 'double')
    disp('No files selected');
    return
end

matPath = uigetdir('d:\', 'Where to put mat 7.3 files');
if matPath == 0
    return
end

numFilesConverted = 0;
for kF = 1:length(filepn)
    numFilesConverted = numFilesConverted + 1;
disp(['kF = ' num2str(kF)])
    l = load(filepn{kF});
    save(fullfile(matPath, filen{kF}), '-struct', 'l', '-v7.3');
end

disp([10 'Conversion finished. ' num2str(numFilesConverted)...
    ' files were converted.' 10 'Source mat-files are in folder ' filep 10 ...
    'Output mat-files are in folder ' matPath])
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