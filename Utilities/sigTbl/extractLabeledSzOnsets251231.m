format compact
close all
clear
% filep = 'N:\EEG conversion\MisaET3025\label nejedly test 03';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion ORIG FS\NatySST_TdTET339\';
% snlp = 'n:\EEG conversion ORIG FS\NatymTORET283\';
% snlp = 'n:\EEG conversion ORIG FS\NatySST_TdTET343\';
% snlp = 'n:\EEG conversion ORIG FS\NatySST_TdTET413\';

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


% savep = 'n:\EEG conversion ORIG FS\ET283Sz';


%% For Premek for seizure onset patterns
%% Subject
% subjNm = "CO006701";
% subjNm = "JK003911";
% subjNm = "MoniET430"; subjNmToSearchFor = 'recID_37';
% subjNm = "NatySST_TdTET343"; subjNmToSearchFor = 'recID_20';
% subjNm = "BH003592"; subjNmToSearchFor = 'recID_BH003592';
% subjNm = "BH003593"; subjNmToSearchFor = 'recID_BH003593';
% subjNm = "BH002390"; subjNmToSearchFor = 'recID_BH002390';
subjNm = "MK001791"; subjNmToSearchFor = 'recID_MK001791';
%% Signal
% snlp = '\\neurodata4\VideoEEG sklad1\Bobik\Bobik03 converted\'; snlTemplate = '*.smrx';
% snlp = '\\neurodata4\VideoEEG sklad1\EEG conversion 5000Hz\JK003911\'; snlTemplate = '*.mat';

% MoniET430
% snlp = 'y:\EEG data\FERDA-PC\20210628converted\'; snlTemplate = '*.smrX';
% snlp = 'y:\EEG data\FERDA-PC\20210709converted\'; snlTemplate = '*.smrX';
% snlp = 'y:\EEG data\FERDA-PC\20210716converted\'; snlTemplate = '*.smrX';
% snlp = 'y:\EEG data\FERDA-PC\20210731converted\'; snlTemplate = '*.smrX';
% snlp = 'y:\EEG data\FERDA-PC\20210813converted\'; snlTemplate = '*.smrX';

% NatySST_TdTET343
% snlp = 'y:\EEG data\AMALKA-PC\20210324converted\'; snlTemplate = '*.smrX';
% snlp = 'y:\EEG data\AMALKA-PC\20210421converted\'; snlTemplate = '*.smrX';
% snlp = '\\neurodata3\Lab Glia\Video-EEG monitoring\NRU\NRU03 converted\'; snlTemplate = '*.smrx';
 snlp = '\\neurodata3\Lab Neuro Ephys\Video-EEG monitoring 2023\NRD\NRD03 converted\'; snlTemplate = '*.smrx';

% Other
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\CO006701\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\JK003911\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002288\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002287\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002390\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET430\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET490\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET929\';
% snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET534\';

