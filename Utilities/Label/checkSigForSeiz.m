function checkSigForSeiz

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
lnm = strncmpi('tam.', nf, 4); % Logical indices of Seiz mat-files
nm = n(lnm); % Names of mat-files only
pnm = fullfile(matPath, nm); % Names with path

numFiles = length(pnm)

k = 0;
kk = 0;
kkk = 0;
wrongNumSamp = [];
unequal = [];
wrongFsField = [];
while k < numFiles
    k = k + 1
%     tic
    mo = matfile(pnm{k});
    plot(mo.s(9,:))
    ylim([0 100000])
    disp(['File ' nm{k}])

    pause
    
    
%     if ~(abs(mo.numSamp - 300000) < 600) 
%         disp(['File ' nm{k} ' has numSamp = ' num2str(mo.numSamp)])
%         k
%         pause
%         kk = kk + 1
%         wrongNumSamp{kk} = pnm{k};
%     end
%     if mo.fs ~= 5000
%         disp(['File ' nm{k} ' has fs field set to ' num2str(mo.fs)])
%         kkkk = kkkk + 1
%         wrongFsField{kkkk} = pnm{k};
%     end
% 
%     if (size(mo.s, 2) ~= mo.numSamp)
%         disp(['File ' nm{k} ' has unequal numSamp and size(s, 2).'])
%         kkk = kkk + 1
%         unequal{kkk} = pnm{k};
%     end
%     toc
end
% assignin('base', 'wrongNumSamp', wrongNumSamp)
% assignin('base', 'unequal', unequal)
% assignin('base', 'wrongFsField', wrongFsField)
disp(['All seiz files in ' matPath ' were checked for seizures.'])
% disp(['In total ' num2str(length(se)) ' seizure-containing seiz files were found.'])
clear all
