% renameSelectInMATs.m
folder = 'n:\EEG conversion\MoniET534\Label\';
files = dir(fullfile(folder,'*.mat'));

for k = 1:numel(files)
    fn = fullfile(folder, files(k).name);
    S = load(fn);                % load all variables into struct S

    if isfield(S,'lblSet') && istable(S.lblSet)
        T = S.lblSet;
        if any(strcmp(T.Properties.VariableNames,'Select'))
            % Rename the variable
            T = renamevars(T,'Select','Selected');  % requires R2019b or later
            S.lblSet = T;
            % Overwrite the .mat file with the modified variables in S
            save(fn, '-struct', 'S');
            fprintf('Renamed in %s\n', files(k).name);
        else
            fprintf('No "Select" column in lblSet for %s\n', files(k).name);
        end
    else
        fprintf('No table lblSet in %s\n', files(k).name);
    end
end