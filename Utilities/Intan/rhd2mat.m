function rhd2mat

% Uses read_Intan_RHD2000_file_uint16.m to get the data in uint16, sorts
% them and saves in matfile (compressed).

    rhdOrder = [24 23 22 21 20 19 18 17 ...
                01 02 03 04 05 06 07 08 ...
                09 10 11 12 13 14 15 16 ...
                32 31 30 29 28 27 26 25]';
% 	dF = 2;

rhdPath = uigetdir('d:\', 'Select folder with rhd files');
if rhdPath == 0
    return
end
% % % rhdPath = 'H:\Kudlacek_20141129\INTAN';

matPath = uigetdir('d:\', 'Where to put mat files');
if matPath == 0
    return
end
% % % matPath = 'D:\Kudlacek\Temp';

dRHD = dir(rhdPath);
dRHD([dRHD.isdir]) = [];

% dRHD([~strcmp(dRHD(1).name(end-2, end), 'rhd')]) = [];


ports = [];
nameBeg = [];

% for kF = [1:244, 1453:length(dRHD)]

for kF = 1:length(dRHD)
kF
    rhdfname = fullfile(rhdPath, dRHD(kF).name);
    nameBegNew = dRHD(kF).name
    if ~strcmp(nameBegNew(end-2 : end), 'rhd')
'Cont'
        continue
    end
        nameBegNew = nameBegNew(1 : end-17);
    % Load data from rhd into variables
    [ampData, ampCh, frPar] = read_Intan_RHD2000_file_1(rhdfname);
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
    
    
    % Get info file name
    dateS = dRHD(kF).name(end-16 : end-4);
    dateV = datevec(['20' dateS(1:6)], 'yyyymmdd');
    dateV(4) = str2double(dateS(8:9)); dateV(5) = str2double(dateS(10:11)); dateV(6) = str2double(dateS(12:13));
    dateN = datenum(dateV);
    dateStr = datestr(dateN);
    for kFName = 1 : length(ratNames)
        fnames{kFName, 1} = [ratNames{kFName} '_' dateS]; %#ok<AGROW>
    end
    fullf = fullfile(matPath, ratNames, fnames);
%     fullfSig = fullfile(matPath, ratNames, sigFNames);
    
    
    % Create info .mat
    chanNames = {'PirR'; 'PirR2'; 'AmyR'; 'AmyR2'; 'PrhR'; 'PrhR2'; 'CA3R'; 'CA3R2'; 'DGR'; 'DGR2'; 'VHippR'; 'VHippR2'; 'SubR'; 'SubR2'; 'MECR'; 'MECR2';...
                 'PirL'; 'PirL2'; 'AmyL'; 'AmyL2'; 'PrhL'; 'PrhL2'; 'CA3L'; 'CA3L2'; 'DGL'; 'DGL2'; 'VHippL'; 'VHippL2'; 'SubL'; 'SubL2'; 'MECL'; 'MECL2'};
    % Get fs
    fs = frPar.amplifier_sample_rate;
    dF = fs/5000;
    fs = fs/dF;
    
    
    for k = 1 : length(ports)
        nChL = [ampCh.port_number] == ports(k);
        s = ampData(nChL, :); % Data is in uint16
        s(rhdOrder, :) = s; % Sort channels
        
        if dF ~= 1
'Resampling'
            s = resample(s', 1, dF)';
        end
        
        s = s/0.195 + 32768;
        suint = uint32(s);
        tol = 8;
        err = sum(sum((double(suint) - s) > tol));

        % Debug plots
% % % % % % % % % % % % % % taxNoRes = 0 : 1/(fs*dF) : size(sNoRes, 2)/(fs*dF) - 1/(fs*dF);
% % % % % % % % % % % % % % tax = 0 : 1/(fs) : size(s, 2)/(fs) - 1/(fs);
% % % % % % % % % % % % % % 
% % % % % % % % % % % % % % figure
% % % % % % % % % % % % % % plot(taxNoRes, sNoRes(1, :))
% % % % % % % % % % % % % % hold on
% % % % % % % % % % % % % % plot(tax, sRes(1, :), 'r')

if err > 0
    disp(['Number of deviations higher than ' num2str(tol) ' is ' num2str(err) '.'])
end
        s = suint;
        numChan = sum(nChL);
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
% % % % % % % % %         matobj.uintOffset = 32768;
% % % % % % % % %         matobj.uintScaling = 1000/0.195; % After matobj retreival you must subtract the offset and then divide the data by scaling
    end
    clear s chanNames dateStr dateN fs numSamp numChan matobj
end
assignin('base', 'dRHD', dRHD);

'Hotovo'




