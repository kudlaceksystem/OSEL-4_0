function [data,fs,chNames,start_dt] = loadh5single(fpname)
%LOADH5SINGLE loads h5 with single sewwp/data inside.

hi=h5info(fpname);
if numel(hi.Groups) >2
    disp('loadh5single: After the header, there were more sweeps/data in the h5 file. Loading only the first one.')
end

dataset_name = [ hi.Groups(2).Name '/analogScans' ]; % datastoreName
data = h5read(fpname,dataset_name);

% chanNames by data
Nch_data = size(data,2);

try
    chnm = h5read(fpname, '/header/AllChannelNames');
    chNames = cellstr(chnm);
    Nch_header = numel(chNames);
    if Nch_header~=Nch_data
        %disp('loadh5single: Channels dont match, I cropped them to the size of the data. The order might not match.');
        if Nch_header>Nch_data
            chNames = chNames(1:Nch_data);
            %disp(['loadh5single: Channels are: ']);
            %chNames
        end
    end
catch 
    chNames = arrayfun(@num2str,1:Nch_data,'UniformOutput',false)';
end
% Sampling rate
fs = h5read(fpname, '/header/AcquisitionSampleRate');

% debilni cas zacatku datasetu
clockAtRunStart_HHmmss = h5read(fpname, '/header/ClockAtRunStart');
start_dt = datetime(clockAtRunStart_HHmmss, 'Format', 'HH:mm:ss');

end

