classdef controlWindow < handle

    properties
        signalObj
        videoObj
        videoShowObj
        labelObj
        tmr % Timer object, used to run video and cursor along the signal

        plotLimS % Current plot limits on x-axis
        nowS % Video and cursor position in time
        oldNowS % Used for Stop command, returns the video where it started to play
        nowClicked % Logical, used for moving now line
        modifier % char array showing which modifier is pressed (empty most of the time)
        currentDigit % Double. Used for labeling.
        callbackRunning

        showWholeFile % Logical
        linkVerticalZoom % Logical
        persistentNumber % Logical. If TRUE, after you shortly press a number, it behaves like if it was still being press until you shortly press it again
        playSpeed % 1 = normal speed

        currentFile % Number of the currently loaded signal file

        EEGFullData
        EEGSegmentData
        destinationFolder

        automaticLabelSaving
        stg % Settings created by stgs function
        key % Table of keyboard shortcuts created by keyShortTbl funcction
        h % Handles to graphic objects
    end

    methods
        %% Constructor
        function obj = controlWindow
            obj.stg = stgs; % Get settings
            obj.key = keyShortTbl; % Get keyboard shortcuts
            obj.currentFile = 1;
            obj.modifier = '';

            % Create the figure with all the buttons etc.
            obj = createWindow(obj);

            % Create timer. Used for running video and cursor along the signal.
            obj.tmr = timer;
            obj.tmr.ExecutionMode = 'fixedRate';
            obj.tmr.Period = obj.stg.cTimerPeriod;
            obj.tmr.TimerFcn = @obj.cbTimer;

            obj.playSpeed = 1; % Determines the multiples of the timer period that the now line and video jumps every timer period.
            obj.automaticLabelSaving = false;
            obj.showWholeFile = false;
            obj.linkVerticalZoom = false;
            obj.persistentNumber = false;
            obj.callbackRunning = false;

            msg = ['Dear Donkey user,', 10, 10, ...
                'New features!', 10, 10, ...
                'Easily move the displayed file to any location. For details, please contact Nedime.', 10, 10, ...
                'OSEL now supports average reference computation. It removes common activity, reduces noise, centers signals.', 10, ...
                'The user filter is now turned on and off for all channels at once using the top button above the first channel name.',10, ...
                'You can easily cycle between Classes to edit using A key.', 10, ...
                'By pressing Ctrl+space OSEL starts going automatically page by page Press Ctrl+space to stop.', 10, ...
                'V and Z keys save the labels before moving to the next file.', 10,...
                'But do not swich too fast when using V and Z otherwise the labels may be saved incorretly.', 10,...
                'Page Up or Page Down do not save labels and you can use them as fast as you want.', 10,...
                'You are still encouraged to use Ctrl+S often.', 10, 10, ...
                'The main new feature is that the Control Window is joined with the Signal Window.', 10,...
                'This allows you to use Alt key to open the menu and use the underlined letter to perform desired command.', 10,...
                'Horizontal zoom in    Shift + Left Click',10,'Horizontal zoom out  Ctrl + Left Click', 10, 10, ...
                'Enjoy!', 10, 'Nedime, Anna and Jan, your donkey herders'];
            obj.h.tIntroMessage = text(0, -360, 100, msg, 'Parent', obj.h.haxIntro, 'Clipping', 'off', 'VerticalAlignment', 'top', 'Color', [0.6 0 0.6],'FontSize',10);
        end

        %% Callback for menu (implements the functionality already)
        function cbMenu(obj, src, ~) % Callback for menu
            switch src.Tag
                case 'signalLoad' % Possibly move the code to a function
                    % First ask user for the file path and names. If the user changes their mind during the uigetfile and selects nothing,
                    % getFilepn returns empty and nothing happens so we don't clear the current signal.
                    filepn = controlWindow.getFilepn('Select signal files', 'on', '\*.*', 'signal');
                    if isempty(filepn)
                        return
                    end
                    % User selected new signal files. Delete everything and reset the view times.
                    if isa(obj.signalObj, 'signal')
                        % % % delete(obj.signalObj(end))
                        obj.signalObj(end) = [];
                    end
                    obj.currentFile = 1;
                    obj.plotLimS = obj.stg.cDefaultPlotLimS; % Default (usually 0 to 10 seconds or so)
                    obj.nowS = obj.stg.cDefaultPlotLimS(1); % Default (usually 0)
                    obj.signalObj = signal(obj, filepn); % Create the signal object. Only creates figure, does not plot signals.
                    obj.fileUpdate; % Plots signals and updates file names etc.
                    [obj.h.bNav.Enable] = deal('on'); [obj.h.bNav([6, 7]).Enable] = deal('off');
                    obj.h.eCurrentFile.Enable = 'on';
                    obj.h.tTotalFiles.String = ['/', num2str(length(obj.signalObj.filepn))];
                    obj.h.eSignalpn.Enable = 'on';
                    obj.h.mVideo.Enable = 'on';
                    obj.h.mLabel.Enable = 'on';
                    obj.h.eSamplingFreq.Enable = 'on';
                case 'signalChannels'
                    obj.signalObj.channels;

                case 'signalExport'
                    sigTbl = obj.signalObj.plotTbl;

                    % Truncate each channel to plot limits
                    for kch = 1 : size(sigTbl, 1)
                        sigTbl.SigStart(kch) = sigTbl.SigStart(kch) + seconds(obj.plotLimS(1));
                        lim = int64(obj.plotLimS*sigTbl.Fs(kch) + [1 0]);
                        lim(2) = min(lim(2), length(sigTbl.Data{kch}));
                        sigTbl.Data{kch} = sigTbl.Data{kch}(lim(1) : lim(2));
                        sigTbl.SigEnd(kch) = sigTbl.SigStart(kch) + seconds(numel(sigTbl.Data{kch})/sigTbl.Fs(kch));
                    end

                    load('loadpath.mat', 'loadpath')
                    [~, saven] = fileparts(obj.signalObj.filepn{obj.currentFile});
                    [r, i] = regexp(saven, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
                    %                     origDt = r{1}(2 : end);
                    origDt = r{1}(1 : end);
                    newDt = datestr(min(sigTbl.SigStart), 'yymmdd_HHMMSS');
                    saven(i : i + length(origDt) - 1) = newDt;
                    saven = [saven, '-ExportFromFile', origDt(1:6), '__', origDt(8:13), '.mat'];
                    [saven, savep] = uiputfile(fullfile(loadpath, saven));
                    %                     loadpath = savep; save('loadpath.mat', 'loadpath');
                    save(fullfile(savep, saven), 'sigTbl');

                case 'filter50Hz'
                    obj.signalObj.flt50HzTF = ~obj.signalObj.flt50HzTF;
                    obj.signalObj.plotSignal;
                    if obj.signalObj.flt50HzTF
                        obj.h.mFilter50Hz.Checked = 'on';
                    else
                        obj.h.mFilter50Hz.Checked = 'off';
                    end
                case 'filterUser'
                    obj.signalObj.fltUserTF = ~obj.signalObj.fltUserTF;
                    obj.signalObj.plotSignal;
                    if obj.signalObj.fltUserTF
                        obj.h.mFilterUser.Checked = 'on';
                    else
                        obj.h.mFilterUser.Checked = 'off';
                    end
                case 'filterEditUser'  % Filter setting dialog

                    [order, lowFreq, highFreq, applyAll, cancelled] = customFilterDialog(obj);

                    if cancelled
                        disp('User cancelled the operation.');
                    else
                        disp(['Filter Order: ', order]);
                        disp(['Low Cut Frequency: ', lowFreq]);
                        disp(['High Cut Frequency: ', highFreq]);
                        disp(['Apply to All Channels: ', num2str(applyAll)]);
                    end
                    obj.signalObj.fltUserSpecs.ApplyAll = applyAll;
                    obj.signalObj.fltUserSpecs.N = str2double(order);
                    obj.signalObj.fltUserSpecs.F1 = str2double(lowFreq);
                    obj.signalObj.fltUserSpecs.F2 = str2double(highFreq);
                    obj.signalObj.fltUserTF = true;
                    obj.signalObj.plotSignal;
                    obj.h.mFilterUser.Checked = 'on';
                
                case 'AverageRef'
                    obj.signalObj.avgRefTF = ~obj.signalObj.avgRefTF;
                    obj.signalObj.customAverageRefDialog;
                    if obj.signalObj.avgRefTF
                        obj.h.mAverageRef.Checked = 'on';
                    else
                        obj.h.mAverageRef.Checked = 'off';
                    end
                    obj.signalObj.sigUpdate;

                
                case 'toggleBipolar'
                    obj.toggleBipolar;
                
                case 'MoveSignalTo'
                    [loadpath, ~, ~, ~] = controlWindow.getLoadpath([]);
                    obj.destinationFolder  = uigetdir(loadpath,'Please select the destination folder:');
                                      
                   
                case 'videoLoad'
                    % First ask user for the file path and names. If the user changes their mind during the uigetfile and selects nothing,
                    % getFilepn returns empty and nothing happens so no new videoObj is created.
                    filepn = controlWindow.getFilepn('Select video files', 'on', '\*.*', 'video');
                    if isempty(filepn)
                        return
                    end
                    if length(filepn) ~= length(obj.signalObj.filepn) % Throw warning if number of loaded video files is different from number of signal files
                        warning(['_jk Number of loaded video files is ', num2str(length(filepn)),...
                            ' but number of signal files is ', num2str(length(obj.signalObj.filepn))])
                    end
                    if isempty(obj.videoShowObj) % If no video show exists, create one. Only one will be used for any number of videos displayed.
                        obj.videoShowObj = videoShow(obj);
                        [obj.h.bNav.Enable] = deal('on');
                        % obj.h.ePlaySpeed.Enable = 'on';
                        % [obj.h.bPlaySpeed.Enable] = deal('on');
                        obj.h.eBrightness.Enable = 'on';
                        [obj.h.bBrightness.Enable] = deal('on');
                        obj.h.eVideopn.Enable = 'on';
                    end
                    % User selected new video files
                    obj.videoObj = [obj.videoObj, video(obj, filepn)]; % Create the video object
                    obj.videoShowObj = obj.videoShowObj.updateStreams;
                    obj.h.eVideopn.String = obj.videoObj(1).filepn{obj.currentFile};
                case 'videoLoad1'
                    % First ask user for the file path and names. If the user changes their mind during the uigetfile and selects nothing,
                    % getFilepn returns empty and nothing happens so no new videoObj is created.
                    filepn = controlWindow.getFilepn('Select video files', 'on', '\*-1.*', 'video');
                    if isempty(filepn)
                        return
                    end
                    if length(filepn) ~= length(obj.signalObj.filepn) % Throw warning if number of loaded video files is different from number of signal files
                        warning(['_jk Number of loaded video files is ', num2str(length(filepn)),...
                            ' but number of signal files is ', num2str(length(obj.signalObj.filepn))])
                    end
                    if isempty(obj.videoShowObj) % If no video show exists, create one. Only one will be used for any number of videos displayed.
                        obj.videoShowObj = videoShow(obj);
                        [obj.h.bNav.Enable] = deal('on');
                        % obj.h.ePlaySpeed.Enable = 'on';
                        % [obj.h.bPlaySpeed.Enable] = deal('on');
                        obj.h.eBrightness.Enable = 'on';
                        [obj.h.bBrightness.Enable] = deal('on');
                        obj.h.eVideopn.Enable = 'on';
                    end
                    % User selected new video files
                    obj.videoObj = [obj.videoObj, video(obj, filepn)]; % Create the video object
                    obj.videoShowObj = obj.videoShowObj.updateStreams;
                    obj.h.eVideopn.String = obj.videoObj(1).filepn{obj.currentFile};
                case 'videoLoad2'
                    % First ask user for the file path and names. If the user changes their mind during the uigetfile and selects nothing,
                    % getFilepn returns empty and nothing happens so no new videoObj is created.
                    filepn = controlWindow.getFilepn('Select video files', 'on', '\*-2.*', 'video');
                    if isempty(filepn)
                        return
                    end
                    if length(filepn) ~= length(obj.signalObj.filepn) % Throw warning if number of loaded video files is different from number of signal files
                        warning(['_jk Number of loaded video files is ', num2str(length(filepn)),...
                            ' but number of signal files is ', num2str(length(obj.signalObj.filepn))])
                    end
                    if isempty(obj.videoShowObj) % If no video show exists, create one. Only one will be used for any number of videos displayed.
                        obj.videoShowObj = videoShow(obj);
                        [obj.h.bNav.Enable] = deal('on');
                        % obj.h.ePlaySpeed.Enable = 'on';
                        % [obj.h.bPlaySpeed.Enable] = deal('on');
                        obj.h.eBrightness.Enable = 'on';
                        [obj.h.bBrightness.Enable] = deal('on');
                        obj.h.eVideopn.Enable = 'on';
                    end
                    % User selected new video files
                    obj.videoObj = [obj.videoObj, video(obj, filepn)]; % Create the video object
                    obj.videoShowObj = obj.videoShowObj.updateStreams;
                    obj.h.eVideopn.String = obj.videoObj(1).filepn{obj.currentFile};
                case 'videoLoad3'
                    % First ask user for the file path and names. If the user changes their mind during the uigetfile and selects nothing,
                    % getFilepn returns empty and nothing happens so no new videoObj is created.
                    filepn = controlWindow.getFilepn('Select video files', 'on', '\*-3.*', 'video');
                    if isempty(filepn)
                        return
                    end
                    if length(filepn) ~= length(obj.signalObj.filepn) % Throw warning if number of loaded video files is different from number of signal files
                        warning(['_jk Number of loaded video files is ', num2str(length(filepn)),...
                            ' but number of signal files is ', num2str(length(obj.signalObj.filepn))])
                    end
                    if isempty(obj.videoShowObj) % If no video show exists, create one. Only one will be used for any number of videos displayed.
                        obj.videoShowObj = videoShow(obj);
                        [obj.h.bNav.Enable] = deal('on');
                        % obj.h.ePlaySpeed.Enable = 'on';
                        % [obj.h.bPlaySpeed.Enable] = deal('on');
                        obj.h.eBrightness.Enable = 'on';
                        [obj.h.bBrightness.Enable] = deal('on');
                        obj.h.eVideopn.Enable = 'on';
                    end
                    % User selected new video files
                    obj.videoObj = [obj.videoObj, video(obj, filepn)]; % Create the video object
                    obj.videoShowObj = obj.videoShowObj.updateStreams;
                    obj.h.eVideopn.String = obj.videoObj(1).filepn{obj.currentFile};
                case 'labelWindow'
                    if isempty(obj.labelObj)
                        obj.labelObj = label(obj); % Calls createLblFig inside
                    end
                    obj.labelObj.createLblFig;
                case 'labelLoad'
                    if isempty(obj.labelObj)
                        obj.labelObj = label(obj); % Calls createLblFig inside
                        obj.labelObj.createLblFig;
                    end
                    % First ask user for the file path and name. If the user changes their mind during the uigetfile and selects nothing,
                    % getFilepn returns empty and nothing happens so no new videoObj is created.
                    filepn = controlWindow.getFilepn('Select signal files', 'off', '\*-lbl3.*', 'label');
                    if isempty(filepn)
                        return
                    end
                    % User selected a label file, let's continue
                    [flp, fln] = fileparts(filepn{1});
                    obj.labelObj.filep = flp;
                    obj.labelObj.currentFilen = fln;
                    [obj.labelObj.sigInfo, obj.labelObj.lblDef, obj.labelObj.lblSet] = loadLabel(filepn{1});
                    if length(obj.labelObj.lblClassesToShow) ~= size(obj.labelObj.lblDef, 1)
                        obj.labelObj.lblClassesToShow = true(size(obj.labelObj.lblDef, 1), 1);
                        obj.labelObj.lblClassesToEdit = false(size(obj.labelObj.lblDef, 1), 1);
                    end
                    obj.labelObj.lblSetUpdateView;
                    obj.signalObj.lblPlot;
                    obj.h.eLabelpn.String = filepn{1};
                case 'labelPath'
                    if isempty(obj.labelObj)
                        obj.labelObj = label(obj); % Calls createLblFig inside
                    end
                    obj.labelObj.createLblFig;
                    obj.labelObj.getFilep;
                case 'labelSave'
                    obj.labelObj.labelSave;
                case 'labelSaveAs'
                    load('loadpath.mat', 'loadpath')
                    [filen, filep] = uiputfile([loadpath, '*.mat'], 'Save As');
                    if filen == 0
                        return
                    end
                    %                     loadpath = filep;
                    %                     save('loadpath.mat', 'loadpath')
                    sigInfo = obj.labelObj.sigInfo;
                    lblDef = obj.labelObj.lblDef;
                    lblSet = obj.labelObj.lblSet;
                    save(fullfile(filep, filen), 'sigInfo', 'lblDef', 'lblSet')
                case 'labelExportXls'
                    load('loadpath.mat', 'loadpath')
                    [filen, filep] = uiputfile([loadpath, '*.xlsx']);
                    %                     loadpath = filep;
                    %                     save('loadpath.mat', 'loadpath')
                    writetable(obj.labelObj.sigInfo, fullfile(filep, filen), 'Sheet', 1);
                    writetable(obj.labelObj.lblDef, fullfile(filep, filen), 'Sheet', 2);
                    writetable(obj.labelObj.lblSet, fullfile(filep, filen), 'Sheet', 3);
            end
            %% Function for Filter added Apply all channels option
            function [filterOrder, lowCutFreq, highCutFreq, applyAll, isCancelled] = customFilterDialog(obj, src, ~)
                % Creates new dialog window
                d = dialog('Position',[400,400,300,250],'Name','Filter Settings');
                % Default Values
                filterOrder = num2str(obj.signalObj.fltUserSpecs.N);
                lowCutFreq = num2str(obj.signalObj.fltUserSpecs.F1);
                highCutFreq = num2str(obj.signalObj.fltUserSpecs.F2);
                applyAll = obj.signalObj.fltUserSpecs.ApplyAll;
                isCancelled = true;

                % Filter Order
                uicontrol('Parent',d, 'Style','text', 'Position',[20,190,120,20], ...
                    'String','Filter Order:', 'HorizontalAlignment','left');
                filterOrderBox = uicontrol('Parent',d, 'Style','edit', 'Position',[150,190,120,25],'String',filterOrder);

                % Low Cut Frequency
                uicontrol('Parent',d, 'Style','text', 'Position',[20,150,120,20], ...
                    'String','Low Cut Frequency:', 'HorizontalAlignment','left');
                lowCutFreqBox = uicontrol('Parent',d, 'Style','edit', 'Position',[150,150,120,25],'String',lowCutFreq);

                % High Cut Frequency
                uicontrol('Parent',d, 'Style','text', 'Position',[20,110,120,20], ...
                    'String','High Cut Frequency:', 'HorizontalAlignment','left');
                highCutFreqBox = uicontrol('Parent',d, 'Style','edit', 'Position',[150,110,120,25],'String',highCutFreq);

                % Apply to all channels checkbox
                applyAllBox = uicontrol('Parent',d, 'Style','checkbox', 'Position',[20,70,250,25], ...
                    'String','Apply to all channels');

                % OK button
                btnOK = uicontrol('Parent',d, 'Position',[50,20,80,30], ...
                    'String','OK', 'Callback',@okCallback);

                % Cancel button
                btnCancel = uicontrol('Parent',d, 'Position',[170,20,80,30], ...
                    'String','Cancel', 'Callback',@cancelCallback);

                % If OK button pushed
                function okCallback(~,~)
                    filterOrder = filterOrderBox.String;
                    lowCutFreq = lowCutFreqBox.String;
                    highCutFreq = highCutFreqBox.String;
                    applyAll = applyAllBox.Value;
                    isCancelled = false;
                    delete(d); % Close windows
                end

                % If Cancel button pushed
                function cancelCallback(~,~)
                    filterOrder = '';  % Defines default empty values
                    lowCutFreq = '';
                    highCutFreq = '';
                    applyAll = false;
                    isCancelled = true; % User cancelled
                    delete(d); % close windows
                end

                % wait till user closes window
                uiwait(d);

            end

        end

        %% Callback for buttons and file number edit field
        function cbUicontrol(obj, src, ~)
            uicontrol(obj.h.tCurrentFile); % For the clicked button to lose focus so that hitting spacebar does not "click" it again. The focus on the text is benign.
            eval(['obj.', src.Tag, ';']); % Only calls appropriate function
        end

        %% Callback for file path and name edit fields
        function cbEditpn(obj, src, ~) %#ok<INUSL>
            str = eval(['obj.', lower(src.Tag(2 : end - 2)), 'Obj.filepn(obj.currentFile)']);
            src.String = str;
        end

        %% Callback function for sampling frequency
        function cbtextClicked(obj, src, ~)
            str = {max(obj.signalObj.plotTbl.Fs)};

            src.String = str;
            % Add any additional actions here
        end

        %% Callbacks for keyboard
        function cbKey(obj, ~, keyData)
            if isstrprop(keyData.Key, 'digit') % For labeling
                if obj.persistentNumber
                    if isempty(obj.currentDigit)
                        obj.currentDigit = str2double(keyData.Key);
                    else
                        obj.currentDigit = [];
                    end
                else
                    obj.currentDigit = str2double(keyData.Key);
                end
            end
            if isempty(keyData.Modifier)
                obj.modifier = ''; % Modifier (ctrl, shift or alt)
            elseif length(keyData.Modifier) == 1 %#ok<ISCL>
                obj.modifier = keyData.Modifier{1};
            elseif length(keyData.Modifier) == 2 % I don't use all three modifiers at once
                obj.modifier = [keyData.Modifier{2}, '+', keyData.Modifier{1}]; % In case there is Ctrl+Shift. Matlab has shift in the first cell of keyData.Modifier.
            end
            cmdName = char(obj.key.Command(obj.key.Shortcut == keyData.Key & obj.key.Modifier == string(obj.modifier))); % Command name (as specified in the keyShortTbl, it is also function name)
            if ~isempty(cmdName)
                eval(['obj.', cmdName, ';']);
            end
        end
        function cbKeyRelease(obj, ~, keyData)
            if ismember(keyData.Key, {'control', 'shift', 'alt'})
                idx = strfind(obj.modifier, keyData.Key);
                obj.modifier(idx : idx + length(keyData.Key) - 1) = [];
                obj.modifier(obj.modifier == '+') = ' '; % So that we can use strtrim to remove + at the beginning and end
                obj.modifier = strtrim(obj.modifier); % strtrim keeps the spaces between words
                obj.modifier(obj.modifier == ' ') = '+'; % Convert spaces back to +
                if ~isempty(obj.signalObj)
                    obj.signalObj.h.f.WindowButtonDownFcn = @obj.cbSigButtDn;
                end
            end
            if ~obj.persistentNumber
                if isstrprop(keyData.Key, 'digit') % Pertains to labeling
                    obj.currentDigit = [];
                end
            end
        end

        %% Callback for timer
        function cbTimer(obj, ~, ~) % Timer function
            if obj.nowS > obj.signalObj.sigLenS || obj.nowS > max([obj.videoObj.vidLenS]) % We overran signal or video
                stop(obj.tmr)
                return
            end
            if obj.nowS > obj.plotLimS(2) - (1 - obj.stg.cPage)/2*obj.plotLenS % We are approaching the end of current view
                obj.plotLimS = obj.plotLimS + obj.stg.cPage*obj.plotLenS; % Turn page (it's turning not the whole page but obj.stg.cPage which is typically 0.8)
                sigOverrun = obj.plotLimS(2) - obj.signalObj.sigLenS; % How much the new obj.plotLimS overran the total signal length when turning the page (if negative, no overrun occured, this will be most of the time)
                if sigOverrun > 0 % I.e. no overrun occured
                    obj.plotLimS = obj.plotLimS - sigOverrun; % New obj.plotLimS overran signal length so let's shift it back by sigOverrun
                end
                obj.signalObj.sigUpdate;
                obj.signalObj.nowUpdate;
                if ~isempty(obj.videoShowObj)
                    obj.videoObj.nextFrame;
                end
                if ~isempty(obj.labelObj)
                    obj.signalObj.lblUpdate;
                end
            else
                obj.videoObj.nextFrame; % Cursor in the signal is updated withing videoShowObj.nowUpdate
            end
        end
        function cbTimerAutoPage(obj, ~, ~)
            obj.pageForward;
        end

        %% Callbacks for mouse
        function cbSigButtDn(obj, src, ~)
            %             if strcmp(src.Tag, 'signal')
            obj.signalObj.previousCurrentPoint = src.CurrentPoint(1);
            src.WindowButtonMotionFcn = @obj.cbSigButtMotion;
            %             end
        end
        function cbSigButtUp(obj, src, ~)
            % This function is used for visualizing the currently plotted labels in the tabel (e.g. by italic font). Not used in this version.
            updatePlottedTF = false;
            if contains(char(src.WindowButtonMotionFcn), 'cbSigButtMotion') % Do this only when finishing mouse panning
                updatePlottedTF = true;
            end
            src.WindowButtonMotionFcn = [];
            if updatePlottedTF && ~isempty(obj.labelObj)
                drawnow
                %                 obj.labelObj.lblSetUpdatePlotted(obj.labelObj.plottedLabelsIDs);
                %                 drawnow
            end
        end
        function cbSigButtMotion(obj, src, ~)
            %             if strcmp(src.Tag, 'signal')
            if strcmp(src.CurrentObject.Tag, 'now')
                obj.nowMove(src);
            elseif length(src.CurrentObject.Tag) >= 4
                if strcmp(src.CurrentObject.Tag(1 : 4), 'lblL')
                    obj.labelObj.lblBorderMove(src, src.CurrentObject);
                else
                    obj.signalPan(src);
                end
            else
                obj.signalPan(src);
            end
            %             end
        end
        function cbSigZoomButtDn(obj, src, ~, direction)
            obj.signalObj.mouseZoomInDn(src, obj, direction);
        end
        function cbSigZoomButtMotion(obj, src, ~)
            obj.signalObj.mouseZoomInMotion(src);
        end
        function cbSigZoomButtUp(obj, src, ~, direction)
            obj.signalObj.mouseZoomInUp(src, direction);
        end
        function cbSigScrollWheel(obj, ~, evt)
            if strcmpi(obj.modifier, '')
                if evt.VerticalScrollCount < 0
                    obj.backward;
                elseif evt.VerticalScrollCount > 0
                    obj.forward;
                end
            elseif strcmpi(obj.modifier, 'control')
                if evt.VerticalScrollCount < 0
                    obj.verticalZoomIn;
                elseif evt.VerticalScrollCount > 0
                    obj.verticalZoomOut;
                end
            elseif strcmpi(obj.modifier, 'shift')
                if evt.VerticalScrollCount < 0
                    obj.horizontalZoomIn;
                elseif evt.VerticalScrollCount > 0
                    obj.horizontalZoomOut;
                end
            end
        end
        function cbSigMeasureButtDn(obj, src, ~)
            obj.signalObj.mouseMeasureDn(src, obj);
        end
        function cbSigMeasureButtMotion(obj, src, ~)
            obj.signalObj.mouseMeasureMotion(src);
        end
        function cbSigMeasureButtUp(obj, src, ~)
            obj.signalObj.h.f.WindowButtonUpFcn = @obj.cbSigButtUp;
            obj.signalObj.h.f.WindowButtonMotionFcn = [];
            obj.signalObj.mouseMeasureUp(src);
        end
        function cbSigFocus(obj)
            obj.signalObj.h.f.WindowButtonDownFcn = @obj.cbSigButtDn;
            obj.signalObj.h.f.WindowButtonUpFcn = @obj.cbSigButtUp;
            obj.signalObj.h.f.WindowButtonMotionFcn = [];
        end
        
        %% Navigation buttons' functions
        function obj = saveLblPrevFile(obj)
            if obj.callbackRunning
                return
            end
            obj.callbackRunning = true;
            obj.h.f.Interruptible = 'on';
            obj.signalObj.h.f.Interruptible = 'on';
            %             drawnow
            % Save current label
            if ~isempty(obj.labelObj) % First save current label
                obj.labelObj = obj.labelObj.lblSave;
                pause(0.5)
            end
            if obj.currentFile > 1
                stop(obj.tmr)
                obj.plotLimS = [0, obj.plotLenS]; % Keep same zoom
                obj.nowS = obj.plotLimS(1);
                obj.currentFile = obj.currentFile - 1;
                obj.fileUpdate;
            else
                disp(['_jk currentFile = ', num2str(obj.currentFile), '/', num2str(length(obj.signalObj.filepn))])
            end
            obj.h.f.Interruptible = 'on';
            obj.signalObj.h.f.Interruptible = 'on';
            drawnow
            obj.callbackRunning = false;
        end
        function obj = prevFile(obj)
            if obj.callbackRunning
                return
            end
            if obj.currentFile > 1
                stop(obj.tmr)
                obj.plotLimS = [0, obj.plotLenS]; % Keep same zoom
                obj.nowS = obj.plotLimS(1);
                obj.currentFile = obj.currentFile - 1;
                obj.fileUpdate;
            else
                disp(['_jk currentFile = ', num2str(obj.currentFile), '/', num2str(length(obj.signalObj.filepn))])
            end
        end
        function obj = whichIsCreatedPrevFile(obj)
            obj.labelObj = obj.labelObj.lblSave;
            if obj.currentFile > 1
                stop(obj.tmr)
                obj.plotLimS = [0, obj.plotLenS]; % Keep same zoom
                obj.nowS = obj.plotLimS(1);
                obj.currentFile = obj.currentFile - 1;
                obj.fileUpdate;
            else
                disp(['_jk currentFile = ', num2str(obj.currentFile), '/', num2str(length(obj.signalObj.filepn))])
            end
        end
        function obj = jumpToStart(obj)
            obj.plotLimS = [0 obj.plotLenS];
            obj.nowS = obj.plotLimS(1);
            obj.signalObj.sigUpdate; % Updates now as well. If plotLimS(1) == 0, nowS = 0 as well so that the user can play the video from the beginning.
            obj.signalObj.nowUpdate;
            if ~isempty(obj.videoShowObj)
                obj.videoObj.updateNow;
            end
        end
        function obj = pageBackward(obj)
            obj.plotLimS = obj.plotLimS - obj.stg.cPage*obj.plotLenS;
            if obj.plotLimS(1) < 0
                obj.plotLimS = obj.plotLimS - obj.plotLimS(1);
            end
            obj.sigUpdate; % Updates now as well
        end
        function obj = backward(obj)
            obj.plotLimS = obj.plotLimS - obj.stg.cMove*obj.plotLenS;
            if obj.plotLimS(1) < 0
                obj.plotLimS = obj.plotLimS - obj.plotLimS(1);
            end
            obj.sigUpdate;
        end
        function obj = playPause(obj)
            if obj.callbackRunning
                return
            end
            if isempty(obj.videoObj)
                return
            end
            if strcmpi(obj.tmr.Running, 'off')
                obj.oldNowS = obj.nowS;
                obj.videoObj.updateNow;
                start(obj.tmr);
                obj.h.bNav(6).Value = 1;
                obj.tmr.Period = obj.stg.cTimerPeriod;
                obj.tmr.TimerFcn = @obj.cbTimer;
            else
                stop(obj.tmr);
                obj.h.bNav(6).Value = 0;
            end
        end
        function obj = stop(obj)
            if strcmpi(obj.tmr, 'on')
                stop(obj.tmr);
                obj.nowS = obj.oldNowS;
                if obj.nowS < obj.plotLimS(1)
                    obj.plotLimS = [obj.nowS - obj.plotLenS/2, obj.nowS + obj.plotLenS/2];
                end
                if obj.plotLimS(1) < 0
                    obj.plotLimS = obj.plotLimS - obj.plotLimS(1);
                end
                obj.signalObj.sigUpdate;
                obj.signalObj.nowUpdate;
                obj.h.bNav(6).Value = 0;
            end
        end
        function obj = forward(obj)
            obj.plotLimS = obj.plotLimS + obj.stg.cMove*obj.plotLenS;
            sigOverrun = obj.plotLimS(2) - obj.signalObj.sigLenS; % How much we overran the signal (if negative, no overrun occured, this will be most of the time)
            if sigOverrun > 0 % We overrun the signal length
                obj.plotLimS = obj.plotLimS - sigOverrun;
            end
            obj.sigUpdate;
        end
        function obj = pageForward(obj)
            obj.plotLimS = obj.plotLimS + obj.stg.cPage*obj.plotLenS;
            sigOverrun = obj.plotLimS(2) - obj.signalObj.sigLenS; % How much we overran the signal (if negative, no overrun occured, this will be most of the time)
            if sigOverrun > 0 % We overrun the signal length
                obj.plotLimS = obj.plotLimS - sigOverrun;
            end
            obj.sigUpdate;
        end
        function obj = jumpToEnd(obj)
            obj.plotLimS = [obj.signalObj.sigLenS - obj.plotLenS, obj.signalObj.sigLenS];
            obj.sigUpdate;
        end
        function obj = saveLblNextFile(obj)
            if obj.callbackRunning
                return
            end
            obj.callbackRunning = true;
            obj.h.f.Interruptible = 'on';
            obj.signalObj.h.f.Interruptible = 'on';
            % % % % % % % % % % 'c1'
            drawnow
            % Save current label
            if ~isempty(obj.labelObj) % First save current label
                % % % % % % % 'c2 -> s'
                obj.labelObj = obj.labelObj.lblSave;
                % % % % % 's -> c3'
            end
            % % % % % % % % % 'c4'
            if obj.currentFile < length(obj.signalObj.filepn)
                stop(obj.tmr)
                obj.plotLimS = [0, obj.plotLenS]; % Keep same zoom
                obj.nowS = obj.plotLimS(1);
                obj.currentFile = obj.currentFile + 1;
                % % % % % % 'c5'
                obj.fileUpdate;
                % % % % % % 'c6'
            else
                disp(['_jk currentFile = ', num2str(obj.currentFile), '/', num2str(length(obj.signalObj.filepn))])
            end
            obj.h.f.Interruptible = 'on';
            obj.signalObj.h.f.Interruptible = 'on';
            drawnow
            % % % % % 'c7'
            obj.callbackRunning = false;
        end
        function obj = nextFile(obj)
            if obj.callbackRunning
                return
            end
            % Save current label
            % % % %             if ~isempty(obj.labelObj) && obj.automaticLabelSaving % First save current label
            % % % %                 obj.labelObj = obj.labelObj.lblSave;
            % % % %             end
            if obj.currentFile < length(obj.signalObj.filepn)
                stop(obj.tmr)
                obj.plotLimS = [0, obj.plotLenS]; % Keep same zoom
                obj.nowS = obj.plotLimS(1);
                obj.currentFile = obj.currentFile + 1;
                obj.fileUpdate;
            else
                disp(['_jk currentFile = ', num2str(obj.currentFile), '/', num2str(length(obj.signalObj.filepn))])
            end
        end
        function obj = autoPageForward(obj)
            if obj.callbackRunning
                return
            end
            switch obj.tmr.Running
                case 'off'
                    obj.tmr.Period = 1/obj.playSpeed;
                    obj.tmr.BusyMode = 'queue';
                    obj.tmr.TimerFcn = @obj.cbTimerAutoPage;
                    start(obj.tmr)
                    obj.h.bNav(6).Value = 1;
                case 'on'
                    stop(obj.tmr)
                    obj.h.bNav(6).Value = 0;
            end
        end
        function obj = toggleBipolar(obj)
            obj.signalObj.bipolarTF = ~obj.signalObj.bipolarTF;
            if obj.signalObj.bipolarTF
                obj.h.mToggleBipolar.Checked = 'on';
            else
                obj.signalObj.chToPlot = 1 : height(obj.signalObj.sigTbl);
                obj.h.mToggleBipolar.Checked = 'off';
            end
            obj.signalObj.plotSignal;  % Just plots whatever is in plotTbl
        end
        function obj = moveSigToFolder(obj)
            % moveSigToFolder
            if isempty(obj.destinationFolder)
                return
            else
                movefile(obj.signalObj.filepn{obj.currentFile}, obj.destinationFolder); % movefile(oldPath, newPath)
                [filepath,name,ext] = fileparts(obj.signalObj.filepn{obj.currentFile}); 
                filepath = obj.destinationFolder;
                obj.signalObj.filepn{obj.currentFile} = fullfile(filepath, [name ext]); % Update file list
                nextFile(obj); 
                disp('File successfully moved.');
            end
        end
        
        %% Functions related to the middle uipanels
        function obj = toggleShowWholeFile(obj)
            obj.showWholeFile = ~obj.showWholeFile;
        end
        function obj = toggleLinkVerticalZoom(obj)
            obj.linkVerticalZoom = ~obj.linkVerticalZoom;
        end
        function obj = togglePersistentNumber(obj)
            obj.persistentNumber = ~obj.persistentNumber;
        end
        function obj = editCurrentFile(obj)
            % Save current label
            if ~isempty(obj.labelObj) && obj.automaticLabelSaving % First save current label
                obj.labelObj = obj.labelObj.lblSave;
            end
            oldString = obj.h.eCurrentFile.String; % In case user enters string not convertible to double
            kf = str2double(obj.h.eCurrentFile.String); % Current file number. Try to convert to double
            if isnan(kf) % Couldn't convert to double so returned NaN
                obj.h.eCurrentFile.String = oldString;
                return
            end
            if kf >= 1 && kf <= length(obj.signalObj.filepn)
                % Reset everything
                stop(obj.tmr)
                obj.plotLimS = obj.stg.cDefaultPlotLimS;
                obj.nowS = obj.plotLimS(1);
                % Set current file
                obj.currentFile = kf;
                obj.fileUpdate;
            else
                disp(['_jk Requested file number ', num2str(kf), ' but total number of files is ', num2str(length(obj.signalObj.filepn))])
            end
        end
        function obj = editPlaySpeed(obj)
            wasRunning = false;
            if strcmpi(obj.tmr.Running, 'on')
                stop(obj.tmr);
                wasRunning = true;
            end
            obj.playSpeed = str2double(obj.h.ePlaySpeed.String);
            if ~isempty(obj.videoObj)
                obj.tmr.Period = 1/obj.videoObj.vidRdr.FrameRate/obj.playSpeed;
            else
                obj.tmr.Period = 1/obj.playSpeed;
            end
            if wasRunning
                start(obj.tmr);
            end
        end
        function obj = decreasePlaySpeed(obj)
            wasRunning = false;
            if strcmpi(obj.tmr.Running, 'on')
                stop(obj.tmr);
                wasRunning = true;
            end
            obj.playSpeed = obj.playSpeed/obj.stg.cPlaySpeedChange;
            obj.h.ePlaySpeed.String = obj.playSpeed;
            if ~isempty(obj.videoObj)
                obj.tmr.Period = 1/obj.videoObj.vidRdr.FrameRate/obj.playSpeed;
            else
                obj.tmr.Period = 1/obj.playSpeed;
            end
            if wasRunning
                pause(obj.tmr.Period)
                start(obj.tmr);
            end
        end
        function obj = increasePlaySpeed(obj)
            wasRunning = false;
            if strcmpi(obj.tmr.Running, 'on')
                stop(obj.tmr);
                wasRunning = true;
            end
            obj.playSpeed = obj.playSpeed*obj.stg.cPlaySpeedChange;
            obj.h.ePlaySpeed.String = obj.playSpeed;
            if ~isempty(obj.videoObj)
                obj.tmr.Period = 1/obj.videoObj.vidRdr.FrameRate/obj.playSpeed;
            else
                obj.tmr.Period = 1/obj.playSpeed;
            end
            if wasRunning
                pause(obj.tmr.Period)
                start(obj.tmr);
            end
        end
        function obj = editBrightness(obj)
            obj.videoShowObj.brightnessMult = str2double(obj.h.eBrightness.String);
            obj.videoShowObj = obj.videoShowObj.updateStreams;
        end
        function obj = decreaseBrightness(obj)
            obj.videoShowObj.brightnessMult = obj.videoShowObj.brightnessMult/obj.stg.cBrightnessChange;
            obj.h.eBrightness.String = obj.videoShowObj.brightnessMult;
            obj.videoShowObj = obj.videoShowObj.updateStreams;
        end
        function obj = increaseBrightness(obj)
            obj.videoShowObj.brightnessMult = obj.videoShowObj.brightnessMult*obj.stg.cBrightnessChange;
            obj.h.eBrightness.String = obj.videoShowObj.brightnessMult;
            obj.videoShowObj = obj.videoShowObj.updateStreams;
        end
        function obj = neuroSignalStudio_checkbox(obj)
            clc;
            disp('NeuroSignal Studio is running....');
            neuroSignalStudio(obj);
        end

        %% Zoom
        function obj = horizontalZoomIn(obj)
            centerS = mean(obj.plotLimS); % Can be easily changed for nowS
            plotLimitS = centerS + [-obj.plotLenS, obj.plotLenS]/2/obj.stg.cHorizontalZoom;
            if diff(plotLimitS) < 2/min(obj.signalObj.sigTbl.Fs)
                disp('No more zoom in')
                return
            end
            obj.plotLimS = plotLimitS;
            %             obj.plotLimS(2) = obj.plotLimS(1) + obj.plotLenS/obj.stg.cHorizontalZoom; % Zooming around the left-most point
            sigOverrun = obj.plotLimS(2) - obj.signalObj.sigLenS; % How much we overran the signal (if negative, no overrun occured, this will be most of the time)
            if sigOverrun > 0 % We overrun the signal length
                obj.plotLimS = obj.plotLimS - sigOverrun;
            end
            if strcmpi(obj.tmr.Running, 'on') % If timer running, only update signal and don't move now
                obj.signalObj.sigUpdate
            else
                obj.sigUpdate; % This function updates signal and now
            end
        end
        function obj = horizontalZoomOut(obj)
            centerS = mean(obj.plotLimS); % Can be easily changed for nowS
            obj.plotLimS = centerS + [-obj.plotLenS, obj.plotLenS]/2*obj.stg.cHorizontalZoom;
            %             obj.plotLimS(2) = obj.plotLimS(1) + obj.plotLenS*obj.stg.cHorizontalZoom; % Zooming around the left-most point
            obj.plotLimS(1) = max(obj.plotLimS(1), 0);
            obj.plotLimS(2) = min(obj.plotLimS(2), obj.signalObj.sigLenS);
            if strcmpi(obj.tmr.Running, 'on') % If timer running, only update signal and don't move now
                obj.signalObj.sigUpdate
            else
                obj.sigUpdate; % This function updates signal and now
            end
        end
        function obj = verticalZoomIn(obj)
            obj.signalObj.verticalZoomIn;
        end
        function obj = verticalZoomOut(obj)
            obj.signalObj.verticalZoomOut;
        end

        %% Mouse signal view control (panning and zooming)
        function obj = signalPan(obj, src)
            obj.signalObj.h.axSig(1).Units = 'pixels';
            axsigszx = obj.signalObj.h.axSig(1).Position(3); % Axes of signal, size x
            obj.signalObj.h.axSig(1).Units = 'normalized';
            obj.plotLimS = obj.plotLimS + obj.plotLenS*(obj.signalObj.previousCurrentPoint - src.CurrentPoint(1))/axsigszx; % Change obj.plotLimS
            obj.signalObj.previousCurrentPoint = src.CurrentPoint(1);
            sigOverrun = obj.plotLimS(2) - obj.signalObj.sigLenS; % How much we overran the signal (if negative, no overrun occured, this will be most of the time)
            if sigOverrun > 0 % We overrun the signal length
                obj.plotLimS = obj.plotLimS - sigOverrun;
            end
            if obj.plotLimS(1) < 0
                obj.plotLimS = obj.plotLimS - obj.plotLimS(1);
            end
            if strcmpi(obj.tmr.Running, 'off')
                %                 obj.nowS = obj.plotLimS(1) + (1 - obj.stg.cPage)/2*obj.plotLenS;
                obj.nowS = obj.plotLimS(1) + obj.plotLenS/2;
            end
            obj.sigUpdate;
        end
        function obj = nowMove(obj, src)
            obj.signalObj.h.axSig(1).Units = 'pixels';
            axsigszx = obj.signalObj.h.axSig(1).Position(3); % Axes of signal, size x
            obj.signalObj.h.axSig(1).Units = 'normalized';
            obj.nowS = obj.nowS + obj.plotLenS*(src.CurrentPoint(1) - obj.signalObj.previousCurrentPoint)/axsigszx;
            obj.signalObj.previousCurrentPoint = src.CurrentPoint(1);
            obj.signalObj.nowUpdate;
            if ~isempty(obj.videoShowObj)
                obj.videoObj.updateNow;
            end
        end
        function obj = mouseZoomIn(obj)
            obj.signalObj.h.f.WindowButtonDownFcn = {@obj.cbSigZoomButtDn, 'in'};
        end
        function obj = mouseZoomOut(obj)
            if ~isempty(obj.signalObj)
                obj.signalObj.h.f.WindowButtonDownFcn = {@obj.cbSigZoomButtDn, 'out'};
            end
        end
        function obj = mouseZoomFinished(obj, zl) % zl ... zoom limits
            obj.signalObj.h.f.WindowButtonUpFcn = @obj.cbSigButtUp;
            obj.signalObj.h.f.WindowButtonMotionFcn = [];
            obj.plotLimS = zl;
            obj.plotLimS(1) = max(obj.plotLimS(1), 0);
            obj.plotLimS(2) = min(obj.plotLimS(2), obj.signalObj.sigLenS);
            if obj.plotLimS(2) < obj.plotLimS(1) + 2/min(obj.signalObj.sigTbl.Fs)
                disp('No more zoom in')
                obj.plotLimS(2) = obj.plotLimS(1) + 2/min(obj.signalObj.sigTbl.Fs);
                return
            end
            % % pllim = obj.plotLimS; disp(pllim)
            if strcmpi(obj.tmr.Running, 'on') % If timer running, only update signal and don't move now
                obj.signalObj.sigUpdate
            else
                obj.sigUpdate; % This function updates signal and now
            end
        end
        function obj = mouseZoomEscape(obj)
            obj.signalObj.mouseZoomEscape;
        end
        function obj = mouseZoomEscapeFinished(obj)
            obj.signalObj.h.f.WindowButtonUpFcn = @obj.cbSigButtUp;
            obj.signalObj.h.f.WindowButtonMotionFcn = [];
        end
        function obj = mouseMeasure(obj)
            obj.signalObj.h.f.WindowButtonDownFcn = {@obj.cbSigMeasureButtDn};
        end
        function obj = sliderMove(obj, src)
            obj.plotLimS = [src.Value, src.Value + obj.plotLenS];
            obj.plotLimS(1) = max(obj.plotLimS(1), 0);
            obj.plotLimS(2) = min(obj.plotLimS(2), obj.signalObj.sigLenS);
            if strcmpi(obj.tmr.Running, 'on') % If timer running, only update signal and don't move now
                obj.signalObj.sigUpdate
            else
                obj.sigUpdate; % This function updates signal and now
            end
        end

        %% Labels
        function obj = numberPressed(obj)
            % Finally we do not use this function. Labeling by numbers is implemented using obj.currentDigit which is empty when no number is
            % currently pressed.
        end
        function obj = numberReleased(obj)
            % Finally we do not use this function. Labeling by numbers is implemented using obj.currentDigit which is empty when no number is
            % currently pressed.
        end
        function obj = labelDelete(obj)
            obj.labelObj.lblSetDelete;
        end
        function obj = labelUndo(obj)
            obj.labelObj.lblSetUndo;
        end
        function obj = labelSave(obj)
            obj.labelObj.lblSave;
        end
        function obj = jumpToLabel(obj, lblStartS, ch)
            obj.nowS = lblStartS;
            pl = obj.plotLenS;
            fromMargin = (1 - obj.stg.cPage);
            if obj.nowS > obj.plotLimS(2) - fromMargin*obj.plotLenS || obj.nowS < obj.plotLimS(1) + fromMargin*obj.plotLenS % We are approaching the end of current view
                obj.plotLimS(1) = max(0, obj.nowS - fromMargin*pl);
                obj.plotLimS(2) = obj.plotLimS(1) + pl;
                sigOverrun = obj.plotLimS(2) - obj.signalObj.sigLenS; % How much the new obj.plotLimS overran the total signal length when turning the page (if negative, no overrun occured, this will be most of the time)
                if sigOverrun > 0 % I.e. no overrun occured
                    obj.plotLimS = obj.plotLimS - sigOverrun; % New obj.plotLimS overran signal length so let's shift it back by sigOverrun
                end
                obj.signalObj.sigUpdate;
            end
            obj.signalObj.nowUpdate;
            if ~isempty(obj.videoShowObj)
                obj.videoObj.updateNow;
            end
            obj.signalObj.lblUpdate;
            whichAxes = obj.signalObj.chToPlot == ch;
            [obj.signalObj.h.lNow.Visible] = deal('off');
            obj.signalObj.h.lNow(whichAxes).Visible = 'on';
        end
        function obj = nextSigWNonEmptyLabel(obj)
            sl = obj.labelObj.lblSet(obj.labelObj.shownLabels, :); % Table of shown labels (i.e. those with appropriate Class and Channel)
            if isempty(sl)
                jumpToLabelId = -1; % -1 will cause finding new non-empty label file and corresponding signal file
            else
                sls = sortrows(sl, 'Start'); % Shown labels sorted
                slsStartS = datenum(sls.Start - obj.labelObj.sigInfo.SigStart(sls.Channel))*24*3600; %#ok<DATNM> % Start times of shown labels
                % slsEndS = datenum(sls.End - obj.labelObj.sigInfo.SigStart(sls.Channel))*24*3600; % End times of shown labels
                whichAreSelected = find(sls.Selected);
                % Deselect those which are outside the plotLimS
                for kl = 1 : numel(whichAreSelected)
                    if slsStartS(whichAreSelected(kl)) < obj.plotLimS(1) || slsStartS(whichAreSelected(kl)) > obj.plotLimS(2)
                        sls.Selected(whichAreSelected(kl)) = false;
                        id = sls.ID(whichAreSelected(kl));
                        obj.labelObj.lblSet(obj.labelObj.lblSet.ID == id, :).Selected = false;
                    end
                end
                idSel = sls.ID(sls.Selected); % IDs of the labels which are selected (have Select == true)
                if isempty(idSel)
                    % Find the first label (the one with the lowest time)
                    jumpToLabelId = sls.ID(1);
                else
                    if ~isscalar(idSel) % If multiple labels are selected
                        idSel = sls.ID(find(sls.Selected, 1)); % Only the first of the selected
                    end
                    % %                     if (slsEndS(end) < obj.plotLimS(2)) || (idSel == sls.ID(end)) % If now is after all labels or the selected label is the one with the highest Start time
                    if idSel == sls.ID(end) % If the last (with highest StartTime) label is selected
                        jumpToLabelId = -1;
                    else
                        jumpToLabelId = sls.ID(find(sls.ID == idSel, 1) + 1);
                    end
                end
            end
            if jumpToLabelId == -1
                d = dir([obj.labelObj.filep, '/*lbl3.mat']);
                lbln = {d.name}';
                lblpn = fullfile(obj.labelObj.filep, lbln);
                kfToLoad = NaN;
                for kf = obj.currentFile + 1 : numel(obj.signalObj.filepn)
kf_ = kf
                    fileNumber = obj.findCorrespondingFile(obj.signalObj.filepn{kf}, lbln);
                    if isempty(fileNumber)
                        disp('no corresponding file')
                        continue
                    end
                    [newSigInfo, newLblDef, newLblSet] = loadLabel(lblpn{fileNumber});
                    if size(newSigInfo, 1) ~= size(obj.labelObj.sigInfo, 1)
                        kfToLoad = kf; break;
                    end
                    if newSigInfo.ChName ~= obj.labelObj.sigInfo.ChName
                        kfToLoad = kf; break;
                    end
                    if size(newLblDef, 1) > size(obj.labelObj.lblDef, 1)
                        kfToLoad = kf; break;
                    end
                    if ~all(ismember(newLblDef.ClassName, obj.labelObj.lblDef.ClassName))
                        kfToLoad = kf; break;
                    end
                    if obj.labelObj.showShowedChannels
                        showChIdx = ismember(newLblSet.Channel, obj.signalObj.chToPlot);
                    else
                        showChIdx = true(size(newLblSet, 1), 1);
                    end
                    if obj.labelObj.showShowedClasses
                        showClIdx = ismember(newLblSet.ClassName, obj.labelObj.lblDef.ClassName(obj.labelObj.lblClassesToShow));
                    else
                        showClIdx = true(size(newLblSet, 1), 1);
                    end
                    showIdx = showChIdx & showClIdx;
                    % % % showIds = newLblSet.ID(showIdx)
                    if ~isempty(newLblSet(showIdx, :))
                        kfToLoad = kf; break;
                    end
                end
                if ~isnan(kfToLoad)
                    stop(obj.tmr)
                    obj.currentFile = kfToLoad;
                    obj.plotLimS = [0, obj.plotLenS];
                    obj.nowS = obj.plotLimS(1);
                    obj.fileUpdate;
                    sl = obj.labelObj.lblSet;
                    sls = sortrows(sl, 'Start'); % Sorted shown labels
                    idx = find(obj.labelObj.lblSet.ID == sls.ID(1));
                    obj.labelObj.lblSetSelect(idx, '');
                else
                    msgbox('OSEL did not find more non-empty label files.')
                end
            else
                idx = find(obj.labelObj.lblSet.ID == jumpToLabelId);
                obj.labelObj.lblSetSelect(idx, '');
            end
        end
        function obj = prevSigWNonEmptyLabel(obj)
            msgbox('OSEL cannot go backwards. It is a stupid animal. (Jan will try to teach him in the future)')
            % kf = obj.labelObj.prevNonEmptyFile();
            % if isempty(kf)
            %     return
            % end
            % % Reset everything
            % stop(obj.tmr)
            % obj.plotLimS = [0, obj.plotLenS];
            % obj.nowS = obj.plotLimS(1);
            % obj.currentFile = kf;
            % % Set current file
            % obj.fileUpdate;
            % obj.labelObj.lblSetSelect(1, '');
        end
        function obj = nextNonEmptyLabelFile(obj)
            sl = obj.labelObj.lblSet(obj.labelObj.shownLabels, :); % Table of shown labels (i.e. those with appropriate Class and Channel)
            if isempty(sl)
                jumpToLabelId = -1; % -1 will cause finding new non-empty label file and corresponding signal file
            else
                sls = sortrows(sl, 'Start'); % Shown labels sorted
                %                 slsStartS = datenum(sls.Start - obj.labelObj.sigInfo.SigStart(sls.Channel))*24*3600; % Start times of shown labels
                %                 slsEndS = datenum(sls.End - obj.labelObj.sigInfo.SigStart(sls.Channel))*24*3600; % End times of shown labels
                idSel = sls.ID(sls.Selected); % IDs of the labels which are selected (have Select == true)
                if isempty(idSel)
                    % Find the first label (the one with the lowest time)
                    jumpToLabelId = sls.ID(1);
                else
                    if ~isscalar(idSel) % If multiple labels are selected
                        idSel = sls.ID(find(sls.Selected, 1)); % Only the first of the selected
                    end
                    % %                     if (slsEndS(end) < obj.plotLimS(2)) || (idSel == sls.ID(end)) % If now is after all labels or the selected label is the one with the highest Start time
                    if idSel == sls.ID(end) % If the last (with highest StartTime) label is selected
                        jumpToLabelId = -1;
                    else
                        jumpToLabelId = sls.ID(find(sls.ID == idSel, 1) + 1);
                    end
                end
            end
            if jumpToLabelId == -1
                % Need to find next non-empty file

                kf = obj.labelObj.nextNonEmptyFile();
                if isempty(kf)
                    return
                end
                stop(obj.tmr)
                obj.currentFile = kf;
                obj.fileUpdate;

                % Reset everything
                obj.plotLimS = [0, obj.plotLenS];
                obj.nowS = obj.plotLimS(1);
                sl = obj.labelObj.lblSet(obj.labelObj.shownLabels, :); % Table of shown labels
                sls = sortrows(sl, 'Start'); % Sorted shown labels
                idx = find(obj.labelObj.lblSet.ID == sls.ID(1));
                obj.labelObj.lblSetSelect(idx, '');
            else
                idx = find(obj.labelObj.lblSet.ID == jumpToLabelId);
                obj.labelObj.lblSetSelect(idx, '');
            end
        end
        function obj = prevNonEmptyLabelFile(obj)
            kf = obj.labelObj.prevNonEmptyFile();
            if isempty(kf)
                return
            end
            % Reset everything
            stop(obj.tmr)
            obj.plotLimS = [0, obj.plotLenS];
            obj.nowS = obj.plotLimS(1);
            obj.currentFile = kf;
            % Set current file
            obj.fileUpdate;
            obj.labelObj.lblSetSelect(1, '');
        end
        function obj = cycleLabelClassToEdit(obj)
            obj.labelObj.cycleClassToEdit;
        end
        function obj = editCurrentFileFocus(obj)
            uicontrol(obj.h.eCurrentFile);
        end
        function cbResize(~, hf, ~)
            hf.Children(1).Position(2) = hf.Position(4) - 60;
            hf.Children(2).Position(2) = hf.Position(4) - 60;
            hf.Children(3).Position(2) = hf.Position(4) - 60;
        end

        %% Easter eggs
        function obj = easterEgg01(obj) % Shows a painting by Roger Dean in a new window
            l = load('pics/rogerDean1.mat');
            figure('MenuBar', 'none', 'ToolBar', 'none')
            hax = axes('Position', [0 0 1 1]);
            image(l.img1)
            hax.Visible = 'off';
        end
        function obj = easterEgg02(obj) % Changes mouse cursor into a mouse. Active point is mouse's nose.
            
            if ~isempty(obj.signalObj)
                if strcmpi(obj.signalObj.h.f.Pointer, 'custom')
                    obj.signalObj.h.f.Pointer = 'arrow';
                else
                    load('pics/mouse.mat', 'mouse')
                    obj.signalObj.h.f.PointerShapeCData = mouse;
                    obj.signalObj.h.f.Pointer = 'custom';

                    %                     p = double(imread('pics/mouse.bmp')); p(p == 1) = NaN; p(p == 0) = 1;
                    %                     assignin('base', 'p', p)
                    %                     obj.signalObj.h.f.PointerShapeCData = p;
                    %                     obj.signalObj.h.f.Pointer = 'custom';
                end
            end
        end
        % % % function obj = easterEgg03(obj)
        % % %     % obj.h.tIntroMessage.String = 'You tried it! You''re a rebel!!!';
        % % %     % this is the coalesced image included
        % % %     fullFileName = 'giphy.gif';
        % % %     % i'm not going to bother reading CT1 here
        % % %     gifImage = imread(fullFileName, 'Frames', 'all');
        % % %     % get all the colortables from imfinfo()
        % % %     S = imfinfo(fullFileName);
        % % %     numImages = numel(S);
        % % %     % set up figure with a blank image
        % % %     hfEasterEgg03 = figure('Color', 'k', 'units', 'normalized', 'outerposition', [0 0 1 1],...
        % % %         'MenuBar','none','ToolBar','none','DockControls','off');
        % % %     imSize = size(gifImage);
        % % %     screenSize = get(0, "ScreenSize");
        % % %     factor = screenSize(3)/imSize(1); %#ok<NASGU> % Do not know how to use it with the "InitialMagnification". I'm not gonna spend several hours with the easter egg, sorry.
        % % %     hi = imshow(zeros(size(gifImage(:,:,1,1))), "InitialMagnification", 1000, "Interpolation", "bilinear");
        % % %     hi.CDataMapping = 'direct';
        % % %     for k = 1 : numImages
        % % %         % updating the object takes much less time
        % % %         % and so frame delays are more accurate
        % % %         hi.CData = gifImage(:,:,:,k);
        % % %         colormap(S(k).ColorTable)
        % % %
        % % %         % caption = sprintf('Frame %#d of %d', k, numImages);
        % % %         % title(caption);
        % % %         drawnow;
        % % %
        % % %         % use the specified frame delays
        % % %         pause(S(k).DelayTime/100)
        % % %     end
        % % %     close(hfEasterEgg03)
        % % % end

        %% Helper functions
        function obj = fileUpdate(obj)
            % Set the edit field
            obj.h.eCurrentFile.String = num2str(obj.currentFile);

            % Signal
            obj.signalObj.fileUpdate;
            obj.h.eSignalpn.String = obj.signalObj.filepn(obj.currentFile);
            obj.h.eSamplingFreq.String = {max(obj.signalObj.plotTbl.Fs)};
            % Load new label
            if ~isempty(obj.labelObj)
                obj.labelObj = obj.labelObj.fileUpdate; % Load label file (if it exists)
            end

            % Video
            if ~isempty(obj.videoObj)
                for k = 1 : length(obj.videoObj)
                    obj.videoObj(k).fileUpdate;
                end
                obj.videoShowObj = obj.videoShowObj.updateStreams;
                obj.h.eVideopn.String = obj.videoObj.filepn(obj.videoObj.currentFile);
            end
        end
        function obj = sigUpdate(obj)
            % Signal
            obj.signalObj.sigUpdate;
            obj.nowUpdate; % Updates obj.nowS and calls signal, video and label functions to implement the updated now
        end
        function obj = nowUpdate(obj)
            % Updates obj.nowS and calls functions to implement the updated now. Call this function after user whichIsCreateding or zooming not within timerFcn.
            % The form of update depends on whether timer is running
            if strcmpi(obj.tmr.Running, 'on')
                if obj.nowS < obj.plotLimS(1) + obj.plotLenS*obj.stg.cNowMargin || obj.nowS > obj.plotLimS(2) - obj.plotLenS*obj.stg.cNowMargin
                    obj.nowS = obj.plotLimS(1) + obj.plotLenS*obj.stg.cNowMargin;
                end
            else
                obj.nowS = mean(obj.plotLimS);
            end
            obj.signalObj.nowUpdate;
            if ~isempty(obj.videoShowObj)
                obj.videoObj.updateNow;
            end
        end
        function l = plotLenS(obj)
            l = diff(obj.plotLimS);
        end
        function obj = createWindow(obj)
            obj.h.f = figure('Position', obj.stg.cFigPos, 'MenuBar', 'none', 'ToolBar', 'none',...
                'WindowKeyPressFcn', @obj.cbKey,...
                'WindowKeyReleaseFcn', @obj.cbKeyRelease,...
                'WindowButtonDownFcn', @obj.cbSigButtDn,...
                'WindowButtonUpFcn', @obj.cbSigButtUp,...
                'WindowScrollWheelFcn', @obj.cbSigScrollWheel,...
                'Interruptible', 'on', 'BusyAction', 'queue', 'Name', 'Open Signal Explorer and Labeller 4.0');
            obj.h.f.ResizeFcn = @obj.cbResize;

            % Create menu
            % Signal
            obj.h.mSignal = uimenu('Label', '&Signal',...
                'Tag', 'mSignal');
            obj.h.mSignalLoad = uimenu(obj.h.mSignal, 'Label', '&Load...', 'Callback', @obj.cbMenu,...
                'Tag', 'signalLoad');
            obj.h.mSignalChannel = uimenu(obj.h.mSignal, 'Label', '&Channels...', 'Callback', @obj.cbMenu,...
                'Tag', 'signalChannels');
            obj.h.mExportChannel = uimenu(obj.h.mSignal, 'Label', '&Export Displayed...', 'Callback', @obj.cbMenu,...
                'Tag', 'signalExport');
            obj.h.mFilter50Hz = uimenu(obj.h.mSignal, 'Label', 'Filter 50Hz &Hum', 'Callback', @obj.cbMenu,...
                'Tag', 'filter50Hz');
            obj.h.mFilterEditUser = uimenu(obj.h.mSignal, 'Label', 'E&dit User Filter...', 'Callback', @obj.cbMenu,...
                'Tag', 'filterEditUser');
            obj.h.mAverageRef = uimenu(obj.h.mSignal, 'Label', '&Average Reference...', 'Callback', @obj.cbMenu,...
            'Tag', 'AverageRef');
            obj.h.mToggleBipolar = uimenu(obj.h.mSignal, 'Label', 'Bipolar pairs', 'Callback', @obj.cbMenu,...
                'Tag', 'toggleBipolar');
            obj.h.mMoveSignalTo= uimenu(obj.h.mSignal, 'Label', '&Move SignalTo...', 'Callback', @obj.cbMenu,...
            'Tag', 'MoveSignalTo');
           

            % Video
            obj.h.mVideo = uimenu('Label', '&Video',...
                'Tag', 'mVideo', 'Enable', 'off');
            obj.h.mVideoLoad = uimenu(obj.h.mVideo, 'Label', '&Load...', 'Callback', @obj.cbMenu,...
                'Tag', 'videoLoad');
            obj.h.mVideoLoad1 = uimenu(obj.h.mVideo, 'Label', '&Load -1...', 'Callback', @obj.cbMenu,...
                'Tag', 'videoLoad1');
            obj.h.mVideoLoad2 = uimenu(obj.h.mVideo, 'Label', '&Load -2...', 'Callback', @obj.cbMenu,...
                'Tag', 'videoLoad2');
            obj.h.mVideoLoad2 = uimenu(obj.h.mVideo, 'Label', '&Load -3...', 'Callback', @obj.cbMenu,...
                'Tag', 'videoLoad3');


            % Label
            obj.h.mLabel = uimenu('Label', 'L&abel',...
                'Tag', 'mLabel', 'Enable', 'off');
            obj.h.mLabelWindow = uimenu(obj.h.mLabel, 'Label', '&Label Window', 'Callback', @obj.cbMenu,...
                'Tag', 'labelWindow');
            obj.h.mLabelLoad = uimenu(obj.h.mLabel, 'Label', '&Load Single File...', 'Callback', @obj.cbMenu,...
                'Tag', 'labelLoad');
            obj.h.mLabelPath = uimenu(obj.h.mLabel, 'Label', '&Set Path...', 'Callback', @obj.cbMenu,...
                'Tag', 'labelPath');
            obj.h.mLabelSave = uimenu(obj.h.mLabel, 'Label', '&Save', 'Callback', @obj.cbMenu,...
                'Tag', 'labelSave');
            obj.h.mLabelSaveAs = uimenu(obj.h.mLabel, 'Label', '&Save As...', 'Callback', @obj.cbMenu,...
                'Tag', 'labelSaveAs');
            obj.h.mLabelNewDef = uimenu(obj.h.mLabel, 'Label', '&Export label data in xlsx...', 'Callback', @obj.cbMenu,...
                'Tag', 'labelExportXls');

            % Buttons
            obj.h.panNav = uipanel('Units', 'pixels', 'Visible', 'on', 'BorderType', 'line',...
                'Position', obj.stg.cPanButtPos);
            buttText = {'L <', '|<<', '|<', '<<', '<', '||>', '[]', '>', '>>', '>|', '>>|', '> L'}; % Will appear on the buttons in the GUI
            subsCommand = find(obj.key.Command == "prevNonEmptyLabelFile"); % Subscript into keyShortTbl of given command
            buttTag = obj.key.Command(subsCommand : subsCommand + 12 - 1); % These 10 commands must be kept together in the keyShortTbl.m
            for k = 1 : length(buttText)
                % Generate tooltips. They contain the name of the function (literally) and keyboard shortcut.
                if obj.key.Modifier(k) == ""
                    tooltipStr = obj.key.Command(k) + ", " + obj.key.Shortcut(k); % Note that strings are, unlike char arrays, concatenated using +
                else
                    tooltipStr = obj.key.Command(k) + ", " + obj.key.Modifier(k) + "+" + obj.key.Shortcut(k);
                end
                % Generate buttons
                obj.h.bNav(k) = uicontrol('Parent', obj.h.panNav, 'Style', 'pushbutton', 'Units', 'pixels',...
                    'Position', [...
                    (k-1)*obj.stg.cPanButtPos(3)/length(buttText) + 0*obj.stg.cPanButtPos(3)/length(buttText)/10,... % Automatically generate position withing the panel
                    0*obj.stg.cPanButtPos(4)/5,...
                    obj.stg.cPanButtPos(3)/length(buttText)*10/10,...
                    obj.stg.cPanButtPos(4)*5/5],...
                    'String', buttText{k},...
                    'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                    'Tooltip', tooltipStr,...
                    'Tag', buttTag{k}, 'Enable', 'off');
            end
            obj.h.bNav(6).Style = 'togglebutton';

            % Display controls
            obj.h.panFileNumber = uipanel('Units', 'pixels', 'Position', obj.stg.cPanDisplayCtrPos);
            obj.h.cWholeFile = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'checkbox', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanDisplayCtrPos(4)*2/3,...
                obj.stg.cPanDisplayCtrPos(3)/1,...
                obj.stg.cPanDisplayCtrPos(4)*1/3],...
                'String', 'Show whole file', 'Callback', @obj.cbUicontrol,...
                'Tag', 'toggleShowWholeFile', 'Enable', 'on');
            obj.h.cWholeFile = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'checkbox', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanDisplayCtrPos(4)*1/3,...
                obj.stg.cPanDisplayCtrPos(3)/1,...
                obj.stg.cPanDisplayCtrPos(4)*1/3],...
                'String', 'Link vertical zoom', 'Callback', @obj.cbUicontrol,...
                'Tag', 'toggleLinkVerticalZoom', 'Enable', 'on');
            obj.h.cWholeFile = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'pushbutton', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanDisplayCtrPos(4)*0/3,...
                obj.stg.cPanDisplayCtrPos(3)/1.02,...
                obj.stg.cPanDisplayCtrPos(4)*1/3],...
                'String', 'NeuroSignal Studio', 'Callback', @obj.cbUicontrol,...
                'Tag', 'neuroSignalStudio_checkbox', 'Enable', 'on');

            % File number and play speed
            obj.h.panFileNumber = uipanel('Units', 'pixels', 'Position', obj.stg.cPanFileNumberPos);
            obj.h.tCurrentFile = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanFileNumberPos(4)*2/3,...
                obj.stg.cPanFileNumberPos(3)/2,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', 'Current file:', 'Tag', 'testCurrentFile');
            obj.h.eCurrentFile = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'edit', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)/2,...
                obj.stg.cPanFileNumberPos(4)*2/3,...
                obj.stg.cPanFileNumberPos(3)/4,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '0', 'Callback', @obj.cbUicontrol,...
                'Tag', 'editCurrentFile', 'Enable', 'off');
            obj.h.tTotalFiles = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'left',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)*3/4,...
                obj.stg.cPanFileNumberPos(4)*2/3,...
                obj.stg.cPanFileNumberPos(3)/4,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '/0',...
                'Tag', 'textTotalFiles');
            obj.h.tPlaySpeed = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanFileNumberPos(4)*1/3,...
                obj.stg.cPanFileNumberPos(3)/2,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', 'Play speed:',...
                'Tag', 'tPlaySpeed');
            obj.h.ePlaySpeed = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'edit', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)/2,...
                obj.stg.cPanFileNumberPos(4)*1/3,...
                obj.stg.cPanFileNumberPos(3)/4,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '1', 'Callback', @obj.cbUicontrol,...
                'Tag', 'editPlaySpeed', 'Enable', 'off');
            obj.h.bPlaySpeed(1) = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'pushbutton', 'Units', 'pixels',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)*6/8,...
                obj.stg.cPanFileNumberPos(4)*1/3,...
                obj.stg.cPanFileNumberPos(3)/8,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '-',...
                'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                'Tooltip', 'decreasePlaySpeed',...
                'Tag', 'decreasePlaySpeed', 'Enable', 'off');
            obj.h.bPlaySpeed(2) = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'pushbutton', 'Units', 'pixels',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)*7/8,...
                obj.stg.cPanFileNumberPos(4)*1/3,...
                obj.stg.cPanFileNumberPos(3)/8,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '+',...
                'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                'Tooltip', 'increasePlaySpeed',...
                'Tag', 'increasePlaySpeed', 'Enable', 'off');
            obj.h.tBrightness = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanFileNumberPos(4)*0/3,...
                obj.stg.cPanFileNumberPos(3)/2,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', 'Brightness:',...
                'Tag', 'tBrightness');
            obj.h.eBrightness = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'edit', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)/2,...
                obj.stg.cPanFileNumberPos(4)*0/3,...
                obj.stg.cPanFileNumberPos(3)/4,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '1', 'Callback', @obj.cbUicontrol,...
                'Tag', 'editBrightness', 'Enable', 'off');
            obj.h.bBrightness(1) = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'pushbutton', 'Units', 'pixels',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)*6/8,...
                obj.stg.cPanFileNumberPos(4)*0/3,...
                obj.stg.cPanFileNumberPos(3)/8,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '-',...
                'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                'Tooltip', 'decreaseBrightness',...
                'Tag', 'decreaseBrightness', 'Enable', 'off');
            obj.h.bBrightness(2) = uicontrol('Parent', obj.h.panFileNumber, 'Style', 'pushbutton', 'Units', 'pixels',...
                'Position', [...
                obj.stg.cPanFileNumberPos(3)*7/8,...
                obj.stg.cPanFileNumberPos(4)*0/3,...
                obj.stg.cPanFileNumberPos(3)/8,...
                obj.stg.cPanFileNumberPos(4)*1/3],...
                'String', '+',...
                'Callback', @obj.cbUicontrol,... % The callback function knows which button was pressed from the Tag
                'Tooltip', 'increaseBrightness',...
                'Tag', 'increaseBrightness', 'Enable', 'off');

            % File path names
            obj.h.panFilepn = uipanel('Units', 'pixels', 'Position', obj.stg.cPanFilepnPos);
            obj.h.tSignalpn = uicontrol('Parent', obj.h.panFilepn, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanFilepnPos(4)*2/3,...
                obj.stg.cPanFilepnPos(3)*2/10,...
                obj.stg.cPanFilepnPos(4)*1/3],...
                'String', 'Signal:',...
                'Tag', 'tSignalpn');
            obj.h.eSignalpn = uicontrol('Parent', obj.h.panFilepn, 'Style', 'edit', 'Units', 'pixels', 'HorizontalAlignment', 'left',...
                'Position', [...
                obj.stg.cPanFilepnPos(3)*2/10,...
                obj.stg.cPanFilepnPos(4)*2/3,...
                obj.stg.cPanFilepnPos(3)*8/10,...
                obj.stg.cPanFilepnPos(4)*1/3],...
                'String', 'Signal file path and name', 'Callback', @obj.cbEditpn,...
                'Tag', 'eSignalpn', 'Enable', 'on');
            obj.h.tVideopn = uicontrol('Parent', obj.h.panFilepn, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanFilepnPos(4)*1/3,...
                obj.stg.cPanFilepnPos(3)*2/10,...
                obj.stg.cPanFilepnPos(4)*1/3],...
                'String', 'Video:',...
                'Tag', 'tVideopn');
            obj.h.eVideopn = uicontrol('Parent', obj.h.panFilepn, 'Style', 'edit', 'Units', 'pixels', 'HorizontalAlignment', 'left',...
                'Position', [...
                obj.stg.cPanFilepnPos(3)*2/10,...
                obj.stg.cPanFilepnPos(4)*1/3,...
                obj.stg.cPanFilepnPos(3)*8/10,...
                obj.stg.cPanFilepnPos(4)*1/3],...
                'String', 'Video file path and name', 'Callback', @obj.cbEditpn,...
                'Tag', 'eVideopn', 'Enable', 'on');
            obj.h.tLabelpn = uicontrol('Parent', obj.h.panFilepn, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'right',...
                'Position', [...
                0,...
                obj.stg.cPanFilepnPos(4)*0/3,...
                obj.stg.cPanFilepnPos(3)*2/10,...
                obj.stg.cPanFilepnPos(4)*1/3],...
                'String', 'Label:',...
                'Tag', 'tLabelpn');
            obj.h.eLabelpn = uicontrol('Parent', obj.h.panFilepn, 'Style', 'edit', 'Units', 'pixels', 'HorizontalAlignment', 'left',...
                'Position', [...
                obj.stg.cPanFilepnPos(3)*2/10,...
                obj.stg.cPanFilepnPos(4)*0/3,...
                obj.stg.cPanFilepnPos(3)*8/10,...
                obj.stg.cPanFilepnPos(4)*1/3],...
                'String', 'Label file path and name', 'Callback', @obj.cbEditpn,...
                'Tag', 'eLabelpn', 'Enable', 'on');
            % % % %             jFig = get(obj.h.f, 'JavaFrame');
            % % % %             jAxis = jFig.getAxisComponent;
            % % % %             % Set the focus event callback
            % % % %             set(jAxis.getComponent(0), 'FocusLostCallback', @obj.cbFocusLost);
            obj.h.tSamplingFreq = uicontrol('Parent', obj.h.panFilepn, 'Style', 'text', 'Units', 'pixels', 'HorizontalAlignment', 'left',...
                'Position', [...
                0,...
                obj.stg.cPanFilepnPos(4)*2/3,...
                obj.stg.cPanFilepnPos(3)/10,...
                obj.stg.cPanFilepnPos(4)*1/3],...
                'String', 'Fs_max (Hz):',...
                'Tag', 'tSamplingFreq');
            % Add a display element below Fs.
            obj.h.eSamplingFreq = uicontrol('Parent', obj.h.panFilepn, 'Style', 'edit', 'Units', 'pixels', 'HorizontalAlignment', 'left', ...
                'Position', [...
                0, ...
                obj.stg.cPanFilepnPos(4)*1/3, ...
                obj.stg.cPanFilepnPos(3)/10, ...
                obj.stg.cPanFilepnPos(4)*1/3], ...
                'String', 'N/A', 'Callback', @obj.cbtextClicked,...
                'Tag', 'eSamplingFreq', ...
                'Enable', 'on');
            A = imread('pics/Donkey01.png');
            A = A((1 : 512) + round(rand)*512, (1 : 512) + round(rand)*512, :);
            ims = imshow(A);
            obj.h.haxIntro = ims.Parent;
            obj.h.haxIntro.Position = [0.25 0.05 0.5 0.5];
            drawnow
        end
        function delete(obj, ~, ~) % Not fully understand the difference between close, delete and clear. Most importantly, how to clear the object from memory upon closing the window?
            % Save current label
            if ~isempty(obj.labelObj) && obj.automaticLabelSaving % First save current label
                obj.labelObj = obj.labelObj.lblSave;
            end
            t = timerfindall;
            delete(t);
            delete(obj.h.f);
            clear c
        end
    end

    methods (Static)
        function filepn = getFilepn(prompt, multisel, pathTemplate, varargin)
            [loadpath, l, compName, typ] = controlWindow.getLoadpath(varargin);
            [fn, fp] = uigetfile([loadpath, pathTemplate], prompt, 'MultiSelect', multisel); % File names, file path
            if isa(fn, 'double')
                filepn = [];
                return
            end
            % If the user selected only one file, it is returned as a char array. Let's put it in a cell for consistency.
            if ~iscell(fn)
                filen{1} = fn;
            else
                filen = fn;
            end
            filen = sort(filen);
            % for kf = 1 : length(filen)
            %     r = regexp(filen{kf}, '\d\d\d\d\d\d_\d\d\d\d\d\d', 'match');
            %     dt(kf, :) = [datenum(r{1}, 'yymmdd_HHMMSS'), kf]; %#ok<DATNM>
            % end
            % dt = sortrows(dt);
            % fileOrder = int64(dt(:, 2));
            % filenSorted = filen(fileOrder)';
            filenSorted = filen; % Override sorting (may be useful when loading multiple mice)
            filep = fp;
            filepn = fullfile(filep, filenSorted);
            controlWindow.saveLoadpath(l, filep, compName, typ)
        end
        function [loadpath, l, compName, typ] = getLoadpath(vai)
            compName = getenv('computername');
            compName = erase(compName, '-');
            compName = erase(compName, '/');
            compName = erase(compName, '\');
            if ~isempty(vai)
                typ = vai{1};
            else
                typ = 'general';
            end
            if exist('loadpath.mat', 'file')
                l = load('loadpath.mat'); % Second argument: which variable from the file should be loaded
                if isfield(l, 'loadpathSpecial')
                    try
                        loadpath = l.loadpathSpecial.(compName).(typ);
                    catch
                        loadpath = l.loadpath;
                    end
                else
                    loadpath = l.loadpath;
                end
            else
                loadpath = '';
            end
        end
        function saveLoadpath(l, filep, compName, typ)
            l.loadpath = filep;
            l.loadpathSpecial.(compName).(typ) = filep;
            save('loadpath.mat', '-struct', 'l')
            lll = load('loadpath.mat');
            assignin('base', 'lll', lll);
        end
        function fileNumber = findCorrespondingFile(patternFilepn, filepn)
            % patternFilepn must be a char array
            % filepn must be a cell array of file paths and names to chose from
            [~, patternFilen, ~] = fileparts(patternFilepn);
            [~, filen, ~] = fileparts(filepn); % Get file name from file path and name
            fileNumber = find(contains(filen, patternFilen)); % Try to find the pattern in some of the filen
            if isempty(fileNumber) % If the exact match is not found, try to match date and time in the format yymmdd_HHMMSS
                dtSubs = regexpi(patternFilepn, '\d\d\d\d\d\d_\d\d\d\d\d\d'); % Date and time subscript
                dt = patternFilepn(dtSubs : dtSubs + 12);
                fileNumber = find(contains(filepn, dt));
                if length(fileNumber) > 1
                    warning(['_jk ', num2str(length(fileNumber)), ' files corresponding to ', patternFilepn, ' found.']);
                end
            end
        end
        function s = clearInvalidHandles(s)
            fn = fieldnames(s);
            for k = 1 : length(fn)
                if isstruct(s.(fn{k}))
                    s.(fn(k)) = clearInvalidHandles(s.(fn{k}));
                else
                    if ~isvalid(s.(fn{k}))
                        s = rmfield(s, fn{k});
                    end
                end
            end
        end
        function dateN = datenumFromWKJFilen(filen)
            ind = regexpi(filen, '\d\d\d\d\d\d_\d\d\d\d\d\d');
            dt = filen(ind : ind + 12);
            dateN = datenum(dt, 'yymmdd_HHMMSS'); %#ok<DATNM>
        end

    end
end




%% TO DO
%% Related to function
% Show signal info (most importantly Fs)
% Why does video stop when zooming? In video, whichFrame seems to be ok, definitely not higher than than the number of frames.
% Make colorful also the exported xlsx
% Filtering in the table? (Maybe sorting could be enough)
% What if the video is played at negative speed
% Hide now line on demand (add check box somewhere in control window)
% Resize function also for the signal pane
% Maybe each object should have its own currentFile
% Enable labeling even with closed label window
% Highlight selected labels in the signal window
% Rewrite the label windows using figure instead of uifigure. It might improve speed.
% N and B should implement not only jumping to next non-empty label file but also jumping to next label within a file.
% If the number of channels is different from the previous file, draw all channels.
% Fix write xlsx
% Fix zooming
% Rename nextNonEmptyLabelFile if needed (maybe just next label). Do the same with prevNonEmpty...
% Add duration to table of labels (Saly would find it useful).
% Allow change of class in the Label window. Might be useful e.g. when one has the class "Seizure" and wants to copy the data to the class "Racine".
% Can the label have some extra columns (e.g. seizure power computed during automatic detection)?
% Solve the double redrawing of the table of labels
% Write documentation
% Save label when using N and B
% Add "discard changes of current label"
% Changing vertical zoom individually
% Tying vertical zoom across channels
% Show Fs under the channel name
% Show the filter properties maybe as well
% Enable also 50 Hz filtering at the same place
% Changing cursor shape? Hand tool, resize tool, etc.
% Release Zoom Out after Ctrl+S
% Prevent now line from jumping back when video is stopped
% Video player freezes when signal is panned by mouse when it is being played
% Why is the now line shaking after panning the signal
% F keys to bring focus to edit fileds so that one can easily edit them. Use uicontrol(controlHandle)
% Enable pasting file names in the edit fields to jump to specific files
% Write documentation
% R does not work
% Zoom buttons do not work
% After adding a new label class, the main window goes up which hides the definitions window
% Next does not jump to the label only to the file
% Undo should work better
% XLSX of labels contains only time and not date
% Take the Comment string as the default string in the text box
% Improve spacing of the columns in the label table
% History of reviewed files? Probably labels might be enough.

%% Related to code cleanliness and readability
% Menu callback should call appropriate functions (possibly in appropriate classes) and not implement it directly

%% Solved
% SOLVED Buttons for finding next and previous non-empty label file
% SOLVED Enable changing brightness when video is stopped
% SOLVED Choose which channels to filter
% SOLVED Alt+click show also horizontal line and values
% SOLVED prevNonEmptyLabel does not close the waitbar
% SOLVED Signal filtering
% SOLVED Turn of keyboard shortcuts when typing into fields
% SOLVED Freezing vertical zoom (maybe some button for this)

%% Not solved because it would be too difficult and it would not pay off
% NOT NEEDED Intuitive color picking
% NOT NEEDED Make label set columns sortable and solve deleting in the sorted table
% NOT NEEDED Edit field for jumping to specific second in the file (Slider is probably enough)
