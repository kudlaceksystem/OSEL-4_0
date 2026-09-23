close all
clear

filepn = 'k:\JK analysis\jc20181211_1\200Hz avRef\jc20181211_1-181220_152503-VB-200HZavRef_d-250.mat';
load(filepn)

d = 600;
ss = s';
offsetmtx = ones(size(ss, 1), 1)*(1 : d : size(ss, 2)*d);
tax = 0 : 1/fs : (size(ss, 1) - 1)/fs;
sToPlot = ss + offsetmtx;
rng = 165*fs : 295*fs;
hold on
plot(tax(rng), sToPlot(rng, :), 'k')
plot(tax(rng(1) + 0.75*range(rng) + [0 20 20]*fs), [0 0 200] - 500, 'k', 'LineWidth', 3)
text(tax(rng(1) + 0.75*range(rng) + 10*fs), -600, '10 s', 'HorizontalAlignment', 'center', 'FontSize', 24, 'Interpreter', 'latex')
text(tax(rng(1) + 0.75*range(rng) + 21*fs), -400, '200 $\mu$V', 'VerticalAlignment', 'middle', 'FontSize', 24, 'Interpreter', 'latex')

for kr = 1 : size(sToPlot, 2)
    text(tax(rng(1)) - 4, (kr-1)*d, num2str(kr), 'VerticalAlignment', 'middle', 'FontSize', 32, 'Interpreter', 'latex')
end

% screensize = get(0, 'Screensize');
hf = gcf;
hf.Position = [100 100 1920 800];

hf.GraphicsSmoothing = 'on';
hax = gca;
hax.Visible = 'off';

drawnow

% % % % print('D:\Kudlacek\Paper\IED - seizure\Figure\whole recording P82-150418_021652 selected channels dec64.eps', '-depsc', '-painters' )
print('c:\Users\Kudlacek\Documents\Conference\200711 FENS Glasgow\Poster\Sz and IEDs.jpg', '-djpeg', '-r1200')

