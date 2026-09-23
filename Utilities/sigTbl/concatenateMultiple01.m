close all
clear
format compact
prompt = 'Select signal files to concatenate';
[filepn, filep, filen] = getFilepnAllCell(prompt, 'mat');
savep = getSavep('Where to save new long files'); 
minFileDurS = 3600;

r = regexp(filen, '\d\d\d\d\d\d\_\d\d\d\d\d\d', 'match')';
dtShort = cellfun(@(x)datetime(x, 'InputFormat', 'yyMMdd_HHmmss'), r, 'UniformOutput', true);

dtShortPointer = 1;
while dtShortPointer <= numel(dtShort)
    numAdditionalFiles = 0;
    if dtShortPointer <= numel(dtShort) - 1
        while dtShort(dtShortPointer + numAdditionalFiles + 1) - dtShort(dtShortPointer) < seconds(minFileDurS)
            if dtShortPointer + numAdditionalFiles + 2 <= numel(dtShort)
                numAdditionalFiles = numAdditionalFiles + 1;
            else
                break
            end
        end
    end
    disp([num2str(dtShortPointer), '/', num2str(numel(filen))])
    load(filepn{dtShortPointer})
    for kaf = 1 : numAdditionalFiles
        disp([num2str(dtShortPointer + kaf), '/', num2str(numel(filen))])
        l = load(filepn{dtShortPointer + kaf});
        if ~all(l.sigTbl.ChName == sigTbl.ChName)
            disp(filepn{dtShortPointer})
            disp(filepn{dtShortPointer + kaf})
            error('_jk concatenateMultiple01 Different channels.')
        end
        for kch = 1 : size(sigTbl, 1)
            sigTbl.Data{kch} = [sigTbl.Data{kch}, l.sigTbl.Data{kch}];
            sigTbl.SigEnd(kch) = l.sigTbl.SigEnd(kch);
        end
    end
    save([savep, '/', filen{dtShortPointer}], 'sigTbl')
    dtShortPointer = dtShortPointer + numAdditionalFiles + 1;
    clear sigTbl l
end
disp('Finished')
disp('Long files are in')
disp(savep)





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