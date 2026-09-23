function matResample NEPODARILO SE DODELAT
matPath = uigetdir('d:\', 'Select folder with mat files');
if matPath == 0
    return
end
tic

d = dir(matPath);
d([d.isdir]) = [];
d

for kF = 1 : length(d)
kF
[~, ~, ext] = fileparts(fullfile(matPath, d(kF).name));
if ~strcmp(ext, '.mat')
    ext
    continue
end
m1 = matfile(fullfile(matPath, d(kF).name), 'Writable', 0);
% fsOld = matobj.fs
% dF = fsOld/5000
% sig = 0.195*(double(matobj.s) - 32768);
% clear matobj

n1 = fieldnames(m1)

for kfn 1:length(n1)
    if strcmp(n1{kfn}, 's')
        continue
    end
    

% sig = resample(sig', 1, dF)';

if kF == 1 || kF == 1
%     k = load(fullfile(matPath, d(kF).name))
%     s = []
%     save(fullfile(matPath, d(kF).name), 's', '-append')
    delete(fullfile(matPath, d(kF).name))
end

% 
% matobj = matfile(fullfile(matPath, d(kF).name), 'Writable', true);
% 
% matobj.s = sig;
% 
% matobj.fs = fsOld/dF;
% 
% clear matobj
% 
end
'Hotovo'
toc