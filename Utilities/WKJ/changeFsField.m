function changeFsField
matPath = uigetdir('d:\', 'Select folder with mat files');
if matPath == 0
    return
end
tic

d = dir(matPath);
d([d.isdir]) = [];
d

for kF = 1 : length(d)
% kF
[~, ~, ext] = fileparts(fullfile(matPath, d(kF).name));
if ~strcmp(ext, '.mat')
    ext
    continue
end
mo = matfile(fullfile(matPath, d(kF).name), 'Writable', true);
% mo.fs
if mo.numSamp > 3500000
    kF
    mo.numSamp
    error('jk Nerovna se')
end


mo.fs = 5000;
clear mo
end
'Hotovo'
toc