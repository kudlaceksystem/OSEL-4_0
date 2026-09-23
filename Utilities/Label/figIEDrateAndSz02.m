function figIEDrateAndSz02
close all;
% [filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
% load(filepn{1})
% load('G:\WKJ complete_20190125 - LABELED\jc20181211_1  - complete first 14 days EEG - seizures present-labels marked\lbl avRef sz ied - work4\Alljc20181211_1-190102_101647-VB-2000HZ--lbl')

% load('g:\jk20151017\Lbl seiz useiz man till 151106__231954 IED uSz not excluded\Alljk20151017-151106_231954-N1-clm1d--lbl.mat')
% load('f:\_Kudlacek\jk20151019\Lbl seiz useiz det IED\Alljk20151019-151214_080212-N2-clm1d--lbl.mat')
% load('d:\jk20151030_3\Lbl seiz useiz man IED\Alljk20151030_3-151124_063145-A2a_C-sp--lbl.mat')
% load('h:\jk20151109_1\Lbl seiz useiz man till 151201__055538 IED\Alljk20151109_1-151208_083657-A33c_A-d--lbl.mat')
load('h:\jk20151109_2\Lbl seiz useiz man IED\Alljk20151109_2-151216_074252-A33c_B-d--lbl.mat')
% load('h:\jk20151109_3\Lbl seiz useiz det IED\Alljk20151109_3-151217_015507-A33c_C-d--lbl.mat')
% load('i:\jk20151111_1\Lbl Doctoral thesis add IED\Alljk20151111_1-151218_120238-A2b_B-d--lbl.mat')

label
ied{1} = label.IED_Janca.ch01.posN;
ied{2} = label.IED_Janca.ch02.posN;
ied{3} = label.IED_Janca.ch03.posN;
ied{4} = label.IED_Janca.ch04.posN;
ied{5} = label.IED_Janca.ch05.posN;
ied{6} = label.IED_Janca.ch06.posN;
ied{7} = label.IED_Janca.ch07.posN;
ied{8} = label.IED_Janca.ch08.posN;

for kch = 1 : 8
    iedmin(kch) = min(ied{kch});
    iedmax(kch) = max(ied{kch});
end
edmin = min(iedmin);
edmax = max(iedmax);

iedhip = sort([ied{1}, ied{2}, ied{5}, ied{6}]);
iedmcx = sort([ied{3}, ied{4}, ied{7}, ied{8}]);

ed = edmin : 1/24 : edmax;
hchip = histcounts(iedhip, ed);
hcmcx = histcounts(iedmcx, ed);

hf = figure;
hax = axes;
plot((ed(1:end-1)+ed(2:end))/2 - edmin, hchip, 'ZData', 20*ones(size(hchip)), 'Color', [0 0.2 0.8], 'LineWidth', 1.5)
hold on
plot((ed(1:end-1)+ed(2:end))/2 - edmin, hcmcx, 'ZData', 20*ones(size(hcmcx)), 'Color', [0.7 0 0], 'LineWidth', 1.5)
% datetick('x', 'yyyy-mm-dd')
% hax.XTick = floor(min(iedmin)) : 2 : ceil(max(edmax));
stem(label.SeizKudlacek.chAll.posN - edmin, hax.YLim(2)*ones(size(label.SeizKudlacek.chAll.posN)), 'r')
xlabel('Time (days)');
ylabel('Hourly IED count')
hax.YLim = 2*hax.YLim;
title(label.IED_Janca.subject, 'Interpreter', 'none')


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