%% Label
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\CO006701\LabelConcatenated\___CO006701-250911_103720-dec-lbl3---CO006701-251120_162217-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\JK003911\LabelConcatenated\___JK003911-241220_193039-dec-lbl3---JK003911-250315_012233-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002288\LabelConcatenated\___BH002288-240425_172340-dec-lbl3---BH002288-240515_104006-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002287\LabelConcatenated\___BH002287-240425_172340-dec-lbl3---BH002287-240515_093959-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002390\LabelConcatenated\___BH002390-240613_104701-lbl3---BH002390-240803_174448-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET430\LabelConcatenated\___Moni ET 430-210604_120220-INTN-250HZ-001-lbl3---Moni ET 430-210804_001757-INTN-250HZ-002-lbl3.mat'
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET490\LabelConcatenated\___Moni ET 490-220502_135628-INTN-250HZ-001-lbl3---Moni ET 490-220709_034133-INTN-250HZ-005-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET929\LabelConcatenated\___MoniET929-221009_185106-dec-lbl3---MoniET929-221219_095136-dec-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET534\LabelConcatenated\___Moni ET 534-210801_084511-INTN-250HZ-001-lbl3---Moni ET 534-210927_095336-INTN-250HZ-002-lbl3.mat';
% lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT II\Naty SST_TdT ET 343\labelConcatenated\___Naty SST_TdT ET 343-210421_155912-dec-lbl3---Naty SST_TdT ET 343-210425_175912-dec-lbl3.mat';
% lblpn = '\\neurodata3\Lab Glia\Glia EEG Data\BH003593\BH003593_labeConcatenated\___BH003593-240910_115818-dec-lbl3---BH003593-241002_095205-dec-lbl3.mat';
% lblpn = '\\neurodata3\Lab Glia\Glia EEG Data\BH002390\BH002390_labeConcatenated\___BH002390-240613_104701-dec-lbl3---BH002390-240821_153117-dec-lbl3.mat';
lblpn = '\\neurodata\Lab Neurophysiology root\EEG conversion\MK001791\label MisConcatenated\___MK001791-240307_084405-dec-lbl3---MK001791-240513_071206-dec-lbl3.mat';

%% Save extracted
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\CO006701\Extracted seizures orig fs\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\JK003911\Extracted seizures orig fs\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002288\Extracted seizures\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002287\Extracted seizures\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\BH002390\Extracted seizures\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET430\Extracted seizures orig fs\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET490\Extracted seizures\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET929\Extracted seizures\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MoniET534\Extracted seizures\';
% savep = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT II\Naty SST_TdT ET 343\Extracted seizures orig fs\';
% savep = '\\neurodata3\Lab Glia\Glia EEG Data\BH002390\Extracted seizures orig fs\';
savep = '\\neurodata\Lab Neurophysiology root\EEG conversion\MK001791\Extracted seizures orig fs\';


load(lblpn)
% % % sigInfo
% % % lblDef
% % % lblSet
lblCl = "Seizure";
minSzSep = seconds(180);
chToExtract = ["L-", "C-"];
% % % chToExtract = ["L1-", "R1-"];
% % % chToExtract = 1 : 4; % 339
% % % chToExtract = [4 6 1 5 2]; % 283
% % % chToExtract = [4 6 1 5 2]; % 413

d = dir([snlp, snlTemplate]);
snln = {d(~[d.isdir]).name}';
snln = snln(endsWith(snln, snlTemplate(2 : end)));
snlpn = fullfile(snlp, snln);


