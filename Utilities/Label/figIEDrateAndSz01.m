function figIEDrateAndSz01
close all;
% [filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
% load(filepn{1})
% load('G:\WKJ complete_20190125 - LABELED\jc20181211_1  - complete first 14 days EEG - seizures present-labels marked\lbl avRef sz ied - work4\Alljc20181211_1-190102_101647-VB-2000HZ--lbl')
load('d:\jk20151017\Lbl seiz useiz man till 151106__231954 IED uSz not excluded\Alljk20151017-151106_231954-N1-clm1d--lbl.mat')
ied{1} = label.IED_Janca.ch01.posN;
ied{2} = label.IED_Janca.ch02.posN;
ied{3} = label.IED_Janca.ch05.posN;
ied{4} = label.IED_Janca.ch06.posN;

for kch = 1 : 4
    iedmin(kch) = min(ied{kch});
    edmax(kch) = max(ied{kch});
end
for kch = 1 : 4
    ied{kch} = ied{kch};
%     ied{kch} = ied{kch} - min(iedmin);
    iedTotal(kch) = length(ied{kch});
end
% ed = 0 : 1/24/60 : ceil(max(edmax - min(iedmin)));
% ed = 0 : 1/24 : ceil(max(edmax - min(iedmin)));
ed = min(iedmin) : 1/24 : ceil(max(edmax));
for kch = 1 : 4
    hc(:, kch) = histcounts(ied{kch}, ed);
end
hf = figure;
hax = axes;
plot((ed(1:end-1)+ed(2:end))/2, hc)
% datetick('x', 'yyyy-mm-dd')
% hax.XTick = floor(min(iedmin)) : 2 : ceil(max(edmax));
hold on
stem(label.SEIZURE.chAll.posN, hax.YLim(2)*ones(size(label.SEIZURE.chAll.posN)), 'r')
xlabel('Time (days)');
ylabel('Hourly IED count')
hax.YLim = 2*hax.YLim;
legend([label.IED_Janca.chanNames, {'Seizures'}])

% 
% hfBar = figure;
% haxBar = axes;
% c = categorical(label.IED_Janca.chanNames)
% bar(c, iedTotal)
% c = categorical(label.IED_Janca.chanNames)
end



function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([path '\' ext], prompt, 'MultiSelect', 'on');
path = filep; save('path.mat', 'path');
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
path = filep;
end