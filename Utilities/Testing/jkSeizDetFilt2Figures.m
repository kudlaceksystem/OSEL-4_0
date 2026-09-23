function markers_out = jkSeizDetFilt2Figures(EEG_signal, fs, fgr)

%% Settings
minSeizDur1 = 1;
minSeizSep = 10;
minSeizDur2 = 5; % In seconds
fsd = 200;

thMult = 3;

fLow = 12;
fHigh = 35;

fEnvelope = 0.3;
nbins = 50;

%% preprocessing
s = EEG_signal;
if fs > 1000
    s = resample(s, 1, fs/1000);
    fs = 1000;
end
s = resample(s, 1, fs/fsd);

t = 0 : 1/fsd : (length(s) - 1)/fsd;

%% Filter
% [sb, sa] = butter(4, [fLow*2/fsd, fHigh*2/fsd]); % Signal filter
Nfir = 64;
sa = 1;
sb = fir1(Nfir,[fLow*2/fsd, fHigh*2/fsd]);

sFilt = filter(sb, sa, [s;zeros(ceil(Nfir/2), 1)]);
sFilt = sFilt(ceil(Nfir/2) + 1 : end); 
sFiltAbs = abs(sFilt);

%% Envelope
[eb, ea] = butter(4, fEnvelope*2/fsd, 'low'); % Envelope filter
sEnv = filtfilt(eb, ea, sFiltAbs);

%% Threshold
envRound = round(sEnv/max(sEnv)*nbins)/nbins*max(sEnv);
th = thMult*mode(envRound);

%% Thresholding
seizDet = sEnv > th;
seizOn = find(diff([false; seizDet]) == 1);
seizOff = find(diff([seizDet; false]) == -1);

pocetZacatkuSeRovnaPocetKoncu = length(seizOn) == length(seizOff);
if ~pocetZacatkuSeRovnaPocetKoncu
    error('jk Pocet zacatku se nerovna pocet koncu')
end

%% Detection strategy
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




% 
% % toc
% % 
% figure
% subplot(211)
% plot(s)
% hold on
% plot([seizOn seizOn]', 3.5*[-ones(length(seizOn), 1) ones(length(seizOn), 1)]', 'g')
% plot([seizOff seizOff]', 3.5*[-ones(length(seizOff), 1) ones(length(seizOff), 1)]', 'r')
% hold off
% % xlim([0 4.5e5])
% 
% % subplot(212)
% % plot(EEG_filtAbs)
% 
% subplot(212)
% plot(EEGAbsLPF)
% hold on
% % plot([0 length(EEGAbsLPF)], thMult*[mean(EEGAbsLPF) mean(EEGAbsLPF)], 'r')
% plot([0 length(EEGAbsLPF)], [th th], 'g')
% hold off
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

markers_out = [seizOn seizOff]/fsd;





