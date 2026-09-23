function detectorEvaluation02
filep = 'd:\Kudlacek\Experiment\Long-term analysis\Doctoral thesis\Critical slowing\Preictal rat 180809\Detector evaluation\Epi lbl man and det\';
d = dir(filep);
filen = {d.name};
filen = filen(~[d.isdir]);

% gsName = 'SWKudlacek01'; % Field of label structure containing gold standard
% detName = 'SWDetector01'; % Field of label structure containing detector detections
gsName = 'ThetaKudlacek01'; % Field of label structure containing gold standard
detName = 'ThetaJK3'; % Field of label structure containing detector detections

totalS = 1200; % Seconds


for kf = 1 : length(filen)
%     filen{kf}
    filepn = [filep, filen{kf}];
    l = load(filepn);
    % Gold standard
    if isfield(l.label.(gsName), 'ch02')
        gsOn = (l.label.(gsName).ch02.posN - l.label.(gsName).ch02.fileDateN)*3600*24;
        gsOff = gsOn + l.label.(gsName).ch02.durN*3600*24;
    else
        gsOn = [];
        gsOff = [];
    end
    tax = 0 : 10000;
    gs = zeros(size(tax));
    gs(round(gsOn) + 1) = 1;
    gs(round(gsOff) + 1) = -1;
    gs = cumsum(gs);
    gs = gs(totalS : 3600);
    
    
    % Detector
    detOn = (l.label.(detName).ch01.posN - l.label.(detName).ch01.fileDateN)*3600*24;
    detOff = detOn + l.label.(detName).ch01.durN*3600*24;
    tax = 0 : 10000;
    det = zeros(size(tax));
    det(round(detOn) + 1) = 1;
    det(round(detOff) + 1) = -1;
    det = cumsum(det);
    det = det(totalS : 3600);
    
    tp = gs & det;
    fp = ~gs & det;
    tn = ~gs & ~det;
    fn = gs & ~det;
    
    totS(kf) = 3600 - totalS;
    gsTotalS(kf) = sum(gs);
    detTotalS(kf) = sum(det);
    nongsTotalS(kf) = sum(~gs);
    tpS(kf) = sum(tp);
    fpS(kf) = sum(fp);
    tnS(kf) = sum(tn);
    fnS(kf) = sum(fn);
%     prevalence(kf) = gsTotalS/totalS;
%     ppv(kf) = tpS/detTotalS;
%     sensitivity(kf) = tpS/gsTotalS;
%     npv(kf) = tnS/nonGsTotalS;
%     fpr(kf) = fpS/totalS;
end
TOT = sum(totS);
GS = sum(gsTotalS);
NONGS = sum(nongsTotalS);
DET = sum(detTotalS);
TP = sum(tpS);
FP = sum(fpS);
TN = sum(tnS);
FN = sum(fnS);
PREV = GS/TOT
SEN = TP/GS
PPV = TP/DET
NPV = TN/NONGS
ACC = (TP + TN)/TOT
end


