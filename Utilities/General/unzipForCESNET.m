function unzipForCESNET
%ZIPFORCESNET Summary of this function goes here
%   Detailed explanation goes here


filepnAll = getFilepnAll;
unzipp = uigetdir('d:\', 'Select destination folder');
datestr(now)
% zipSrcNames = cell(0);
% zipSrcSz = 0;
for kF = 1 : length(filepnAll)
    unzip(filepnAll{kF}, unzipp)
    datestr(now)
    disp([num2str(kF), '/', num2str(length(filepnAll)), '  ', filepnAll{kF}, ' finished.'])
end
disp('Unzip finished')
end

function o = getFilepnAll
[matn, matp] = uigetfile('d:\*.*', 'Select zip files', 'MultiSelect', 'on');
if isa(matn, 'double')
    disp('No files selected');
    return
end
o = fullfile(matp, matn);
end
