function addLabel
srcType = 'Vojta1';
[srcpn, ~, ~] = getFilepnAllCell('Select source files whose marker type will be added', 'mat');
[mainpn, ~, mainn] = getFilepnAllCell('Select files to which new marker type will be added', 'mat');
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
savep = uigetdir(path, 'Where to save modified files');

switch srcType
    case 'Vojta1'
        load(srcpn{1})
        name = 'SeizVojta1';
        color = '1 0.2 0';
        instant = false;
        for kf = 1 : length(mainpn)
kf
            load(mainpn{kf})
            
            label = addMarkerType(label, name, color, instant);
                        
            ssplit = strsplit(mainn{kf}, '-');
            fileDateN = datenum(ssplit{2}, 'yymmdd_HHMMSS');
            if kf < length(mainn)
                ssplitnext = strsplit(mainn{kf + 1}, '-');
                fileDateNnext = datenum(ssplitnext{2}, 'yymmdd_HHMMSS');
                whichBelongHerei = chan(1).seizPos > fileDateN & chan(1).seizPos < fileDateNnext;
            else
                whichBelongHerei = chan(1).seizPos > fileDateN;
            end
            
            for kch = 1 : 8
                chname = ['ch' num2str(kch, '%02.0f')];
                label.(name).(chname).posN = chan(1).seizPos(whichBelongHerei);
                label.(name).(chname).durN = chan(1).seizDur(whichBelongHerei);
                label.(name).(chname).value = 6*ones(1, sum(double(whichBelongHerei)));
                label.(name).(chname).fileDateN = fileDateN;
            end
            label.(name).chAll.posN = chan(1).seizPos(whichBelongHerei);
            label.(name).chAll.durN = chan(1).seizDur(whichBelongHerei);
            label.(name).chAll.value = 6*ones(1, sum(double(whichBelongHerei)));
            label.(name).chAll.fileDateN = fileDateN;
            save([savep '\' mainn{kf}], 'label')
            clear label
        end
        
%     case 'jk_elSeizInduction'
% %         load(srcpn{1})
%         name = 'elSeizInduction';
%         color = '0 0 0';
%         instant = true;
%         for kf = 1 : length(mainpn)
% kf
%             load(mainpn{kf})
%             label = addMarkerType(label, name, color, instant); % Inicialize new marker
%             ssplit = strsplit(mainn{kf}, '-');
%             fileDateN = datenum(ssplit{2}, 'yymmdd_HHMMSS');
%             if kf < length(mainn) % If it is not the last main file
%                 ssplitnext = strsplit(mainn{kf + 1}, '-');
%                 fileDateNnext = datenum(ssplitnext{2}, 'yymmdd_HHMMSS');
%                 whichBelongHerei = mkPos > fileDateN & mkPos < fileDateNnext;
%             else
%                 whichBelongHerei = mkPos > fileDateN;
%             end
%             
%             for kch = 1 : 1
%                 chname = ['ch' num2str(kch, '%02.0f')];
%                 label.(name).(chname).posN = chan(1).seizPos(whichBelongHerei);
%                 label.(name).(chname).durN = chan(1).seizDur(whichBelongHerei);
%                 label.(name).(chname).value = 6*ones(1, sum(double(whichBelongHerei)));
%                 label.(name).(chname).fileDateN = fileDateN;
%             end
%             label.(name).chAll.posN = chan(1).seizPos(whichBelongHerei);
%             label.(name).chAll.durN = chan(1).seizDur(whichBelongHerei);
%             label.(name).chAll.value = 6*ones(1, sum(double(whichBelongHerei)));
%             label.(name).chAll.fileDateN = fileDateN;
%             save([savep '\' mainn{kf}], 'label')
%             clear label
%         end
end
'addLabel finished'
end

function label = addMarkerType(label, name, color, instant)
    label.(name).name = name;
    label.(name).color = color;
    label.(name).instant = instant;
    label.(name).chanNames = label.SeizKudlacek.chanNames;
    label.(name).subject = label.SeizKudlacek.subject;
    label.(name).srcSigFile = label.SeizKudlacek.srcSigFile;
end


function [filepn, filep, filen] = getFilepnAllCell(prompt, ext)
try
    load('path.mat');
catch
    path = 'D:\Kudlacek\*.';
end
[filen, filep] = uigetfile([path '\' ext], prompt, 'MultiSelect', 'on');
path = filep; save('path.mat', 'path');
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
path = filep;
end
