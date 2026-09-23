function matDecim1

fsNew = 200;
% detCh = [];
% detCh = [7 8 9 10 11 12 13 14 15 16 23 24 25 26 27 28 29 30 31 32]; % Hipp + EC
detCh = 1:32;


[filepn, filep, filen] = getFilepnAllCell('Select mat files', 'mat')

if isa(filen, 'double')
    disp('No files selected');
    return
end

decPath = uigetdir('d:\', 'Where to put mat files');
if decPath == 0
    return
end

if ~isempty(detCh)
    detPath = uigetdir('d:\', 'Where to put OON files');
    if detPath == 0
        detCh = [];
    end
end

%% Main Loop
numFilesConverted = 0;
for kF = 1:length(filepn)
    numFilesConverted = numFilesConverted + 1;
    datetime
disp(['kF = ' num2str(kF)])
    currentfname = filepn{kF};
disp(currentfname)
    % Load data from rhd into variables
    l = load(currentfname);
    l.s = l.intScale*(double(l.s) - l.intOffset)';
%     tOrig = 0 : 1/l.fs : (length(l.s) - 1)/l.fs;
%     sOrig = l.s(:, 12);
    if l.fs > 1000
        l.s = resample(l.s, 1, l.fs/1000);
        l.fs = 1000;
    end
    l.s = resample(l.s, 1, l.fs/fsNew);
%     sNew = l.s(:, 12);
    sForDet = l.s;
    l.s = uint32(l.s/l.intScale + l.intOffset)';
    l.fs = fsNew;
    save([decPath '\' filen{kF}(1 : end-4) '-d.mat'], '-struct', 'l')
    
    %% Check plots
%     tNew = 0 : 1/l.fs : (length(l.s) - 1)/l.fs;
%     p1 = plot(tNew, sNew, 'b');
%     p1.ZData = ones(length(sNew), 1)';
%     hold on
%     p2 = plot(tOrig, sOrig, 'r');
%     p2.ZData = -ones(length(sOrig), 1)';
    
    %% Detections
    if ~isempty(detCh)
        tic
        label(1).pos = [];
        label(1).dur = [];
        label(1).chan = [];
        label(1).chanType = [];
        label(1).value = [];
        for kR = 1 : length(detCh)
            OOSAllCh{kR} = jkSeizDetFilt1(sForDet(:, detCh(kR)), l.fs); % First column onset second column offset in seconds
            label(1).name = 'jkSeizDetFilt1';
            label(1).color = '1 0 0';
            if ~isempty(OOSAllCh{kR})
                label(1).pos = [label(1).pos, OOSAllCh{kR}(:, 1)'];
                label(1).dur = [label(1).dur, OOSAllCh{kR}(:, 2)' - OOSAllCh{kR}(:, 1)'];
                label(1).chan = [label(1).chan, detCh(kR)*ones(1, size(OOSAllCh{kR}, 1))];
                label(1).chanType = [label(1).chanType, ones(1, size(OOSAllCh{kR}, 1))];
                label(1).value = [label(1).value, ones(1, size(OOSAllCh{kR}, 1))];
            end
            save([decPath '\' filen{kF}(1 : end-4) '-d.mat'], 'label', '-append')
        end
        % Get total seizure duration across all channels
        seizAS = []; % All seizure detections regardless of channel in one column, in seconds
        for r = 1 : length(detCh)
            % Left column - time of event, right column onset (1) or ending (-1)
            if ~isempty(OOSAllCh{r})
                seizAS = [seizAS;...
                      OOSAllCh{r}(:,1) ones(length(OOSAllCh{r}(:,1)), 1);...
                      OOSAllCh{r}(:,2) -ones(length(OOSAllCh{r}(:,2)), 1)]; %#ok<AGROW>
            end
        end
        if ~isempty(seizAS)
            seizASortS = sortrows(seizAS, 1);
            seizOnOff = diff([0; sign(cumsum(seizASortS(:,2)))]);
            % Left column onset, right column offset of the seizure
            OOS = [seizASortS(seizOnOff == 1, 1), seizASortS(seizOnOff == -1, 1)]; % Result
            OON = l.dateN + OOS/24/3600; %#ok<NASGU>
        else
            OON = [];
        end
        save([detPath '\' filen{kF} '-OON.mat'], 'OON')
        
        
    end
    clear l OOS OON seizAS
    toc
end

disp([10 'Conversion finished. ' num2str(numFilesConverted)...
    ' files were converted.' 10 'Source rhd-files are in folder ' filep 10 ...
    'Output mat-files are in folder ' decPath])
end




function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
[filen, filep] = uigetfile(['d:\*.' ext], prompt, 'MultiSelect', 'on');
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
% % % 
% % % function label = OON2Lab1(OON, labelTypeNames, labelColors)
% % % for kLT = 1 : length(labelTypeNames)
% % %     label(kLT).name = labelTypeNames{kLT};
% % %     if ~isempty(OON{kLT})
% % %         label(kLT).pos = OON{kLT}(:, 1);
% % %         label(kLT).dur = OON{kLT}(:, 2) - OON{kLT}(:, 1);
% % %     else
% % %         label(kLT).pos = zeros(0, 1);
% % %         label(kLT).dur = zeros(0, 1);
% % %     end
% % %     label(kLT).chan = ones(size(OON{kLT}, 1), 1);
% % %     label(kLT).chanType = ones(size(OON{kLT}, 1), 1);
% % %     label(kLT).value = ones(size(OON{kLT}, 1), 1);
% % %     label(kLT).color = labelColors{kLT};
% % %     assignin('base', 'label', label)
% % % end
% % % end