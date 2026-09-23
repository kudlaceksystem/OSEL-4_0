close all; clear;
% filep = 'g:\Kudlacek\jk20151109_2\dec\';
filep = 'I:\jk20151111_2\dec\'
% filep = 'l:\jk20151017\dec\';
d = dir(filep);
filen = {d.name};
filen = filen(~[d.isdir]);
sAll = [];
% load('g:\Kudlacek\jk20151109_2\Lbl seiz useiz man\all1.mat');
load('i:\jk20151111_2\Lbl seiz useiz manually for Brno detector\all1.mat')
timeFrom = '151120_000000';
timeTo = '151121_000000';

sAll = nan(1, 1e8);
tax = sAll;
% tax = datenum(timeFrom, 'yymmdd_HHMMSS') : 1/24/3600/100 : datenum(timeTo, 'yymmdd_HHMMSS');
% sAll = zeros(size(tax));
pointer = 1;
for kf = 91 : 1 : 93
    kf
    l = load([filep, filen{kf}]);
    sdd = resample(l.s(1, :), 1, 2);
    tax(pointer : pointer + length(sdd) - 1) = l.dateN + (0 : 1/24/3600/100 : (length(sdd) - 1)/24/3600/100);
    sAll(pointer : pointer + length(sdd) - 1) = sdd;
    pointer = pointer + length(sdd);
    clear l sd sdd
end


hf = figure;
hf.Units = 'centimeters';
hf.Position = [10 10 9 5];
hax = axes;
hax.Position = [0.13 0.1 0.86 0.9]
plot(tax, sAll, 'k')
% plot(tax, sAll, 'k')
hax = gca;
hax.XTickLabel = datestr(hax.XTick);
hold on
szx = label.SeizKudlacek.chAll.posN(label.SeizKudlacek.chAll.posN > min(tax) & label.SeizKudlacek.chAll.posN < max(tax));
scatter(szx, ones(size(szx))*7, 'r', 'v', 'filled')
hax.Visible = 'off';
text(hax.XLim(1), 0, 'LFP')
text(hax.XLim(1), 7, 'Seizure')

% x(1 : 3 : 3*length(szx) - 2) = szx;
% x(2 : 3 : 3*length(szx) - 1) = szx;
% x(3 : 3 : 3*length(szx)) = NaN(size(szx));
% y(1 : 3 : 3*length(szx) - 2) = 5*ones(size(szx));
% y(2 : 3 : 3*length(szx) - 1) = 7*ones(size(szx));
% y(3 : 3 : 3*length(szx)) = NaN(size(szx));
% plot(x, y, 'r')
% clear x y
% 
% 
% 
% 
% atx = label.uSeizJK1.chAll.posN(label.uSeizJK1.chAll.posN < datenum(timeTo, 'yymmdd_HHMMSS') & label.uSeizJK1.chAll.posN > datenum(timeFrom, 'yymmdd_HHMMSS'));
% x(1 : 3 : 3*length(atx) - 2) = atx;
% x(2 : 3 : 3*length(atx) - 1) = atx;
% x(3 : 3 : 3*length(atx)) = NaN(size(atx));
% y(1 : 3 : 3*length(atx) - 2) = 8*ones(size(atx));
% y(2 : 3 : 3*length(atx) - 1) = 9*ones(size(atx));
% y(3 : 3 : 3*length(atx)) = NaN(size(atx));
% plot(x, y, 'b')
% clear x y
% 
% scatter(datenum('151125_030724', 'yymmdd_HHMMSS'), -7, 'g', 'v', 'filled')
% scatter(datenum('151125_220708', 'yymmdd_HHMMSS'), -7, 'g', 'v', 'filled')
% scatter(datenum('151126_185312', 'yymmdd_HHMMSS'), -7, 'g', 'v', 'filled')
% 
% 





