clear all; close all; clc;

%% Settings
% pathFolder = 'd:\Users\Admin\Documents\DATA\_Kudlacek\jk20140731_5\natural\140818\';
pathFolder = 'd:\Users\Admin\Documents\FATA2\';


%% Prepare
addpath(fullfile(pwd, 'SON'));

tmpDir = dir(pathFolder);
tmpDir(~[tmpDir(:).isdir]) = [];
tmpDir(ismember({tmpDir.name}, {'.', '..'})) = [];

pathFile = [];
date = {};
datenum = [];
for f = 1:length(tmpDir)
    pathSubFolder = fullfile(pathFolder, tmpDir(f).name);

    tmpFile = dir(fullfile(pathSubFolder, '*.smr'));
    tmpFile([tmpFile(:).isdir]) = [];
    pathFile = [pathFile; cellfun(@(x) fullfile(pathSubFolder, x), {tmpFile.name}, 'UniformOutput', false)'];
    
    date = [date; {tmpFile.date}'];
    datenum = [datenum; [tmpFile.datenum]'];
end

if isempty(pathFile)
    tmpFile = dir(fullfile(pathFolder, '*.smr'));
    tmpFile([tmpFile(:).isdir]) = [];
    pathFile = [pathFile; cellfun(@(x) fullfile(pathFolder, x), {tmpFile.name}, 'UniformOutput', false)'];
    
    date = [date; {tmpFile.date}'];
    datenum = [datenum; [tmpFile.datenum]'];
end
clear tmpDir tmpFile pathSubFolder

%% Process
for f = 1:1 % DEBUG
% for f = 1:length(pathFile)
    [pathstr, name, ~] = fileparts(pathFile{f});
    pathSave = fullfile(pathstr, [name '-e.mat']);
    
    %% Load
    fid = fopen(pathFile{f});
    
    % Chan list
    chanList = SONChanList(fid);

    tmpCL = chanList;
    tmpCL([tmpCL.kind] ~= 1) = [];

    chanVect = [tmpCL.number];
    numChan = length(chanVect);
    
    % Chan list 2
    tmpCL2 = chanList;
    tmpCL2([tmpCL2.kind] == 1) = [];
    
    chanVect2 = [tmpCL2.number];
    numChan2 = length(chanVect2);
    
    % Fill NO DATA channels
    ND.nonData = cell(1, numChan2);
    ND.npoints = zeros(1, numChan2);
    ND.names = cell(1, numChan2);
    
    for ch = 2:numChan2
%         [tmpD, tmpI] = SONGetChannel(fid, chanVect2(ch), 'scale', 'progress');
        [tmpD, tmpI] = SONGetChannel(fid, chanVect2(ch), 'scale');
        
        ND.nonData{ch} = tmpD;
        ND.npoints(ch)= tmpI.npoints;
        ND.names{ch} = tmpI.title;
    end
    
    % Prepare
%     [tmpD, tmpI] = SONGetChannel(fid, chanVect(1), 'scale', 'progress');
%     [tmpD, tmpI] = SONGetChannel(fid, chanVect(1), 'progress');
    [tmpD, tmpI] = SONGetChannel(fid, chanVect(1), 'scale');
    
    data = zeros(tmpI.npoints, numChan, 'like', tmpD);
    startChan = zeros(1, numChan);
    stopChan = zeros(1, numChan);
    mins = zeros(1, numChan);
    maxs = zeros(1, numChan);
    scales = zeros(1, numChan);
    offsets = zeros(1, numChan);
    names = cell(1, numChan);
    
    % Fill DATA channels
    data(:, 1) = tmpD;
    startChan(1) = tmpI.start;
    stopChan(1) = tmpI.stop;
    mins(1) = tmpI.min;
    maxs(1) = tmpI.max;
    scales(1) = tmpI.scale;
    offsets(1) = tmpI.offset;
    names{1} = tmpI.title;
    
    for ch = 2:numChan
%         [tmpD, tmpI] = SONGetChannel(fid, chanVect(ch), 'scale', 'progress');
%         [tmpD, tmpI] = SONGetChannel(fid, chanVect(ch), 'progress');
        [tmpD, tmpI] = SONGetChannel(fid, chanVect(ch), 'scale');
        
        data(:, ch) = tmpD;
        startChan(ch) = tmpI.start;
        stopChan(ch) = tmpI.stop;
        mins(ch) = tmpI.min;
        maxs(ch) = tmpI.max;
        scales(ch) = tmpI.scale;
        offsets(ch) = tmpI.offset;
        names{ch} = tmpI.title;
    end
    
    ans = fclose(fid);
    
    
    %% Save
    mf = matfile(pathSave, 'Writable', true);
    
    mf.data = data;
    
    mf.numChan = numChan;
    mf.names = names;
    
    mf.fileName = tmpI.FileName;
    mf.date = date{f};
    mf.datenum = datenum(f);
    mf.fs = 1/(tmpI.sampleinterval/1000000);
    mf.npoints = tmpI.npoints;
    mf.start = startChan;
    mf.stop = stopChan;
    mf.units = tmpI.units;
    mf.min = mins;
    mf.max = maxs;
    mf.scale = scales;
    mf.offset = offsets;
    
    mf.ND = ND;
    
    clear fs tmpCL numChan pathstr name chanList chanVect mf
end

clear fid f ans
