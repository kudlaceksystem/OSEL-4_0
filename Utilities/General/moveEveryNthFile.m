function moveEveryNthFile
    %% %%%%%%%% %%
    %% SETTINGS %%
    %% %%%%%%%% %%
    folderAllData = '\\neurodata3\Lab Glia\NLD\NLD03 converted\';
    folderSubset = '\\neurodata3\Lab Glia\Test folder\';
    fileType = 'rhs';
    firstFileIndex = 3;
    everyNthFile = 10000;
    action = 'copy';
    moveEveryNthFile01(folderAllData, folderSubset, fileType, firstFileIndex, everyNthFile, action)
end


%% %%%%%%%%% %%
%% FUNCTIONS %%
%% %%%%%%%%% %%
function moveEveryNthFile01(folderAllData, folderSubset, fileType, firstFileIndex, everyNthFile, action)
    % Validate the action input
    if ~ismember(action, {'move', 'copy'})
        error('Invalid action. Use ''move'' or ''copy''.');
    end
    
    % Get the list of files with the specified fileType in folderAllData
    files = dir(fullfile(folderAllData, ['*.' fileType]));
    
    % Sort the files alphabetically by name
    [~, idx] = sort({files.name});
    files = files(idx);
    
    % Create the folderSubset directory if it doesn't exist
    if ~exist(folderSubset, 'dir')
        mkdir(folderSubset);
    end
    
    % Initialize the counter for moved/copied files
    movedFilesCount = 0;
    
    % Loop through the files and move/copy every Nth file starting from firstFileIndex
    for i = firstFileIndex:everyNthFile:length(files)
        % Construct the source and destination file paths
        sourceFile = fullfile(folderAllData, files(i).name);
        destinationFile = fullfile(folderSubset, files(i).name);
        
        % Move or copy the file based on the action input
        if strcmp(action, 'move')
            movefile(sourceFile, destinationFile);
        elseif strcmp(action, 'copy')
            copyfile(sourceFile, destinationFile);
        end
        
        % Increment the counter
        movedFilesCount = movedFilesCount + 1;
    end
    
    % Print the number of moved/copied files to the Command Window
    fprintf('%s %d files.\n', capitalizeFirstLetter(action), movedFilesCount);
end

function str = capitalizeFirstLetter(str)
    % Capitalize the first letter of a string
    str(1) = upper(str(1));
end