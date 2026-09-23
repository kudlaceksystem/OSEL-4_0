function replaceStringsInTables(srcFolder, dstFolder, patternOld, patternNew)
% replaceSKInTables Replace substring in all table variables in MAT-files.
%   replaceSKInTables(srcFolder,dstFolder) searches for *.mat files in
%   srcFolder, loads each file, finds table variables, replaces every
%   occurrence of "SK00918" with "SK000918" inside those tables, and saves
%   the modified table variables to MAT-files with the same names in
%   dstFolder.
%
%   replaceSKInTables(...,patternOld,patternNew) lets you override the
%   default substrings.
%
%   Example:
%     replaceSKInTables('C:\data\in','C:\data\out')
%
% Notes:
% - The function preserves variable names and saves only the modified table
%   variables into the output .mat file.
% - It handles nested cells, string arrays, char arrays, and categorical data.

    if nargin < 3 || isempty(patternOld), patternOld = "SKSK000918"; end
    if nargin < 4 || isempty(patternNew), patternNew = "SK000918"; end

    if ~isfolder(srcFolder)
        error('Source folder does not exist: %s', srcFolder);
    end
    if ~isfolder(dstFolder)
        mkdir(dstFolder);
    end

    files = dir(fullfile(srcFolder, '*.mat'));
    for fi = 1:numel(files)
        srcPath = fullfile(files(fi).folder, files(fi).name);
        S = load(srcPath);                 % load all variables into struct S
        vars = fieldnames(S);

        % Collect modified variables to save
        outStruct = struct();

        for v = 1:numel(vars)
            vname = vars{v};
            val = S.(vname);
            if istable(val)
                % Modify table in-place
                val = replaceInTable(val, patternOld, patternNew);
                outStruct.(vname) = val;
            end
        end

        % If no table variables found, still write an empty file? Skip instead.
        if isempty(fieldnames(outStruct))
            % nothing to save; skip
            fprintf('No tables in %s — skipped.\n', files(fi).name);
            continue
        end

        dstPath = fullfile(dstFolder, files(fi).name);
        save(dstPath, '-struct', 'outStruct', '-v7.3'); % use -v7.3 for safety
        fprintf('Processed %s -> %s\n', files(fi).name, dstPath);
    end
end

%% Helper: replaceInTable
function T = replaceInTable(T, oldStr, newStr)
% Walk each variable in table and replace occurrences of oldStr with newStr.

    varNames = T.Properties.VariableNames;
    for k = 1:numel(varNames)
        col = T.(varNames{k});
        col = replaceInValue(col, oldStr, newStr);
        T.(varNames{k}) = col;
    end
end

%% Helper: replaceInValue (recursive for cells)
function out = replaceInValue(x, oldStr, newStr)
% Replace occurrences in different container types.

    % Strings
    if isstring(x)
        out = replace(x, oldStr, newStr);
        return
    end

    % Char arrays (column vector of char rows or char matrix)
    if ischar(x)
        % If char matrix or char row vector, convert to string and back
        s = string(x);
        s = replace(s, oldStr, newStr);
        out = char(s);
        return
    end

    % Cell arrays: recursively apply to each element
    if iscell(x)
        out = x;
        for i = 1:numel(x)
            out{i} = replaceInValue(x{i}, oldStr, newStr);
        end
        return
    end

    % Categorical
    if isa(x, 'categorical')
        cats = categories(x);
        cats = string(cats);                % convert to string array
        cats = replace(cats, oldStr, newStr);
        % rebuild categorical with same ordinalness and protectedness
        if isordinal(x)
            out = categorical(string(x), cats, 'Ordinal', true);
        else
            out = categorical(string(x), cats);
        end
        return
    end

    % For tables inside tables or timetable
    if istable(x) || istimetable(x)
        out = replaceInTable(x, oldStr, newStr);
        return
    end

    % Numeric / logical / datetime / duration / etc: leave as-is
    out = x;
end
