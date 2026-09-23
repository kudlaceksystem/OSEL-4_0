close all
clear
subjnm = 'jc20190313_1';
% filep = 'N:\EEG conversion\MisaET3025\label nejedly test 03';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion ORIG FS\NatySST_TdTET339\';
% snlp = 'n:\EEG conversion ORIG FS\NatymTORET283\';
% snlp = 'n:\EEG conversion ORIG FS\NatySST_TdTET343\';
% snlp = 'n:\EEG conversion ORIG FS\NatySST_TdTET413\';
snlp = ['k:\JK analysis\', subjnm, '\250Hz\'];
% d = dir(filep);
% filen = d(end).name;
% filepn = fullfile(filep, filen);
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Dead mice\mTOR MUT\NatySST_TdTET339\Labels Kudlajda\___NatySST_TdTET339-210312_223552-dec-lbl3---NatySST_TdTET339-210319_183602-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Dead mice\mTOR MUT\NatySST_TdTET339\Labels Kudlajda\___NatySST_TdTET339-210324_224616-dec-lbl3---NatySST_TdTET339-210401_082207-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT\NatymTORET283\Labels Kudlajda concatenated\___NatymTORET283-210125_142536-dec-lbl3---NatymTORET283-210130_183349-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT\NatymTORET283\Labels Kudlajda concatenated\___NatymTORET283-210201_121547-dec-lbl3---NatymTORET283-210304_235955-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT\NatymTORET283\Labels Kudlajda concatenated\___NatymTORET283-210305_015955-dec-lbl3---NatymTORET283-210305_155956-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\mTOR MUT\Naty SST_TdT ET 343\label Kudlajda concatenated\___Naty SST_TdT ET 343-210421_175912-dec-lbl3---Naty SST_TdT ET 343-210425_175912-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\mTOR MUT\Naty SST_TdT ET 413\Labels Kudlajda concatenated\___Naty SST_TdT ET 413-210415_165632-dec-lbl3---Naty SST_TdT ET 413-210426_223728-dec-lbl3.mat';
lblp = ['k:\JK analysis\', subjnm, '\lbl3 sz one file\'];
d = dir([lblp, '*.mat']);
lblpn = [lblp, d.name];
% savep = 'n:\EEG conversion ORIG FS\ET283Sz';
savep = ['k:\JK analysis\', subjnm, '\250Hz sz\'];

load(lblpn);
lblCl = "SEIZURE";
minSzSep = seconds(10);
% chToExtract = 1 : 5; % 339
% chToExtract = [4 6 1 5 2]; % 283
chToExtract = [4 6 1 5 2]; % 413

d = dir(snlp);
snln = {d(~[d.isdir]).name};
snlpn = fullfile(snlp, snln);

r = cellfun(@(x) x{1}, regexp(snln, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match'), 'UniformOutput', 0); % From signal file names, get strings of date and time
snlDt = cellfun(@(x) datetime(x, 'InputFormat', 'yyMMdd_HHmmss', 'Format', 'yyMMdd_HHmmss'), r)'; % Extract the signal datetime

% Keep only relevant label class
lblSet = lblSet(string(lblSet.ClassName) == lblCl, :);
lblSet = sortrows(lblSet, 'Start');

% Remove duplicit labels (even if they were in different channels)
lblSet(diff(lblSet.Start) < seconds(0.1), :) = [];

% Check if duration is positive
if any(lblSet.End - lblSet.Start < 0)
%     disp(lblSet)
%     disp(lblSet.End - lblSet.Start)
    % If the duration is negative, swap Start and End
    lblSet(lblSet.End - lblSet.Start < 0, [3 4]) = fliplr(lblSet(lblSet.End - lblSet.Start < 0, [3 4]));
    warning('_jk Negative seizure duration. Swapped Start and End in those labels.')
end

% Remove labels with too short interval before them
bsi = lblSet.Start(2 : end) - lblSet.End(1 : end - 1); % Between seizure interval
lblSet.End([bsi < minSzSep; false]) = lblSet.End([false; bsi < minSzSep]); % In those, who have too short BSI after them, copy the End of the next label to their End.
lblSet([false; bsi < minSzSep], :) = [];

for kl = 1 : size(lblSet, 1)
    disp(['Extracting label ', num2str(kl)])
% % % lblSet.Start(kl)
% % % lblSet.End(kl)
    lblSt = lblSet.Start(kl) - seconds(10)
    lblEn = lblSet.End(kl) + seconds(10);
% % % lblSt.Format = 'yyMMdd_HHmmss';
% % % lblSt
% % % lblEn.Format = 'yyMMdd_HHmmss';
% % % lblEn

% % % % lblSt.Format = 'yyMMdd_HHmmss';
% % % % lblSt

    snlFirst = find(snlDt <= lblSt, 1, 'last')
    
% % % % snlDt(snlFirst)
    snlLast = find(snlDt < lblEn, 1, 'last');
    
    
% % % snlpn{snlFirst}
    l = load(snlpn{snlFirst});
    chToExtract = 1 : size(l.sigTbl, 1);
    sigTbl = l.sigTbl; % This will be the basis
    sigTbl = sigTbl(chToExtract, :);
    for kch = 1 : size(sigTbl, 1)
        sigTbl.SigStart(kch) = lblSt;
        sigTbl.SigEnd(kch) = lblEn;
        sigTbl.Data{kch} = NaN(1, fix(seconds(lblEn - lblSt)*sigTbl.Fs(kch))); % Prepare empty vectors
    end
    for kf = snlFirst : snlLast
        l = load(snlpn{kf});
        l.sigTbl = l.sigTbl(chToExtract, :);
        for kch = 1 : size(sigTbl, 1)
            fs = sigTbl.Fs(kch);
            if l.sigTbl.Fs(kch) ~= fs
                disp(sigTbl)
                loadedSigTbl = l.sigTbl;
                disp(loadedSigTbl)
                error('_jk Fs do not agree')
            end
            if l.sigTbl.ChName(kch) ~= sigTbl.ChName(kch)
                disp(sigTbl)
                loadedSigTbl = l.sigTbl;
                disp(loadedSigTbl)
                error('_jk Channels do not agree')
            end
            newStSub = max(fix(seconds(lblSt - snlDt(kf))*fs), 1); % Where to take new data
            newEnSub = min(fix(seconds(lblEn - snlDt(kf))*fs), size(l.sigTbl.Data{kch}, 2));
            oldStSub = fix(seconds(snlDt(kf) - lblSt)*fs) + newStSub + 1; % Where to write them
            oldEnSub = oldStSub + newEnSub - newStSub;
            sigTbl.Data{kch}(oldStSub : oldEnSub) = l.sigTbl.Data{kch}(newStSub : newEnSub);

% % % % plot(sigTbl.Data{kch})
% % % % pause

        end
    end
    
    
% % % figure
% % % plot(sigTbl.Data{1})
% % % title(num2str(kl))
% % % pause
    
    [~, snln, savee] = fileparts(snlpn{snlFirst});
    ss = strsplit(snln, '-');
    
    saven = ['___', ss{1}, '-', datestr(lblSt, 'yymmdd_HHMMSS'), '-', ss{3}, '-', char(lblCl), savee];
    save(fullfile(savep, saven), 'sigTbl');
    clear sigTbl l
end




disp('Finished')




