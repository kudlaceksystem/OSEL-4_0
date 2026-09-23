% copyRandom20FromExtracted.m
% --- Header: set these before running ---
xlsxFile = '\\neurodata3\Lab Neuro Ephys\Kudlacek\Seizure onset patterns\Data for Premek.xlsx';        % Excel file path
destRoot  = '\\neurodata3\Lab Neuro Ephys\Kudlacek\Seizure onset patterns\Data for Premek'; % Destination folder for copies from all sources
sheetName = 1;                         % Excel sheet (name or index)
colIndex  = 3;                         % column with folder names
startRow  = 3;                         % start reading from this row
maxFiles  = 20;                        % keep at most this many files
% ---------------------------------------

% Read the Excel table (only the relevant region)
[~,~,raw] = xlsread(xlsxFile, sheetName);
if size(raw,1) < startRow
    error('Excel file has fewer rows than startRow.');
end
folderNames = raw(startRow:end, colIndex);
% Ensure destRoot exists
if ~exist(destRoot,'dir')
    mkdir(destRoot);
end

for i = 1:numel(folderNames)
    fn = folderNames{i};
    if isempty(fn) || ~ischar(fn) && ~isstring(fn)
        fprintf('Row %d: empty or invalid folder name — skipping\n', startRow + i - 1);
        continue;
    end
    srcFolder = char(fn);
    extractedFolder = fullfile(srcFolder, 'Extracted seizures');
    targetFolder20  = fullfile(srcFolder, 'Extracted seizures 20');

    if ~exist(extractedFolder,'dir')
        fprintf('Source "%s": no "Extracted seizures" — skipping\n', srcFolder);
        continue;
    end
    if ~exist(targetFolder20,'dir')
        mkdir(targetFolder20);
    end

    % List files (exclude directories)
    d = dir(extractedFolder);
    isFile = ~[d.isdir];
    files = d(isFile);
    if isempty(files)
        fprintf('Source "%s": no files in "Extracted seizures"\n', srcFolder);
        continue;
    end

    nFiles = numel(files);
    if nFiles > maxFiles
        idx = randperm(nFiles, maxFiles);
    else
        idx = 1:nFiles;
    end
    selected = files(idx);

    % Copy each selected file to both destinations
    for k = 1:numel(selected)
        srcFile = fullfile(extractedFolder, selected(k).name);

        % Copy into Extracted seizures 20
        dst1 = fullfile(targetFolder20, selected(k).name);
        try
            copyfile(srcFile, dst1);
        catch ME
            fprintf('Failed to copy to "%s": %s\n', dst1, ME.message);
            continue;
        end

        % Copy into global destination root (optionally preserve subfolders by source name)
        % Here we put all files into destRoot; if you prefer to keep per-source subfolders,
        % uncomment the per-source block below and comment the flat copy.
        dstFlat = fullfile(destRoot, selected(k).name);
        try
            copyfile(srcFile, dstFlat);
        catch ME
            fprintf('Failed to copy to "%s": %s\n', dstFlat, ME.message);
        end
    end

    fprintf('Source "%s": copied %d file(s) to "%s" and "%s"\n', ...
        srcFolder, numel(selected), targetFolder20, destRoot);
end

% If you prefer to keep files organized by source folder in destRoot, replace the
% dstFlat copy above with these lines (uncomment):
%     srcBase = matlab.lang.makeValidName(sprintf('source_%d', i)); % or use a sanitized folder name
%     destPerSource = fullfile(destRoot, srcBase);
%     if ~exist(destPerSource,'dir'), mkdir(destPerSource); end
%     dstPer = fullfile(destPerSource, selected(k).name);
%     copyfile(srcFile, dstPer);