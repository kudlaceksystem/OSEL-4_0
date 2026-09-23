function uniteFiles01



close all
clear
% fs = 1000;
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
% save('filepn.mat', 'filepn', 'filen')
% load('filepn.mat')

try
    load('startpath.mat'); %#ok<LOAD>
catch
    startpath = 'D:\Kudlacek\*.';
end
savep = uigetdir(startpath, 'Where to save modified label files');
% savep = '.';
% savep = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - complete first 14 days EEG - seizures present-labels marked\lbl avRef sz ied - work3';

hwb = waitbar(0, 'Files unification in progress...');

load(filepn{1})
lAll = label; %#ok<NODEF>
lAll
lblnm = fieldnames(label);
for klbl = 1 : length(lblnm)
    if isfield(lAll, lblnm{klbl})
        chnm = fieldnames(label.(lblnm{klbl}));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
        for kch = 1 : length(chnm)
            if isempty(label.(lblnm{klbl}).(chnm{kch}))
                continue
            end
            propnm = fieldnames(label.(lblnm{klbl}).(chnm{kch}));
            for kprop = 1 : length(propnm)
                label.(lblnm{klbl}).(chnm{kch}).(propnm{kprop}) = [];
            end
        end
    end
end
% label.SEIZURE.chAll
% pause

for kf = 2 : length(filepn)
%     disp(kf)
%     disp(filepn{kf})
    waitbar(kf/length(filepn))
    load(filepn{kf})
    lblnm = fieldnames(label);
    for klbl = 1 : length(lblnm) % Over labels
        if isfield(lAll, lblnm{klbl})
            chnm = fieldnames(label.(lblnm{klbl}));
            chnm = chnm(contains(chnm, 'ch'));
            chnm = chnm(~contains(chnm, 'cha'));
            for kch = 1 : length(chnm) % Over channels
                if isfield(lAll.(lblnm{klbl}), chnm{kch})
                    if isempty(label.(lblnm{klbl}).(chnm{kch}))
                        continue
                    end
                    if isempty(label.(lblnm{klbl}).(chnm{kch}).posN)
                        continue
                    end
                    propnm = fieldnames(label.(lblnm{klbl}).(chnm{kch}));
                    propnm = propnm(~contains(propnm, 'cha'));
                    for kprop = 1 : length(propnm) % Over properties
                        toAdd = label.(lblnm{klbl}).(chnm{kch}).(propnm{kprop});
% % %                         toAdd = toAdd(:)';
% if strcmp(propnm{kprop}, 'power')
% toAdd
% pause
% end
                        if size(toAdd, 2) ~= size(label.(lblnm{klbl}).(chnm{kch}).posN, 2) && ~isempty(toAdd)
                            toAdd = repelem(toAdd(1), length(label.(lblnm{klbl}).(chnm{kch}).posN));
% % %                             toAdd = toAdd(:)';
                        end
                        if isfield(lAll.(lblnm{klbl}).(chnm{kch}), propnm{kprop})
% x2 = toAdd
% 
% x1 = All.(lblnm{klbl}).(chnm{kch}).(propnm{kprop})
                            lAll.(lblnm{klbl}).(chnm{kch}).(propnm{kprop}) = [lAll.(lblnm{klbl}).(chnm{kch}).(propnm{kprop}), toAdd];

                        else
                            lAll.(lblnm{klbl}).(chnm{kch}).(propnm{kprop}) = toAdd;
                        end
                    end
                else
                    if isempty(label.(lblnm{klbl}).(chnm{kch}))
                        continue
                    else
                        lAll.(lblnm{klbl}).(chnm{kch}) = label.(lblnm{klbl}).(chnm{kch});                        
                    end
                    if isempty(lAll.(lblnm{klbl}).(chnm{kch}).posN)
                        lAll.(lblnm{klbl}).(chnm{kch}).fileDateN = [];
                        lAll.(lblnm{klbl}).(chnm{kch}).fileEndN = [];
                    end
                end
            end
        else
            lAll.(lblnm{klbl}) = label.(lblnm{klbl});
            chnmnm = fieldnames(lAll.(lblnm{klbl}));
            for kkch = 1 : length(chnmnm)
                chnm = fieldnames(label.(lblnm{klbl}));
                chnm = chnm(contains(chnm, 'ch'));
                chnm = chnm(~contains(chnm, 'cha'));
                for kch = 1 : length(chnm)
                    if isempty(lAll.(lblnm{klbl}).(chnm{kch}).posN)
                        lAll.(lblnm{klbl}).(chnm{kch}).fileDateN = [];
                        lAll.(lblnm{klbl}).(chnm{kch}).fileEndN = [];
                    end
                end
            end
        end
    end
% label.SEIZURE.chAll
% pause
end
clear label
label = lAll;
save([savep, '\All', filen{kf}], 'label')
delete(hwb)
disp('Finished')
end

function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('startpath.mat'); %#ok<LOAD>
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
startpath = filep; %#ok<NASGU>
end
