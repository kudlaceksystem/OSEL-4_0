classdef labelUI < handle
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
        
        controlObj
        
        h
        stg
        key
    end
    
    methods
        function obj = labelUI(ctrObj)
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
                'VariableNames', {'ClassName',   'Channel',  'Start',    'End',        'Value',       'Comment', 'Select',  'ID',    'SignalFile'});
            %                     E.g. Seizure), Channel,    _______datetime_______,   User-defined,  Comment,   For delete,  Unique,  Signal filepn
            
            obj.updateSigInfo;
            [obj.controlObj.signalObj.h.axSig.ButtonDownFcn] = deal(@obj.cbAxesClick); % Set up callback for axes so that we can insert labels
            obj.lblClassesToShow = true(0);
            obj.lblClassesToEdit = false(0);
        end
        function obj = lblDefEdit(obj)
            if isfield(obj.h, 'labelDef')
                if isvalid(obj.h.labelDef)
                    figure(obj.h.labelDef)
                    return
                end
            end
            obj.h.labelDef = uifigure('Position', obj.stg.lDefEditFigPos, 'Name', 'Label definitions', 'Tag', 'labelDef',...
                'WindowKeyPressFcn', @obj.cbKey); % Does not work with figure
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
                    'Text', 'Close', 'Tooltip', 'Delete lbl definition',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefClose');
        end
        
        %% Callbacks
        function cbUicontrol(obj, src, ~)
            uicontrol(obj.controlObj.h.tCurrentFile); % For the clicked button to lose focus so that hitting spacebar does not "click" it again. The focus on the text is benign.
            eval(['obj.', src.Tag, ';']); % Only calls appropriate function
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
            switch evt.EventName
                case 'CellSelection'
                    obj.lblClassesToShow = false(size(obj.lblClassesToShow));
                    obj.lblClassesToShow(evt.Indices(:, 1)) = true;
                case 'CellEdit' % Cell editing is forbiden for now in the uitable
            end
            obj.lblSetUpdateView;
            obj.controlObj.signalObj.lblUpdate;
        end
        function cbUitLblSelEdit(obj, ~, evt) % Select which labels to edit (possibly find better names for these functions)
            switch evt.EventName
                case 'CellSelection'
                    obj.lblClassesToEdit = false(size(obj.lblClassesToEdit));
                    obj.lblClassesToEdit(evt.Indices(:, 1)) = true;
                case 'CellEdit' % Cell editing is forbiden for now in the uitable
            end
            obj.lblSetUpdateView;
        end
        function cbUitLblSetEdit(obj, ~, evt) % If the user edited a field in label set (the nomenclature is unfortunate here)
            obj.lblSetOld = obj.lblSet;
            if strcmpi(evt.EventName, 'CellEdit')
                obj.lblSet{evt.Indices(1), evt.Indices(2)} = evt.NewData;
            end
            obj.lblSetUpdateView;
            obj.controlObj.signalObj.lblUpdateOne(obj.lblSet.ID(evt.Indices(1)));
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        function cbUitLblSetSelect(obj, ~, evt)
            obj.lblSetSelected(obj.shownLabels(evt.Indices(:, 1)));
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
            elseif length(keyData.Modifier) == 1
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
                    obj.saveLabel
                case 'l'
                    obj.saveLabel
            end
        end
        
        %% Label definition functions
        function obj = lblDefNew(obj)
            clNm = obj.lblDef.ClassName;
            clNm = clNm(contains(clNm, "MyLabel"));
            if ~isempty(clNm)
                n = max(str2num(char(extractAfter(clNm, 'MyLabel')))) + 1; %#ok<ST2NM>
            else
                n = [];
            end
            if isempty(n)
                n = 1;
            end
            ClassName = "MyLabel"+num2str(n); ChannelMode = "one"; LabelType = "point"; Color = "0.5 1 0.3";
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
% % %             tblToUpdate = {obj.h.uitLblDef, obj.h.uitLblSelShow, obj.h.uitLblSelEdit};
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
            loadpath = filp;
            save('loadpath.mat', 'loadpath')
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
                    obj.lblSet(1 : end, :) = [];
                elseif length(nFile) > 1 % Multiple corresponding files found (this will hopefully be an unusual situation often due to some mess).
                    disp(['_jk ', num2str(length(nFile)), ' corresponding label files found.'])
                    obj.currentFilen = userSelectFile();
                    if isempty(obj.currentFilen)
                        obj.lblSet(1 : end, :) = [];
                    else
                        [obj.sigInfo, obj.lblDef, obj.lblSet] = loadLabel(fullfile(obj.filep,obj.currentFilen)); % Function loadLabel is in a separate file.
                        if length(obj.lblClassesToShow) ~= size(obj.lblDef, 1)
                            obj.lblClassesToShow = true(size(obj.lblDef, 1), 1);
                            obj.lblClassesToEdit = false(size(obj.lblDef, 1), 1);
                        end
                    end
                elseif length(nFile) == 1 % One corresponding file found.
                    obj.currentFilen = filen{nFile};
                    [obj.sigInfo, obj.lblDef, obj.lblSet] = loadLabel(fullfile(obj.filep,obj.currentFilen));
                    if length(obj.lblClassesToShow) ~= size(obj.lblDef, 1)
                        obj.lblClassesToShow = true(size(obj.lblDef, 1), 1);
                        obj.lblClassesToEdit = false(size(obj.lblDef, 1), 1);
                    end
                else
                    error(['_jk nFile = ', num2str(nFile)])
                end
            end
            obj.updateSigInfo; % The sig info should be updated anyway
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
tic
            drawnow limitrate nocallbacks
            tblToUpdate = {obj.h.uitLblSet};
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
            for kuit = 1 : length(tblToUpdate) % Possibly remove the loop over one element
                tblToUpdate{kuit}.Data = lblset(:, 1 : size(tblToUpdate{kuit}.Data, 2)); % Copy the data from lblset
                % Make text black (just in case it was different)
