close all
clear all

pname = 'y:\_EEG-A2a\jk20150724_1';
pname = 'y:\_EEG-A2a\test';
pname = 'd:\Pokusna data d\Rename debug';
oldRatName = 'jk20150724_2';
newRatName = 'jk20150724_1';
d = dir(pname);
fname = {d(3:end).name}';
kCorruptFiles = 1;
for kd = 1 : length(fname)
kkdd = kd
file = fname{kd}
    try
        l = load([pname '\' fname{kd}]);
disp(l.sub_name)
%% %%%%%%%%%%%%%%%%%%%%%%
        if isfield(l, 'sub_name')
            if strcmp(l.sub_name, newRatName)
                disp('Name ok')
            else
                l.sub_name = newRatName;
                save([pname '\' fname{kd}], '-struct', 'l', '-v7.3')
            end
        else
            l.sub_name = newRatName;
            save([pname '\' fname{kd}], '-struct', 'l', '-v7.3')
        end
%% %%%%%%%%%%%%%%%%%%%%%%%
    catch
        corruptFiles{kCorruptFiles} = fname{kd};
        kCorruptFiles = kCorruptFiles + 1;
'catch catch'
        continue
    end

%     pause(0.01)
end

disp('Corrupt files:')
if exist('corruptFiles')
    for kDisp = 1 : length(corruptFiles)
        disp(corruptFiles{kDisp})
    end
end