r = cellfun(@(x) x{1}, regexp(snln, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match'), 'UniformOutput', 0); % From signal file names, get strings of date and time
snlDt = cellfun(@(x) datetime(x, 'InputFormat', 'yyMMdd_HHmmss', 'Format', 'yyMMdd_HHmmss'), r)'; % Extract the signal datetime
% % % r = cellfun(@(x) x{1}, regexp(snln, '\d+ \d+ \d+_\d+ \d+ \d+', 'match'), 'UniformOutput', 0); % From signal file names, get strings of date and time
% % % snlDt = cellfun(@(x) datetime(x, 'InputFormat', 'dd MM yy_HH mm ss', 'Format', 'yyMMdd_HHmmss'), r); % Extract the signal datetime
% % % snlDt = snlDt - hours(2);

% Sort according to the datetime
[snlDt, idx] = sort(snlDt);    % ascending by datetime
snln = snln(idx);
snlpn = snlpn(idx);

% Keep only relevant label class
lblSet = lblSet(string(lblSet.ClassName) == lblCl, :);
lblSet = sortrows(lblSet, 'Start');
lblSet = lblSet(lblSet.Value > 1, :);

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
    disp(['Extracting label ', num2str(kl, '%05.0f'), '/', num2str(size(lblSet, 1), '%05.0f')])
% % % lblSet.Start(kl)
% % % lblSet.End(kl)
    lblSt = lblSet.Start(kl) - seconds(300)
    lblEn = lblSet.End(kl) + seconds(300)
    snlFirst = find(snlDt <= lblSt, 1, 'last')
    snlLast = find(snlDt < lblEn, 1, 'last')
    if isempty(snlFirst) || isempty(snlLast)
        disp('Event number:')
        disp(kl)
        disp('Event date and time:')
        disp(lblSet.Start(kl))
        warning('_jk No valid signal found for this event.');
        continue
    end
    sigTbl = loadSignal(snlpn{snlFirst});
    if ~exist('subjNmToSearchFor', 'var')
        subjNmToSearchFor = subjNm;
    end
    sigTbl = sigTbl(contains(sigTbl.Subject, subjNmToSearchFor), :);
    chSub = NaN(numel(chToExtract), 1);
    for kch = 1 : numel(chToExtract)
        chSub(kch) = find(startsWith(sigTbl.ChName, chToExtract(kch)));
    end
    sigTbl = sigTbl(chSub, :);
    for kch = 1 : size(sigTbl, 1)
        sigTbl.SigStart(kch) = lblSt;
        sigTbl.SigEnd(kch) = lblEn;
        sigTbl.Data{kch} = NaN(1, fix(seconds(lblEn - lblSt)*sigTbl.Fs(kch))); % Prepare empty vectors
    end
    for kf = snlFirst : snlLast
        sigTbl2 = loadSignal(snlpn{kf});
        if ~exist('subjNmToSearchFor', 'var')
            subjNmToSearchFor = subjNm;
        end
        sigTbl2 = sigTbl2(contains(sigTbl2.Subject, subjNmToSearchFor), :);
        chSub = NaN(numel(chToExtract), 1);
        for kch = 1 : numel(chToExtract)
            chSub(kch) = find(startsWith(sigTbl2.ChName, chToExtract(kch)));
        end
        sigTbl2 = sigTbl2(chSub, :);
        for kch = 1 : size(sigTbl, 1)
            fs = sigTbl.Fs(kch);
            if sigTbl2.Fs(kch) ~= fs
                disp(sigTbl)
                loadedSigTbl = sigTbl2;
                disp(loadedSigTbl)
                error('_jk Fs do not agree')
            end
            % % % newStSub = max(fix(seconds(lblSt - snlDt(kf))*fs), 1); % Where to take new data
            % % % newEnSub = min(fix(seconds(lblEn - snlDt(kf))*fs), size(sigTbl2.Data{kch}, 2));
            % % % oldStSub = fix(seconds(snlDt(kf) - lblSt)*fs) + newStSub + 1; % Where to write them
            % % % oldEnSub = oldStSub + newEnSub - newStSub;
            newStSub = max(fix(seconds(lblSt - sigTbl2.SigStart(1))*fs), 1); % Where to take new data
            newEnSub = min(fix(seconds(lblEn - sigTbl2.SigStart(1))*fs), size(sigTbl2.Data{kch}, 2));
            oldStSub = fix(seconds(sigTbl2.SigStart(1) - lblSt)*fs) + newStSub + 1; % Where to write them
            oldEnSub = oldStSub + newEnSub - newStSub;

            sigTbl.Data{kch}(oldStSub : oldEnSub) = sigTbl2.Data{kch}(newStSub : newEnSub);
        end
    end
    [~, snln, ~] = fileparts(snlpn{snlFirst});
    ss = strsplit(snln, '-');
    saven = ['___', char(subjNm), '-', datestr(lblSt, 'yymmdd_HHMMSS'), '-', char(lblCl), '_val', num2str(lblSet.Value(kl)), '.mat']; %#ok<DATST>
    if ~exist(savep, 'dir')
        mkdir(savep)
    end
    save(fullfile(savep, saven), 'sigTbl');
    clear sigTbl l
end
disp(subjNm)
disp('Extracted data are in:')
disp(savep)
disp('Finished')

