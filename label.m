classdef label < handle
    properties
        sigInfo % Table containing info about the signal file (name, start, end etc.)
        lblSet % Table containing all the labels
        lblSetOld % For undo
        lblDef % Table containing definitions of label classes (names, colors etc.)
        lblDefSelection % Double. Helper property which keeps track of selected cells. Used for manual deleting of table cells.
        
        lblClassesToShow
        lblClassesToEdit
        showShowedChannels % Logical scalar
        showShowedClasses % Logical scalar
        shownLabels % Subscripts into lblSet
        plottedLabelsIDs
        
        filep % Cell array of char vectors
        currentFilen % Char vector
        originalCallbacks % Save callbacks here when you need to turn them off for a while and then turn them back on
        
        controlObj
        
        h
        stg
        key
    end
    
    methods
        function obj = label(ctrObj)
            obj.controlObj = ctrObj;
            obj.stg = stgs;
            obj.key = keyShortTbl;
            datetime.setDefaultFormats('default','HH:mm:ss')
            
            if isempty(obj.controlObj.signalObj)
                errordlg('No signal loaded. Load signals first.')
            end
            
            nSigCh = size(obj.controlObj.signalObj.sigTbl, 1);
            
            % Initialize signal info table
            obj.sigInfo = table('Size', [nSigCh, 7],...
                'VariableTypes', {'string',       'string',       'string',       'string',       'datetime',  'datetime'  'double'},...
                'VariableNames', {'FileName',     'FilePath',     'Subject',      'ChName',       'SigStart',  'SigEnd',   'Fs'}); % Possible dropouts should be stored in a label class
            [sigFilep, sigFilen, sigFilee] =  fileparts(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile});
            obj.sigInfo.FileName = repelem(string([sigFilen, sigFilee]), nSigCh)';
            obj.sigInfo.FilePath = repelem(string(sigFilep)+"\", nSigCh)';
            obj.sigInfo(:, 3 : 7) = obj.controlObj.signalObj.sigTbl(:, 1 : 5);
            
            % Initialize label definitions table (create a dummy one line table and then delete that line to get an empty table with the proper data
            % types)
            ClassName = "MyLabel";
            ChannelMode = categorical("one"); ChannelMode = addcats(ChannelMode, ["one", "all"]); % one: the label is associated with a channel,
            % all: the label is associated with animal's behavior, power-line glitch, lights on, etc. and displays in all channels (but, in fact, is
            % not associated with them)
            LabelType = categorical("point"); LabelType = addcats(LabelType, ["point", "roi"]);
            Color = "0.5 1 0.3";
            obj.lblDef = table(ClassName, ChannelMode, LabelType, Color); % Dummy table. I was not able to declare the Color as 1x3 double array. 'double' creates only a scalar.
            obj.lblDef(1, :) = [];
            
            % Initialize label set table, see comments below each column
            obj.lblSet = table('Size', [0 9],...
                'VariableTypes', {'string',      'int16',    'datetime', 'datetime',   'double',      'string',  'logical',   'int64', 'string'},...
                'VariableNames', {'ClassName',   'Channel',  'Start',    'End',        'Value',       'Comment', 'Selected',  'ID',    'SignalFile'});
            %                     E.g. Seizure), Channel,    _______datetime_______,   User-defined,  Comment,   For delete,  Unique,  Signal filepn
            
            obj.updateSigInfo;
            [obj.controlObj.signalObj.h.axSig.ButtonDownFcn] = deal(@obj.cbAxesClick); % Set up callback for axes so that we can insert labels
            obj.lblClassesToShow = true(0);
            obj.lblClassesToEdit = false(0);
            obj.showShowedChannels = false(0);
            obj.showShowedClasses = false(0);
        end
        function obj = lblDefEdit(obj)
            if isfield(obj.h, 'labelDef')
                if isvalid(obj.h.labelDef)
                    figure(obj.h.labelDef)
                    return
                end
            end
            obj.h.labelDef = uifigure('Position', obj.stg.lDefEditFigPos, 'Name', 'Label definitions', 'Tag', 'labelDef',...
                'WindowKeyPressFcn', @obj.cbKey, 'MenuBar', 'none', 'ToolBar', 'none'); % Does not work with figure
            movegui(obj.h.labelDef,'center');
            obj.h.uitLblDef = uitable(obj.h.labelDef, 'Data', obj.lblDef, 'ColumnSortable', true, 'ColumnEditable', true,...
                'Position', [20, 20, obj.stg.lDefEditFigPos(3) - 120, obj.stg.lDefEditFigPos(4) - 40],...
                'CellEditCallback', @obj.cbUitLblDefEdit, 'CellSelectionCallback', @obj.cbUitLblDefSelect, 'DisplayDataChangedFcn', @obj.cbUitLblDisp,...
                'Tag', 'uitLblDef', 'Interruptible', 'off');
            obj.lblDefUpdateView;
            
            obj.h.defbutt(1) = uibutton(obj.h.labelDef, 'push', 'Position', [obj.stg.lDefEditFigPos(3) - 80, obj.stg.lDefEditFigPos(4) - 80, 60, 30],...
                    'Text', 'New', 'Tooltip', 'Add new lbl definition',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefNew');
            obj.h.defbutt(2) = uibutton(obj.h.labelDef, 'push', 'Position', [obj.stg.lDefEditFigPos(3) - 80, obj.stg.lDefEditFigPos(4) - 120, 60, 30],...
                    'Text', 'Duplicate', 'Tooltip', 'Duplicate lbl definition',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefDuplicate');
            obj.h.defbutt(3) = uibutton(obj.h.labelDef, 'push', 'Position', [obj.stg.lDefEditFigPos(3) - 80, obj.stg.lDefEditFigPos(4) - 160, 60, 30],...
                    'Text', '*.xlsx', 'Tooltip', 'Download displayed table as *.xlsx',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefXls');
            obj.h.defbutt(4) = uibutton(obj.h.labelDef, 'push', 'Position', [obj.stg.lDefEditFigPos(3) - 80, obj.stg.lDefEditFigPos(4) - 200, 60, 30],...
                    'Text', 'Delete', 'Tooltip', 'Delete lbl definition',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefDel');

            obj.h.defbutt(5) = uibutton(obj.h.labelDef, 'push', 'Position', [obj.stg.lDefEditFigPos(3) - 80, 20, 60, 30],...
                    'Text', 'Close', 'Tooltip', 'Close. Changes are already saved.',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefClose');
        end
        
        %% Callbacks
        function cbUicontrol(obj, src, ~)
            uicontrol(obj.controlObj.h.tCurrentFile); % For the clicked button to lose focus so that hitting spacebar does not "click" it again. The focus on the text is benign.
            eval(['obj.', src.Tag, ';']); %#ok<EVLDOT> % Only calls appropriate function
        end
        function cbUitLblDefEdit(obj, src, evt)
            % Handles changes of label class definitions. Changes also labels in given class so that they correspond to the new definition.
            % Contains a nested function cncl which is used when the user cancels editing.
            if evt.PreviousData == evt.NewData
                cncl;
                return
            end
            
            % Mark the edited field by white font color
            stylForegrColWhite = uistyle('FontColor','w');
            addStyle(obj.h.uitLblDef, stylForegrColWhite, 'cell', evt.Indices);
            
            % If the edited Label class already contains labels (in the obj.lblSet) ask the user for confirmation
            if ~isempty(obj.lblSet(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1)), :))
                sel = uiconfirm(obj.h.labelDef, ['You are editing label class ',  char(obj.lblDef.ClassName(evt.Indices(1))),...
                    ' and it already contains labels. Are you sure you want change ',...
                    char(obj.lblDef.Properties.VariableNames(evt.Indices(2))), '?'], 'Change label class', 'Icon','warning');
            else
                sel = 'OK'; % No labels yet, no need to ask user for confirmation
            end
            if strcmpi(sel, 'Cancel')
                cncl
                return
            end
            
            % User clicked OK. If ChannelMode or LabelType are edited the already made labels have to be changed accordingly.
            if obj.lblDef.Properties.VariableNames(evt.Indices(2)) == "ChannelMode"
                if string(evt.NewData) == "all"
                    if ~isempty(obj.lblSet(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1)), :))

                        sel = uiconfirm(obj.h.labelDef, 'You are changing ChannelMode from "one" to "all". All Channel values will be set to 0. This cannot be undone. OK?',...
                            'Change label class ChannelMode', 'Icon','warning');
                    else
                        sel = 'OK';
                    end
                    if strcmpi(sel, 'OK')
                        obj.lblSet.Channel(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1))) = 0;
                    else
                        cncl; return
                    end
                elseif string(evt.NewData) == "one"
                    if ~isempty(obj.lblSet(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1)), :))
                        sel = uiconfirm(obj.h.labelDef, 'You are changing ChannelMode from "all" to "one". All Channel values will be set to 1. This cannot be undone. OK?',...
                            'Change label class ChannelMode', 'Icon','warning');
                    else
                        sel = 'OK';
                    end
                    if strcmpi(sel, 'OK')
                        obj.lblSet.Channel(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1))) = 1;
                    else
                        cncl; return
                    end
                else
                    error(['_jk Unknown obj.lblDef.ChannelMode ', char(obj.lblDef.ChannelMode(evt.Indices(1)))])
                end
            elseif obj.lblDef.Properties.VariableNames(evt.Indices(2)) == "LabelType"
                if string(evt.NewData) == "roi"
                    if ~isempty(obj.lblSet(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1)), :))
                        sel = uiconfirm(obj.h.labelDef, 'You are changing LabelType from "point" to "roi". All durations will be set to 1 s. OK?',...
                            'Change label class LabelType', 'Icon','warning');
                    else
                        sel = 'OK';
                    end
                    if strcmpi(sel, 'OK')
                        obj.lblSet.End(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1))) =...
                            obj.lblSet.Start(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1))) + 1/3600/24;
                    else
                        cncl; return
                    end
                elseif string(evt.NewData) == "point"
                    if ~isempty(obj.lblSet(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1)), :))
                        sel = uiconfirm(obj.h.labelDef, 'You are changing LabelType from "roi" to "point". All Ends will be set to same values as Starts (zero duration). OK?',...
                            'Change label class LabelType', 'Icon','warning');
                    else
                        sel = 'OK';
                    end
                    if strcmpi(sel, 'OK')
                        obj.lblSet.End(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1))) =...
                            obj.lblSet.Start(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1)));
                    else
                        cncl; return
                    end
                else
                    error(['_jk Unknown obj.lblDef.LabelType ', char(obj.lblDef.LabelType(evt.Indices(1)))])
                end
            elseif obj.lblDef.Properties.VariableNames(evt.Indices(2)) == "ClassName" % In this case we don't ask the user and change the name in obj.lblSet
                if any(strcmp(obj.lblDef.ClassName, string(evt.NewData)))
                    uialert(obj.h.labelDef, ['You entered label class name ', evt.NewData, ' which already exists. Choose another name.'], 'Error');
                    cncl; return
                end
                obj.lblSet.ClassName(obj.lblSet.ClassName == obj.lblDef.ClassName(evt.Indices(1))) = string(evt.NewData);
            end
            obj.lblDef{evt.Indices(1), evt.Indices(2)} = evt.NewData; % Change the data in obj.lblDef
            obj.lblDefUpdateView;
            obj.lblSetUpdateView;
            obj.controlObj.signalObj.lblPlot;
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
            
            % Nested function invoked when user clicks Cancel at certain point
            function cncl
                src.Data{evt.Indices(1), evt.Indices(2)} = evt.PreviousData;
                stylForegrColBlack = uistyle('FontColor','k');
                addStyle(obj.h.uitLblDef, stylForegrColBlack, 'cell', evt.Indices);
            end
        end
        function cbUitLblDefSelect(obj, ~, evt)
            obj.lblDefSelection = evt.Indices; % To keep track of selected cells in R2019b. https://www.mathworks.com/matlabcentral/answers/548586-programmatical-access-to-current-selection-in-uitable-under-uifigure
        end
        function cbUitLblSelShow(obj, ~, evt) % Select which labels to show
            if isempty(evt.Indices)
                return
            end
            switch evt.EventName
                case 'CellSelection'
