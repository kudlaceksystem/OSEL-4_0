close all; clear
filep = 'd:\Kudlacek\Experiment\IED - seizures\Scripts 4\10ch th0.5 thMax1 raw OK - Copy\';
d = dir(filep);
filen = {d.name};
filen = filen(~[d.isdir]);

for kf = 1 : size(filen, 1)
    [filep, filen{kf}]
    openfig([filep, filen{kf}])
    pause
    
end

