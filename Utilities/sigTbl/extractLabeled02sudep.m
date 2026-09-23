% function extractLabeled02sudep
    [lblpn, ~, lbln] = getFilepnAllCell('Select label files', 'mat');
    snlp = getPath('Where look for signal files');
    savep = getPath('Where to save extracted signal');
% lblp = 'R:\SUDEP\Jan testing\2023_08_21\label\';
% d = dir([lblp, '*-lbl3.mat']);
% lbln = {d.name};
% lblpn = fullfile(lblp, lbln)';
% snlp = 'n:\EEG conversion\bk_20230816 OLD\';
% savep = 'n:\EEG conversion\bk_20230816 OLD\Extracted seizures';

marginStartS = 5; % Left margin added to the label in seconds (i.e. subtracted from the Start)
marginEndS = 10; % Right margin added to the label in seconds (i.e. added to the End)
    
    % hwb = waitbar(0, 'Extracting labeled signal...');
    % now000 = now;
    % nTimeEst = 20;
    % timeToAllM = 1;
    for kf = 1 : length(lblpn)
        kf
        % %% Display progress
        % waitbar(kf/length(filepn), hwb, ['Renaming labels, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        % if kf == nTimeEst
        %     nowTimeEst = now;
        %     timeToTimeEst = nowTimeEst - now000;
        %     timeToAllM = timeToTimeEst*length(filepn)/nTimeEst*24*60;
        %     waitbar(kf/length(filepn), hwb, ['Renaming labels, ', num2str(timeToAllM*(1 - kf/length(filepn))), ' minutes remaining...'])
        % end
        
        load(lblpn{kf})
        snlpn = findCorrespondingSig(lblpn{kf}, snlp);
        load(snlpn)
        sigTblOrig = sigTbl; % Create a copy

        % Check if the dates in the lbl and snl files agree
        if any(sigInfo.SigStart ~= sigTblOrig.SigStart)
            lblpn{kf}
            sigInfo.SigStart
            snlpn
            sigTblOrig.SigStart
            error('_jk Different SigStart')
        end
        
        for kl = 1 : size(lblSet, 1) % Over individual labels
            stS = seconds(lblSet.Start(kl) - sigTbl.SigStart(lblSet.Channel(kl))); % Start in seconds
            stS = stS - marginStartS;
            enS = seconds(lblSet.End(kl) - sigTbl.SigStart(lblSet.Channel(kl))); % Start in seconds
            enS = enS + marginEndS;
            for kch = 1 : size(sigTblOrig, 1)
                st = stS*sigTbl.Fs(kch); % Start in samples
                en = enS*sigTbl.Fs(kch); % End in samples
                sigTbl.SigStart(kch) = sigTblOrig.SigStart(kch) + seconds(stS);
                sigTbl.SigEnd(kch) = sigTblOrig.SigStart(kch) + seconds(enS);
                sigTbl.Data{kch} = sigTblOrig.Data{kch}(fix(st) + 1 : fix(en));
            end
            dateStr = datestr(sigTbl.SigStart(1), 'yymmdd_HHMMSS');
            snln = [char(sigTbl.Subject(1)), '-' dateStr, '-ExtractedSz.mat']; 
            savepn = fullfile(savep, snln);
            save(savepn, 'sigTbl')
            % clear sigTbl sigTblOrig sigInfo lblDef slblSet
        end
        clear sigTbl sigTblOrig sigInfo lblDef slblSet
    end
    % delete(hwb)
    disp('Finished')
% end


%% %%%%%%%%% %%
%% FUNCTIONS %%
%% %%%%%%%%% %%
function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
    loadpath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
    if exist('startpath.mat', 'file')
        load('startpath.mat', 'loadpath');
    end
    [filen, filep] = uigetfile([loadpath '\*.' ext], prompt, 'MultiSelect', 'on');
    if ischar(filep)
        loadpath = filep;
        if exist('startpath.mat', 'file')
            save('startpath.mat', 'loadpath', '-append');
        else
            save('startpath.mat', 'loadpath');
        end
    end
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
end
function pth = getPath(prompt)
    savepath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
    if exist('startpath.mat', 'file')
        load('startpath.mat'); %#ok<LOAD>
    end
    pth = uigetdir(savepath, prompt);
    if ischar(pth)
        savepath = pth;
        save('startpath.mat', 'savepath', '-append');
    end
end
function snlpn = findCorrespondingSig(filepn, snlp)
    pattern = regexp(filepn, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
%     pattern = regexp(filepn, '_\d\d\d.smr', 'match');
    % pattern = [fileNum, '.smr'];
    % d = dir([snlp, '/*.smr*']);
    d = dir([snlp, '/*.mat']);
    d = d(~[d.isdir]);
    snlnAll = {d.name}';
    snln = snlnAll{contains(snlnAll, pattern)};
    snlpn = fullfile(snlp, snln);
end













































% 
% 
% 
% % filep = 'N:\EEG conversion\MisaET3025\label nejedly test 03';
% % snlp = '\\neurodata\Lab Neurophysiology root\EEG conversion ORIG FS\NatySST_TdTET339\';
% % snlp = 'n:\EEG conversion ORIG FS\NatymTORET283\';
% % snlp = 'n:\EEG conversion ORIG FS\NatySST_TdTET343\';
% % snlp = 'n:\EEG conversion ORIG FS\NatySST_TdTET413\';
% snlp = 'n:\EEG conversion\bk_20230816 OLD\';
% % d = dir(filep);
% % filen = d(end).name;
% % filepn = fullfile(filep, filen);
% % lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Dead mice\mTOR MUT\NatySST_TdTET339\Labels Kudlajda\___NatySST_TdTET339-210312_223552-dec-lbl3---NatySST_TdTET339-210319_183602-dec-lbl3.mat';
% % lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Dead mice\mTOR MUT\NatySST_TdTET339\Labels Kudlajda\___NatySST_TdTET339-210324_224616-dec-lbl3---NatySST_TdTET339-210401_082207-dec-lbl3.mat';
% % lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT\NatymTORET283\Labels Kudlajda concatenated\___NatymTORET283-210125_142536-dec-lbl3---NatymTORET283-210130_183349-dec-lbl3.mat';
% % lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT\NatymTORET283\Labels Kudlajda concatenated\___NatymTORET283-210201_121547-dec-lbl3---NatymTORET283-210304_235955-dec-lbl3.mat';
% % lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\Hotove\mTOR MUT\NatymTORET283\Labels Kudlajda concatenated\___NatymTORET283-210305_015955-dec-lbl3---NatymTORET283-210305_155956-dec-lbl3.mat';
% % lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\mTOR MUT\Naty SST_TdT ET 343\label Kudlajda concatenated\___Naty SST_TdT ET 343-210421_175912-dec-lbl3---Naty SST_TdT ET 343-210425_175912-dec-lbl3.mat';
% % lblpn = '\\neurodata\Lab Neurophysiology root\EEG Naty\mTOR MUT\Naty SST_TdT ET 413\Labels Kudlajda concatenated\___Naty SST_TdT ET 413-210415_165632-dec-lbl3---Naty SST_TdT ET 413-210426_223728-dec-lbl3.mat';
% lblpn = 'r:\SUDEP\Jan testing\2023_08_21\label\';
% % savep = 'n:\EEG conversion ORIG FS\ET283Sz';
% savep = 'n:\EEG conversion\bk_20230816 OLD\Extracted seizures\';
% 
% 
% load(lblpn);
% lblCl = "Seizure";
% minSzSep = seconds(180);
% % chToExtract = 1 : 5; % 339
% % chToExtract = [4 6 1 5 2]; % 283
% chToExtract = [4 6 1 5 2]; % 413
% 
% d = dir(snlp);
% snln = {d(~[d.isdir]).name};
% snlpn = fullfile(snlp, snln);
% 
% r = cellfun(@(x) x{1}, regexp(snln, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match'), 'UniformOutput', 0); % From signal file names, get strings of date and time
% snlDt = cellfun(@(x) datetime(x, 'InputFormat', 'yyMMdd_HHmmss', 'Format', 'yyMMdd_HHmmss'), r)'; % Extract the signal datetime
% 
% % Keep only relevant label class
% lblSet = lblSet(string(lblSet.ClassName) == lblCl, :);
% lblSet = sortrows(lblSet, 'Start');
% 
% % Remove duplicit labels (even if they were in different channels)
% lblSet(diff(lblSet.Start) < seconds(0.1), :) = [];
% 
% % Check if duration is positive
% if any(lblSet.End - lblSet.Start < 0)
% %     disp(lblSet)
% %     disp(lblSet.End - lblSet.Start)
%     % If the duration is negative, swap Start and End
%     lblSet(lblSet.End - lblSet.Start < 0, [3 4]) = fliplr(lblSet(lblSet.End - lblSet.Start < 0, [3 4]));
%     warning('_jk Negative seizure duration. Swapped Start and End in those labels.')
% end
% 
% % Remove labels with too short interval before them
% bsi = lblSet.Start(2 : end) - lblSet.End(1 : end - 1); % Between seizure interval
% lblSet.End([bsi < minSzSep; false]) = lblSet.End([false; bsi < minSzSep]); % In those, who have too short BSI after them, copy the End of the next label to their End.
% lblSet([false; bsi < minSzSep], :) = [];
% 
% for kl = 1 : size(lblSet, 1)
%     disp(['Extracting label ', num2str(kl)])
% % % % lblSet.Start(kl)
% % % % lblSet.End(kl)
%     lblSt = lblSet.Start(kl) - seconds(10)
%     lblEn = lblSet.End(kl) + seconds(10);
% % % % lblSt.Format = 'yyMMdd_HHmmss';
% % % % lblSt
% % % % lblEn.Format = 'yyMMdd_HHmmss';
% % % % lblEn
% 
% % % % % lblSt.Format = 'yyMMdd_HHmmss';
% % % % % lblSt
% 
%     snlFirst = find(snlDt <= lblSt, 1, 'last')
% 
% % % % % snlDt(snlFirst)
%     snlLast = find(snlDt < lblEn, 1, 'last');
% 
% 
% % % % snlpn{snlFirst}
%     l = load(snlpn{snlFirst});
%     chToExtract = 1 : size(l.sigTbl, 1);
%     sigTbl = l.sigTbl; % This will be the basis
%     sigTbl = sigTbl(chToExtract, :);
%     for kch = 1 : size(sigTbl, 1)
%         sigTbl.SigStart(kch) = lblSt;
%         sigTbl.SigEnd(kch) = lblEn;
%         sigTbl.Data{kch} = NaN(1, fix(seconds(lblEn - lblSt)*sigTbl.Fs(kch))); % Prepare empty vectors
%     end
%     for kf = snlFirst : snlLast
%         l = load(snlpn{kf});
%         l.sigTbl = l.sigTbl(chToExtract, :);
%         for kch = 1 : size(sigTbl, 1)
%             fs = sigTbl.Fs(kch);
%             if l.sigTbl.Fs(kch) ~= fs
%                 disp(sigTbl)
%                 loadedSigTbl = l.sigTbl;
%                 disp(loadedSigTbl)
%                 error('_jk Fs do not agree')
%             end
%             if l.sigTbl.ChName(kch) ~= sigTbl.ChName(kch)
%                 disp(sigTbl)
%                 loadedSigTbl = l.sigTbl;
%                 disp(loadedSigTbl)
%                 error('_jk Channels do not agree')
%             end
%             newStSub = max(fix(seconds(lblSt - snlDt(kf))*fs), 1); % Where to take new data
%             newEnSub = min(fix(seconds(lblEn - snlDt(kf))*fs), size(l.sigTbl.Data{kch}, 2));
%             oldStSub = fix(seconds(snlDt(kf) - lblSt)*fs) + newStSub + 1; % Where to write them
%             oldEnSub = oldStSub + newEnSub - newStSub;
%             sigTbl.Data{kch}(oldStSub : oldEnSub) = l.sigTbl.Data{kch}(newStSub : newEnSub);
%         end
%     end
% 
% 
% % % % figure
% % % % plot(sigTbl.Data{1})
% % % % title(num2str(kl))
% % % % pause
% 
%     [~, snln, savee] = fileparts(snlpn{snlFirst});
%     ss = strsplit(snln, '-');
% 
%     saven = ['___', ss{1}, '-', datestr(lblSt, 'yymmdd_HHMMSS'), '-', ss{3}, '-', char(lblCl), savee];
%     save(fullfile(savep, saven), 'sigTbl');
%     clear sigTbl l
% end
% 
% 
% 
% 
% disp('Finished')
% 
% 
% 
% 
