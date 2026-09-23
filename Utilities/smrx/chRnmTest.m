% addpath('CEDMATLAB')
addpath('CEDMATLAB/CEDS64ML')
fhand = CEDS64Open('ABCD-220725_155302-MonaBodaPetaMisa-000.smrx', 1)
[iOK, nm] = CEDS64ChanTitle(fhand, 1)
iOK = CEDS64CloseAll
% 
% fhand = CEDS64Open('ABCD-220725_155302-MonaBodaPetaMisa-000.smrx', 1)
% [iOK, nm2] = CEDS64ChanTitle(fhand, 1)
% iOK = CEDS64CloseAll