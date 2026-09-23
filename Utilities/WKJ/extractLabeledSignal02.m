%% Takes into account label onset (posN) and duration (durN).

close all
clear

lblname = 'SEIZURE';
beforeD = 30*1/24/3600; % In days
afterD = 30*1/24/3600; % In days

% % lblname = 'uSeizJK1';
% lblname = 'Non_unitedLabel';
% beforeD = 0; % In days
% afterD = 0; % In days


try
    load('startfilep.mat');
catch
    startfilep = 'D:\';
end
% % % lbln = 'Alljk20151017-151104_163426-N1-clm1--lbl.mat';
% % % lblp = 'D:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis defense\uSeiz corr surrogates\jk20151017\lbl unitedLabel\';
[lbln, lblp] = uigetfile([startfilep, '..\*-lbl.mat'], 'Select label file');
if ~isempty(lblp)
    startfilep = lblp;
    save('startfilep.mat', 'startfilep')
end
lblpn = [lblp, lbln];
% lblpn = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - seizures present\lbl avRef sz ied 190404 unite 190406\JoinedTooCloseAlljc20181211_1-190102_101647-VB-200HZavRef_d--lbl.mat';
load(lblpn)

% sigp = 'D:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis defense\uSeiz corr surrogates\jk20151030_3\dec';
% sigp = 'D:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis defense\uSeiz corr surrogates\jk20151109_2\dec';
sigp = uigetdir([startfilep, '..'], 'Browse folder with signal files');
d = dir(sigp);
d = d(~[d.isdir]);
signn = {d.name};
clear d

% svp = 'D:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis defense\uSeiz corr surrogates\jk20151030_3\extr interictal';
% svp = 'D:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis defense\uSeiz corr surrogates\jk20151111_1\extr useiz';
% svp = 'D:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis defense\uSeiz corr surrogates\jk20151109_2\extr interictal';
% svp = 'D:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis defense\uSeiz corr surrogates\jk20151109_2\extr useiz';

svp = uigetdir([startfilep, '\..\'], 'Where to save extracted signal');

% Get fileDateN of all signal files into the variable fdn
fdn = NaN(length(signn), 1);
for ksig = 1 : length(signn)
    ss = strsplit(signn{ksig}, '-');
    fdn(ksig, 1) = datenum(ss{2}, 'yymmdd_HHMMSS');
end


ch = label.(lblname).chAll;
hwb = waitbar(0, 'Extracting labeled signal...');
for km = 1 : length(ch.posN)
    % Find signal file containing the sz onset
%     sigSzInd = find(diff(fdn > ch.posN(km)));
    beD = ch.posN(km) - beforeD;
    enD = ch.posN(km) + ch.durN(km) + afterD;
    sigBeInd = find(diff([fdn > beD; 1]));
    sigEnInd = find(diff([fdn > enD; 1]));
    load([sigp, '\', signn{sigBeInd}])
% % % %     lsex = length(taxSamp)
    lensex = round(beforeD*24*3600*fs + ch.durN(km)*24*3600*fs + afterD*24*3600*fs);
    sex = NaN(size(s, 1), lensex); % Signal extracted
    for kf = sigBeInd : sigEnInd
        load([sigp, '\', signn{kf}])
        sexInd = round((dateN - beD)*24*3600*fs + 1);
        lens = size(s, 2);
        if sexInd < 1
            sexoverlap = lensex - (lens + (sexInd-1));
            if sexoverlap >=0
                sex(:, 1 : end - sexoverlap) = s(:, -sexInd + 2 : end);
            else
                sex(:, 1 : end) = s(:, -sexInd + 2 : end + sexoverlap);
            end
        elseif sexInd >=1
            sexoverlap = lensex - (lens + (sexInd-1));
            if sexoverlap >=0
                sex(:, sexInd : end - sexoverlap) = s(:, 1 : end);
            else
                sex(:, sexInd : end) = s(:, 1 : end + sexoverlap);
            end
        end
    end
    clear s
    s = sex;
    dateN = beD;
    [nCh, N] = size(s);
    dateStr = datestr(dateN);
    endN = enD;
    units = 'uV';
    svn = [ss{1}, '-', datestr(dateN, 'yymmdd_HHMMSS'), '-', ss{3}, '-', ss{4}, '_interictal-000.mat'];
    svpn = [svp, '\', svn];
    save(svpn, 's', 'fs', 'chanNames', 'dateN', 'endN', 'dateStr', 'subject', 'nCh', 'N', 'units')
    waitbar(km/length(ch.posN));
end
delete(hwb)