%                     obj.lblClassesToShow = false(size(obj.lblClassesToShow));
%                     obj.lblClassesToShow(evt.Indices(:, 1)) = true;
                    obj.lblClassesToShow(evt.Indices(:, 1)) = ~obj.lblClassesToShow(evt.Indices(:, 1));
                case 'CellEdit' % Cell editing is forbiden for now in the uitable
            end
            obj.lblSetUpdateView;
            obj.controlObj.signalObj.lblUpdate;
        end
        function cbUitLblSelEdit(obj, ~, evt) % Select which labels to edit (possibly find better names for these functions)
            if isempty(evt.Indices)
                return
            end
            switch evt.EventName
                case 'CellSelection'
                    obj.lblClassesToEdit = false(size(obj.lblClassesToEdit));
                    obj.lblClassesToEdit(evt.Indices(:, 1)) = true;
                case 'CellEdit' % Cell editing is forbiden for now in the uitable
            end
            obj.lblSetUpdateView;
        end
        function cbUitLblSetEdit(obj, ~, evt) % If the user edited a field in label set (the nomenclature is unfortunate here)
            % Note that Comment is edited within cbUitLblSetSelect
            obj.lblSetOld = obj.lblSet;
            if obj.showShowedChannels
                showChIdx = ismember(obj.lblSet.Channel, obj.controlObj.signalObj.chToPlot);
            else
                showChIdx = true(size(obj.lblSet, 1), 1);
            end
            if obj.showShowedClasses
                showClIdx = ismember(obj.lblSet.ClassName, obj.lblDef.ClassName(obj.lblClassesToShow));
            else
                showClIdx = true(size(obj.lblSet, 1), 1);
            end
            showIdx = showChIdx & showClIdx;
            shownIds = obj.lblSet.ID(showIdx);

            newdata = evt.NewData;
            obj.lblSet{obj.lblSet.ID == shownIds(evt.Indices(1)), evt.Indices(2)} = newdata;

            obj.lblSetUpdateView;
            obj.controlObj.signalObj.lblUpdateOne(shownIds(evt.Indices(1)));
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function cbUitLblSetSelect(obj, src, evt)
            if isempty(evt.Indices)
                return
            end
            % If the user clicks on the Comment column, open inputdlg to edit it
            if evt.Indices(2) == 6
                if obj.showShowedChannels
                    showChIdx = ismember(obj.lblSet.Channel, obj.controlObj.signalObj.chToPlot);
                else
                    showChIdx = true(size(obj.lblSet, 1), 1);
                end
                if obj.showShowedClasses
                    showClIdx = ismember(obj.lblSet.ClassName, obj.lblDef.ClassName(obj.lblClassesToShow));
                else
                    showClIdx = true(size(obj.lblSet, 1), 1);
                end
                showIdx = showChIdx & showClIdx;
                shownIds = obj.lblSet.ID(showIdx);
                in = inputdlg;
                newdata = string(in{1});
                obj.lblSet{obj.lblSet.ID == shownIds(evt.Indices(1)), evt.Indices(2)} = newdata;
            end

            if src.ColumnEditable(evt.Indices(1, 2))
                return
            end
            obj.lblSetSelect(obj.shownLabels(evt.Indices(:, 1)), '');
        end
        function cbUitLblDisp(obj, src, evt)
        % If display changes (if the user sorts the data)
            if strcmp(evt.Interaction, 'sort')
                obj.updateColors(src);
            elseif strcmp(evt.Interaction, 'edit')
                obj.updateColors(src);
            end
        end
        function cbKey(obj, src, keyData)
            if isempty(keyData.Modifier)
                modifier = ''; % Modifier (ctrl, shift or alt)
            elseif length(keyData.Modifier) == 1 %#ok<ISCL>
                modifier = keyData.Modifier{1};
            elseif length(keyData.Modifier) == 2 % I don't use all three modifiers at once
                modifier = [keyData.Modifier{2}, '+', keyData.Modifier{1}]; % In case there is Ctrl+Shift. Matlab has shift in the first cell of keyData.Modifier.
            end
            if isempty(modifier)
                keychar = keyData.Key;
            else
                keychar = [modifier, '+', keyData.Key];
            end
            switch keychar
                case 'delete'
                    obj.lblSetDelete;
                case 'control+c'
                    obj.copyToClipboard(src);
                case 'control+z'
                    obj.lblSetUndo;
                case 'control+d'
                    obj.lblSetDuplicate;
                case 'control+f'
                    obj.lblDefEdit;
                case 'control+s'
                    obj.lblSave
                case 'l'
                    obj.lblSave
                case 'n'
                    obj.controlObj.nextNonEmptyLabelFile;
                case 'b'
                    obj.controlObj.prevNonEmptyLabelFile;
            end
        end
        
        %% Label definition functions
        function obj = lblDefNew(obj)
            clNm = obj.lblDef.ClassName;
            clNm = clNm(contains(clNm, "Seizure"));
            if ~isempty(clNm)
                after = char(extractAfter(clNm, 'Seizure'));
                if isempty(after)
                    n = 2;
                else
                    n = max(str2num(char(extractAfter(clNm, 'Seizure')))) + 1; %#ok<ST2NM>
                end
            else
                n = [];
            end
