%% This is just copy of the lines used in the command line

load('jk20141113-141202_033036-sp.mat')

sPremek = zeros(1, 600*5000);

r = 0;

r = r + 1; [g(r, 1), ~] = ginput(1); sPremek(r, :) = s(g(r, 1) - 300*5000 + 1 : g(r, 1) - 300*5000 + size(sPremek, 2));

for ks = 1 : 14; figure(2); plot(sPremek(ks, :)); pause; end