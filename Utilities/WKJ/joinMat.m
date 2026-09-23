function joinMat

finalDur = 120*60;

% Get short mat-file names
[filepn, filep, filen] = getFilepnAllCell('Select short mat-files', 'mat');
if isa(filen, 'double')
    disp('No files selected');
    return
end

matPath = uigetdir('d:\', 'Where to put long mat-files');
if matPath == 0
    return
end

numFiles = length(filepn);
k = 0;
while k < numFiles
k = k + 1
kN = k;
    l = load(filepn{k}); % Input structure
    
%     [l.s, l.fs] = res2fs5000(l.s, l.fs, l.intScale, l.intOffset); % Resample to 5000 if needed
    l.numSamp = size(l.s, 2);
    
    while l.numSamp/l.fs < finalDur && k < numFiles
        k = k + 1
        moadd = matfile(filepn{k});
        if ~isequal(moadd.chanNames, l.chanNames)
            error('jk Attempt to add file with different chanNames!')
        end
        sadd = moadd.s;
%         [sadd, ~] = res2fs5000(moadd.s, moadd.fs, moadd.intScale, moadd.intOffset); % Resample to 5000 if needed
        l.numSamp = l.numSamp + size(sadd, 2);
        l.s = [l.s, sadd];
    end
    save(fullfile(matPath, [filen{kN}]), '-struct', 'l', '-v7.3');
end

k+1 == numFiles
disp([10 'Joining finished. ' num2str(k)...
    ' files were converted.' 10 'Source short mat-files are in folder ' filep 10 ...
    'Output long mat-files are in folder ' matPath])

% disp(['All files in ' matPath ' were joined to new files in ' joinedPath '.'])
% clear all
end


function [sd, fsd] = res2fs5000(s, fs, intScale, intOffset)
if fs ~= 5000;
    warning('jk Resampling')
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
    
    figure(2)
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