%             if isempty(n)
%                 n = 1;
%             end
            ClassName = "Seizure"+num2str(n); ChannelMode = "one"; LabelType = "roi"; Color = "1 0 0";
            newRow = table(ClassName, ChannelMode, LabelType, Color);
            obj.lblDef(end+1, :) = newRow;
            obj.lblClassesToShow = [obj.lblClassesToShow; true];
            obj.lblClassesToEdit = [false(size(obj.lblClassesToEdit)); true];
            obj.lblDefUpdateView;
            obj.lblSetUpdateView;
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function obj = lblDefDel(obj)
            rowSel = unique(obj.lblDefSelection(:, 1)); % Selected rows (classes)
            stylForegrColWhite = uistyle('FontColor','w');
            addStyle(obj.h.uitLblDef, stylForegrColWhite, 'row', rowSel);
            charact = []; % Will contain label class names as a character vector. Separated by char(10).
            for k = 1 : length(rowSel)
                charact = [charact, 10, char(obj.lblDef.ClassName(rowSel(k)))]; %#ok<AGROW>
            end
            sel = uiconfirm(obj.h.labelDef, ['Are you sure you want to delete ', num2str(length(rowSel)), ' label class',...
                charact, 10, '?'], 'Delete lbl definitions', 'Icon','warning');
            if strcmpi(sel, 'OK')
                for kr = 1 : length(rowSel)
                    obj.lblSet(obj.lblSet.ClassName == obj.lblDef.ClassName(rowSel(kr)), :) = [];
                end
                obj.lblDef(rowSel, :) = [];
                obj.lblClassesToShow(rowSel) = [];
                obj.lblClassesToEdit(rowSel) = [];
                obj.lblDefUpdateView;
                obj.lblSetUpdateView;
            else
                stylForegrColBlack = uistyle('FontColor','k');
                addStyle(obj.h.uitLblDef, stylForegrColBlack, 'row', rowSel);
            end
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function obj = lblDefClose(obj)
            close(obj.h.labelDef)
        end
        function obj = lblDefUpdateView(obj)
            drawnow
            tblToUpdate = {obj.h.uitLblDef};
            for kuit = 1 : length(tblToUpdate)
                tblToUpdate{kuit}.Data = obj.lblDef(:, 1 : size(tblToUpdate{kuit}.Data, 2));
                stylForegrColBlack = uistyle('FontColor','k');
                addStyle(tblToUpdate{kuit}, stylForegrColBlack, 'row', 1 : size(obj.lblDef, 1))
                obj.updateColors(tblToUpdate{kuit});
            end
        end
        function obj = lblDefDuplicate(obj)
            newRows = obj.lblDef(unique(obj.lblDefSelection(:, 1)), :);
            for kr = 1 : size(newRows, 1)
                newRows.ClassName(kr) = newRows.ClassName(kr)+"2";
            end
            obj.lblDef = [obj.lblDef; newRows];
            obj.lblClassesToShow = [obj.lblClassesToShow; true];
            obj.lblClassesToEdit = [false(size(obj.lblClassesToEdit)); true];
            obj.lblDefUpdateView;
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function lblDefXls(obj)
            disp(obj.h.uitLblDef.DisplayData)
            load('loadpath.mat', 'loadpath')
            [filn, filp] = uiputfile([loadpath, '*.xlsx']);
