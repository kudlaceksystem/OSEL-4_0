% renameSmrxFiles.m
% Created 11.05.2026 by NK
% Renames .smrx files using the recording datetime stored in the file's
% internal File Information block (read via CEDS64TimeDate).
%
% Target format: [LetterGroup]-[YYMMDD]_[hhmmss]-[OptionalTag]-[SeqNum].smrx
% Example:       CD-230109_144342-ThaoAdam-001.smrx
%
% Requirements: CED MATLAB library (CEDS64ML)

format compact

%% ===== USER CONFIGURATION =============================================
folderPath     = '\\neurodata4\VideoEEG sklad1\CESNET\jk20140731\orig fs';   % Folder with .smrx files (renamed in place)
optionalTag    = '';             % Inserted before seq number; set '' to omit
seqNum         = '001';          % Fallback seq number if none found in old filename
maxFileSizeGB  = 2;              % Files larger than this (GB) are skipped
cedLibPath     = '';             % CED library path; auto-detected if empty
dryRun         = true;           % true = preview only | false = rename files
%% ======================================================================

% --- Load CED library --------------------------------------------------
cedLibPath = initCEDLib(cedLibPath);

fprintf('Folder : %s\n\n', folderPath);

% --- Discover .smrx files ----------------------------------------------
files = listSmrxFiles(folderPath);
if isempty(files)
    fprintf('No .smrx files found in:\n  %s\n', folderPath);
    safeUnloadLib();
    return
end
fprintf('Found %d .smrx file(s).\n\n', numel(files));

% --- Process each file -------------------------------------------------
nRenamed = 0;  nSkipped = 0;  nError = 0;

for k = 1 : numel(files)
    oldName  = files(k).name;
    oldPath  = fullfile(folderPath, oldName);
    fileSizeGB = files(k).bytes / 1024^3;
    fprintf('[%d/%d]  %s  (%.2f GB)\n', k, numel(files), oldName, fileSizeGB);

    % 0. Skip oversized files
    if fileSizeGB > maxFileSizeGB
        fprintf('  SKIP — file is %.2f GB (limit: %g GB).\n\n', fileSizeGB, maxFileSizeGB);
        nSkipped = nSkipped + 1;
        continue
    end

    % 1. Extract letter-group prefix (everything before the first '-')
    prefix = extractPrefix(oldName);
    if isempty(prefix)
        fprintf('  SKIP — no letter-group prefix detected.\n\n');
        nSkipped = nSkipped + 1;
        continue
    end

    % 2. Read recording-start datetime from internal file metadata
    recDt = readFileDateTime(oldPath);
    if isnat(recDt)
        fprintf('  SKIP — could not read datetime from file.\n\n');
        nSkipped = nSkipped + 1;
        continue
    end
    fprintf('  Metadata datetime : %s\n', char(recDt));

    % 3. Extract sequence number from old filename, fall back to seqNum
    fileSeq = extractSeqNum(oldName, seqNum);
    fprintf('  Sequence number   : %s\n', fileSeq);

    % 4. Build target filename
    newName = buildName(prefix, recDt, optionalTag, fileSeq);
    newPath = fullfile(folderPath, newName);
    fprintf('  Target filename   : %s\n', newName);

    % 5. Validate before any rename
    [ok, reason] = validateName(newName);
    if ~ok
        fprintf('  SKIP — validation failed: %s\n\n', reason);
        nSkipped = nSkipped + 1;
        continue
    end
    if strcmpi(oldName, newName)
        fprintf('  SKIP — filename already in correct format.\n\n');
        nSkipped = nSkipped + 1;
        continue
    end
    if exist(newPath, 'file')
        fprintf('  SKIP — a file with the target name already exists.\n\n');
        nSkipped = nSkipped + 1;
        continue
    end

    % 6. Rename in place (or preview in dry-run mode)
    if dryRun
        fprintf('  [DRY RUN] Would rename — set dryRun = false to apply.\n\n');
        nRenamed = nRenamed + 1;
    else
        try
            movefile(oldPath, newPath);
            fprintf('  OK — renamed.\n\n');
            nRenamed = nRenamed + 1;
        catch ME
            fprintf('  ERROR — %s\n\n', ME.message);
            nError = nError + 1;
        end
    end
end

safeUnloadLib();

% --- Summary -----------------------------------------------------------
fprintf('===== SUMMARY =====\n');
fprintf('Files found : %d\n', numel(files));
if dryRun
    fprintf('Would rename: %d  (dry run)\n', nRenamed);
else
    fprintf('Renamed     : %d\n', nRenamed);
end
fprintf('Skipped     : %d\n', nSkipped);
fprintf('Errors      : %d\n', nError);
if dryRun
    fprintf('\n[DRY RUN] No files were changed. Set dryRun = false to apply.\n');
end


%% ===== LOCAL FUNCTIONS ================================================

function cedpath = initCEDLib(cedpath)
% Locate and load the CED64 shared library.
    if isempty(cedpath)
        cedpath = getenv('CEDS64ML');
    end
    if isempty(cedpath)
        % Fallback: look in CEDMATLAB subfolder next to this script
        cedpath = fullfile(fileparts(mfilename('fullpath')), 'CEDMATLAB', 'CEDS64ML');
        setenv('CEDS64ML', cedpath);
    end
    addpath(cedpath);
    CEDS64LoadLib(cedpath);
    fprintf('CED library : %s\n', cedpath);
end

