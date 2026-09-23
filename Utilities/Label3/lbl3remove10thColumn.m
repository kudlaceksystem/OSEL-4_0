% keepFirst9Columns_lblSet.m
folder = 'n:\EEG conversion\MoniET534\Label\';
files = dir(fullfile(folder,'*.mat'));

for k = 1:numel(files)
    fn = fullfile(folder, files(k).name);
    S = load(fn);                  % load all variables into struct S

    if isfield(S,'lblSet') && istable(S.lblSet)
        T = S.lblSet;
        if width(T) > 9
            % Keep only first 9 columns
            T = T(:,1:9);
            S.lblSet = T;
            save(fn, '-struct', 'S');    % overwrite .mat with modified variables
            fprintf('Truncated lblSet to 9 cols in %s\n', files(k).name);
        else
            fprintf('lblSet has %d columns in %s — no change\n', width(T), files(k).name);
        end
    else
        fprintf('No table lblSet in %s\n', files(k).name);
    end
end