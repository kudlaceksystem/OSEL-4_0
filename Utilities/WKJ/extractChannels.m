function extractChannels
nCh = [1 : 68];


% Get input mat-file names
[filepn, filep, filen] = getFilepnAllCell('Select mat-files', 'mat');
if isa(filen, 'double')
    disp('No files selected');
    return
end

matPath = uigetdir('d:\', 'Where to put output mat-files');
if matPath == 0
    return
end

numFilesConverted = 0;

for kF = 1:length(filepn)
    numFilesConverted = numFilesConverted + 1;
disp(['kF = ' num2str(kF)])
disp(filepn{kF})
    l = load(filepn{kF});
    l.s = l.s(nCh, :);
%     l.chanNames = {'DHippR'; 'DHippR2'; 'DHippL'; 'DHippL2'};
    l.chanNames = {'Ga1','Ga2','Ga3','Ga4','Ga5','Ga6','Ga7','Ga8','Gb1','Gb2','Gb3','Gb4','Gb5','Gb6','Gb7','Gb8','Gc1','Gc2','Gc3','Gc4','Gc5','Gc6','Gc7','Gc8','Gd1','Gd2','Gd3','Gd4','Gd5','Gd6','Gd7','Gd8','TL1','TL2','TL3','TL4','TL5','TL6','TP1','TP2','TP3','TP4','TP5','TP6','TBa1','TBa2','TBa3','TBa4','TBb1','TBb2','TBb3','TBb4','TBc1','TBc2','TBc3','TBc4','TBd1','TBd2','TBd3','TBd4','AH1','AH2','AH3','AH4','AH5','AH6','AH7','AH8'};
    l.numChan = length(nCh);
% fullfile(matPath, filen)
    save(fullfile(matPath, filen{kF}), '-struct', 'l');
    clear l
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


