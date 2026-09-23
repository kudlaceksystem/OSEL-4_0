function lbl3JoinFiles
    [filepn1, ~, filen1] = getFilepnAllCell('Select label files 1', 'mat');
    [filepn2, ~, filen2] = getFilepnAllCell('Select label files 2', 'mat');
    savep = getSavep('Where to save modified label files');
    
    %% Add second group to the label files from the first group
    for kf = 1 : length(filepn1)
        load(filepn1{kf}, 'sigInfo', 'lblDef', 'lblSet');
        lblSet.ClassName = string(lblSet.ClassName);
        lblSet.Comment = string(lblSet.Comment);
        lblSet.SignalFile = string(lblSet.SignalFile);
        dtc = regexp(filen1{kf}, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
        whichFile = find(contains(filepn2, dtc));
        if isempty(whichFile)
            [~, saven, savee] = fileparts(filen1{kf});
            savepne = [savep, '\', saven, savee];
            save(savepne, 'sigInfo', 'lblDef', 'lblSet')
            continue
        end
        l2 = load(filepn2{whichFile});
%         if ~isempty(l2.lblSet)
            l2.lblSet.ClassName = string(l2.lblSet.ClassName);
            l2.lblSet.Comment = string(l2.lblSet.Comment);
            l2.lblSet.SignalFile = string(l2.lblSet.SignalFile);
            if ~all(size(sigInfo.Subject) == size(l2.sigInfo.Subject))
                disp(filepn1{kf})
                disp(filepn2{kf})
                disp(size(sigInfo.Subject))
                disp(size(l2.sigInfo.Subject))
                error('_jk Different number of channels')
            end
            if ~all(sigInfo.Subject == l2.sigInfo.Subject)
                disp(filepn1{kf})
                disp(filepn2{kf})
                disp(sigInfo.Subject)
                disp(l2.sigInfo.Subject)
                error('_jk Different subjects')
            end
            if ~all(sigInfo.ChName == l2.sigInfo.ChName)
                disp(filepn1{kf})
                disp(filepn2{kf})
                disp(sigInfo.ChName)
                disp(l2.sigInfo.ChName)
                error('_jk Different subjects')
            end
            lblDef = [lblDef; l2.lblDef]; %#ok<AGROW>
            lblSet = [lblSet; l2.lblSet]; %#ok<AGROW>
%         end
        [~, saven, ~] = fileparts(filen1{kf});
        ss = strsplit(saven, '-');
        savepne = [savep, '\', ss{1}, '-', ss{2}, '-lbl3.mat'];
        save(savepne, 'sigInfo', 'lblDef', 'lblSet')
    end
    
    %% Add first group to the results
    for kf = 1 : length(filepn2)
        load(filepn2{kf}, 'sigInfo', 'lblDef', 'lblSet');
        lblSet.ClassName = string(lblSet.ClassName);
        lblSet.Comment = string(lblSet.Comment);
        lblSet.SignalFile = string(lblSet.SignalFile);
        dtc = regexp(filen2{kf}, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
        whichFile = find(contains(filepn1, dtc));
        if isempty(whichFile)
            [~, saven, savee] = fileparts(filen2{kf});
            savepne = [savep, '\', saven, savee];
            save(savepne, 'sigInfo', 'lblDef', 'lblSet')
            continue
        end
        l1 = load(fullfile(savep, filen1{whichFile}));
        l1.lblSet.ClassName = string(l1.lblSet.ClassName);
        l1.lblSet.Comment = string(l1.lblSet.Comment);
        l1.lblSet.SignalFile = string(l1.lblSet.SignalFile);
        if ~all(size(sigInfo.Subject) == size(l1.sigInfo.Subject))
            disp(filepn1{kf})
            disp(filepn2{kf})
            disp(size(sigInfo.Subject))
            disp(size(l1.sigInfo.Subject))
            error('_jk Different number of channels')
        end
        if ~all(sigInfo.Subject == l1.sigInfo.Subject)
            disp(filepn1{kf})
            disp(filepn2{kf})
            disp(sigInfo.Subject)
            disp(l2.sigInfo.Subject)
            error('_jk Different subjects')
        end
        if ~all(sigInfo.ChName == l1.sigInfo.ChName)
            disp(filepn1{kf})
            disp(filepn2{kf})
            disp(sigInfo.ChName)
            disp(l2.sigInfo.ChName)
            error('_jk Different subjects')
        end
        lblDef = [lblDef; l1.lblDef]; %#ok<AGROW>
        lblSet = [lblSet; l1.lblSet]; %#ok<AGROW>
% % % % % % %         [~, saven, savee] = fileparts(filen2{kf});
% % % % % % %         savepne = [savep, '\', saven, savee];
        [~, saven, ~] = fileparts(filen2{kf});
        ss = strsplit(saven, '-');
        savepne = [savep, '\', ss{1}, '-', ss{2}, '-lbl3.mat'];
        save(savepne, 'sigInfo', 'lblDef', 'lblSet')
    end
    
    %% Remove duplicates, set new IDs (so that they are unique)
    d = dir([savep, '\*lbl3.mat']);
    filepn = fullfile(savep, {d.name}');
    for kf = 1 : size(filepn, 1)
        load(filepn{kf})
        [~, idx] = unique(lblSet(:, 1 : 5), 'rows', 'first');
        lblSet = lblSet(sort(idx), :);
        lblSet.ID = (1 : size(lblSet, 1))';
        save(filepn{kf}, 'sigInfo', 'lblDef', 'lblSet')
    end
    disp('Finished')
end

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

