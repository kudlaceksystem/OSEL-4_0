function invertLabel03
[sigpn, sigp, sign] = getFilepnAllCell('Select signal files for which you want label files to exist', 'mat');
% lblname = 'SEIZURE'; % This label will be inverted
% lblch = 'chAll'; % This channels will be inverted
% nonch = 'ch04'; % The inverted label will be assigned to this channel
% mindurS = 10; % Minimum duration of the inverted label
% addAlsoChAll = true;
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
lblp = uigetdir(startpath, 'Browse original label files')
% lblp = 'C:\Users\Kudlacek\Documents\Experiment\FCD\jc20181218_1\lbl avRef sz RacineJK01 test NonSz'

d = dir(lblp);
lbln = {d.name};
lbln = lbln(~[d.isdir]);
savep = uigetdir(startpath, 'Where to save modified label files')
% savep = 'C:\Users\Kudlacek\Documents\Experiment\FCD\jc20181218_1\lbl avRef sz RacineJK01 test NonSz Output'
for kf = 1 : length(sigpn)
    ls = load(sigpn{kf});
    klbl = findCorrespondingFile(sigpn{kf}, lbln);
    if isempty(klbl)
        [~, signn, ~] = fileparts(sign{kf});
        lblsvn = [signn, '-lbl.mat'];
    else
        lblsvn = lbln{klbl};
    end
    if isempty(klbl)
        label.(lblname).(lblch).posN = [];
        label.(lblname).(lblch).durN = [];
        label.(lblname).(lblch).value = [];
        label.(lblname).(lblch).fileDateN = ls.dateN;
        label.(lblname).(lblch).fileEndN = ls.dateN + size(ls.s, 2)/ls.fs/3600/24;
        if addAlsoChAll
            label.(lblname).chAll.posN = [];
            label.(lblname).chAll.durN = [];
            label.(lblname).chAll.value = [];
            label.(lblname).chAll.fileDateN = ls.dateN;
            label.(lblname).chAll.fileEndN = ls.dateN + size(ls.s, 2)/ls.fs/3600/24;
        end            
        label.(lblname).name = lblname;
        label.(lblname).color = '1 0.2 0';
        label.(lblname).instant = 0;
        label.(lblname).subject = ls.subject;
        label.(lblname).chanNames = ls.chanNames;
        label.(lblname).srcSigFile = sign{kf};
    else        
        load([lblp, '\', lbln{klbl}]);
    end
% label1 = label.SEIZURE.chAll.posN
    if ~isfield(label, lblname)
        label.(lblname).(lblch).posN = [];
        label.(lblname).(lblch).durN = [];
        label.(lblname).(lblch).value = [];
        label.(lblname).(lblch).fileDateN = ls.dateN;
        label.(lblname).(lblch).fileEndN = ls.dateN + size(ls.s, 2)/ls.fs/3600/24;
        if addAlsoChAll
            label.(lblname).chAll.posN = [];
            label.(lblname).chAll.durN = [];
            label.(lblname).chAll.value = [];
            label.(lblname).chAll.fileDateN = ls.dateN;
            label.(lblname).chAll.fileEndN = ls.dateN + size(ls.s, 2)/ls.fs/3600/24;
        end            
        label.(lblname).name = lblname;
        label.(lblname).color = '1 0.2 0';
        label.(lblname).instant = 0;
        label.(lblname).subject = ls.subject;
        label.(lblname).chanNames = ls.chanNames;
        label.(lblname).srcSigFile = sign{kf};
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
% % %     endN = fileDateN + 1200/3600/24;
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
    if addAlsoChAll
        label.(['Non_', lblname]).chAll.posN = nonposN;
        label.(['Non_', lblname]).chAll.durN = nondurN;
        label.(['Non_', lblname]).chAll.fileDateN = fileDateN*ones(size(nonposN));
        label.(['Non_', lblname]).chAll.fileEndN = endN*ones(size(nonposN));
        label.(['Non_', lblname]).chAll.value = 5*ones(size(nonposN));
    end
    label.(['Non_', lblname]).name = ['Non_', lblname];
    label.(['Non_', lblname]).color = col;
    label.(['Non_', lblname]).instant = 0;
    label.(['Non_', lblname]).subject = label.(lblname).subject;
    label.(['Non_', lblname]).chanNames = label.(lblname).chanNames;
    label.(['Non_', lblname]).srcSigFile = label.(lblname).srcSigFile;
    save([savep, '\', lblsvn], 'label')
    clear label
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



