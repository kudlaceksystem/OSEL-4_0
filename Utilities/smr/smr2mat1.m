function smr2mat1
% All channels must have the same fs.

addpath ..\son

% Get smr-files
[filepn, ~, filen] = getFilepnAllCell('Select smr-files', 'smr');
if isa(filepn, 'double')
    disp('No files selected');
    return
end

matPath = uigetdir('d:\', 'Where to put mat-files');
if matPath == 0
    return
end

ratName = inputdlg('Enter rat name');

numFilesConverted = 0;
for kF = 1:length(filepn)
    numFilesConverted = numFilesConverted + 1;
disp(['kF = ' num2str(kF)])
    smrfname = filepn{kF};
disp(smrfname)

    allVar.chanNames = loadChanNames(filepn{kF});
    fid = fopen(filepn{kF});
    fh = SONFileHeader_PV(fid);
    dateV(1) = fh.timeDate.Year;
    for kD = 1 : 5;
        dateV(kD + 1) = fh.timeDate.Detail(7 - kD); %#ok<AGROW>
    end
    allVar.dateN = datenum(dateV);
    allVar.dateStr = datestr(allVar.dateN);
    allVar.fs = loadFs(filepn{kF}, 1);
    allVar.intOffset = 0;
    allVar.intScale = 1/6553.5; % To volts (ADC range is from -5 to 5 volts, 10 volts in total)
    allVar.howToGetDataInUnitsSpecified = 'sdouble = (double(sint) - (intOffset + phyOffset))*(intScale*phyScale)';
    allVar.numChan = length(allVar.chanNames);
    fid = fopen(filepn{kF});

    for kCh = 1 : allVar.numChan
        [allVar.s(kCh, :), h] = SONGetADCChannel(fid, kCh);
        allVar.phyScale(kCh) = h.scale;
        allVar.phyOffset(kCh) = -h.offset/(allVar.intScale*allVar.phyScale(kCh));
        allVar.units = h.units;
        allVar.numSamp(kCh) = h.npoints;
    end
    
    fclose(fid);
    
    yearStr = num2str(dateV(1));
    yearStr = yearStr(3 : 4);
    dateOurFormat = [yearStr, num2str(dateV(2), '%02d'), num2str(dateV(3), '%02d'),...
        '_' num2str(dateV(4), '%02d'), num2str(dateV(5), '%02d'), num2str(dateV(6), '%02d')];
    indNumber = regexp(filen{kF}, '[_-]\d\d\d\.smr', 'once');
    if ~isempty(indNumber)
        number = filen{kF}(indNumber + 1 : indNumber + 3);
    else
        number = [];
    end
    outfilepn = fullfile(matPath, [ratName{1}, '-', dateOurFormat, '-', number, '.mat']);
    save(outfilepn, '-struct', 'allVar')
    clear allVar
end
end

%% getFilepnAllCell
function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
[filen, filep] = uigetfile(['d\*.' ext], prompt, 'MultiSelect', 'on');
filepn = fullfile(filep, filen);
if ~iscell(filepn) && ~iscell(filep) && ~iscell(filen)
    a{1} = filepn;
    b{1} = filep;
    c{1} = filen;
    clear filepn filep filen
    filepn = a;
    filep = b;
    filen = c;
end
end

%% loadChanNames
function [chanNames, chanNNames] = loadChanNames(filepn) % Input argument is file path and name
smrChListFID = fopen(filepn);
chanNames = SONChanList(smrChListFID); % Structure
chanNames = {chanNames.title};
chanNames = chanNames(1 : end - 2);
chanNames = chanNames(:);
numCh = length(chanNames);
numsSpaces = [num2str((1 : numCh)', '%02d\n'), char(32*ones(numCh, 1))]; % Numbers with spaces
chanNNames = cell(numCh, 1);
for k = 1 : numCh
    chanNNames{k} = [numsSpaces(k, :), chanNames{k}];
end
fclose(smrChListFID);
end

%% loadFs
function fs = loadFs(filepn, ch)
fid = fopen(filepn);
fs = 1/SONGetSampleInterval(fid, ch);
fclose(fid);
end

%% Not needed in this function

% %% loadBlockLen
% function bLen = loadBlockLen(filepn, ch)
% % Returns vector of SON block lengths in each channel. For each channel the
% % block length is supposed to be constant, else errormsg appears.
% % Uses SON library
% fid = fopen(filepn);
% B = SONGetBlockHeaders(fid, ch);
% bLen = max(B(5, :));
% if min(B(5, 1 : end-1)) ~= bLen(r)
%     errordlg(['Block lenghts not constant in channel No. ' num2str(nCh(r))]);
%     return;
% end
% fclose(fid);
% end

% %% loadChannel
% function sch = loadChannel(filepn, ch, varargin) % File path and name, channel, beginning, end
% % If beginning and end are not specified the whole signal is loaded
% if length(varargin) == 2
%     be = varargin{1}; % In seconds
%     en = varargin{2}; % In seconds
% elseif isempty(varargin)
%     be = 0; % In seconds
%     en = inf;
% else
% error(['Length of varargin is ' num2str(length(varargin))...
%     '. You must specify beginning and end of the signal you wish to load'...
%     ' (4 input arguments to the function) or nothing'...
%     ' (2 input arguments to the function).'])
% end
%             
% fid = fopen(filepn);
%             
% if be ~= 0 || en ~= inf
%     fs = loadFs(filepn, ch);
%     beSa = be*fs; enSa = en*fs;
%     bLen = loadBlockLen(filepn, ch);
% 
%     bBe = uint64(floor(be/bLen) + 1); % Blocks where beginning appears
%     bEn = uint64(floor(be/bLen) + 1); % Blocks where end appears
% 
%     sbBeSa = beSa - bLen.*(bBe - 1); % Howmanyeth sample the beginning is within its block
% %                 sbEn = enSa - bLen.*(bEn - 1); % Howmanyeth sample the end is within its block
% 
%     sch = single(SONGetChannel(fid, ch, bBe, bEn, 'scale'));
%     sch = sch(sbBe, sbBeSa + enSa - beSa);
% else
%     sch = single(SONGetChannel(fid, ch, 'scale'));
% end
% end
% 
