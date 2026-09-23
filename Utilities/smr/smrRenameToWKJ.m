% Now adjusted for jk20140731 r5
ratname = 'jk20140911';

filep = 's:\_Kudlacek\Chronic\jk20140911_7\20140919_r7\';

addpath ..\FileRename_29Nov2010
addpath ..\FileRename_29Nov2010\compiledMex
addpath ..\son

d = dir([filep '\*.smr']);
filenAll = {d.name};

disp('Start renaming')
for kf = 1 : numel(filenAll)
[filep '\' filenAll{kf}];
    fid = fopen([filep '\' filenAll{kf}]);
    he = SONFileHeader_PV(fid);
    fclose(fid);
    yrstr = num2str(he.timeDate.Year);
    de = he.timeDate.Detail;
    tdstring = [yrstr(3:4), num2str(de(6), '%02d'), num2str(de(5), '%02d'),...
        '_', num2str(de(4), '%02d'), num2str(de(3), '%02d'), num2str(de(2), '%02d')];
    dCurr = dir([filep '\' filenAll{kf}(1 : end - 4) '*']);
    filenCurr = {dCurr.name};
    for kff = 1 : numel(filenCurr)
        fnumext = filenCurr{kff}(8 : end);
        newfilen = [ratname, '-', tdstring, '-N-sp-', fnumext]
        [Status, Msg] = FileRename([filep '\' filenCurr{kff}], [filep, '\', newfilen]);
    end
end

disp('Rename finished')
% Source = '..\barcin soubor';
% Dest = '..\barcin soubor2';
% [Status, Msg] = FileRename(Source, Dest)