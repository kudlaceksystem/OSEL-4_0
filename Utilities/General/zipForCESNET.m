function zipForCESNET
%ZIPFORCESNET Summary of this function goes here
%   Detailed explanation goes here


filenpAll = getFilenpAll;
zipp = uigetdir('d:\', 'Where to save zip files')

zipSrcNames = cell(0);
zipSrcSz = 0;
for kF = 1 : length(filenpAll)
kF
    zipSrcNames = [zipSrcNames, filenpAll(kF)]; %#ok<AGROW>
    f = java.io.File(filenpAll(kF));
    fsz = length(f); % File size
    zipSrcSz = zipSrcSz + fsz;
    if zipSrcSz > 3.5e9 || kF == length(filenpAll)
        [~, fnStart, ~] = fileparts(zipSrcNames{1})
        [~, fnEnd, ~] = fileparts(zipSrcNames{end});
        zip([zipp, '\', fnStart, ' to ', fnEnd '.zip'], zipSrcNames)
        zipSrcSz = 0;
        zipSrcNames = cell(0);
    end
end
disp('Zipping finished')
a = fileparts(filenpAll{1})
disp(['Source files are in ' fileparts(filenpAll{1})])
disp(['Zip files are in ' zipp])
end

function o = getFilenpAll
[matn, matp] = uigetfile('d:\*.*', 'Select files', 'MultiSelect', 'on');
if isa(matn, 'double')
    disp('No files selected');
    return
end
o = fullfile(matp, matn);
end



















































































































