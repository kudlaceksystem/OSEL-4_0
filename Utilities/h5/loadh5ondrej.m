function [data,fs,chanNames,start_dt] = loadh5ondrej(fpname,zesileni)
arguments
    fpname
    zesileni
end
% Jan Chvojka super function
%
% zesileni = cislo ktere odpovida hodnote knobu zesileni na modrem AMsystems zesilovaci

[data,fs,chanNames,start_dt] = loadh5single(fpname);

% Ondrejovo nastaveni
rozsah=10; %% rozsah digitizeru je +/-10V
mVmistoV=1000; %%zobrazit mV
data = double(data)/(2^15)*rozsah/zesileni*mVmistoV; % this is now in mV


end