% -----------------------------------------------------------------------
function files = listSmrxFiles(folder)
% Returns a struct array of .smrx files (case-insensitive extension match).
    candidates = [dir(fullfile(folder, '*.smrx')); ...
                  dir(fullfile(folder, '*.smrX')); ...
                  dir(fullfile(folder, '*.SMRX'));...
                  dir(fullfile(folder, '*.smr'))];
    if ~isempty(candidates)
        [~, ia] = unique({candidates.name});   % deduplicate
        candidates = candidates(ia);
    end
    files = candidates(~[candidates.isdir]);
end

% -----------------------------------------------------------------------
function prefix = extractPrefix(filename)
% Returns the alphanumeric group before the first '-' (e.g. "ABCD").
tok = regexp(filename, '^([A-Za-z0-9]+)-', 'tokens', 'once');
if isempty(tok)
    tok = regexp(filename, '^([A-Za-z0-9]+) ', 'tokens', 'once');
    if isempty(tok)
        prefix = '';
    else
        prefix = tok{1};
    end
else
    prefix = tok{1};
end
end

% -----------------------------------------------------------------------
function dt = readFileDateTime(filepath)
% Opens the .smrx file and extracts the recording-start datetime from the
% File Information block using CEDS64TimeDate.
%
% CEDS64TimeDate returns td as a 7-element vector:
%   td = [centisec, sec, min, hour, day, month, year]
% Reversing td(2:end) yields [year, month, day, hour, min, sec],
% which is the argument order expected by datetime().
    dt = NaT;

    fhand = CEDS64Open(filepath);
    if fhand <= 0
        warning('renameSmrx:openFailed', 'CEDS64Open failed for:\n  %s', filepath);
        return
    end

    % Ignore first return value — CEDS64TimeDate uses a different success
    % convention than other CED functions; reference code discards it with ~.
    [~, td] = CEDS64TimeDate(fhand);

    try
        CEDS64Close(fhand);
    catch
        % Some library versions lack CEDS64Close; the unload step will clean up.
    end

    % td = [centisec, sec, min, hour, day, month, year]  (7 elements)
    if numel(td) < 7
        warning('renameSmrx:readFailed', ...
            'CEDS64TimeDate returned only %d element(s) for:\n  %s', numel(td), filepath);
        return
    end

    % td(2:end) = [sec, min, hour, day, month, year]
    % fliplr     = [year, month, day, hour, min,  sec]
    try
        dt = datetime(fliplr(td(2:end)));
    catch ME
        warning('renameSmrx:parseFailed', 'datetime parse error: %s', ME.message);
    end
end

% -----------------------------------------------------------------------
function seq = extractSeqNum(filename, defaultSeq)
% Extracts the sequence number embedded in the old garbled filename.
% The seq number always appears just before the garbled second datetime block.
% Works for both formats:
%   "ABCD-221207_125948 98 15 12 22_19 0 33.smrX"          → 098
%   "ABCD-230130_153852-000.smrx 99  7 2 23_23 39 43.smrX" → 099
% Falls back to defaultSeq if the pattern is not found.
    tok = regexp(filename, '(\d+)\s+\d+\s+\d+\s+\d+_\d+\s+\d+\s+\d+', 'tokens', 'once');
    if ~isempty(tok)
        n = str2double(tok{1});
        seq = sprintf('%03d', n);
    else
        seq = defaultSeq;
    end
end

% -----------------------------------------------------------------------
function name = buildName(prefix, dt, tag, seq)
% Assembles the target filename from its components.
    dateStr = char(datetime(dt, 'Format', 'yyMMdd_HHmmss'));
    if isempty(tag)
        name = sprintf('%s-%s-%s.smrx', prefix, dateStr, seq);
    else
        name = sprintf('%s-%s-%s-%s.smrx', prefix, dateStr, tag, seq);
    end
end

% -----------------------------------------------------------------------
function [ok, reason] = validateName(fname)
% Checks the generated filename for illegal characters, format compliance,
% and plausible date/time values before any rename is attempted.
    ok = true;  reason = '';

    % No characters illegal in Windows filenames
    if any(ismember(fname, '\/:*?"<>|'))
        ok = false;  reason = 'contains illegal filename characters';  return
    end

    % Must match the expected pattern (case-insensitive extension)
    %   [A-Za-z0-9]+ - YYMMDD_hhmmss - OptionalTag - 001 .smrx
    pat = '^[A-Za-z0-9]+-\d{6}_\d{6}(-[^-]+)?-\d{3}\.smrx$';
    if isempty(regexp(fname, pat, 'once', 'ignorecase'))
        ok = false;  reason = 'does not match target format pattern';  return
    end

    % Sanity-check embedded date/time values
    tok = regexp(fname, '(\d{6})_(\d{6})', 'tokens', 'once');
    if ~isempty(tok)
        d = tok{1};   t = tok{2};
        mm = str2double(d(3:4));   dd = str2double(d(5:6));
        hh = str2double(t(1:2));   mn = str2double(t(3:4));   ss = str2double(t(5:6));
        if mm < 1 || mm > 12 || dd < 1 || dd > 31 || ...
           hh > 23  || mn > 59  || ss > 59
            ok = false;  reason = 'embedded date/time values are out of valid range';  return
        end
    end
end

% -----------------------------------------------------------------------
function safeUnloadLib()
    try
        unloadlibrary ceds64int;
    catch
        % Library already unloaded or was never loaded successfully.
    end
end