% % % % %% Plots for prof. Vlcek
% % % % figure
% % % % histogram(envRound, nbins)
% % % % saveas(gcf, ['Histogram ' num2str(fgr) '.eps']);
% % % % 
% % % % nr = 3;
% % % % nc = 1;
% % % % figure(fgr + 1)
% % % % subplot(nr, nc, 1)
% % % % plot(t, s)
% % % % resP
% % % % ylim([-max(abs(s)) max(abs(s))]);
% % % % 
% % % % subplot(nr, nc, 2)
% % % % plot(t, sFilt)
% % % % resP
% % % % ylim([-max(abs(sFilt)) max(abs(sFilt))]);
% % % % 
% % % % subplot(nr, nc, 3)
% % % % plot(t, sFiltAbs)
% % % % resP
% % % % ylim([0 max(abs(sFiltAbs))]);
% % % % drawnow % Required to avoid Java errors
% % % % jF1 = get(gcf, 'JavaFrame'); 
% % % % jF1.setMaximized(true);
% % % % % saveas(gcf, ['FltDet ' num2str(fgr + 1) '.eps']);
% % % % saveas(gcf, ['FltDet ' num2str(fgr + 1) '.jpg']);
% % % % 
% % % % 
% % % % nr = 3;
% % % % nc = 1;
% % % % figure(fgr + 2)
% % % % subplot(nr, nc, 1)
% % % % plot(t, sFiltAbs)
% % % % resP
% % % % ylim([0 max(abs(sFiltAbs))]);
% % % % 
% % % % subplot(nr, nc, 2)
% % % % plot(t, sEnv)
% % % % resP
% % % % ylim([0 max(abs(sEnv))]);
% % % % 
% % % % subplot(nr, nc, 3)
% % % % plot(t, envRound)
% % % % resP
% % % % ylim([0 max(abs(envRound))]);
% % % % drawnow % Required to avoid Java errors
% % % % jF1 = get(gcf, 'JavaFrame'); 
% % % % jF1.setMaximized(true);
% % % % % saveas(gcf, ['FltDet ' num2str(fgr + 2) '.eps']);
% % % % saveas(gcf, ['FltDet ' num2str(fgr + 2) '.jpg']);
% % % % 
% % % % 
% % % % %% Selection
% % % % st = 95201;
% % % % en = 102000;
% % % % 
% % % % nr = 3;
% % % % nc = 1;
% % % % hf3 = figure(fgr + 3)
% % % % subplot(nr, nc, 1)
% % % % plot(t(st : en), s(st : en))
% % % % resP
% % % % ylim([-max(abs(s)) max(abs(s))]);
% % % % xlim([st/fsd, en/fsd]);
% % % % 
% % % % subplot(nr, nc, 2)
% % % % plot(t(st : en), sFilt(st : en))
% % % % resP
% % % % ylim([-max(abs(sFilt)) max(abs(sFilt))]);
% % % % xlim([st/fsd, en/fsd]);
% % % % 
% % % % subplot(nr, nc, 3)
% % % % plot(t(st : en), sFiltAbs(st : en))
% % % % resP
% % % % ylim([0 max(abs(sFiltAbs))]);
% % % % xlim([st/fsd, en/fsd]);
% % % % drawnow % Required to avoid Java errors
% % % % jF1 = get(gcf, 'JavaFrame'); 
% % % % jF1.setMaximized(true);
% % % % % saveas(gcf, ['FltDet ' num2str(fgr + 3) '.eps']);
% % % % saveas(gcf, ['FltDet ' num2str(fgr + 3) '.jpg']);
% % % % 
% % % % 
% % % % nr = 3;
% % % % nc = 1;
% % % % figure(fgr + 4)
% % % % subplot(nr, nc, 1)
% % % % plot(t(st : en), sFiltAbs(st : en))
% % % % resP
% % % % ylim([0 max(abs(sFiltAbs))]);
% % % % xlim([st/fsd, en/fsd]);
% % % % 
% % % % subplot(nr, nc, 2)
% % % % plot(t(st : en), sEnv(st : en))
% % % % resP
% % % % ylim([0 max(abs(sEnv))]);
% % % % xlim([st/fsd, en/fsd]);
% % % % 
% % % % subplot(nr, nc, 3)
% % % % plot(t(st : en), envRound(st : en))
% % % % resP
% % % % ylim([0 max(abs(envRound))]);
% % % % xlim([st/fsd, en/fsd]);
% % % % drawnow % Required to avoid Java errors
% % % % jF1 = get(gcf, 'JavaFrame'); 
% % % % jF1.setMaximized(true);
% % % % % saveas(gcf, ['FltDet ' num2str(fgr + 4) '.eps']);
% % % % saveas(gcf, ['FltDet ' num2str(fgr + 4) '.jpg']);
% % % 

