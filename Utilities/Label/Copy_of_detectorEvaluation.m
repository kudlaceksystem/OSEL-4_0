function detectorEvaluation

fp = 'i:\Labels for detector evaluation\modified1\';
% 'All'
% fn = {'jk20170323_1-170412_145119-A2b_A-E-092-lbl.mat';
% 'jk20170323_1-170412_152617-A2b_A-E-093-lbl.mat';
% 'jk20170323_1-170416_150535-A2b_A-E-145-lbl.mat';
% 'jk20170323_1-170416_153849-A2b_A-E-146-lbl.mat';
% 'jk20170323_1-170420_170021-A2b_A-E-199-lbl.mat';
% 'jk20170323_1-170420_171741-A2b_A-E-199-lbl.mat';
% 'jk20170323_1-170424_152313-A2b_A-E-251-lbl.mat';
% 'jk20170323_1-170424_160844-A2b_A-E-251-lbl.mat';
% 'jk20170323_2-170412_144546-A2b_B-E-092-lbl.mat';
% 'jk20170323_2-170412_153650-A2b_B-E-093-lbl.mat';
% 'jk20170323_2-170416_151649-A2b_B-E-145-lbl.mat';
% 'jk20170323_2-170416_160833-A2b_B-E-146-lbl.mat';
% 'jk20170323_2-170420_161614-A2b_B-E-199-lbl.mat';
% 'jk20170323_2-170420_171724-A2b_B-E-199-lbl.mat';
% 'jk20170323_2-170424_154500-A2b_B-E-251-lbl.mat';
% 'jk20170323_2-170424_163621-A2b_B-E-252-lbl.mat';
% 'jk20170323_3-170412_144633-A2b_C-E-092-lbl.mat';
% 'jk20170323_3-170412_154008-A2b_C-E-093-lbl.mat';
% 'jk20170323_3-170416_151209-A2b_C-E-145-lbl.mat';
% 'jk20170323_3-170416_164130-A2b_C-E-146-lbl.mat';
% 'jk20170323_3-170420_155537-A2b_C-E-198-lbl.mat';
% 'jk20170323_3-170420_164347-A2b_C-E-199-lbl.mat';
% 'jk20170323_3-170424_153229-A2b_C-E-251-lbl.mat';
% 'jk20170323_3-170424_155925-A2b_C-E-251-lbl.mat'};

% 'CtrlLEV'
% fn = {'jk20170323_1-170412_145119-A2b_A-E-092-lbl.mat';
% 'jk20170323_1-170412_152617-A2b_A-E-093-lbl.mat';
% 'jk20170323_2-170420_161614-A2b_B-E-199-lbl.mat';
% 'jk20170323_2-170420_171724-A2b_B-E-199-lbl.mat';
% 'jk20170323_3-170416_151209-A2b_C-E-145-lbl.mat';
% 'jk20170323_3-170416_164130-A2b_C-E-146-lbl.mat'};

% 'CtrlLCM'
% fn = {'jk20170323_1-170420_170021-A2b_A-E-199-lbl.mat';
% 'jk20170323_1-170420_171741-A2b_A-E-199-lbl.mat';
% 'jk20170323_2-170412_144546-A2b_B-E-092-lbl.mat';
% 'jk20170323_2-170412_153650-A2b_B-E-093-lbl.mat';
% 'jk20170323_3-170424_153229-A2b_C-E-251-lbl.mat';
% 'jk20170323_3-170424_155925-A2b_C-E-251-lbl.mat'};
% 
% 'LEV'
% fn = {'jk20170323_1-170424_152313-A2b_A-E-251-lbl.mat';
% 'jk20170323_1-170424_160844-A2b_A-E-251-lbl.mat';
% 'jk20170323_2-170416_151649-A2b_B-E-145-lbl.mat';
% 'jk20170323_2-170416_160833-A2b_B-E-146-lbl.mat';
% 'jk20170323_3-170412_144633-A2b_C-E-092-lbl.mat';
% 'jk20170323_3-170412_154008-A2b_C-E-093-lbl.mat';};
% 
% 'LCM'
% fn = {'jk20170323_1-170416_150535-A2b_A-E-145-lbl.mat';
% 'jk20170323_1-170416_153849-A2b_A-E-146-lbl.mat';
% 'jk20170323_2-170424_154500-A2b_B-E-251-lbl.mat';
% 'jk20170323_2-170424_163621-A2b_B-E-252-lbl.mat';
% 'jk20170323_3-170420_155537-A2b_C-E-198-lbl.mat';
% 'jk20170323_3-170420_164347-A2b_C-E-199-lbl.mat'};


