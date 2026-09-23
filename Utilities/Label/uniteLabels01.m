function uniteLabels01
close all
lblallnm = 'unitedLabel';
color = '1 0 1';
[filepn, ~, filen] = getFilepnAllCell('Select label files', 'mat');
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
savep = uigetdir(startpath, 'Where to save modified label files');
save('startpath.mat', 'startpath');

% savep = 'G:\WKJ complete_20190125 - LABELED\jc20181211_1  - complete first 14 days EEG - seizures present-labels marked\lbl avRef sz ied - work3'

hwb = waitbar(0, 'Label unification in progress...')
for kf = 1 : length(filepn)
waitbar(kf/length(filepn))
kf
filepn{kf}
    load(filepn{kf})
    lblnm = fieldnames(label);
    subject = [];
    srcSigFile = [];
    chanNames = [];
    chnmall = [];
    for klbl = 1 : length(lblnm)
        sbj = label.(lblnm{klbl}).subject;
        if ~isempty(subject)
            if ~strcmp(subject, sbj)
                error('jk subject names different between labels')
            end
        else
            subject = sbj;
        end
        
        if isfield(label.(lblnm{klbl}), 'srcSigFile')
            ssf = label.(lblnm{klbl}).srcSigFile;
%             if ~isempty(srcSigFile)
%                 if ~strcmp(srcSigFile, ssf)
% srcSigFile
% ssf
%                     error('jk srcSigFile different between labels')
%                 end
%             else
                srcSigFile = ssf;
%             end
        end
        
        if isfield(label.(lblnm{klbl}), 'chanNames')
            if ~isempty(label.(lblnm{klbl}).chanNames)
                chanNames = label.(lblnm{klbl}).chanNames;
            end
        end
        if label.(lblnm{klbl}).instant
            continue
        end
        chnm = fieldnames(label.(lblnm{klbl}));
        chnm = chnm(contains(chnm, 'ch'));
        chnm = chnm(~contains(chnm, 'cha'));
        for kc = 1 : length(chnm)
            if all(~strcmp(chnmall, chnm{kc}))
                chnmall = [chnmall, chnm(kc)];
            end
        end
    end
    
    label.(lblallnm).name = lblallnm;
    label.(lblallnm).color = color;
    label.(lblallnm).instant = 0;
    label.(lblallnm).chanNames = chanNames;
    label.(lblallnm).subject = subject;
    label.(lblallnm).srcSigFile = srcSigFile;
    
    for kch = 1 : length(chnmall)
        label.(lblallnm).(chnmall{kch}).posN = [];
        label.(lblallnm).(chnmall{kch}).durN = [];
        label.(lblallnm).(chnmall{kch}).value = [];
        label.(lblallnm).(chnmall{kch}).fileDateN = [];
        label.(lblallnm).(chnmall{kch}).fileEndN = [];
        for klbl = 1 : length(lblnm)
            if label.(lblnm{klbl}).instant
                continue
            end
            if isfield(label.(lblnm{klbl}), chnmall{kch})
                label.(lblallnm).(chnmall{kch}).posN = [label.(lblallnm).(chnmall{kch}).posN, label.(lblnm{klbl}).(chnmall{kch}).posN];
                label.(lblallnm).(chnmall{kch}).durN = [label.(lblallnm).(chnmall{kch}).durN, label.(lblnm{klbl}).(chnmall{kch}).durN];
                label.(lblallnm).(chnmall{kch}).value = [label.(lblallnm).(chnmall{kch}).value, label.(lblnm{klbl}).(chnmall{kch}).value];
                if isfield(label.(lblnm{klbl}).(chnmall{kch}), 'fileDateN')
                    label.(lblallnm).(chnmall{kch}).fileDateN = [label.(lblallnm).(chnmall{kch}).fileDateN, label.(lblnm{klbl}).(chnmall{kch}).fileDateN];
                end
                if isfield(label.(lblnm{klbl}).(chnmall{kch}), 'fileEndN')
                    label.(lblallnm).(chnmall{kch}).fileEndN = [label.(lblallnm).(chnmall{kch}).fileEndN, label.(lblnm{klbl}).(chnmall{kch}).fileEndN];
                end
            end
        end
    end
save([savep, '\', filen{kf}], 'label')
end
delete(hwb)
'Finished'
end

function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('startpath.mat');
catch
    startpath = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([startpath '\' ext], prompt, 'MultiSelect', 'on');
startpath = filep; save('startpath.mat', 'startpath');
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
startpath = filep;
end