%             loadpath = filp;
%             save('loadpath.mat', 'loadpath')
            writetable(obj.h.uitLblDef.DisplayData, fullfile(filp, filn));
        end
        
        %% Label functions
        function obj = fileUpdate(obj)
            [obj.controlObj.signalObj.h.lNow.Visible] = deal('off'); % I don't know why I'm hiding the now line here :-D
            drawnow
            obj.currentFilen = '';
            if isempty(obj.filep)
                obj.lblSet(1 : end, :) = [];
            else
                % Find corresponding label file
                d = dir(obj.filep);
                filen = {d(~[d.isdir]).name};
                [~, sigFilen, ~] = fileparts(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile});
                nFile = obj.controlObj.findCorrespondingFile(sigFilen, filen);
                % Depending on the number of corresponding label files take an appropriate action
                if isempty(nFile)
                    disp('_jk No corresponding label file found.')
                    obj.lblSet(1 : end, :) = []; % obj.lblDef remains unchanged, obj.sigInfo is updated below (it's updated anyway)
                elseif length(nFile) > 1 % Multiple corresponding files found (this will hopefully be an unusual situation often due to some mess).
                    disp(['_jk ', num2str(length(nFile)), ' corresponding label files found.'])
                    obj.currentFilen = userSelectFile();
                    if isempty(obj.currentFilen)
                        obj.lblSet(1 : end, :) = [];
                    else
                        pause(0.01)
                        [obj.sigInfo, lblD, obj.lblSet] = loadLabel(fullfile(obj.filep,obj.currentFilen)); %#ok<ASGLU> % Function loadLabel is in a separate file.
% newVN = lblD.Properties.VariableNames
% oldVN = obj.lblDef.Properties.VariableNames
                        
                        if length(obj.lblClassesToShow) ~= size(obj.lblDef, 1)
                            obj.lblClassesToShow = true(size(obj.lblDef, 1), 1);
                            obj.lblClassesToEdit = false(size(obj.lblDef, 1), 1);
                        end
                    end
                elseif length(nFile) == 1 %#ok<ISCL> % One corresponding file found.
                    obj.currentFilen = filen{nFile};
                    pause(0.01) % I hope it could maybe prevent saving old data under this new name.
                    [obj.sigInfo, lblD, obj.lblSet] = loadLabel(fullfile(obj.filep,obj.currentFilen));
                    newLblD = [lblD; obj.lblDef];
                    [~, ia] = unique(newLblD.ClassName);
                    obj.lblDef = newLblD(ia, :);
                    if length(obj.lblClassesToShow) ~= size(obj.lblDef, 1)
                        obj.lblClassesToShow = true(size(obj.lblDef, 1), 1);
                        obj.lblClassesToEdit = false(size(obj.lblDef, 1), 1);
                    end
                else
                    disp(nFile)
                    error(['_jk nFile = ', num2str(nFile)])
                end
            end
            obj.updateSigInfo;
            obj.lblSetUpdateView;
            obj.controlObj.signalObj.lblPlot;
            obj.controlObj.h.eLabelpn.String = fullfile([obj.filep, '\'], char(obj.currentFilen));
            
            % Nested function
            function fln = userSelectFile % Nested function
                hD = dialog('Position',[500 500 500 400],'Name','Multiple corresponding label files found');
                uicontrol('Parent', hD, 'Style', 'text', 'Position', [50 350 400 40],...
                           'String','Choose the label file to load.');
                hList = uicontrol(hD, 'Style', 'listbox', 'Position', [50 100 400 250]);
                hList.String = filen(nFile);
                uicontrol('Parent', hD, 'Position', [100 20 100 40], 'String', 'OK',...
                           'Callback', @ok);
                uicontrol('Parent', hD, 'Position', [300 20 100 40], 'String', 'Close',...
                           'Callback', @cncl);
                uiwait(hD);
                
                % Nested functions
                function cncl(src, ~) % Nested function in a nested function
                    fln = '';
                    delete(src.Parent)
                end
                function ok(src, ~) % Nested function in a nested function
                    fln = hList.String{hList.Value};
                    delete(src.Parent)
                end
            end
        end % Loads new label file (and deletes old labels, the user should have saved them if they wanted to keep them)
        function obj = lblSetUpdateView(obj)
            drawnow limitrate nocallbacks
            lblset = obj.lblSet;
            if obj.showShowedChannels
                showChIdx = ismember(lblset.Channel, obj.controlObj.signalObj.chToPlot);
            else
                showChIdx = true(size(lblset, 1), 1);
            end
            if obj.showShowedClasses
                showClIdx = ismember(lblset.ClassName, obj.lblDef.ClassName(obj.lblClassesToShow));
            else
                showClIdx = true(size(lblset, 1), 1);
            end

            showIdx = showChIdx & showClIdx;
            obj.shownLabels = find(showIdx);
            lblset = lblset(obj.shownLabels, :);
            obj.h.uitLblSet.Data = obj.stringToChar(table2cell(lblset(:, 1 : size(obj.h.uitLblSet.Data, 2)))); % Copy the data from lblset
            % Colors
            obj.updateColors(obj.h.uitLblSet);
            % The upper tables
            tblToUpdate = {obj.h.uitLblSelShow, obj.h.uitLblSelEdit};
            lblClassesTo = {obj.lblClassesToShow, obj.lblClassesToEdit};
            drawnow limitrate nocallbacks
            for kuit = 1 : length(tblToUpdate)
                Selected = lblClassesTo{kuit};
                data = table2cell([obj.lblDef(:, 1 : size(tblToUpdate{kuit}.Data, 2) - 1), table(Selected)]);
                data = obj.stringToChar(data);
                tblToUpdate{kuit}.Data = data;
                obj.updateColors(tblToUpdate{kuit});
            end
            drawnow
        end
        function obj = lblSetDuplicate(obj)
            newRows = obj.lblSet(obj.lblSet.Selected, :);
            highestID = max(obj.lblSet.ID);
            for k = 1 : size(newRows, 1)
                newRows.ID(k) = highestID + k;
            end
            obj.lblSet = [obj.lblSet; newRows];
            obj.lblSetUpdateView;
            obj.controlObj.signalObj.newLabel;
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function cbAxesClick(obj, src, evt)
            if isempty(obj.controlObj.currentDigit)
                return
            end
            % Determine channel
            if strcmp(src.Tag(1 : 5), 'axSig')
                whichSigCh = obj.controlObj.signalObj.chToPlot(str2double(src.Tag(6 : end)));
            else
                error(['_jk Signal axes Tag expected to begin ''axSig'' but is ', src.Tag])
            end
            % Loop over all label classes to which label should be added (most of the time the user will select only one class)
            clToEd = find(obj.lblClassesToEdit);
            for kcl = 1 : length(clToEd)
                ClassName = obj.lblDef.ClassName(clToEd(kcl));
                if obj.lblDef.ChannelMode(clToEd(kcl)) == "one"
                    Channel = whichSigCh;
                elseif obj.lblDef.ChannelMode(clToEd(kcl)) == "all"
                    Channel = 0;
                else
                    error("_jk Unknown obj.lblDef.ChannelMode " + string(obj.lblDef.ChannelMode(clToEd(kcl))))
                end
                Start = obj.sigInfo.SigStart(whichSigCh) + evt.IntersectionPoint(1)/3600/24; % datetime can be sumated with datenum and result is datetime
                if obj.lblDef.LabelType(clToEd(kcl)) == "point"
                    End = Start;
                elseif obj.lblDef.LabelType(clToEd(kcl)) == "roi"
                    End = obj.sigInfo.SigEnd(whichSigCh);
                end
                Value = obj.controlObj.currentDigit;
                Comment = "";
                Selected = false;
                if isempty(obj.lblSet)
                    ID = 1;
                else
                    ID = max(obj.lblSet.ID) + 1;
                end
                SignalFile = obj.sigInfo.FilePath(whichSigCh) + obj.sigInfo.FileName(whichSigCh);
                
                if size(obj.lblSet, 2) > 9
                    obj.lblSet = obj.lblSet(:, 1 : 9);
                end
                if any(matches(obj.lblSet.Properties.VariableNames, 'Select'))
                    obj.lblSet = renamevars(obj.lblSet, 'Select', 'Selected');
                end
                
                obj.lblSet(end+1, :) = table(ClassName, Channel, Start, End, Value, Comment, Selected, ID, SignalFile);
                obj.lblSet = sortrows(obj.lblSet, 'Start');
                
                % Draw the new label in the signal window
                obj.controlObj.signalObj.newLabel;
                obj.lblSetUpdateView;
            end
        end
        function obj = lblBorderMove(obj, srcFig, src)
            sigObj = obj.controlObj.signalObj; % Just to make the code clearer
            sigObj.h.axSig(1).Units = 'pixels';
            axsigszx = sigObj.h.axSig(1).Position(3); % Axes of signal, size x in pixels
            sigObj.h.axSig(1).Units = 'normalized'; % Go back so that resizing the figure works
            id = str2double(src.Tag(6 : end));
            nLbl = obj.lblSet.ID == id; % Row number in the lblSet
            switch src.Tag(1:5)
                case 'lblLA' % point labels have only one line lblLA (label Line All)
                    obj.lblSet.Start(nLbl) = obj.lblSet.Start(nLbl) + ...
                        (obj.controlObj.plotLenS*(srcFig.CurrentPoint(1) - sigObj.previousCurrentPoint)/axsigszx)/24/3600;
                    obj.lblSet.End(nLbl) = obj.lblSet.Start(nLbl);
                case 'lblLS' % roi label Line Start
                    obj.lblSet.Start(nLbl) = min(obj.lblSet.End(nLbl), obj.lblSet.Start(nLbl) + ...
                        (obj.controlObj.plotLenS*(srcFig.CurrentPoint(1) - sigObj.previousCurrentPoint)/axsigszx)/24/3600);
                case 'lblLE' % roi label Line End
                    obj.lblSet.End(nLbl) = max(obj.lblSet.Start(nLbl), obj.lblSet.End(nLbl) + ...
                        (obj.controlObj.plotLenS*(srcFig.CurrentPoint(1) - sigObj.previousCurrentPoint)/axsigszx)/24/3600);
            end
            sigObj.previousCurrentPoint = srcFig.CurrentPoint(1);
            % Draw the change
            ch = obj.lblSet.Channel(nLbl);
            if ch == 0
                ch = obj.controlObj.signalObj.chToPlot(1);
            end

            st = datenum(obj.lblSet.Start(nLbl) - obj.sigInfo.SigStart(ch))*24*3600; %#ok<DATNM> % In seconds
            en = datenum(obj.lblSet.End(nLbl) - obj.sigInfo.SigStart(ch))*24*3600; %#ok<DATNM> % In seconds
            if obj.lblDef.LabelType(obj.lblDef.ClassName == obj.lblSet.ClassName(nLbl)) == "point"
                sigObj.h.lblLA(id).XData = st*[1 1];
            elseif obj.lblDef.LabelType(obj.lblDef.ClassName == obj.lblSet.ClassName(nLbl)) == "roi"
                sigObj.h.lblLS(id).XData = st*[1 1];
                sigObj.h.lblLE(id).XData = en*[1 1];
                sigObj.h.lblPa(id).XData([1, 2, 3, 4]) = [st, en, en, st];
            end
            obj.lblSetUpdateView; % Update the table
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function obj = lblClicked(obj, src, evt) % Shorten the roi-type label
            id = str2double(src.Tag(6 : end));
            nLbl = find(obj.lblSet.ID == id);
            tagPrefix = src.Tag(1:5);
            
            if isempty(obj.controlObj.currentDigit)
                obj.lblSetSelect(nLbl, tagPrefix);
            else
                switch tagPrefix
                    case 'lblPa'
                        ch = obj.lblSet.Channel(nLbl);
                        if ch == 0
                            ch = find(obj.controlObj.signalObj.sigTbl.ChName...
                                == obj.controlObj.signalObj.plotTbl.ChName(1)); % We will draw the labels of ChannelMode 'all' in these axes
                        end
                        obj.lblSet.End(nLbl) = evt.IntersectionPoint(1)/3600/24 + obj.sigInfo.SigStart(ch);
                        obj.controlObj.signalObj.lblUpdateOne(id);
                end
            end
            obj.lblSetUpdateView;
        end
        function obj = lblSetSelect(obj, nLbl, tagPrefix) % Called from lblClicked
            if strcmp(tagPrefix, 'lblLE') || strcmp(tagPrefix, 'lblLS')
                return
            end
            nonNLbl = setdiff(1 : size(obj.lblSet, 1), nLbl); % Get the non-selected cell subscripts
            obj.lblSet.Selected(nonNLbl) = false;
            obj.lblSet.Selected(nLbl) = true;
            obj.lblSetUpdateView;
            ch = obj.lblSet.Channel(nLbl(1));
            if ch == 0
                ch = obj.controlObj.signalObj.chToPlot(1);
            end
            if ch > size(obj.sigInfo, 1)
                warning(['_jk Label Channel is ', num2str(ch), ' but number of signal channels is ', num2str(size(obj.sigInfo, 1)), '. Changing Channel to 1.'])
                ch = 1;
                obj.lblSet.Channel(nLbl(1)) = 1;
            end
            lblStartS = datenum(obj.lblSet.Start(nLbl(1)) - obj.sigInfo.SigStart(ch))*24*3600; %#ok<DATNM>
            obj.controlObj.jumpToLabel(lblStartS, ch);
        end
        function obj = lblSetDelete(obj)
            obj.lblSetOld = obj.lblSet; % For undo (only one step back possible)
            idToDelete = obj.lblSet.ID(obj.lblSet.Selected);
            try
                obj.controlObj.signalObj.lblDelete(idToDelete);
            catch
            end
            obj.lblSet(obj.lblSet.Selected, :) = [];
            % obj.controlObj.signalObj.lblDelete(idToDelete); 
            obj.lblSetUpdateView;
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function obj = lblSetUndo(obj)
            lblSetTemp = obj.lblSet;
            obj.lblSet = obj.lblSetOld;
            obj.lblSetOld = lblSetTemp;
            obj.lblSetUpdateView;
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function lblSetXls(obj)
            disp(obj.h.uitLblSet.DisplayData)
            load('loadpath.mat', 'loadpath')
            [xlsfilen, xlsfilep] = uiputfile([loadpath, '*.xlsx']);
%             loadpath = xlsfilep;
%             save('loadpath.mat', 'loadpath')
%             writetable(obj.h.uitLblSet.DisplayData, fullfile(xlsfilep, xlsfilen));
            writecell(obj.h.uitLblSet.DisplayData, fullfile(xlsfilep, xlsfilen), 'FileType', 'spreadsheet');
        end
        function obj = lblShowShowedChannels(obj)
            obj.showShowedChannels = obj.h.butt(strcmp({obj.h.butt.Tag}, 'lblShowShowedChannels')).Value;
            obj.lblSetUpdateView;
        end
        function obj = lblShowShowedClasses(obj)
            obj.showShowedClasses = obj.h.butt(strcmp({obj.h.butt.Tag}, 'lblShowShowedClasses')).Value;
            obj.lblSetUpdateView;
        end
        function obj = lblTogglePersistentNumber(obj)
            obj.controlObj.currentDigit = [];
            obj.controlObj.persistentNumber = obj.h.butt(strcmp({obj.h.butt.Tag}, 'lblTogglePersistentNumber')).Value;
        end
        function obj = setSignalAxesCallback(obj)
            obj.controlObj.signalObj.h.axSig(~ishandle(obj.controlObj.signalObj.h.axSig)) = [];
            [obj.controlObj.signalObj.h.axSig.ButtonDownFcn] = deal(@obj.cbAxesClick);
        end
        function obj = cycleClassToEdit(obj)
            obj.lblClassesToEdit = circshift(obj.lblClassesToEdit, 1);
            obj.lblSetUpdateView;
            figure(obj.controlObj.signalObj.h.f)
            % % % uicontrol(obj.controlObj.h.tCurrentFile); % For the clicked button to lose focus so that hitting spacebar does not "click" it again. The focus on the text is benign.
        end

        %% Saving and loading
        function obj = getFilep(obj)
            [loadpath, l, compName, typ] = obj.controlObj.getLoadpath({'label'});
% %             load('loadpath.mat', 'loadpath')
% %             if ~ischar(loadpath)
% %                 loadpath = '';
% %             end
            fp = uigetdir(loadpath, 'Label path');
            if fp == 0
                return
            end
%             loadpath = fp;
%             save('loadpath.mat', 'loadpath')
            obj.filep = fp;
            obj.fileUpdate;
            obj.controlObj.saveLoadpath(l, obj.filep, compName, typ)
        end
        function obj = lblSave(obj)
            if isempty(obj.filep)
                obj.getFilep;
            end
            % Determine current signal file name
            currentSigFilepn = obj.controlObj.signalObj.filepn{obj.controlObj.currentFile};
            [~, currentSigFilen] = fileparts(currentSigFilepn);
            obj.currentFilen = [currentSigFilen, '-lbl3.mat'];
            % If a corresponding label file exists, change obj.currentFilen to that to avoid creating duplicit label file
            d = dir([obj.filep '\*-lbl3.mat']);
            lblfilen = {d.name};
            fileNumber = obj.controlObj.findCorrespondingFile(currentSigFilen, lblfilen);
            if ~isempty(fileNumber)
                if fileNumber > 0
                    obj.currentFilen = lblfilen{fileNumber};
                end
            end
            
            sigInfo = obj.sigInfo; %#ok<PROP>
            lblDef = obj.lblDef; %#ok<PROP>
            lblSet = obj.lblSet; %#ok<PROP>
            vrNm = lblSet.Properties.VariableNames; %#ok<PROP>
            for k = 1 : length(vrNm)
                if isa(lblSet.(vrNm{k}), 'string') %#ok<PROP>
                    lblSet.(vrNm{k}) = categorical(lblSet.(vrNm{k})); %#ok<PROP>
                end
            end
            % If a corresponding label file already exists in the folder, save to that file (i.e. save under the name of that label file)
savingAtFilen = obj.currentFilen;
ss = strsplit(savingAtFilen, '-');
saveDtStr = string(ss{2});
saveDtStr = regexp(saveDtStr, "\d\d\d\d\d\d_\d\d\d\d\d\d", 'match');
if ~isempty(saveDtStr)
    fileName1 = char(obj.sigInfo.FileName(1));
    % % % % % % % % % % % % % parts = strsplit(fileName1, '-');
    % % % % % % % % % % % % % if numel(parts) >= 3
    % % % % % % % % % % % % %     fileName1 = [parts{1}, '-', parts{2}, '_', parts{3}];
    % % % % % % % % % % % % % end
    % % % % % % % % % % % % % ss = strsplit(fileName1, '-');
    % % % % % % % % % % % % % fileDtStr = string(ss{2});
    % % % fileDtStr = regexp(fileDtStr, "\d\d\d\d\d\d_\d\d\d\d\d\d", 'match');
    fileDtStr = regexp(fileName1, "\d\d\d\d\d\d_\d\d\d\d\d\d", 'match');
    throwErrorTF = false;
    if saveDtStr ~= fileDtStr || ~contains(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile}, char(saveDtStr))
        throwErrorTF = true;
    end
    if throwErrorTF
        saveDtStr_ = saveDtStr
        saveDtStr_ = saveDtStr
        lblDef_ = obj.lblDef
        lblSet_ = obj.lblSet
        sigInfo_ = obj.sigInfo
        objFilen_ = obj.currentFilen
        signalObjFilen_ = obj.controlObj.signalObj.filepn{obj.controlObj.currentFile}
        errordlg('_jk ERROR! Saving at different time than what is inside the file. Call Jan Kudlacek +420 728 710 994 immediately and try to remember what you did.')
        pause
    end
end
            save(fullfile(obj.filep, obj.currentFilen), 'sigInfo', 'lblDef', 'lblSet')
            pause(0.01)
            obj.controlObj.h.eLabelpn.String = fullfile([obj.filep, '\'], char(obj.currentFilen));
        end
        function fileNumber = nextNonEmptyFile(obj)
            hwb = waitbar(0, 'Searching for next non-empty label...');
% % % % % % % %             if ~isempty(obj.lblSet)
% % % % % % % %                 sigStarts = obj.controlObj.signalObj.sigTbl.SigStart(obj.lblSet.Channel); % Signal starts for each label. Most of the time signals start at the same time.
% % % % % % % %                 posS = datenum(obj.lblSet.Start - sigStarts)*24*3600; % Label positions in secondds from signal starts.
% % % % % % % %             end
            d = dir([obj.filep, '\*.mat']);
            filen = {d(~[d.isdir]).name}'; % Label file names
            filen = sort(filen); %#ok<TRSRT>
            for kf = 1 : length(filen)
                if rem(kf, 20) == 1
                    waitbar(kf/length(filen))
                end
                dt = regexpi(filen{kf}, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match'); % Date and time
% %                 dt = regexpi(filen{kf}, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D', 'match'); % Date and time
% %                 dt = dt{1}(2 : end-1);
                dt = dt{1}(1 : end);
dt_ = dt
mss = max(obj.controlObj.signalObj.sigTbl.SigStart); mss.Format = 'yyMMdd_HHmmss'; mss_ = mss

                if datenum(datetime(dt, 'InputFormat', 'yyMMdd_HHmmss') - max(obj.controlObj.signalObj.sigTbl.SigStart)) > 5/24/3600
                    [~, lbldef, lblset] = loadLabel(fullfile(obj.filep, filen{kf}));
                    if obj.showShowedChannels
                        showChIdx = ismember(lblset.Channel, obj.controlObj.signalObj.chToPlot);
                    else
                        showChIdx = true(size(lblset, 1), 1);
                    end
                    if obj.showShowedClasses
                        if ~all(string(obj.lblDef.ClassName) == string(lbldef.ClassName)) % If the class names are different than before, take into account all classes
                            showClIdx = true(size(lblset, 1), 1);
                        else
                            showClIdx = ismember(lblset.ClassName, obj.lblDef.ClassName(obj.lblClassesToShow));
                        end
                    else
                        showClIdx = true(size(lblset, 1), 1);
                    end
                    showIdx = showChIdx & showClIdx;
                    if any(showIdx)
                        fileNumber = obj.controlObj.findCorrespondingFile(filen{kf}, obj.controlObj.signalObj.filepn);
                        if isempty(fileNumber)
                            disp(['_jk No signal file corresponds to label file ', filen{kf}])
                        end
                        delete(hwb)
                        return
                    end
                end
            end
            delete(hwb)
        end
        function fileNumber = prevNonEmptyFile(obj)
            hwb = waitbar(0, 'Searching for next non-empty label...');
            d = dir([obj.filep, '\*.mat']);
            filen = {d(~[d.isdir]).name}';
            filen = sort(filen); %#ok<TRSRT>
            for kf = length(filen) : -1 : 1
                waitbar(kf/length(filen))
                dt = regexpi(filen{kf}, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match'); % Date and time
% %                 dt = regexpi(filen{kf}, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D', 'match'); % Date and time
% %                 dt = dt{1}(2 : end-1);
                dt = dt{1}(1 : end);
                if datenum(datetime(dt, 'InputFormat', 'yyMMdd_HHmmss') - min(obj.controlObj.signalObj.sigTbl.SigStart)) < -5/24/3600
                    [~, ~, lblset] = loadLabel(fullfile(obj.filep, filen{kf}));
                    if obj.showShowedChannels
                        showChIdx = ismember(lblset.Channel, obj.controlObj.signalObj.chToPlot);
                    else
                        showChIdx = true(size(lblset, 1), 1);
                    end
                    if obj.showShowedClasses
                        showClIdx = ismember(lblset.ClassName, obj.lblDef.ClassName(obj.lblClassesToShow));
                    else
                        showClIdx = true(size(lblset, 1), 1);
                    end
                    showIdx = showChIdx & showClIdx;
                    if any(showIdx)
                        fileNumber = obj.controlObj.findCorrespondingFile(filen{kf}, obj.controlObj.signalObj.filepn);
                        if isempty(fileNumber)
                            disp(['_jk No signal file corresponds to label file ', filen{kf}])
                        end
                        delete(hwb)
                        return
                    end
                end
            end
            delete(hwb)
        end
        
        %% Helper functions
        function obj = updateColors(obj, uit) % Use this when sorting
            drawnow
            c = [];
            for k = 1 : size(uit.DisplayData, 1)
                colIdx = find(strcmp(uit.ColumnName, 'ClassName'));
                c(k, :) = str2num(obj.lblDef.Color(obj.lblDef.ClassName == string(uit.DisplayData{k, colIdx}))); %#ok<FNDSB,AGROW,ST2NM> % Base color of the label
                if any(ismember(uit.ColumnName, 'Value'))
                    colIdx = find(strcmp(uit.ColumnName, 'Value'));
                    c(k, :) = 1 - (1 - c(k, :))*double(uit.DisplayData{k, colIdx}/9); %#ok<FNDSB,AGROW> % Bleach the color according to the Value
                end
            end
            if ~isempty(c)
                uit.BackgroundColor = c;
            end
        end
        function obj = updateSigInfo(obj)
            nSigCh = size(obj.controlObj.signalObj.sigTbl, 1);
            nSigChLabel = size(obj.sigInfo, 1);
% % % sigInfo2 = obj.sigInfo
% % %             if nSigCh ~= nSigChLabel
% % %                 % obj = []; % Since obj is now empty, the label (empty label) will not be automatically saved
% % %                 warning(['_jk nSigCh=', num2str(nSigCh), ' but nSigChLabel=', num2str(nSigChLabel)])
% % %                 % return
% % %             end
% % % sigInfo2 = obj.sigInfo
% % %             [sigFilep, sigFilen, sigFilee] =  fileparts(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile});
% % %             obj.sigInfo.FileName = repelem(string([sigFilen, sigFilee]), nSigCh)';
% % %             obj.sigInfo.FilePath = repelem(string(sigFilep), nSigCh)';
% % %             obj.sigInfo(:, 3 : 7) = obj.controlObj.signalObj.sigTbl(:, 1 : 5);
% % %             obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
            
            % Initialize signal info table
            obj.sigInfo = table('Size', [nSigCh, 7],...
                'VariableTypes', {'string',       'string',       'string',       'string',       'datetime',  'datetime'  'double'},...
                'VariableNames', {'FileName',     'FilePath',     'Subject',      'ChName',       'SigStart',  'SigEnd',   'Fs'}); % Possible dropouts should be stored in a label class
            [sigFilep, sigFilen, sigFilee] =  fileparts(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile});
            obj.sigInfo.FileName = repelem(string([sigFilen, sigFilee]), nSigCh)';
            obj.sigInfo.FilePath = repelem(string(sigFilep)+"\", nSigCh)';
            obj.sigInfo(:, 3 : 7) = obj.controlObj.signalObj.sigTbl(:, 1 : 5);
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function obj = createLblFig(obj)
            % Try to implement this with figure and not uifigure. Needs to change the table formating functions.
            if isfield(obj.h, 'f')
                if isvalid(obj.h.f)
                    figure(obj.h.f)
                    return
                end
            end
            obj.h.f = figure('Position', obj.stg.lFigPos, 'Name', 'Label', 'Tag', 'label',...
                'WindowKeyPressFcn', @obj.cbKey, 'MenuBar', 'none', 'ToolBar', 'none');
            
            obj.h.panTL = uipanel(obj.h.f, 'Position', [0.01, 0.8, 0.48 0.2], 'Title', 'Label classes to show'); % Top Left
            obj.h.panTR = uipanel(obj.h.f, 'Position', [0.51, 0.8, 0.48 0.2], 'Title', 'Label classes to edit'); % Top Right
            
            Show = obj.lblClassesToShow; % Show this channel?
            dataT = [obj.lblDef(:, 1), table(Show)];
            colNm = dataT.Properties.VariableNames;
            data = table2cell(dataT);
            obj.h.uitLblSelShow = uitable(obj.h.panTL, 'Data', obj.stringToChar(data), 'ColumnName', colNm, 'RowName', [],...
                'Units', 'normalized', 'Position', [0 0 1 1], 'ColumnWidth', {150, 50},...
                'CellEditCallback', @obj.cbUitLblSelShow, 'CellSelectionCallback', @obj.cbUitLblSelShow,...
                'Tag', 'uitLblSelShow');
            
            Show = obj.lblClassesToEdit; % Show this channel?
            dataT = [obj.lblDef(:, 1), table(Show)];
            colNm{2} = 'Edit';
            data = obj.stringToChar(table2cell(dataT));
            obj.h.uitLblSelEdit = uitable(obj.h.panTR, 'Data', obj.stringToChar(data), 'ColumnName', colNm, 'RowName', [],...
                'Units', 'normalized', 'Position', [0 0 1 1], 'ColumnWidth', {150, 50},...
                'CellEditCallback', @obj.cbUitLblSelEdit, 'CellSelectionCallback', @obj.cbUitLblSelEdit,...
                'Tag', 'uitLblSelEdit');
            
            obj.h.panM = uipanel(obj.h.f, 'Position', [0.01, 0.1, 0.98 0.7], 'Title', 'Labels'); % Top Left
            colNm = obj.lblSet.Properties.VariableNames;
            data = obj.stringToChar(table2cell(obj.lblSet));
            obj.h.uitLblSet = uitable(obj.h.panM, 'Data', data, 'ColumnName', colNm, 'RowName', [],...
                'Units', 'normalized', 'Position', [0 0 1 1],...
                'ColumnWidth', {90, 33, 58, 58, 33, 'auto', 38, 33, 'auto'},...
                'ColumnEditable', logical([0 1 0 0 1 0 0 0 0]),...
                'CellEditCallback', @obj.cbUitLblSetEdit, 'CellSelectionCallback', @obj.cbUitLblSetSelect,...
                'Tag', 'uitLblSet');
            drawnow
            obj.lblSetUpdateView;
            
            obj.h.butt(1) = uicontrol('Parent', obj.h.f, 'Style', 'pushbutton',...
                    'Units', 'normalized', 'Position', [0.01, 0.05, 0.24, 0.05],...
                    'String', 'Duplicate', 'TooltipString', 'Duplicate label, ctrl+d',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetDuplicate');
            obj.h.butt(2) = uicontrol('Parent', obj.h.f, 'Style', 'pushbutton',...
                    'Units', 'normalized', 'Position', [0.25, 0.05, 0.24, 0.05],...
                    'String', 'Delete', 'TooltipString', 'Delete label, delete',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetDelete');
            obj.h.butt(3) = uicontrol('Parent', obj.h.f, 'Style', 'pushbutton',...
                    'Units', 'normalized', 'Position', [0.5, 0.05, 0.24, 0.05],...
                    'String', 'Undo', 'TooltipString', 'Undo, ctrl+z',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetUndo');
            obj.h.butt(4) = uicontrol('Parent', obj.h.f, 'Style', 'pushbutton',...
                    'Units', 'normalized', 'Position', [0.75, 0.05, 0.24, 0.05],...
                    'String', '*.xlsx', 'TooltipString', 'Download displayed table as *.xlsx',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetXls');
            obj.h.butt(5) = uicontrol('Parent', obj.h.f, 'Style', 'pushbutton',...
                    'Units', 'normalized', 'Position', [0.01, 0.00, 0.24, 0.05],...
                    'String', 'Definitions', 'TooltipString', 'Open label definitions, ctrl+f',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefEdit');
            obj.h.butt(6) = uicontrol('Parent', obj.h.f, 'Style', 'togglebutton',...
                    'Units', 'normalized', 'Position', [0.25, 0.00, 0.24, 0.05],...
                    'String', 'Channels', 'TooltipString', 'Show only channels showed in the signal window',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblShowShowedChannels');
            obj.h.butt(7) = uicontrol('Parent', obj.h.f, 'Style', 'togglebutton',...
                    'Units', 'normalized', 'Position', [0.5, 0.00, 0.24, 0.05],...
                    'String', 'Classes', 'TooltipString', 'Show only classes showed in the signal window',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblShowShowedClasses');
            obj.h.butt(8) = uicontrol('Parent', obj.h.f, 'Style', 'togglebutton',...
                    'Units', 'normalized', 'Position', [0.75, 0.00, 0.24, 0.05],...
                    'String', 'Persistent Number', 'TooltipString', 'Allow number press to persist',...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblTogglePersistentNumber');
        end
        function copyToClipboard(obj, src)
            if strcmp(src.Tag, 'labelDef')
                selectedTable = obj.lblDef(unique(obj.lblDefSelection(:, 1)), unique(obj.lblDefSelection(:, 2))); %#ok<NASGU>
            elseif strcmp(src.Tag, 'label')
                selectedTable = obj.lblSet(obj.lblSet.Selected, :); %#ok<NASGU>
            else
                error(['_jk Unknown source copyToClipboard ', src.Tag])
            end
            textOutput = evalc('disp(selectedTable)');
            clipboard('copy', textOutput)
        end
        
        function delete(obj)
            delete(obj.h.f)
        end
    end
    methods (Static)
        function c = stringToChar(c)
            for kr = 1 : numel(c)
                if isstring(c{kr})
                    c{kr} = char(c{kr});
                end
            end
            for kr = 1 : numel(c)
                if isa(c{kr}, 'datetime')
                    c{kr} = datestr(c{kr}, 'HH:MM:SS'); %#ok<*DATST>
                end
            end
        end
    end
end

