function isSeizure

matPath = uigetdir('h:\_Kudlacek\jk20141113\', 'Select folder with mat files');
% matPath = uigetdir(cd, 'Select folder with mat files');
if matPath == 0
    return
end

% joinedPath = [matPath '\Joined'];
% mkdir(matPath, 'Joined');


d = dir(matPath);
d([d.isdir]) = []; % Remove dirs
n = {d.name}; % All names in the directory
nf = cellfun(@(c) fliplr(c), n, 'UniformOutput', false); % Flipped names in cell array
lnm = strncmpi('tam.zieS_', nf, 9); % Logical indices of Seiz mat-files
nm = n(lnm); % Names of mat-files only
pnm = fullfile(matPath, nm); % Names with path

numFiles = length(pnm)

k = 0;
kk = 0;
se = [];
while k < numFiles
    k = k + 1
    mo = matfile(pnm{k});
    if ~isempty(mo.seizOOS)
        disp(['File ' nm{k} ' contains one or more seizures.'])
        kk = kk + 1
        se{kk} = nm{k};
    end
end
assignin('base', 'se', se)
disp(['All seiz files in ' matPath ' were checked for seizures.'])
disp(['In total ' num2str(length(se)) ' seizure-containing seiz files were found.'])
clear all
