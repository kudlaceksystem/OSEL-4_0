function invertLabel02
[lblpn, lblp, lbln] = getFilepnAllCell('Select label files to which the inverted label will be added', 'mat');
lblname = 'SEIZURE';
lblch = 'chAll';
nonch = 'ch04';
mindurS = 10;
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
sigp = uigetdir(startpath, 'Signal files');
d = dir(sigp);
signm = {d.name};
signm = signm(~[d.isdir]);
savep = uigetdir(startpath, 'Where to save modified files');

for kf = 1 : length(lblpn)
kf
    load(lblpn{kf});
    ksig = findCorrespondingFile(lblpn{kf}, signm);
    ls = load([sigp, '\', signm{ksig}]);
    if ~isfield(label, lblname)
        label.(lblname).chAll.posN = [];
        label.(lblname).subject = ls.subject;
        label.(lblname).chanNames = ls.chanNames;
        label.(lblname).srcSigFile = signm{ksig};
        label.(lblname).color = '1 0.2 0';
    end
    ch = label.(lblname).(lblch);
    % Check if fileDateN corresponds
% % %     if fileDateN ~= ls.dateN
% % %         error(['_jk Files ', 10, lbln{kf}, ' and ', 10, sign{ksig}, 10, ' have dates ', datestr(fileDateN), ' and ', datestr(ls.dateN), ' respectively.'])
% % %     end
    fileDateN = ls.dateN;
    siglenS = size(ls.s, 2)/ls.fs;
    siglenN = siglenS/3600/24;
    startN = fileDateN;
    endN = fileDateN + 1200/3600/24;
    endN = fileDateN + siglenN;
    nonposN = [];
    nondurN = [];
    if ~isempty(ch.posN)
        if ch.posN(1) <= startN
            nonposN(1) = ch.posN(1) + ch.durN(1);
            if length(ch.posN) > 1
                nondurN(1) = min(ch.posN(2), endN) - nonposN(1);
            else
                nondurN(1) = endN - nonposN(1);
            end
            k = 2;
        else
            nonposN(1) = startN;
            nondurN(1) = min(ch.posN(1), endN) - nonposN(1);
            k = 1;
        end
        while k <= length(ch.posN)
            nonposN(end + 1) = ch.posN(k) + ch.durN(k);
            if length(ch.posN) >= k+1
                nondurN(end + 1) = min(ch.posN(k+1), endN) - nonposN(end);
            else
                nondurN(end + 1) = endN - nonposN(end);
            end
            k = k + 1;
        end
    else
        nonposN(1) = startN;
        nondurN(1) = endN - startN;
    end
    
    % Remove too short events
    nonposN(nondurN < mindurS/3600/24) = [];
    nondurN(nondurN < mindurS/3600/24) = [];
    
    % Prepare color
    hsv = rgb2hsv(str2num(label.(lblname).color));
    hsv(1) = mod(hsv(1) + 0.5, 1);
    col = num2str(hsv2rgb(hsv));
    
    label.(['Non_', lblname]).(nonch).posN = nonposN;
    label.(['Non_', lblname]).(nonch).durN = nondurN;
    label.(['Non_', lblname]).(nonch).fileDateN = fileDateN*ones(size(nonposN));
    label.(['Non_', lblname]).(nonch).fileEndN = endN*ones(size(nonposN));
    label.(['Non_', lblname]).(nonch).value = 5*ones(size(nonposN));
    label.(['Non_', lblname]).name = ['Non_', lblname];
    label.(['Non_', lblname]).color = col;
    label.(['Non_', lblname]).instant = 0;
    label.(['Non_', lblname]).subject = label.(lblname).subject;
    label.(['Non_', lblname]).chanNames = label.(lblname).chanNames;
    label.(['Non_', lblname]).srcSigFile = label.(lblname).srcSigFile;
    save([savep, '\', lbln{kf}], 'label')
end
'Finished'
end


function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([startpath '\' ext], prompt, 'MultiSelect', 'on');
startpath = filep; save('startpath.mat', 'startpath');
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
startpath = filep;
end

function outInd = findCorrespondingFile(filepnin, filepnsToSearch)
    filepnindtInd = regexpi(filepnin, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D') + 1;
    dt = filepnin(filepnindtInd : filepnindtInd + 12);
    outInd = find(~cellfun(@isempty, regexp(filepnsToSearch, dt)));
end



