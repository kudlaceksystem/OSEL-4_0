close all
clear
prompt = 'Select signal files to concatenate';
[filepn, filep, filen] = getFilepnAllCell(prompt, 'mat');
savep = getSavep('Where to save new long file?');

load(filepn{1})
for kf = 2 : numel(filepn)
    l = load(filepn{kf});
    for kch = 1 : size(sigTbl, 1)
        sigTbl.Data{kch} = [sigTbl.Data{kch}, l.sigTbl.Data{kch}];
        sigTbl.SigEnd(kch) = l.sigTbl.SigEnd(kch);
    end
end

save([savep, '/', filen{1}], 'sigTbl')






function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
    loadpath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
    if exist('startpath.mat', 'file')
        load('startpath.mat', 'loadpath');
    end
    [filen, filep] = uigetfile([loadpath '\*.' ext], prompt, 'MultiSelect', 'on');
    if ischar(filep)
        loadpath = filep;
        if exist('startpath.mat', 'file')
            save('startpath.mat', 'loadpath', '-append');
        else
            save('startpath.mat', 'loadpath');
        end
    end
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
function savep = getSavep(prompt)
    savepath = 'C:\Users\Kudlacek\Documents\Experiment\Matlab';
    if exist('startpath.mat', 'file')
        load('startpath.mat'); %#ok<LOAD>
    end
    savep = uigetdir(savepath, prompt);
    if ischar(savep)
        savepath = savep;
        save('startpath.mat', 'savepath', '-append');
    end
end