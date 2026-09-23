close all, clear
% load '..\jk20151017\orig fs\jk20151017-151104_022205-N1-clm1_o-031.mat'
% load('G:\Kudlacek\jk20151109_1\dec\jk20151109_1-151123_163959-A33c_A-d-161.mat')
% load('g:\Heralding spikes Motol\Kudlajdized data\Extracted Heraldings\P139-170316_210310-XX-E-999.mat')
% load('h:\Heralding spikes Motol\Kudlajdized data\Analysis 180223\orig fs Bipolar\P82-150418_021113-XX-her-999.mat')


filepn = 'L:\jk20151017\dec\jk20151017-151028_215514-N1-clm1d-999.mat'; % Small alpha-tail
% filepn = 'L:\jk20151017\dec\jk20151017-151029_025925-N1-clm1d-999.mat'; % Small alpha-tail
% filepn = 'L:\jk20151017\dec\jk20151017-151030_001911-N1-clm1d-999.mat'; % Bilateral alpha-tail, first seizure
% filepn = 'L:\jk20151017\dec\jk20151017-151030_184059-N1-clm1d-999.mat'; % Unilateral alpha-tail
% filepn = 'L:\jk20151017\dec\jk20151017-151031_004547-N1-clm1d-999.mat'; % Massive alpha-tail
% filepn = 'L:\jk20151017\dec\jk20151017-151031_155859-N1-clm1d-999.mat'; % Bilateral alpha-tail
% filepn = 'L:\jk20151017\dec\jk20151017-151101_010555-N1-clm1d-999.mat'; % Bilateral and unilateral alpha-tails
% filepn = 'L:\jk20151017\dec\jk20151017-151103_110857-N1-clm1d-999.mat'; % Bilateral alpha-tail
load(filepn)

resample_factor = 1;
d = 2;
% ss = s([16 17 25 27 70 71 72 80 81 82], :)';
% size(ss)
% ss = resample(ss, 1, resample_factor);
% fs = fs/resample_factor
% size(ss)
ss = s';
offsetmtx = ones(size(ss, 1), 1)*(1 : d : size(ss, 2)*d);
tax = 0 : 1/fs : (size(ss, 1) - 1)/fs;
sToPlot = ss + offsetmtx;
rng = 3298*200 : 3305*200;
plot(tax(rng), sToPlot(rng, :), 'k')
hold on

% patchColor = 0.85;

% plot(78.332+[-0.5 0.8 0.8 -0.5 -0.5], [-500 -500 9500 9500 -500], 'Color', patchColor*[1 1 1])
% plot(106.7188+[-0.5 0.8 0.8 -0.5 -0.5], [-500 -500 9500 9500 -500], 'Color', patchColor*[1 1 1])
% plot(339.7207+[-0.5 1.8 1.8 -0.5 -0.5], [-500 -500 9500 9500 -500], 'Color', patchColor*[1 1 1])

screensize = get(0, 'Screensize');
hf = gcf;
hf.Position = [1 1 1500 800];
% hf.Position = [1 1 3300 1080];

drawnow

% % % % % % % % close all
% % % % % % % % plot([1 : 100000]', randn(100000, 1));
% % % % % % % % % patch([1000 10000 10000 1000], [-3 -3 3 3], [-2 -2 -2 -2], [0.4 1 0.3]);
% % % % % % % % hf = gcf;
% % % % % % % % hf.GraphicsSmoothing = 'on'
% % % % % % % % hf.Position = [1 1 3300 1080];
% % % % % % % % 

% print('D:\Kudlacek\Paper\IED - seizure\Figure\whole recording P82-150418_021652 selected channels dec64.eps', '-depsc', '-painters' )
% saveas(hf, 'D:\Kudlacek\Paper\IED - seizure\Figure\whole recording P82-150418_021652 selected channels dec64 saveas.eps', 'eps')

% plot([50 60], -10*[1 1], 'k', 'LineWidth', 1.5)
% plot([60 60], [-2.5 2.5]-10, 'k', 'LineWidth', 1.5)
