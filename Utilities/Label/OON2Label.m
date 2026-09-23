function OON2Label
kLTMax = 2; % Number of label types
labelTypeNames = {'seiz'};
labelColors = {'1 0 0'};
for kLT = 1 : kLTMax
    % Get OON mat-file names
    [filepn{kLT}, filep{kLT}, filen{kLT}] = getFilepnAllCell('Select OON mat-files', 'mat');
    if isnumeric(filen{kLT}{1})
        disp('No files selected');
        return
    end
end
% filepn
% filep
% filen

% Where to put label mat-files
savePath = uigetdir('D:\Kudlacek\Experiment');
if isnumeric(savePath)
    disp('No save path selected');
    return
end

if length(filen{1}) ~= length(filen{2})
    error('Different number of files')
end
for kF = 1 : length(filen{1})
kF
    for kLT = 1 : kLTMax
        l = load(filepn{kLT}{kF});
        flds = fieldnames(l);
        OON{kLT} = l.(flds{1});
    end
    label = OON2Lab1(OON, labelTypeNames, labelColors);
        
    save(fullfile(savePath, ['Label_' filen{1}{kF}]), 'label')
end
disp('OON2Label finished')
end

function label = OON2Lab1(OON, labelTypeNames, labelColors)
for kLT = 1 : length(labelTypeNames)
    label(kLT).name = labelTypeNames{kLT};
    if ~isempty(OON{kLT})
        label(kLT).pos = OON{kLT}(:, 1);
        label(kLT).dur = OON{kLT}(:, 2) - OON{kLT}(:, 1);
    else
        label(kLT).pos = zeros(0, 1);
        label(kLT).dur = zeros(0, 1);
    end
    label(kLT).chan = ones(size(OON{kLT}, 1), 1);
    label(kLT).chanType = ones(size(OON{kLT}, 1), 1);
    label(kLT).value = ones(size(OON{kLT}, 1), 1);
    label(kLT).color = labelColors{kLT};
    assignin('base', 'label', label)
end
end

function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
[filen, filep] = uigetfile(['D:\Kudlacek\CVUT FEL\BSG\All\Data For Evaluation\*.' ext], prompt, 'MultiSelect', 'on');
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