gsName = 'JK_SWR'; % Field of label structure containing gold standard
detName = 'RIPPLE'; % Field of label structure containing detector detections
chNames = repelem({'ch05', 'ch04', 'ch05'}, 8);
reqDetInGS = 0;
reqGSInDet = 0.5;
% fs = 1000;

for kf = 1 : length(fn)
    chName = chNames{kf};
    fpn = [fp, fn{kf}];
    l = load(fpn);
    [posNgs, durNgs, posNdet, durNdet] = getPosDur(l, gsName, detName, chName);
    TPvec = zeros(length(posNdet), 1);
    wasDiscovered = zeros(length(posNgs), 1); % Was this GS marker discovered by at least one detection?
    for km = 1 : length(posNdet)
        susp1 = posNgs + durNgs > posNdet(km); % Suspected 1 (gs endings after det beginning)
        susp2 = posNgs < posNdet(km) + durNdet(km); % Suspected 2 (gs beginning before det ending)
        suspl = logical(susp1) & logical(susp2); % Logical index into gs
        if sum(double(suspl)) == 0
            TPvec(km) = 0;
        else
            suspsub = find(suspl);
            for ks = 1 : length(suspsub)
                overl(ks) = min(posNgs(suspsub(ks))+durNgs(suspsub(ks)), posNdet(km)+durNdet(km)) - max(posNgs(suspsub(ks)), posNdet(km));
            end
            overlap = sum(overl);
            durNgsAll = sum(durNgs(suspsub));
            if overlap/durNgsAll > reqDetInGS && overlap/durNdet(km) > reqGSInDet
                TPvec(km) = 1;
                wasDiscovered(suspl) = 1;
            else
                TPvec(km) = 0;
            end
        end
    end
    TPfile(kf) = sum(TPvec);
    FPfile(kf) = sum(double(~logical(TPvec)));
    FNfile(kf) = sum(double(~logical(wasDiscovered)));
end
TP = sum(TPfile)
FP = sum(FPfile)
FN = sum(FNfile)
Sensitivity = TP/(TP + FN)
PPV = TP/(TP + FP)
end


function [posNgs, durNgs, posNdet, durNdet] = getPosDur(l, gsName, detName, chName)
posNgs = [];
durNgs = [];
posNdet = [];
durNdet = [];
if isfield(l.label, gsName)
    if isfield(l.label.(gsName), chName)
        if isfield(l.label.(gsName).(chName), 'posN')
            posNgs = l.label.(gsName).(chName).posN;
            durNgs = l.label.(gsName).(chName).durN;
        end
    end
end
if isfield(l.label, detName)
    if isfield(l.label.(detName), chName)
        if isfield(l.label.(detName).(chName), 'posN')
            posNdet = l.label.(detName).(chName).posN;
            durNdet = l.label.(detName).(chName).durN;
        end
    end
end
end


% function [gst, dett] = loadIntoTimeAx(fpn, gsName, detName, chName, fs)
% l = load(fpn);
% posNgs = l.label.(gsName).(chName).posN;
% durNgs = l.label.(gsName).(chName).durN;
% tbe = min(posNgs); % Beginning of time axis
% ten = max(posNgs + durNgs); % End of time axis
% tax = zeros(fix((ten - tbe)*24*3600*fs), 1);
% gst = tax;
% for km = 1 : length(posN)
%     gst(fix((posN(km) - tbe)*24*3600*fs) + 1 : fix((posN(km) + durN(km) - tbe)*24*3600*fs)) = 1;
% end
% for km = 1
% gst = []
% dett = []
% end