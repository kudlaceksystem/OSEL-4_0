close all, clear


filepn = 'g:\Kudlacek\jk20151109_2\dec\jk20151109_2-151126_185312-A33c_B-d-000.mat';
load(filepn)

resample_factor = 1;
d = 5;
% ss = resample(ss, 1, resample_factor);
% fs = fs/resample_factor
ss = s([2 4 6 8], :)';
offsetmtx = ones(size(ss, 1), 1)*(1 : d : size(ss, 2)*d);
tax = 0 : 1/fs : (size(ss, 1) - 1)/fs;
sToPlot = ss + offsetmtx;
rng = 01*200 : 1200*200;
% patch([1715.5 1763.7 1763.7 1715.5], [-3 -3 14 14], [-2 -2 -2 -2], [1 0.8 0.7], 'EdgeColor', 'none');
hold on
plot(tax(rng), sToPlot(rng, :), 'k')

% patchColor = 0.85;

% plot(78.332+[-0.5 0.8 0.8 -0.5 -0.5], [-500 -500 9500 9500 -500], 'Color', patchColor*[1 1 1])
% plot(106.7188+[-0.5 0.8 0.8 -0.5 -0.5], [-500 -500 9500 9500 -500], 'Color', patchColor*[1 1 1])
% plot(339.7207+[-0.5 1.8 1.8 -0.5 -0.5], [-500 -500 9500 9500 -500], 'Color', patchColor*[1 1 1])

screensize = get(0, 'Screensize');
hf = gcf;
hf.Position = [1 1 1500 800];
% hf.Position = [1 1 3300 1080];

drawnow

% close all
% plot([1 : 100000]', randn(100000, 1));
% hf = gcf;
% hf.GraphicsSmoothing = 'on'
% hf.Position = [1 1 3300 1080];


% print('D:\Kudlacek\Paper\IED - seizure\Figure\whole recording P82-150418_021652 selected channels dec64.eps', '-depsc', '-painters' )
% saveas(hf, 'D:\Kudlacek\Paper\IED - seizure\Figure\whole recording P82-150418_021652 selected channels dec64 saveas.eps', 'eps')

% plot([50 60], -10*[1 1], 'k', 'LineWidth', 1.5)
% plot([60 60], [-2.5 2.5]-10, 'k', 'LineWidth', 1.5)
