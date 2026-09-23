function signalGood

filenpAll = getFilenpAll;

dnAll = [];
fromEnd = 0;
for kF = 1 : length(filenpAll)
    [~, fn, ~] = fileparts(filenpAll{kF});
    [~, filen{kF}, ~] = fileparts(filenpAll{kF}); %#ok<AGROW>
    dv = [str2double(fn(end-12-fromEnd:end-11-fromEnd)) + 2000,...
        str2double(fn(end-10-fromEnd:end-9-fromEnd)),...
        str2double(fn(end-8-fromEnd:end-7-fromEnd)),...
        str2double(fn(end-5-fromEnd:end-4-fromEnd)),...
        str2double(fn(end-3-fromEnd:end-2-fromEnd)),...
        str2double(fn(end-1-fromEnd:end-fromEnd))];
    dn = datenum(dv);
    dnAll = [dnAll; dn]; %#ok<AGROW>
end

figure
% hp = stem(diff(dnAll));
hp(1) = stem(dnAll(1:end-1), diff(dnAll));

figure
hp(2) = scatter(dnAll, ones(length(dnAll), 1));

for khp = 1 : length(hp)
hp(khp).Parent.TickLabelInterpreter = 'none';
tickPos = linspace(dnAll(1), dnAll(end), 10);
hp(khp).Parent.XTick = tickPos;
hp(khp).Parent.XTickLabel = datestr(tickPos);
end
% hp.Parent.YLim = [0, max(diff(dnAll))];
% hp.Parent.YTick = [0, max(diff(dnAll))];
% hp.Parent.YTickLabel = [0, max(diff(dnAll))*24*60]; % y axis wil be in minutes
end


function o = getFilenpAll
[matn, matp] = uigetfile('i:\_Kudlacek\jk20141130\*.*', 'Select files', 'MultiSelect', 'on');
if isa(matn, 'double')
    disp('No files selected');
    return
end
o = fullfile(matp, matn);
end
