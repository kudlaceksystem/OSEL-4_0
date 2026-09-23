function lbl3JoinFiles02
% Does not check whether there is the same number of channels in both lbl3 files. Requires only one subject in all files.

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
            [~, saven, ~] = fileparts(filen1{kf});
            ss = strsplit(saven, '-');
            savepne = [savep, '\', ss{1}, '-', ss{2}, '-lbl3.mat'];
            save(savepne, 'sigInfo', 'lblDef', 'lblSet')
            continue
        end
        l2 = load(filepn2{whichFile});
%         if ~isempty(l2.lblSet)
            l2.lblSet.ClassName = string(l2.lblSet.ClassName);
            l2.lblSet.Comment = string(l2.lblSet.Comment);
            l2.lblSet.SignalFile = string(l2.lblSet.SignalFile);
            if ~all(sigInfo.Subject == sigInfo.Subject(1))
                disp(filepn1{kf})
                disp(lblInfo)
                error('_jk Multiple subjects')
            end
            if ~all(l2.sigInfo.Subject == sigInfo.Subject(1))
                disp(filepn1{kf})
                disp(filepn2{whichFile})
                disp(sigInfo)
                disp(l2.sigInfo)
                error('_jk Subjects do not correspond')
            end
            if size(l2.sigInfo, 1) ~= size(sigInfo)
                minCh = min(size(l2.sigInfo, 1), size(sigInfo, 1));
                if ~all(l2.sigInfo.ChName(1 : minCh) == sigInfo.ChName(1 : minCh))
                    disp(sigInfo)
                    disp(l2.sigInfo)
                    error('_jk Channels do not correspond')
                else
                    if size(l2.sigInfo, 1) > size(sigInfo)
                        sigInfo = l2.sigInfo;
                    end
                end
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
        d = dir(savep);
        dn = {d.name};
        filen1 = dn(~[d.isdir]);
        filepn1 = fullfile(savep, filen1);
        whichFile = find(contains(filepn1, dtc));
        if isempty(whichFile)
            [~, saven, ~] = fileparts(filen2{kf});
            ss = strsplit(saven, '-');
            savepne = [savep, '\', ss{1}, '-', ss{2}, '-lbl3.mat'];
            save(savepne, 'sigInfo', 'lblDef', 'lblSet')
            continue
        end
        l1 = load(fullfile(savep, filen1{whichFile}));
        l1.lblSet.ClassName = string(l1.lblSet.ClassName);
        l1.lblSet.Comment = string(l1.lblSet.Comment);
        l1.lblSet.SignalFile = string(l1.lblSet.SignalFile);
        if ~all(sigInfo.Subject == sigInfo.Subject(1))
            disp(filepn1{whichFile})
            disp(sigInfo)
            error('_jk Multiple subjects')
        end
        if ~all(l1.sigInfo.Subject == sigInfo.Subject(1))
            disp(filepn1{whichFile})
            disp(filepn2{kf})
            disp(sigInfo)
            disp(l1.sigInfo)
            error('_jk Subjects do not correspond')
        end
        if size(l1.sigInfo, 1) ~= size(sigInfo)
            minCh = min(size(l1.sigInfo, 1), size(sigInfo, 1));
            if ~all(l1.sigInfo.ChName(1 : minCh) == sigInfo.ChName(1 : minCh))
                disp(sigInfo)
                disp(l1.sigInfo)
                error('_jk Channels do not correspond')
            else
                if size(l1.sigInfo, 1) > size(sigInfo)
                    sigInfo = l1.sigInfo;
                end
            end
        end
        lblDef = [lblDef; l1.lblDef]; %#ok<AGROW>
        lblSet = [lblSet; l1.lblSet]; %#ok<AGROW>
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