%                 stylForegrColBlack = uistyle('FontColor','k');
%                 addStyle(tblToUpdate{kuit}, stylForegrColBlack, 'row', 1 : size(lblset, 1));
                % Show selection by bold
                styl = uistyle('FontAngle','normal');
                if ~isempty(find(~lblset.Selected, 1))
                    addStyle(obj.h.uitLblSet, styl, 'row', find(~lblset.Selected));
                end
%                 styl = uistyle('FontAngle','italic');
%                 if ~isempty(find(lblset.Selected, 1))
%                     addStyle(obj.h.uitLblSet, styl, 'row', find(lblset.Selected));
%                 end
                % Colors
                obj.updateColors(tblToUpdate{kuit});
            end
toc
            tblToUpdate = {obj.h.uitLblSelShow, obj.h.uitLblSelEdit};
            lblClassesTo = {obj.lblClassesToShow, obj.lblClassesToEdit};
            drawnow limitrate nocallbacks
            for kuit = 1 : length(tblToUpdate)
                Selected = lblClassesTo{kuit};
                data = [obj.lblDef(:, 1 : size(tblToUpdate{kuit}.Data, 2) - 1), table(Selected)];
                tblToUpdate{kuit}.Data = data;
                stylForegrColBlack = uistyle('FontColor','k');
                addStyle(tblToUpdate{kuit}, stylForegrColBlack, 'row', 1 : size(obj.lblSet, 1));
                obj.updateColors(tblToUpdate{kuit});
            end
            drawnow
        end
        function obj = lblSetUpdatePlotted(obj, nID) % Rather slow
            idxPlotted = ismember(obj.h.uitLblSet.DisplayData{:, strcmp(obj.h.uitLblSet.ColumnName, 'ID')}, nID); % Logical indices into the uitable of the plotted labels
            styl = uistyle('FontWeight', 'normal');
            r = find(~idxPlotted);
            if ~isempty(r)
                addStyle(obj.h.uitLblSet, styl, 'row', r);
            end
            styl = uistyle('FontWeight', 'bold');
            r = find(idxPlotted);
            if ~isempty(r)
                addStyle(obj.h.uitLblSet, styl, 'row', r);
            end
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
                Start = obj.sigInfo.SigStart(whichSigCh) + evt.IntersectionPoint(1)/3600/24; % datetime can be summed with datenum and result is datetime
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
                obj.lblSet(end+1, :) = table(ClassName, Channel, Start, End, Value, Comment, Selected, ID, SignalFile);
                
                % Draw the new label in the signal window
