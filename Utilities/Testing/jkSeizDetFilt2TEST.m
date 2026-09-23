% jkSeizDetFilt2 testing script
close all, clear all
% load('L:\_Kudlacek\jk20141113\jk20141113 decimate\jk20141113-sp-141124_180551-d.mat');
load('L:\_Kudlacek\jk20141113\jk20141113 decimate\jk20141113-sp-141202_195035-d.mat');
sdouble = intScale*(double(s) - intOffset);
mrk = jkSeizDetFilt2Figures(sdouble(9, :)', fs, 10)
mrk = jkSeizDetFilt2Figures(sdouble(12, :)', fs, 20)