% %% Plots for prof. Vlcek
% figure
% histogram(envRound, nbins)
% saveas(gcf, ['Histogram ' num2str(fgr) '.eps']);
% 
% nr = 4;
% nc = 1;
% figure(fgr + 1)
% subplot(nr, nc, 1)
% plot(t, s)
% resP
% ylim([-max(abs(s)) max(abs(s))]);
% 
% subplot(nr, nc, 2)
% plot(t, sFilt)
% resP
% ylim([-max(abs(sFilt)) max(abs(sFilt))]);
% 
% subplot(nr, nc, 3)
% plot(t, sFiltAbs)
% resP
% ylim([0 max(abs(sFiltAbs))]);
% drawnow % Required to avoid Java errors
% jF1 = get(gcf, 'JavaFrame'); 
% jF1.setMaximized(true);
% 
% subplot(nr, nc, 4)
% plot(t, sEnv)
% resP
% hold on
% plot([min(t), max(t)], [th th], 'r', 'LineWidth', 2)
% ylim([0 max(abs(sEnv))]);
% % saveas(gcf, ['FltDet ' num2str(fgr + 1) '.eps']);
% saveas(gcf, ['FltDet ' num2str(fgr + 1) '.jpg']);
% 
% 
% 
% nr = 3;
% nc = 1;
% figure(fgr + 2)
% subplot(nr, nc, 1)
% histogram(envRound, nbins)
% % plot(t, sEnv)
% % resP
% % ylim([0 max(abs(sEnv))]);
% % 
% subplot(nr, nc, 2)
% plot(t, envRound)
% hold on
% plot([min(t), max(t)], [th/3 th/3], 'g', 'LineWidth', 2)
% plot([min(t), max(t)], [th th], 'r', 'LineWidth', 2)
% resP
% ylim([0 max(abs(envRound))]);
% 
% subplot(nr, nc, 3)
% plot(t, sEnv)
% hold on
% plot([min(t), max(t)], [th th], 'r', 'LineWidth', 2)
% resP
% ylim([0 max(abs(sEnv))]);
% drawnow % Required to avoid Java errors
% jF1 = get(gcf, 'JavaFrame'); 
% jF1.setMaximized(true);
% % saveas(gcf, ['FltDet ' num2str(fgr + 2) '.eps']);
% saveas(gcf, ['FltDet ' num2str(fgr + 2) '.jpg']);
% 
% 
% %% Selection
% st = 95301;
% en = 101000;
% 
% nr = 4;
% nc = 1;
% hf3 = figure(fgr + 3)
% subplot(nr, nc, 1)
% plot(t(st : en), s(st : en))
% resP
% ylim([-max(abs(s)) max(abs(s))]);
% xlim([st/fsd, en/fsd]);
% 
% subplot(nr, nc, 2)
% plot(t(st : en), sFilt(st : en))
% resP
% ylim([-max(abs(sFilt)) max(abs(sFilt))]);
% xlim([st/fsd, en/fsd]);
% 
% subplot(nr, nc, 3)
% plot(t(st : en), sFiltAbs(st : en))
% resP
% ylim([0 max(abs(sFiltAbs))]);
% xlim([st/fsd, en/fsd]);
% 
% subplot(nr, nc, 4)
% plot(t(st : en), sEnv(st : en))
% resP
% hold on
% plot([min(t), max(t)], [th th], 'r', 'LineWidth', 2)
% ylim([0 max(abs(sEnv))]);
% xlim([st/fsd, en/fsd]);
% drawnow % Required to avoid Java errors
% jF1 = get(gcf, 'JavaFrame'); 
% jF1.setMaximized(true);
% % saveas(gcf, ['FltDet ' num2str(fgr + 3) '.eps']);
% saveas(gcf, ['FltDet ' num2str(fgr + 3) '.jpg']);
% 
% 
% nr = 3;
% nc = 1;
% figure(fgr + 4)
% subplot(nr, nc, 1)
% histogram(envRound, nbins)
% % plot(t(st : en), sEnv(st : en))
% % resP
% % ylim([0 max(abs(sEnv))]);
% % xlim([st/fsd, en/fsd]);
% 
% subplot(nr, nc, 2)
% plot(t(st : en), envRound(st : en))
% resP
% hold on
% plot([min(t), max(t)], [th/3 th/3], 'g', 'LineWidth', 2)
% plot([min(t), max(t)], [th th], 'r', 'LineWidth', 2)
% ylim([0 max(abs(envRound))]);
% xlim([st/fsd, en/fsd]);
% 
% subplot(nr, nc, 3)
% plot(t(st : en), sEnv(st : en))
% resP
% hold on
% plot([min(t), max(t)], [th th], 'r', 'LineWidth', 2)
% ylim([0 max(abs(sEnv))]);
% xlim([st/fsd, en/fsd]);
% drawnow % Required to avoid Java errors
% jF1 = get(gcf, 'JavaFrame'); 
% jF1.setMaximized(true);
% % saveas(gcf, ['FltDet ' num2str(fgr + 4) '.eps']);
% saveas(gcf, ['FltDet ' num2str(fgr + 4) '.jpg']);
% 

% figure
% freqz(sb, sa, 20000, fs)
% figure
% impz(sb, sa)
% figure
% zplane(sb, sa, fs)

figure
freqz(eb, ea, 20000, fs)
figure
impz(eb, ea)
figure
zplane(eb, ea, fs)




% 
% function resP
% hold on
% m = markers_out;
% for kP = 1 : size(markers_out)
%     pat(kP) = patch([m(kP, 1) m(kP, 2) m(kP, 2) m(kP, 1)], [-100 -100 100 100], 'r');
%     pat(kP).ZData = [-10 -10 -10 -10]; pat(kP).LineStyle = 'none'; pat(kP).FaceAlpha = 0.25;
% end
% end
end


