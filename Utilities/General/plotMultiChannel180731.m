close all, clear
% load '..\jk20151017\orig fs\jk20151017-151104_022205-N1-clm1_o-031.mat'
% load('G:\Kudlacek\jk20151109_1\dec\jk20151109_1-151123_163959-A33c_A-d-161.mat')
% load('g:\Heralding spikes Motol\Kudlajdized data\Extracted Heraldings\P139-170316_210310-XX-E-999.mat')
% load('h:\Heralding spikes Motol\Kudlajdized data\Analysis 180223\orig fs Bipolar\P82-150418_021113-XX-her-999.mat')


filepn = 'd:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis\Critical slowing\Preictal rat 180719\Detector evaluation\Epi\jk20151111_1-151127_131718-A2b_B-d-999.mat';
load(filepn)

resample_factor = 1;
d = 3.5;
% ss = resample(ss, 1, resample_factor);
% fs = fs/resample_factor
ss = s([2 4 6 8], :)';
offsetmtx = ones(size(ss, 1), 1)*(1 : d : size(ss, 2)*d);
tax = 0 : 1/fs : (size(ss, 1) - 1)/fs;
sToPlot = ss + offsetmtx;
rng = 1692*200 : 1780*200;
patch([1715.5 1763.7 1763.7 1715.5], [-3 -3 14 14], [-2 -2 -2 -2], [1 0.8 0.7], 'EdgeColor', 'none');
hold on
plot(tax(rng), sToPlot(rng, :), 'k')

patchColor = 0.85;

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
