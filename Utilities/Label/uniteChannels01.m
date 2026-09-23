function uniteChannels01
close all
fs = 200;
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
savep = uigetdir(startpath, 'Where to save modified label files');
startpath = savep;
save('startpath.mat', 'startpath');

% savep = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - complete first 14 days EEG - seizures present-labels marked\lbl avRef sz ied - work3'

hwb = waitbar(0, 'Channel unification in progress...');
for kf = 1 : length(filepn)
waitbar(kf/length(filepn))
% kf
% filepn{kf}
    clear label
    load(filepn{kf})
    lblnm = fieldnames(label);
    for klbl = 1 : length(lblnm)
        chnm = fieldnames(label.(lblnm{klbl}));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
        onN = [];
        offN = [];
        fileDateN = [];
        fileEndN = [];
        for kch = 1 : length(chnm)
            if isempty(label.(lblnm{klbl}).(chnm{kch}))
                continue
            end
            if isempty(label.(lblnm{klbl}).(chnm{kch}).posN)
                continue
            end
            onN = [onN, label.(lblnm{klbl}).(chnm{kch}).posN];
            if ~label.(lblnm{klbl}).instant
                offN = [offN, label.(lblnm{klbl}).(chnm{kch}).posN + label.(lblnm{klbl}).(chnm{kch}).durN];
            end
            if isempty(fileDateN)
                if isfield(label.(lblnm{klbl}).(chnm{kch}), 'fileDateN')
                    if ~isempty(label.(lblnm{klbl}).(chnm{kch}).fileDateN)
                        fileDateN = label.(lblnm{klbl}).(chnm{kch}).fileDateN(1);
                    end
                end
                if isfield(label.(lblnm{klbl}).(chnm{kch}), 'fileEndN')
                    if ~isempty(label.(lblnm{klbl}).(chnm{kch}).fileEndN)
                        fileEndN = label.(lblnm{klbl}).(chnm{kch}).fileEndN(1);
                    end
                end
            end
        end
        if ~label.(lblnm{klbl}).instant
            if isempty(onN)
                label.(lblnm{klbl}).chAll.posN = [];
                label.(lblnm{klbl}).chAll.durN = [];
                label.(lblnm{klbl}).chAll.value = [];
                if ~isempty(fileDateN)
                    label.(lblnm{klbl}).chAll.fileDateN = fileDateN;
                end
                if ~isempty(fileEndN)
                    label.(lblnm{klbl}).chAll.fileEndN = fileEndN;
                end
                continue
            end
            taxStart = min(onN)-10/fs/3600/24;
            taxEnd = max(offN)+10/fs/3600/24;
            tax = taxStart : 1/fs/3600/24 : taxEnd;
            updown = zeros(size(tax));
            for ko = 1 : length(onN)
                updown(int64((onN(ko)-taxStart)*fs*3600*24)) = updown(int64((onN(ko)-taxStart)*fs*3600*24)) + 1;
            end
            for ko = 1 : length(offN)
                updown(int64((offN(ko)-taxStart)*fs*3600*24)) = updown(int64((offN(ko)-taxStart)*fs*3600*24)) - 1;
            end
            onNAll = (find(diff(sign(cumsum(updown))) == 1) + 1)/fs/3600/24 + taxStart;
            offNAll = find(diff(sign(cumsum(updown))) == -1)/fs/3600/24 + taxStart;
            label.(lblnm{klbl}).chAll.posN = onNAll;
            label.(lblnm{klbl}).chAll.durN = offNAll - onNAll;
            label.(lblnm{klbl}).chAll.value = 5*ones(size(label.(lblnm{klbl}).chAll.posN));
            if ~isempty(fileDateN)
                label.(lblnm{klbl}).chAll.fileDateN = fileDateN*ones(size(label.(lblnm{klbl}).chAll.posN));
            end
            if ~isempty(fileEndN)
                label.(lblnm{klbl}).chAll.fileEndN = fileEndN*ones(size(label.(lblnm{klbl}).chAll.posN));
            end
        else
            if isempty(onN)
                label.(lblnm{klbl}).chAll.posN = [];
                label.(lblnm{klbl}).chAll.value = [];
                if ~isempty(fileDateN)
                    label.(lblnm{klbl}).chAll.fileDateN = fileDateN;
                end
                if ~isempty(fileEndN)
                    label.(lblnm{klbl}).chAll.fileEndN = fileEndN;
                end
                continue
            end
            taxStart = min(onN)-10/fs/3600/24;
            taxEnd = max(offN)+10/fs/3600/24;
            tax = taxStart : 1/fs/3600/24 : taxEnd;
            allMarkers = zeros(size(tax));
            allMarkers(int64((onN-taxStart)*fs*3600*24)) = 1;
            label.(lblnm{klbl}).chAll.posN = find(allMarkers)/fs/3600/24 + taxStart;
            label.(lblnm{klbl}).chAll.value = 5*ones(size(label.(lblnm{klbl}).chAll.posN));
            if ~isempty(fileDateN)
                label.(lblnm{klbl}).chAll.fileDateN = fileDateN*ones(size(label.(lblnm{klbl}).chAll.posN));
            end
            if ~isempty(fileEndN)
                label.(lblnm{klbl}).chAll.fileEndN = fileEndN*ones(size(label.(lblnm{klbl}).chAll.posN));
            end
        end
    end
save([savep, '\', filen{kf}], 'label')
end
delete(hwb)
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



