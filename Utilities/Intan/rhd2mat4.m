function rhd2mat4

% Uses read_Intan_RHD2000_file_uint16.m to get the data in uint16, sorts
% them and saves in matfile (compressed).

    rhdOrderAll{32} = [24 23 22 21 20 19 18 17 ...
                       01 02 03 04 05 06 07 08 ...
                       09 10 11 12 13 14 15 16 ...
                       32 31 30 29 28 27 26 25]';
    rhdOrderAll{04} = [4 3 1 2];
    
    chanNamesAll{32} = {'PirR'; 'PirR2'; 'AmyR'; 'AmyR2'; 'PrhR'; 'PrhR2'; 'CA3R'; 'CA3R2'; 'DGR'; 'DGR2'; 'VHippR'; 'VHippR2'; 'SubR'; 'SubR2'; 'MECR'; 'MECR2';...
                        'PirL'; 'PirL2'; 'AmyL'; 'AmyL2'; 'PrhL'; 'PrhL2'; 'CA3L'; 'CA3L2'; 'DGL'; 'DGL2'; 'VHippL'; 'VHippL2'; 'SubL'; 'SubL2'; 'MECL'; 'MECL2'};
    chanNamesAll{04} = {'DHippR'; 'DHippR2';...
                        'DHippL'; 'DHipp2'};
               
    fs = 5000;

% Get rhd-file names
[filepn, filep, filen] = getFilepnAllCell('Select rhd files', 'rhd');
if isa(filen, 'double')
    disp('No files selected');
    return
end

% rhdPath = uigetdir('d:\', 'Select folder with rhd files');
% if rhdPath == 0
%     return
% end
% % % rhdPath = 'H:\Kudlacek_20141129\INTAN';

matPath = uigetdir('d:\', 'Where to put mat files');
if matPath == 0
    return
end
% % % matPath = 'D:\Kudlacek\Temp';

% dRHD = dir(rhdPath);
% dRHD([dRHD.isdir]) = [];

% dRHD([~strcmp(dRHD(1).name(end-2, end), 'rhd')]) = [];


ports = [];
nameBeg = [];
numFilesConverted = 0;

for kF = 1:length(filepn)
    numFilesConverted = numFilesConverted + 1;
disp(['kF = ' num2str(kF)])
%     rhdfname = fullfile(rhdPath, dRHD(kF).name);
    rhdfname = filepn{kF};
disp(rhdfname)
%     nameBegNew = dRHD(kF).name
    nameBegNew = filen{kF};
%     if ~strcmp(nameBegNew(end-2 : end), 'rhd')
% 'Cont'
%         continue
%     end

        nameBegNew = nameBegNew(1 : end-17);
        
    % Load data from rhd into variables
    [ampData, ampCh, frPar] = read_Intan_RHD2000_file_1(rhdfname);
    size(ampData)
    ampCh
    frPar
    pause
    
    
    
    
    % Get port numbers and rat names, mkdir
    portsNew = unique([ampCh.port_number]);
    samePorts = 0;
    if size(ports) == size(portsNew)
        samePorts = all(ports == portsNew);
        sameName = strcmp(nameBeg, nameBegNew);
    end
    if ~samePorts || ~sameName
        ports = portsNew;
        nameBeg = nameBegNew;
        prefixes = unique({ampCh.port_prefix});
        clear prompts
        for kPrompt = 1 : length(ports)
            prompts{kPrompt} = ['Name of rat on port ' prefixes{kPrompt}]; %#ok<AGROW>
        end
        ratNames = inputdlg(prompts, 'Rat names');
% % % ratNames = {'jk1uint16'; 'jk2uint16'};
    
        for kDir = 1 : length(ratNames)
            mkdir(matPath, ratNames{kDir});
        end
    end
    
    % Get info, file name
    dateS = filen{kF}(end-16 : end-4);
    dateV = datevec(['20' dateS(1:6)], 'yyyymmdd');
    dateV(4) = str2double(dateS(8:9)); dateV(5) = str2double(dateS(10:11)); dateV(6) = str2double(dateS(12:13));
    dateN = datenum(dateV);
    dateStr = datestr(dateN);
    for kFName = 1 : length(ratNames)
        fnames{kFName, 1} = [ratNames{kFName} '-sp-' dateS]; %#ok<AGROW> % mat-file names
    end
    fullf = fullfile(matPath, ratNames, fnames); % mat-file names with path
%     fullfSig = fullfile(matPath, ratNames, sigFNames);
    
    
    % Create info .mat
    
    % Get fsO (Original fs)
    fsO = frPar.amplifier_sample_rate;
    dF = fsO/fs;
    
    
    for k = 1 : length(ports)
        nlChL = [ampCh.port_number] == ports(k);
        rhdOrder = rhdOrderAll{sum(nlChL)};
        chanNames = chanNamesAll{sum(nlChL)};
        if isempty(rhdOrder)
            error(['Unsupported number of channels on port number' num2str(k) '!']);
        end
        s = ampData(nlChL, :); % Data is in uint16
        s(rhdOrder, :) = s; % Sort channels
        
        if dF ~= 1
disp('Resampling')
            s = resample(s', 1, dF)';
        end
        
        s = s/0.195 + 32768; % read_Intan_RHD2000_file_1 converted the signal to double, now we're converting it back to uint 32 to save space
        suint = uint32(s);
        tol = 20;
        err = sum(sum((double(suint) - s) > tol));


if err > 20
    disp(['Number of deviations higher than ' num2str(tol) ' is ' num2str(err) '.'])
end
        s = suint;
        numChan = sum(nlChL);
        numSamp = size(s, 2);
% % %         save([fullf{k} '_Info.mat'], 'chanNames', 'dateStr', 'dateN', 'fs', 'numSamp', 'numChan');
% % %         save([fullf{k} '_Sig.mat'], 's');
        
        matobj = matfile(fullf{k}, 'Writable', true);
        matobj.s = s;
        matobj.chanNames = chanNames;
        matobj.dateStr = dateStr;
        matobj.dateN = dateN;
        matobj.fs = fs;
        matobj.numSamp = numSamp;
        matobj.numChan = numChan;
        matobj.intScale = 0.195/1000; % Multiply data by this to convert it from integer to mV
        matobj.intOffset = 32768;
        matobj.int2double = 'sdouble = intScale*(double(s) - intOffset)';
    end
    clear s chanNames dateStr dateN numSamp numChan matobj
end

disp([10 'Conversion finished. ' num2str(numFilesConverted)...
    ' files were converted.' 10 'Source rhd-files are in folder ' filep 10 ...
    'Output mat-files are in folder ' matPath])
end

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


