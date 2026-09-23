close all, clear
% load '..\jk20151017\orig fs\jk20151017-151104_022205-N1-clm1_o-031.mat'
% load('G:\Kudlacek\jk20151109_1\dec\jk20151109_1-151123_163959-A33c_A-d-161.mat')

% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-17_22-49.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-17_23-44.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_00-15.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_01-24.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_01-41.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_01-54.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_02-11.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_02-28.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_02-49.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_03-20.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_03-42.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_04-05.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_04-24.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_04-40.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_05-38.mat')
% load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_05-54.mat')
% load('G:\Heralding spikes Motol\P139_Horava\P139_2017-03-16_20-58_seizure.mat')
% load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-06_14-13_seizure.mat')
% load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-06_22-39_seizure.mat')
% load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-07_16-52_seizure.mat')
% load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-08_03-41_seizure.mat')
% load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-08_09-59_seizure.mat')
% load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-09_04-20_seizure.mat')
% load('G:\Heralding spikes Motol\P147_Fliegelova\P147_2017-06-18_06-46_seizure.mat')
% load('G:\Heralding spikes Motol\P147_Fliegelova\P147_2017-06-20_05-29_seizure.mat')


% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-17_22-49_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-17_23-44_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_00-15_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_01-24_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_01-41_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_01-54_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_02-11_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_02-28_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_02-49_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_03-20_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_03-42_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_04-05_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_04-24_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_04-40_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_05-38_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P82_Vovsova\P82_2015-04-18_05-54_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P139_Horava\P139_2017-03-16_20-58_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-06_14-13_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-06_22-39_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-07_16-52_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-08_03-41_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-08_09-59_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P144_Navratilik\P144_2017-05-09_04-20_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P147_Fliegelova\P147_2017-06-18_06-46_seizure_err.txt');
% nChErr = load('G:\Heralding spikes Motol\P147_Fliegelova\P147_2017-06-20_05-29_seizure_err.txt');

% fid = fopen('G:\Heralding spikes Motol\P139_Horava.txt');
% fid = fopen('G:\Heralding spikes Motol\P144_Navratilik.txt');
% fid = fopen('G:\Heralding spikes Motol\P147_Fliegelova.txt');
fid = fopen('G:\Heralding spikes Motol\P82_Vovsova.txt');
seizures = textscan(fid, '%s', 'delimiter', char(10));
seizs = seizures{1};
% seizdateN = datenum(seizs, 'dd.mm.yyyy HH:MM:SS');
seizdateN = datenum(seizs, 'dd-mmm-yyyy HH:MM:SS');
fclose('all');

close all;
distance = 300;
% ss = s([1 4 6 8], 257000 : 270000)';
ss = double(d);
ss = ss(:, setdiff(1 : size(d, 2), nChErr));
% ss = ss(:, setdiff(1 : 20, nChErr));

offsetmtx = ones(size(ss, 1), 1)*(1 : distance : size(ss, 2)*distance);
% tax = 0 : 1/fs : (size(ss, 1) - 1)/fs;
tax = tabs;
plot(tax, ss + offsetmtx, 'k')
hax = gca;
hold on
plot([seizdateN seizdateN], hax.YLim, 'r', 'LineWidth', 2)
hax.XLim = [min(tax) max(tax)];
datetick('x','HH:MM:SS','keepticks','keeplimits');
% plot([50 60], -10*[1 1], 'k', 'LineWidth', 1.5)
% plot([60 60], [-2.5 2.5]-10, 'k', 'LineWidth', 1.5)

hf = gcf;
drawnow % Required to avoid Java errors
jF1 = get(hf, 'JavaFrame'); 
jF1.setMaximized(true);
