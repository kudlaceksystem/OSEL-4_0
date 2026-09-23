%% Takes into account only label onset (posN). The length of the extracted segment is given by beforeD + afterD.

close all
clear

lblname = 'SEIZURE';
beforeD = 30*1/24/3600; % In days
afterD = 30*1/24/3600; % In days

% lblname = 'uSeizJK1';
% beforeD = 0; % In days
% afterD = 0; % In days


try
    load('startfilep.mat');
catch
    startfilep = 'D:\';
end
[lbln, lblp] = uigetfile([startfilep, '..\*-lbl.mat'], 'Select label file');
if ~isempty(lblp)
    startfilep = lblp;
    save('startfilep.mat', 'startfilep')
end
lblpn = [lblp, lbln];
% lblpn = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - seizures present\lbl avRef sz ied 190404 unite 190406\JoinedTooCloseAlljc20181211_1-190102_101647-VB-200HZavRef_d--lbl.mat';
load(lblpn)
sigp = uigetdir([startfilep, '..'], 'Browse folder with signal files');
% sigp = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - seizures present\200Hz avRef';
d = dir(sigp);
d = d(~[d.isdir]);
signn = {d.name};
clear d

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
    enD = ch.posN(km) + afterD;
    sigBeInd = find(diff([fdn > beD; 1]));
    sigEnInd = find(diff([1; fdn > enD])) - 1;
    
    sigBeInd
    signn{sigBeInd}
    
    load([sigp, '\', signn{sigBeInd}])
% % % %     taxSamp = -beforeD*24*3600*fs : afterD*24*3600*fs - 1;
% % % %     lsex = length(taxSamp)
    lsex = beforeD*24*3600*fs + afterD*24*3600*fs;
    sex = NaN(size(s, 1), lsex); % Signal extracted
    
    for kf = sigBeInd : sigEnInd
        load([sigp, '\', signn{kf}])
        sexInd = round((dateN - beD)*24*3600*fs + 1);
        if sexInd < 1
            ls = size(s, 2);
            sexoverlap = lsex - (ls + (sexInd-1));
            if sexoverlap >=0
                sex(:, 1 : end - sexoverlap) = s(:, -sexInd + 2 : end);
            else
                sex(:, 1 : end) = s(:, -sexInd + 2 : end + sexoverlap);
            end
        elseif sexInd >=1
            sexoverlap = lsex - (ls + (sexInd-1));
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
    svn = [ss{1}, '-', datestr(dateN, 'yymmdd_HHMMSS'), '-', ss{3}, '-', ss{4}, '_useiz-000.mat'];
    svpn = [svp, '\', svn];
    save(svpn, 's', 'fs', 'chanNames', 'dateN', 'endN', 'dateStr', 'subject', 'nCh', 'N', 'units')
    waitbar(km/length(ch.posN));
end
delete(hwb)




