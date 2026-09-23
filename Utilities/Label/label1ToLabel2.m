function label1ToLabel2
chnms = {'DHippR'; 'DHippR2'; 'MCxR'; 'MCxR2';
         'DHippL'; 'DHippL2'; 'MCxL'; 'MCxL2'};
chnms = {'PirR'; 'PirR2'; 'AmyR'; 'AmyR2'; 'PrhR'; 'PrhR2'; 'CA3R'; 'CA3R2'; 'DGR'; 'DGR2'; 'VHippR'; 'VHippR2'; 'SubR'; 'SubR2'; 'MECR'; 'MECR2';...
         'PirL'; 'PirL2'; 'AmyL'; 'AmyL2'; 'PrhL'; 'PrhL2'; 'CA3L'; 'CA3L2'; 'DGL'; 'DGL2'; 'VHippL'; 'VHippL2'; 'SubL'; 'SubL2'; 'MECL'; 'MECL2'};

sbj = 'jk20141113';

[filen, filep] = uigetfile('*.mat', 'Select Label1 files', 'MultiSelect', 'on');
savep = uigetdir;

for kf = 1 : length(filen)
    lbl1ToLbl2(filep, filen{kf}, savep, chnms, sbj)
disp(['File number ' kf])
end
disp('label1ToLabel2 finished')
end



function lbl1ToLbl2(filep, filen, savep, chnms, sbj)
load([filep '\' filen])
unitedCh = {'allCh'}; %#ok<NASGU>

for kn = 1 : length(label) %#ok<NODEF>
    finm = fieldnames(label);
    
    % Information common for all channels
    for kfi = 1 : length(finm)
        if ismember(finm{kfi}, {'name', 'color', 'instant'})
            lb.(label(kn).name).(finm{kfi}) = label(kn).(finm{kfi});
        end
    end
    
%     if isfield(lb.(label(kn).name), 'subject')
%         if iscell(lb.(label(kn).name).subject)
%             lb.(label(kn).name).subject = lb.(label(kn).name).subject{1};
%             if iscell(lb.(label(kn).name).subject)
%                 lb.(label(kn).name).subject = lb.(label(kn).name).subject{1};
%             end
%         end
%     end
    
    lb.(label(kn).name).chanNames = chnms;
    lb.(label(kn).name).subject = sbj;
    lb.(label(kn).name).srcSigFile = {filen};
    
    % Sort out by channels
    finm = fieldnames(label(kn));
    allch = unique(label(kn).chan);
    allPrimaryCh = allch(allch < 1000);
    for kch = 1 : length(allPrimaryCh)
        for kfi = 1 : length(finm)
            if ismember(finm{kfi}, {'name', 'color', 'instant', 'subject', 'fileDateStr'})
                continue
            end
            if strcmp(finm{kfi}, 'chanNames')
%                 lb.(label(kn).name).(['ch' num2str(allPrimaryCh(kch), '%02d')]).chanName = label(kn).chanNames{allPrimaryCh(kch)};
                lb.(label(kn).name).(['ch' num2str(allPrimaryCh(kch), '%02d')]).chanName = chnms{allPrimaryCh(kch)};
                continue
            end
            currentField = label(kn).(finm{kfi});
            switch finm{kfi}
                case 'pos'
%                     dateNfield = label(kn).fileDateN;
                    lb.(label(kn).name).(['ch' num2str(allPrimaryCh(kch), '%02d')]).posN =...
                        currentField(label(kn).chan == allPrimaryCh(kch))/3600/24 + label(kn).fileDateN(label(kn).chan == allPrimaryCh(kch));
                case 'dur'
                    lb.(label(kn).name).(['ch' num2str(allPrimaryCh(kch), '%02d')]).durN =...
                        currentField(label(kn).chan == allPrimaryCh(kch))/3600/24;
                otherwise
                    lb.(label(kn).name).(['ch' num2str(allPrimaryCh(kch), '%02d')]).(finm{kfi}) = currentField(label(kn).chan == allPrimaryCh(kch));
            end
        end
    end
    
% %     allSecondaryCh = allch(allch >= 1000);
%     allSecondaryCh = 1001;
%     for kch = 1 : length(allSecondaryCh)
%         for kfi = 1 : length(finm)
%             if ismember(finm{kfi}, {'name', 'color', 'instant', 'subject', 'fileDateStr'})
%                 continue
%             end
%             if strcmp(finm{kfi}, 'chanNames')
% %                 lb.(label(kn).name).(['ch' num2str(allPrimaryCh(kch), '%02d')]).chanName = label(kn).chanNames{allPrimaryCh(kch)};
%                 lb.(label(kn).name).(unitedCh{allSecondaryCh(kch)-1000}).chanNames = chnms;
%                 continue
%             end
%             currentField = label(kn).(finm{kfi});
%             lb.(label(kn).name).(unitedCh{allSecondaryCh(kch)-1000}).(finm{kfi}) = currentField(label(kn).chan == allSecondaryCh(kch));
%         end
%     end
end
label = lb; %#ok<NASGU>
save([savep '\' filen], 'label')
assignin('base', 'lb', lb)
end