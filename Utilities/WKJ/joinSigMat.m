function joinSigMat

finalDur = 30*60;


matPath = uigetdir('h:\_Kudlacek\jk20141113\', 'Select folder with mat files');
% matPath = uigetdir(cd, 'Select folder with mat files');
if matPath == 0
    return
end

joinedPath = [matPath '\Joined'];
mkdir(matPath, 'Joined');


d = dir(matPath);
d([d.isdir]) = []; % Remove dirs
n = {d.name}; % All names in the directory
nf = cellfun(@(c) fliplr(c), n, 'UniformOutput', false); % Flipped names in cell array
lnm = strncmpi('tam.', nf, 4); % Logical indices of mat-files
nm = n(lnm); % Names of mat-files only
pnm = fullfile(matPath, nm); % Names with path

numFiles = length(pnm)

k = 0;
while k < numFiles
k = k + 1
%     moin = matfile(pnm{k}); % Input matobj
    stout = load(pnm{k}); % Input structure
    
    [stout.s, stout.fs] = res2fs5000(stout.s, stout.fs, stout.intScale, stout.intOffset); % Resample to 5000 if needed
    stout.numSamp = size(stout.s, 2);
    
    while stout.numSamp/stout.fs < finalDur && k < numFiles
        k = k + 1
        moadd = matfile(pnm{k});
        if ~isequal(moadd.chanNames, stout.chanNames)
            error('jk Attempt to add file with different chanNames!')
        end
        [sadd, ~] = res2fs5000(moadd.s, moadd.fs, moadd.intScale, moadd.intOffset); % Resample to 5000 if needed
        stout.numSamp = stout.numSamp + size(sadd, 2);
        stout.s = [stout.s, sadd];
    end
    tic
    save(fullfile(joinedPath, ['Joined_' nm{k}]), '-struct', 'stout', '-v7.3');
    toc
end
disp(['All files in ' matPath ' were joined to new files in ' joinedPath '.'])
clear all
end




function [sd, fsd] = res2fs5000(s, fs, intScale, intOffset)
if fs ~= 5000;
    disp('Resampling')
    fsd = 5000;
    df = fs/fsd;
    s = double(s);
    s = intScale*(s - intOffset);
    sd = resample(s', 1, df)';
    sd = (sd/intScale) + intOffset;
    sd = uint16(sd);
    s = (s/intScale) + intOffset;
    t = 0 : 1/fs : size(s, 2)/fs - 1/fs;
    td = 0 : 1/fsd : size(sd, 2)/fsd - 1/fsd;
    
    subplot(211)
    plot(t, s(7, :))

    subplot(212)
    plot(t, s(7, :))
    hold on
    plot(td, sd(7, :), 'r')
    pause(1)
    hold off
else
    sd = s;
    fsd = fs;
end
end








