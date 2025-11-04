function [sigInfo, lblDef, lblSet] = loadLabel(filepn)
    [~, filen, ext] = fileparts(filepn);
    
    ss = strsplit(filen, '-');
    e = [ss{end}, ext];
    
    %% Add your data format as a case in this switch and implement a loading method below
    switch e
        case 'lbl3.mat'
            load(filepn, 'sigInfo', 'lblDef', 'lblSet');
            vrNm = lblSet.Properties.VariableNames;
            for k = 1 : length(vrNm)
                if isa(lblSet.(vrNm{k}), 'categorical')
                    lblSet.(vrNm{k}) = string(lblSet.(vrNm{k}));
                end
                lblSet.Comment(ismissing(lblSet.Comment)) = "";
            end
            lblSet = lblSet(lblSet.Channel > 0, :); % Remove negative channels. Negative channels are used in analyses (e.g. -1 is logical function any, -2 is logical function all).
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%% Functions for loading various data formats %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

% % % % % % % % %% WKJ mat-file
% % % % % % % % function sigTbl = loadWKJ(l)
% % % % % % % %     % Subject
% % % % % % % %     if isstring(l.subject)
% % % % % % % %         if length(l.subject) == size(l.s, 1)
% % % % % % % %             Subject = l.subject(:);
% % % % % % % %         elseif length(l.subject) == 1
% % % % % % % %             Subject = repelem(l.subject, size(l.s, 1))';
% % % % % % % %         end
% % % % % % % %     elseif iscell(l.subject)
% % % % % % % %         if length(l.subject) == size(l.s, 1)
% % % % % % % %             Subject = string(l.subject(:));
% % % % % % % %         elseif length(l.subject) == 1
% % % % % % % %             Subject = string(repelem(l.subject, size(l.s, 1))');
% % % % % % % %         end
% % % % % % % %     elseif ischar(l.subject)
% % % % % % % %         Subject = repelem(string(l.subject), size(l.s, 1))';
% % % % % % % %     else
% % % % % % % %         error(['_jk size(s) = ', num2str(size(s)), ' but subject = ', l.subject])
% % % % % % % %     end
% % % % % % % %     
% % % % % % % %     % Channel names
% % % % % % % %     ChName = string(l.chanNames')';
% % % % % % % %     
% % % % % % % %     % Sampling rate
% % % % % % % %     if length(l.fs) == size(l.s, 1)
% % % % % % % %         Fs = l.fs(:);
% % % % % % % %     elseif length(l.fs) == 1
% % % % % % % %         Fs = ones(size(l.s, 1), 1) * l.fs;
% % % % % % % %     else
% % % % % % % %         error(['_jk size(s) = ', num2str(size(s)), ' but size(fs) = ', num2str(size(fs))])
% % % % % % % %     end
% % % % % % % %     
% % % % % % % %     % Signal start in datenum format
% % % % % % % %     SigStart = datetime( ones(size(l.s, 1), 1) * l.dateN, 'ConvertFrom', 'datenum' );
% % % % % % % %     
% % % % % % % %     % Signal end in datenum format
% % % % % % % %     SigEnd = SigStart  +  size(l.s, 2)./Fs/3600/24;
% % % % % % % %         
% % % % % % % %     % Signal proper
% % % % % % % %     Data = l.s;
% % % % % % % %     
% % % % % % % %     % Create table
% % % % % % % %     sigTbl = table(Subject, ChName, SigStart, SigEnd, Fs, Data);
% % % % % % % % end
% % % % % % % % 
% % % % % % % % 
% % % % % % % % 
