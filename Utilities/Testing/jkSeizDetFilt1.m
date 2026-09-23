function markers_out = jkSeizDetFilt1(EEG_signal, fs)
% % % % peakAmpMult = 10; % How many times the peak must be higher than mode
% peakMinD = 0.02; % Peaks' minimal distance
% % % % lenCountFilt = 5; % Length of FIR counting similar periods
% maxPer = 1;
minSeizDur1 = 3;
minSeizSep = 10;
minSeizDur2 = 5; % In seconds

fsd = 200;
df = fs/fsd; % decimation factor
EEG_Selection = resample(EEG_signal, 1, df);
lSigD = length(EEG_Selection);
% EEG_Selection = resample(EEG_signal(0.00001e7:1.79999e7), 1, df);
% EEG_Selection = resample(EEG_signal(1.267e7:1.272999e7), 1, df);

%% preprocessing
% tic

thMult = 3;

fLow = 15;
fHigh = 35;

% % % % % [b, a] = butter(4, 1*2/fsd, 'high');
[b, a] = butter(3, [fLow*2/fsd, fHigh*2/fsd]);
% % % % % freqz(b, a, 20000, fs)

% EEG_filtAbs = sqrt(abs(filter(b, a, EEG_Selection)));

EEG_filtAbs = abs(filter(b, a, EEG_Selection));


[bl, al] = butter(3, 0.2*2/fsd, 'low');
EEGAbsLPF = filtfilt(bl, al, EEG_filtAbs);

[bTh, aTh] = butter(3, 0.02*2/fsd, 'low');
EEGThLPF = filtfilt(bTh, aTh, EEG_filtAbs);
EEGThLPFRound = round(EEGThLPF/max(EEGThLPF)*200)/200*max(EEGThLPF);

th = thMult*mode(EEGThLPFRound);

seizDet = EEGAbsLPF > th;
% seizOn = find(diff(seizDet == 1) == 1);
% seizOff = find(diff(seizDet == 1) == -1);
seizOn = find(diff([false; seizDet]) == 1);
seizOff = find(diff([seizDet; false]) == -1);
pocetZacatkuSeRovnaPocetKoncu = length(seizOn) == length(seizOff);
% seizOn
% seizOff


pocetZacatkuSeRovnaPocetKoncu = length(seizOn) == length(seizOff);
if ~pocetZacatkuSeRovnaPocetKoncu
    error('jk Pocet zacatku se nerovna pocet koncu')
end

% Remove short events
lSeizOn = length(seizOn);
k = 0;
while k < lSeizOn
    k = k + 1;
    if seizOff(k) - seizOn(k) < minSeizDur1*fsd
        seizOff(k) = [];
        seizOn(k) = [];
        lSeizOn = lSeizOn - 1;
        k = k - 1;
    end
end



% Join seizures that are close together
lSeizOn = length(seizOn);
k = 0;
while k < lSeizOn - 1
    k = k + 1;
    if seizOn(k + 1) - seizOff(k) < minSeizSep*fsd
        seizOff(k) = [];
        seizOn(k+1) = [];
        lSeizOn = lSeizOn - 1;
        k = k - 1;
    end
end




% Remove short seizures
lSeizOn = length(seizOn);
k = 0;
while k < lSeizOn
    k = k + 1;
    if seizOff(k) - seizOn(k) < minSeizDur2*fsd
        seizOff(k) = [];
        seizOn(k) = [];
        lSeizOn = lSeizOn - 1;
        k = k - 1;
    end
end





% toc
% 
figure(18)
subplot(211)
plot(EEG_Selection)
hold on
plot([seizOn seizOn]', 3.5*[-ones(length(seizOn), 1) ones(length(seizOn), 1)]', 'g')
plot([seizOff seizOff]', 3.5*[-ones(length(seizOff), 1) ones(length(seizOff), 1)]', 'r')
hold off
% xlim([0 4.5e5])

% subplot(212)
% plot(EEG_filtAbs)

subplot(212)
plot(EEGAbsLPF)
hold on
% plot([0 length(EEGAbsLPF)], thMult*[mean(EEGAbsLPF) mean(EEGAbsLPF)], 'r')
plot([0 length(EEGAbsLPF)], [th th], 'g')
hold off
% plot([seizOn seizOn]', 0.1*[-ones(length(seizOn), 1) ones(length(seizOn), 1)]', 'g')
% ylim([0 0.2])
% 
% % EEGAbsTrend = round(EEGAbsTrend/max(EEGAbsTrend)*50)/50*max(EEGAbsTrend);
% % modeEEG = mode(EEGAbsTrend);
% 
% % figure
% % spectrogram(EEG_Selection, 250, [], [], 250, 'yaxis')

