function lbl3sigTblCorrespondence01
    % [snlpn, ~, ~] = getFilepnAllCell('Select signal files subject list', 'xlsx');
    snlpn = {'N:\EEG conversion\MK008826\info\signalFileSubjectTbl.xlsx'};
    snlXlsx = readtable(snlpn{1});
    % [lblpn, ~, ~] = getFilepnAllCell('Select label files subject list', 'xlsx');
    lblpn = {'N:\EEG conversion\MK008826\info\labelFileSubjectTbl.xlsx'};
    lblXlsx = readtable(lblpn{1});
    % savep = getSavep('Where to save the resulting table');
    savep = 'N:\EEG conversion\MK008826\info';

    subjSnl = unique(snlXlsx.Subject);
    if numel(subjSnl) > 1
        disp(subjSnl)
        error('_jk Multiple subjects in signals.')
    end
    
    subjLbl = unique(snlXlsx.Subject);
    if numel(subjLbl) > 1
        disp(subjLbl)
        error('_jk Multiple subjects in signals.')
    end
    
    snlXlsx.LabelExists = zeros(height(snlXlsx), 1);

    for ks = 1 : height(snlXlsx)
        ks_ = ks
        [~, fn, ~] = fileparts(snlXlsx.FilePathName{ks});
        snlSdt = regexpi(fn, '.*\d\d\d\d\d\d_\d\d\d\d\d\d', 'match'); % Signal subject date time
        for kl =  1 : height(lblXlsx)
            [~, fn, ~] = fileparts(lblXlsx.FilePathName{kl});
            lblSdt = regexpi(fn, '.*\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
            if strcmp(snlSdt, lblSdt)
                snlXlsx.LabelExists(ks) = snlXlsx.LabelExists(ks) + 1;
            end
        end
    end
    snlXlsx
    
    savepn = fullfile(savep, 'signalLabelCorrespondenceTbl.xlsx')
    writetable(snlXlsx, savepn)
end





%% %%%%%%%%% %%
%% FUNCTIONS %%
%% %%%%%%%%% %%
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