% 'signal'
% tic
                obj.controlObj.signalObj.newLabel;
% toc
% 'label'
% tic
                obj.lblSetUpdateView;
% toc
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
                    obj.lblSet.Start(nLbl) = obj.lblSet.Start(nLbl) + ...
                        (obj.controlObj.plotLenS*(srcFig.CurrentPoint(1) - sigObj.previousCurrentPoint)/axsigszx)/24/3600;
                case 'lblLE' % roi label Line End
                    obj.lblSet.End(nLbl) = obj.lblSet.End(nLbl) + ...
                        (obj.controlObj.plotLenS*(srcFig.CurrentPoint(1) - sigObj.previousCurrentPoint)/axsigszx)/24/3600;
            end
            sigObj.previousCurrentPoint = srcFig.CurrentPoint(1);
            % Draw the change
            ch = obj.lblSet.Channel(nLbl);
            if ch == 0
                ch = obj.controlObj.signalObj.chToPlot(1);
            end
            st = datenum(obj.lblSet.Start(nLbl) - obj.sigInfo.SigStart(ch))*24*3600; % In seconds
            en = datenum(obj.lblSet.End(nLbl) - obj.sigInfo.SigStart(ch))*24*3600; % In seconds
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
                obj.lblSetSelected(nLbl, tagPrefix);
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
        function obj = lblSetSelected(obj, nLbl, tagPrefix) % Called from lblClicked
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
            lblStartS = datenum(obj.lblSet.Start(nLbl(1)) - obj.sigInfo.SigStart(ch))*24*3600;
            obj.controlObj.jumpToLabel(lblStartS, ch);
        end
        function obj = lblSetDelete(obj)
            obj.lblSetOld = obj.lblSet; % For undo (only one step back possible)
            
            idToDelete = obj.lblSet.ID(obj.lblSet.Selected);
            obj.controlObj.signalObj.lblDelete(idToDelete) % First delete the graphic object then the table entry
            obj.lblSet(obj.lblSet.Selected, :) = [];
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
            loadpath = xlsfilep;
            save('loadpath.mat', 'loadpath')
            writetable(obj.h.uitLblSet.DisplayData, fullfile(xlsfilep, xlsfilen));
        end
        function obj = lblShowShowedChannels(obj)
            obj.showShowedChannels = obj.h.butt(strcmp({obj.h.butt.Tag}, 'lblShowShowedChannels')).Value;
            obj.lblSetUpdateView;
        end
        function obj = lblShowShowedClasses(obj)
            obj.showShowedClasses = obj.h.butt(strcmp({obj.h.butt.Tag}, 'lblShowShowedClasses')).Value;
            obj.lblSetUpdateView;
        end
        function obj = setSignalAxesCallback(obj)
            [obj.controlObj.signalObj.h.axSig.ButtonDownFcn] = deal(@obj.cbAxesClick);
        end
        
        %% Saving and loading
        function obj = getFilep(obj)
            load('loadpath.mat', 'loadpath')
            fp = uigetdir(loadpath, 'Label path');
            if fp == 0
                return
            end
            loadpath = fp;
            save('loadpath.mat', 'loadpath')
            obj.filep = fp;
            obj.fileUpdate;
        end
        function obj = lblSave(obj)
            if isempty(obj.filep)
                obj.getFilep;
            end
            currentSigFilepn = obj.controlObj.signalObj.filepn{obj.controlObj.currentFile};
            [~, currentSigFilen] = fileparts(currentSigFilepn);
            obj.currentFilen = [currentSigFilen, '-lbl3.mat'];
            sigInfo = obj.sigInfo; %#ok<PROP>
            lblDef = obj.lblDef; %#ok<PROP>
            lblSet = obj.lblSet; %#ok<PROP>
            vrNm = lblSet.Properties.VariableNames; %#ok<PROP>
            for k = 1 : length(vrNm)
                if isa(lblSet.(vrNm{k}), 'string') %#ok<PROP>
                    lblSet.(vrNm{k}) = categorical(lblSet.(vrNm{k})); %#ok<PROP>
                end
            end
            save(fullfile(obj.filep, obj.currentFilen), 'sigInfo', 'lblDef', 'lblSet')
            obj.controlObj.h.eLabelpn.String = fullfile([obj.filep, '\'], char(obj.currentFilen));
        end
        function fileNumber = nextNonEmptyFile(obj)
            d = dir([obj.filep, '\*.mat']);
            filen = {d(~[d.isdir]).name}';
            for kf = 1 : length(filen)
                dtSubs = regexpi(filen{kf}, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D') + 1; % Date and time subscript
                dt = filen{kf}(dtSubs : dtSubs + 12);
                if datetime(dt, 'InputFormat', 'yyMMdd_HHmmss') > max(obj.controlObj.signalObj.sigTbl.SigStart)
                   [~, ~, l] = loadLabel(fullfile(obj.filep, filen{kf}));
                    if size(l, 1) > 0
                        fileNumber = obj.controlObj.findCorrespondingFile(filen{kf}, obj.controlObj.signalObj.filepn);
                        if isempty(fileNumber)
                            disp(['_jk No signal file corresponds to label file ', filen{kf}])
                        end
                        return
                    end
                end
            end
        end
        function fileNumber = prevNonEmptyFile(obj)
            d = dir([obj.filep, '\*.mat']);
            filen = {d(~[d.isdir]).name}';
            for kf = length(filen) : -1 : 1
                dtSubs = regexpi(filen{kf}, '\D\d\d\d\d\d\d_\d\d\d\d\d\d\D') + 1; % Date and time subscript
                dt = filen{kf}(dtSubs : dtSubs + 12);
                if datetime(dt, 'InputFormat', 'yyMMdd_HHmmss') < min(obj.controlObj.signalObj.sigTbl.SigStart - 2/24/3600)
                   [~, ~, l] = loadLabel(fullfile(obj.filep, filen{kf}));
                    if size(l, 1) > 0
                        fileNumber = obj.controlObj.findCorrespondingFile(filen{kf}, obj.controlObj.signalObj.filepn);
                        if isempty(fileNumber)
                            disp(['_jk No signal file corresponds to label file ', filen{kf}])
                        end
                        return
                    end
                end
            end
        end
        
        %% Helper functions
        function obj = updateColors(obj, uit) % Use this when sorting
            drawnow
            c = [];
            for k = 1 : size(uit.DisplayData, 1)
                c(k, :) = str2num(obj.lblDef.Color(obj.lblDef.ClassName == string(uit.DisplayData.ClassName(k)))); %#ok<AGROW,ST2NM> % Base color of the label
                if any(ismember(uit.ColumnName, 'Value'))
                    c(k, :) = 1 - (1 - c(k, :))*double(uit.DisplayData.Value(k)/9); %#ok<AGROW> % Bleach the color according to the Value
                end
            end
            if ~isempty(c)
                uit.BackgroundColor = c;
            end
        end
        function obj = updateSigInfo(obj)
            nSigCh = size(obj.controlObj.signalObj.sigTbl, 1);
            [sigFilep, sigFilen, sigFilee] =  fileparts(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile});
            obj.sigInfo.FileName = repelem(string([sigFilen, sigFilee]), nSigCh)';
            obj.sigInfo.FilePath = repelem(string(sigFilep), nSigCh)';
            obj.sigInfo(:, 3 : 7) = obj.controlObj.signalObj.sigTbl(:, 1 : 5);
            obj.controlObj.h.eLabelpn.String = [fullfile([obj.filep, '\'], char(obj.currentFilen)), '*'];
        end
        
        function obj = createLblFig(obj)
            if isfield(obj.h, 'f')
                if isvalid(obj.h.f)
                    figure(obj.h.f)
                    return
                end
            end
            obj.h.f = uifigure('Position', obj.stg.lFigPos, 'Name', 'Label', 'Tag', 'label', 'WindowKeyPressFcn', @obj.cbKey); % Does not work with figure
            
            obj.h.g = uigridlayout(obj.h.f);
            obj.h.g.RowHeight = {'2x', 'fit', '4x', 60, 'fit', '1x', 50}; % uigridlayout for lbl definitions, uilabel, lbl table, uilabel, signal info table, buttons
            obj.h.g.ColumnWidth = {'1x'};
            
            obj.h.g2 = uigridlayout(obj.h.g); % Nested uigridlayout for lbl definitions
            obj.h.g2.RowHeight = {'fit', '1x'}; % uilabel, lbl definition tables
            obj.h.g2.ColumnWidth = {'1x', '1x'}; % Label classes to show, Label classes to edit
            
            obj.h.lLblSelShow = uilabel(obj.h.g2,'Text','Label classes to show');
            obj.h.lLblSelEdit = uilabel(obj.h.g2,'Text','Label classes to edit'); % This label is inserted by clicking
            
            Show = obj.lblClassesToShow; % Show this channel?
            data = [obj.lblDef(:, 1), table(Show)];
            obj.h.uitLblSelShow = uitable(obj.h.g2, 'Data', data, 'ColumnEditable', logical([0 1]), 'ColumnWidth', {'auto', 'auto'},...
                'CellEditCallback', @obj.cbUitLblSelShow, 'CellSelectionCallback', @obj.cbUitLblSelShow,...
                'Tag', 'uitLblSelShow');
            Show = obj.lblClassesToEdit; % Show this channel?
            data = [obj.lblDef(:, 1), table(Show)];
            obj.h.uitLblSelEdit = uitable(obj.h.g2, 'Data', data, 'ColumnEditable', logical([0 0]), 'ColumnWidth', {'auto', 'auto'},...
                'CellEditCallback', @obj.cbUitLblSelEdit, 'CellSelectionCallback', @obj.cbUitLblSelEdit,...
                'Tag', 'uitLblSelEdit');
            
            obj.h.lLblSet = uilabel(obj.h.g,'Text','Labels');
            obj.h.uitLblSet = uitable(obj.h.g, 'Data', obj.lblSet, 'ColumnSortable', false,...
                'ColumnEditable', logical([0 1 1 1 1 1 0 0 0]),...
                'ColumnWidth', {70, 33, 58, 58, 33, 'auto', 38, 33, 'auto'},...
                'CellEditCallback', @obj.cbUitLblSetEdit, 'CellSelectionCallback', @obj.cbUitLblSetSelect, 'DisplayDataChangedFcn', @obj.cbUitLblDisp, ...
                'Tag', 'uitLblSet');
            drawnow
            obj.lblSetUpdateView;
            
            % Buttons
            obj.h.g3 = uigridlayout(obj.h.g, 'Padding', [0 10 0 0]);
            obj.h.g3.RowHeight = {'1x', '1x'}; % uilabel, lbl definition tables
            obj.h.g3.ColumnWidth = {'1x', '1x', '1x', '1x'}; % Lbl def edit, duplicate, delete, undo, show only showed channels, show only showed classes
            obj.h.butt(1) = uibutton(obj.h.g3, 'push',...
                    'Text', 'Duplicate', 'Tooltip', 'Duplicate label, ctrl+d',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetDuplicate');
            obj.h.butt(2) = uibutton(obj.h.g3, 'push',...
                    'Text', 'Delete', 'Tooltip', 'Delete label, delete',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetDelete');
            obj.h.butt(3) = uibutton(obj.h.g3, 'push',...
                    'Text', 'Undo', 'Tooltip', 'Undo, ctrl+z',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetUndo');
            obj.h.butt(4) = uibutton(obj.h.g3, 'push',...
                    'Text', '*.xlsx', 'Tooltip', 'Download displayed table as *.xlsx',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblSetXls');
            obj.h.butt(5) = uibutton(obj.h.g3, 'push',...
                    'Text', 'Definitions', 'Tooltip', 'Open label definitions, ctrl+f',...
                    'ButtonPushedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblDefEdit');
            obj.h.butt(6) = uibutton(obj.h.g3, 'state',...
                    'Text', 'Channels', 'Tooltip', 'Show only channels showed in the signal window',...
                    'ValueChangedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblShowShowedChannels');
            obj.h.butt(7) = uibutton(obj.h.g3, 'state',...
                    'Text', 'Classes', 'Tooltip', 'Show only classes showed in the signal window',...
                    'ValueChangedFcn', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tag', 'lblShowShowedClasses');
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
end