pocetZacatkuSeRovnaPocetKoncu = length(seizOn) == length(seizOff);
if ~pocetZacatkuSeRovnaPocetKoncu
    error('jk Pocet zacatku se nerovna pocet koncu')
end

regLocSE = [seizOn seizOff]/fsd;
markers_out = regLocSE;
return





















% % % % % subplot(411)
% % % % % subplot(412)
% % % % % plot(filter(bl, al, EEG_signal))
% % % % % subplot(412)
% % % % % plot(EEGAbsTrend)
% % % % 
% % % % % 
% % % % % absEEG = abs(EEG_Selection);
% % % % % absEEG = filtfilt(b, a, absEEG);
% % % % % subplot(412)
% % % % % plot(absEEG)

% [peaks, locs] = findpeaks(EEG_Selection, 'MINPEAKHEIGHT', peakAmpMult*modeEEG, 'MINPEAKDISTANCE', peakMinD*fsd);
% % % subplot(411)
% % % hold on
% % % scatter(locs, peaks, 'm')
% % % hold off

% insP = diff(locs); % Instant period
% locsP = locs(1:end-1);
% % % subplot(412)
% % % stem(locsP, insP)
% % % xlim([0, lSigD])


% shortIntI = insP < maxPer*fsd; % Indices of periods shorter than maxPer
% insP = insP(shortIntI);
% locsP = locsP(shortIntI);

% dInsP = diff(insP);
% regulLocs = locsP(2:end);
% % % subplot(413)
% % % stem(regulLocs, dInsP)
% % % xlim([0, lSigD])

% % % % % insP(1:end-1)*tolSimilarPer
% if ~isempty(dInsP)
%     regul = abs(dInsP) < min(insP(1:end-1)*tolSimilarPer, 0.2*fsd); % One if periods were similar
% else
%     markers_out = [];
%     return
% end
% % % % % regul = abs(dInsP) < (0.1*fsd); % One if periods were similar
% % % % % subplot(413)
% % % % % stem(regulLocs, regul)


% numRegul = filter(ones(1, lenCountFilt), 1, regul);
% % % subplot(414)
% % % stem(regulLocs, numRegul)
% % % xlim([0, lSigD])


% % % % % locsShort = locs(2:end-1);
% regularI = numRegul == lenCountFilt;
% regularI = logical([regularI(lenCountFilt-1 : end); zeros(lenCountFilt-2, 1)]); % One if at that loc the peaks are regular
% regularityLoc = regulLocs(regularI); % Locations of regularity
% regLocSE = [regularityLoc - seizTimeTol*fsd, regularityLoc + seizTimeTol*fsd]; % Start End
% k = 1;
% while k < size(regLocSE, 1)
%     if regLocSE(k + 1, 1) < regLocSE(k, 2)
%         regLocSE(k, 2) = regLocSE(k + 1, 2);
%         regLocSE(k + 1, :) = [];
%     else
%         k = k + 1;
%     end
% end
% 
% % % subplot(411)
% % % hold on
% % % stem(regLocSE(:,1), ones(length(regLocSE(:,1)), 1), 'r')
% % % stem(regLocSE(:,2), -ones(length(regLocSE(:,1)), 1), 'r')
% % % hold off
% % % xlim([0, lSigD])

% pause(1)

% regLocSE = regLocSE/fsd;


% % % % % % % 
% % % % % % % 
% % % % % % % % ze = zeros(length(EEG_Selection), 1);
% % % % % % % % ze(fix(locs)) = peaks;
% % % % % % % % subplot(414)
% % % % % % % % plot(ze)
% % % % % % % 
% % % % % % % % % % figure
% % % % % % % % spectrogram(ze, 2048, 'yaxis') 
% % % % % % % 
% % % % % % % % 'hilbert'
% % % % % % % % tic
% % % % % % % % EEGHilb = hilbert(EEG_Selection);
% % % % % % % % absEEGHilb = abs(EEGHilb);
% % % % % % % % toc
% % % % % % % % figure
% % % % % % % % % plot3(1:length(EEGHilb), real(EEGHilb), imag(EEGHilb))
% % % % % % % % % subplot(413)
% % % % % % % % plot(absEEGHilb)
% % % % % % % % EEGHilbHilb = hilbert(absEEGHilb);
% % % % % % % % absEEGHilbHilb = abs(EEGHilbHilb);
% % % % % % % % % subplot(414)
% % % % % % % % plot(absEEGHilbHilb)
% % % % % % % % 

