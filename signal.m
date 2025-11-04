classdef signal < handle
    properties
        filepn % Files' paths and names

        sigTbl % Table with loaded signals.       Subject        ChName       SigStart       SigEnd      Fs           Data       
        plotTbl % Table containing only signals which will be plotted
        bipolarTbl % Table containing bipolar montage of the channels (substracted Neighbouring channels from same region)
        sigLenS % Duration of the longest channel (normally, all channels should have the same duration)
        chToPlot % Double array. Which channels should be plotted.
        verticalZoom % Double
        measurePoints % 2x2 double
        
        previousCurrentPoint % Used for panning and zooming by mouse
        zoomPoints
        
        fltUserSpecs % User-defined filter specifications
        fltUserTF % User-defined filter
        flt50HzTF % Should we filter 50 Hz hum?
        avgRefTF % Should we compute average refernce montage?
        bipolarTF % Do we compute bipolar montage on neighbouring channels?
        no_bipolar % Used for ending bipolar montage
        avgRefChannelNames
        whichChToFilter % Which channels should be filtered by the user filter

        bipolarTblTF % whether the plotTbl was created outside the plot function or not
        
        stg % Settings created by stgs function
        key % Table of keyboard shortcuts created by keyShortTbl function
        h % Handles to graphic objects
        
        controlObj % controlWindow object stored here
    end
    
    methods
        function obj = signal(ctrObj, fpn) % controlObj passes filepn to the constructor in the fpn
            obj.filepn = fpn;
            obj.controlObj = ctrObj;
            obj.stg = stgs;
            obj.key = keyShortTbl;
            obj = obj.makeFigure(ctrObj);
            obj.verticalZoom = 1;
            % User bandpass filter initial specifications
            obj.fltUserSpecs.ApplyAll = false;
            obj.fltUserSpecs.N = 3;
            obj.fltUserSpecs.F1 = 3;
            obj.fltUserSpecs.F2 = 90;
            obj.flt50HzTF = false;
            obj.avgRefTF = false;
            obj.bipolarTF = false;
            % % % % obj.no_bipolar = false;
            obj.fltUserTF = true; % There used to be an option in the Signal menu to turn the filter on or off. Now it is done by text below ChName.
            obj.whichChToFilter = [];
            % % % % obj.bipolarTblTF = false;
        end

        function obj = fileUpdate(obj)
            if ~isempty(obj.sigTbl)
                chnmOld = obj.sigTbl.ChName;
            else
                chnmOld = "";
            end
            figure(obj.h.f)
            delete(obj.h.panChNm.Children); delete(obj.h.panSig.Children); delete(obj.h.panTime.Children);
            obj.sigTbl = loadSignal(obj.filepn{obj.controlObj.currentFile});
            obj.sigLenS = datenum(max(obj.sigTbl.SigEnd) - min(obj.sigTbl.SigStart))*3600*24;
            obj.controlObj.plotLimS(2) = min(obj.controlObj.plotLimS(2), obj.sigLenS);
            if obj.controlObj.showWholeFile
                obj.controlObj.plotLimS(1) = 0;
                obj.controlObj.plotLimS(2) = obj.sigLenS;
            end
     
            if length(chnmOld) ~= size(obj.sigTbl, 1)
                obj.chToPlot = 1 : size(obj.sigTbl, 1);
            else
                if any(chnmOld ~= obj.sigTbl.ChName)
                    obj.chToPlot = 1 : size(obj.sigTbl, 1);
                end
            end
            obj = obj.plotSignal;
        end

        %% Plotting
        function obj = plotSignal(obj)
            delete(obj.h.panChNm.Children); delete(obj.h.panSig.Children); delete(obj.h.panTime.Children);
            figure(obj.h.f)
            if isempty(obj.chToPlot)
%                 obj.chToPlot = obj.sigTbl.ChName;
                obj.chToPlot = 1 : size(obj.sigTbl, 1);
            end
%             obj.plotTbl = obj.sigTbl(ismember(obj.sigTbl.ChName, obj.chToPlot), :);
            obj.plotTbl = obj.sigTbl(obj.chToPlot, :);

            if ~obj.bipolarTF
                obj.plotTbl = obj.sigTbl(obj.chToPlot, :);
            else
                obj = applyBipolar(obj);
                % % % obj.plotTbl = obj.bipolarTbl(obj.chToPlot, :);
            end



            numch = size(obj.plotTbl, 1);
            if numel(obj.whichChToFilter) ~= numch
                obj.whichChToFilter = false(numch, 1);
            end
            fltAllString = 'FltAllChn OFF';
            % Plot channel names
            for k = 1 : numch
                obj.h.axChNm(k) = axes('Parent', obj.h.panChNm, 'Position', [0, (numch - k)/numch, 1, 1/numch],...
                    'XLimMode', 'manual', 'XLim', [-0.1 1], 'YLimMode', 'manual', 'YLim', [-1 1], 'Visible', 'off');
                text(0, 0.2, obj.plotTbl.ChName(k), 'VerticalAlignment', 'middle', 'Interpreter', 'none');
                if obj.whichChToFilter(k)
                    fltString = 'Filter ON';
                    bkgClr = [0.6 1 0.6];
                else
                    fltString = 'Filter OFF';
                    bkgClr = [1 0.6 0.6];
                end
                if sum(obj.whichChToFilter) == numch
                    fltAllString = 'FltAllChn ON';
                    bkgClrAll =  [0.6 1 0.6];
                else
                    fltAllString = 'FltAllChn OFF';
                    bkgClrAll = [1 0.6 0.6];
                end
                if k ==1
                
                obj.h.fltEnDis(k) = text(0,-0.8, fltString, 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'BackgroundColor', bkgClr,...
                    'ButtonDownFcn', @obj.usrFltOnOff, 'Tag', ['fltEnDis', num2str(k)],'FontSize',8);
                obj.h.fltEnAllDis(k) = text(0,0.8, fltAllString, 'VerticalAlignment', 'top', 'Interpreter', 'none', 'BackgroundColor', bkgClrAll,...
                    'ButtonDownFcn', @obj.usrFltOnOff, 'Tag', ['fltEnDis', num2str(k-1)]','FontSize',8);
                else
                    obj.h.fltEnDis(k) = text(0,-0.8, fltString, 'VerticalAlignment', 'middle', 'Interpreter', 'none', 'BackgroundColor', bkgClr,...
                    'ButtonDownFcn', @obj.usrFltOnOff, 'Tag', ['fltEnDis', num2str(k)],'FontSize',8);
                end
            end
            
            % Filtering
            if obj.flt50HzTF
                for kch = 1 : size(obj.plotTbl, 1)
                    notchFr = 50;
                    stopFr = notchFr : notchFr : min(obj.plotTbl.Fs(kch) - 1, 200); % Minus 1 hertz so that we don't filetr at Fs/2 which would be useless
                    stopFrNorm = stopFr/obj.plotTbl.Fs(kch);
                    
                    % Zeros
                    zrRe = cos(stopFrNorm*pi);
                    zrRe = [zrRe, fliplr(zrRe)];
                    zrIm = sin(stopFrNorm*pi);
                    zrIm = [zrIm, -fliplr(zrIm)];
                    zr = zrRe + 1i*zrIm;
                    
                    % Poles
                    r = linspace(0.998, 0.998, size(stopFr, 2));
                    plRe = r.*cos(stopFrNorm*pi);
                    plRe = [plRe, fliplr(plRe)];
                    plIm = r.*sin(stopFrNorm*pi);
                    plIm = [plIm, -fliplr(plIm)];
                    pl = plRe + 1i*plIm;
                    % Coefficients
                    num = poly(zr);
                    den = poly(pl);
                    
                    obj.plotTbl.Data{kch} = single(filtfilt(num, den, double(obj.plotTbl.Data{kch})));
                    
                    clear zrRe zrIm plRe plIm zr pl num den
                end
            end
            
            
            if obj.fltUserTF
                if obj.fltUserSpecs.ApplyAll
                    obj.whichChToFilter(:)= true;
                    fltString = 'Filter ON';
                    bkgClr = [0.6 1 0.6];
                    obj.h.fltEnAllDis.String = 'FltAllChn ON';
                    obj.h.fltEnAllDis.BackgroundColor = bkgClr;
                    % obj.plotSignal;
                    for kch = 1 : size(obj.plotTbl, 1)
                        obj.h.fltEnDis(kch).String = fltString;
                        obj.h.fltEnDis(kch).BackgroundColor = bkgClr;
                        [num, den] = butter(obj.fltUserSpecs.N, [obj.fltUserSpecs.F1, obj.fltUserSpecs.F2]/(obj.plotTbl.Fs(kch)/2));
                        obj.plotTbl.Data{kch} = single(filtfilt(num, den, double(obj.plotTbl.Data{kch})));
                        clear num den
                    end
                else
                    for kch = 1 : size(obj.plotTbl, 1)
                        if contains(obj.h.fltEnDis(kch).String, 'ON')
                            [num, den] = butter(obj.fltUserSpecs.N, [obj.fltUserSpecs.F1, obj.fltUserSpecs.F2]/(obj.plotTbl.Fs(kch)/2));
                            obj.plotTbl.Data{kch} = single(filtfilt(num, den, double(obj.plotTbl.Data{kch})));
                            clear num den
                        end
                    end
                end
            end
            

            if obj.avgRefTF
               selectedData = {};
               for kcbx = 1:numel(obj.avgRefChannelNames)
                    chName = obj.avgRefChannelNames(kcbx);
                    chIdx = find(strcmp(obj.plotTbl.ChName, chName));
                    if ~isempty(chIdx)
                        selectedData{end+1,1} = obj.plotTbl.Data{chIdx};
                    end
                end
                averageSignal = mean(cell2mat(selectedData),1);
                obj.plotTbl.Data =  cellfun(@(x) x - averageSignal, obj.plotTbl.Data, 'UniformOutput', false);
                disp(['Applied saved average reference channels: ', strjoin(obj.avgRefChannelNames, ', ')]);
            end

            

            % Plot signal and Now line
            obj.h.axSig = gobjects(numch, 1);
            for k = 1 : numch
                % Create axes
                obj.h.axSig(k) = axes('Parent', obj.h.panSig, 'Position', [0, (numch - k)/numch, 1, 1/numch],...
                    'XLimMode', 'manual', 'YLimMode', 'manual',...
                    'Visible', 'off', 'Clipping', 'off',...
                    'PickableParts', 'all',...
                    'Tag', ['axSig', num2str(k)]);
                if isnan(obj.plotTbl.Data{k})
                    yl = [-1 1];
                    rng = 2;
                else
                    rng = max(obj.plotTbl.Data{k}(1, :)) - min(obj.plotTbl.Data{k}(1, :));
                    if rng == 0
                        rng = 2;
                    end
                    yl = [min(obj.plotTbl.Data{k}(1, :)) - 0.01*rng, max(obj.plotTbl.Data{k}(1, :)) + 0.01*rng];
                end
                obj.h.axSig(k).YLim = yl;
                obj.h.axSig(k).Units = 'pixels';
                obj.h.axSig(k).Position(3) = obj.h.axSig(k).Position(3) - 50;
                obj.h.axSig(k).Position(1) = 50;
%                 obj.h.axSig(k).Position(2) = obj.h.axSig(k).Position(2) + 5;
%                 obj.h.axSig(k).Position(4) = obj.h.axSig(k).Position(4) -10;
                obj.h.axSig(k).Position(2) = obj.h.axSig(k).Position(2);
                obj.h.axSig(k).Position(4) = obj.h.axSig(k).Position(4);
                obj.h.axSig(k).YRuler.Visible = 'on';
                obj.h.axSig(k).Units = 'Normalized';
                % Plot signal
                x = obj.controlObj.plotLimS(1) : 1/obj.plotTbl.Fs(k) : obj.controlObj.plotLimS(2) - 1/obj.plotTbl.Fs(k);
                limOverrun = int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k) + length(x)) - int64(length(obj.plotTbl.Data{k}));
                if limOverrun > 0
                    y = obj.plotTbl.Data{k}(1, int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k)) + 1 : int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k) + length(x) - limOverrun));
                    y = [y, NaN(1, limOverrun)]; %#ok<AGROW>
                else
                    y = obj.plotTbl.Data{k}(1, int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k)) + 1 : int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k) + length(x)));
                end
                obj.h.l(k) = line(x, y, 'Color', 'k', 'HitTest', 'off');
                obj.h.axSig(k).XLim = [min(x), max(x)];
                dc = mean(obj.h.l(k).YData, 'omitnan');
                if obj.controlObj.linkVerticalZoom
                    newyl = [-1/obj.verticalZoom, 1/obj.verticalZoom] + dc;
                else
                    newyl = [min(obj.h.l(k).YData) - dc - 0.01*rng, max(obj.h.l(k).YData) - dc + 0.01*rng]/obj.verticalZoom + dc;
                end
                if ~isnan(newyl)
                    obj.h.axSig(k).YLim = newyl;
                end
                % Plot now line
                obj.h.lNow(k) = line([obj.controlObj.nowS, obj.controlObj.nowS],...
                        mean(obj.h.axSig(k).YLim) + (obj.h.axSig(k).YLim - mean(obj.h.axSig(k).YLim))*1.2, 'ZData', [100 100],...
                        'Color', obj.stg.sNowColor, 'AlignVertexCenters', 'on', 'LineJoin', 'chamfer', 'ButtonDownFcn', @obj.cbNow, 'LineWidth', 1.5, 'LineStyle', '--', 'Tag', 'now');
            end
            if ~isempty(obj.controlObj.labelObj)
                obj.controlObj.labelObj.setSignalAxesCallback;
            end
            % Hide cursor if there is no video
            obj.h.lNow(~ishandle(obj.h.lNow)) = [];
            if isempty(obj.controlObj.videoObj)
                [obj.h.lNow.Visible] = deal('off');
            end
            
            % Plot time ticks
            obj.h.axTime = axes('Parent', obj.h.panTime, 'Position', [0, 0.9, 1, 1/numch],...
                    'XLimMode', 'manual', 'YLimMode', 'manual', 'YLim', [-1 1], 'Visible', 'on', 'TickDir', 'out');
            obj.h.axTime.YRuler.Visible = 'off';
            obj.h.axTime.Units = 'pixels';
            obj.h.axTime.Position(3) = obj.h.axTime.Position(3) - 50;
            obj.h.axTime.Position(1) = 50;
            obj.h.axTime.Units = 'Normalized';
            
            % Dummy plot to get the ticks
            x = obj.controlObj.plotLimS(1) : 1/obj.plotTbl.Fs(1) : obj.controlObj.plotLimS(2) - 1/obj.plotTbl.Fs(1);
            y = NaN(size(x));
            obj.h.ltime = line(x, y);
            obj.h.axTime.XLim = [min(x), max(x)];
            obj.h.axTime.TickLabelInterpreter = 'tex';
            xlb = num2str(obj.h.axTime.XTick');
            row1 = mat2cell(xlb, ones(1, size(xlb, 1)), size(xlb, 2))';
            row1 = pad(row1, 7, 'left');
            dts = datestr(min(obj.sigTbl.SigStart) + obj.h.axTime.XTick/24/3600); % Dates in matrix
            for kd = 1 : size(dts, 1)
                row2{kd} = dts(kd, end-7 : end); %#ok<AGROW>
            end
            labelArray = [row1; row2];
            tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
            obj.h.axTime.XTickLabel = [];
            obj.h.axTime.XTickLabel = tickLabels;
            
            % Slider
            obj.h.panTime.Units = 'pixels';
            obj.h.slider = uicontrol('Style', 'slider', 'Parent', obj.h.panTime, 'Position', [50, 0, obj.h.panTime.Position(3) - 50, 15],...
                'Callback', @obj.cbSlider);
            obj.h.panTime.Units = 'normalized';
            
            % Slider
            slidSz = 1/(max(obj.sigLenS/obj.controlObj.plotLenS, 1.0001) - 1);
            obj.h.slider.Max = obj.sigLenS - obj.controlObj.plotLenS;
            obj.h.slider.SliderStep = [min(slidSz/10, 1), slidSz];
            obj.h.slider.Value = obj.controlObj.plotLimS(1)*0.999999;
            obj.h.slider.Units = 'normalized';
        end
        function obj = sigUpdate(obj)
            numch = size(obj.plotTbl, 1);
            % Plot signal
            obj.controlObj.plotLimS = sort(obj.controlObj.plotLimS);
            for k = 1 : numch
                x = obj.controlObj.plotLimS(1) : 1/obj.plotTbl.Fs(k) : obj.controlObj.plotLimS(2) - 1/obj.plotTbl.Fs(k);
                limOverrun = int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k) + length(x)) - int64(length(obj.plotTbl.Data{k}));
                if limOverrun > 0
                    y = obj.plotTbl.Data{k}(1, int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k)) + 1 : int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k) + length(x) - limOverrun));
                    y = [y, NaN(1, limOverrun)]; %#ok<AGROW>
                else
                    y = obj.plotTbl.Data{k}(1, int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k)) + 1 : int64(obj.controlObj.plotLimS(1)*obj.plotTbl.Fs(k) + length(x)));
                end
                obj.h.l(k).XData = x;
                obj.h.l(k).YData = y;
                obj.h.axSig(k).XLim = [min(x), max(x)];
            end
            % Plot time ticks
            x = obj.controlObj.plotLimS(1) : 1/obj.plotTbl.Fs(1) : obj.controlObj.plotLimS(2) - 1/obj.plotTbl.Fs(1);
            y = NaN(size(x));
            obj.h.ltime.XData = x;
            obj.h.ltime.YData = y;
            obj.h.axTime.XLim = [min(x), max(x)];
            xlb = num2str(obj.h.axTime.XTick');
            row1 = mat2cell(xlb, ones(1, size(xlb, 1)), size(xlb, 2))';
            row1 = pad(row1, 7, 'left');
            dts = datestr(min(obj.sigTbl.SigStart) + obj.h.axTime.XTick/24/3600); % Dates in matrix
            for kd = 1 : size(dts, 1)
                row2{kd} = dts(kd, end-7 : end); %#ok<AGROW>
            end
            labelArray = [row1; row2];
            tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
            obj.h.axTime.XTickLabel = [];
            obj.h.axTime.XTickLabel = tickLabels;
            
            % Slider change
            slidSz = 1/(max(obj.sigLenS/obj.controlObj.plotLenS, 1.0001) - 1);
            obj.h.slider.Max = obj.sigLenS - obj.controlObj.plotLenS;
            obj.h.slider.SliderStep = [min(slidSz/10, 1), slidSz];
            obj.h.slider.Value = obj.controlObj.plotLimS(1)*0.999999;
            
            %  Label update
            if ~isempty(obj.controlObj.labelObj)
                obj.lblUpdate;
            end
        end
        function obj = nowUpdate(obj)
            numch = size(obj.plotTbl, 1);
            % Plot signal
            for k = 1 : numch
                obj.h.lNow(k).XData = [obj.controlObj.nowS, obj.controlObj.nowS];
            end
            if isa(obj.h.f.CurrentObject, 'matlab.graphics.GraphicsPlaceholder')
                return
            end
            if strcmp(obj.controlObj.tmr.Running, 'on')
                return
            end
            if ~contains(obj.h.f.CurrentObject.Tag, 'lbl')
                if isempty(obj.controlObj.videoObj)
                    [obj.h.lNow.Visible] = deal('off');
                else
                    [obj.h.lNow.Visible] = deal('on');
                end
            end
        end
        
        function obj = customAverageRefDialog(obj)   % Function for calculating average reference
            if obj.avgRefTF 
                disp('Average Reference Mode is ON!!')
                % Creates new dialog window
                dialogAveRef = dialog('Position', [300, 300, 300, 50 + 30 * numel(obj.sigTbl.ChName)], 'Name','Average Reference Settings');
                % Default Values
                checkboxes = gobjects(numel(obj.sigTbl.ChName), 1);
                for kchbx = 1:numel(obj.sigTbl.ChName)
                    checkboxes(kchbx) = uicontrol('Parent', dialogAveRef, ...
                        'Style', 'checkbox', ...
                        'Position', [50, 50 + (numel(obj.sigTbl.ChName) - kchbx) * 30, 200, 30], ...
                        'String', obj.sigTbl.ChName{kchbx}, ...
                        'Value', ismember(obj.sigTbl.ChName{kchbx}, obj.sigTbl.ChName(obj.chToPlot)));
                    avgRefChannelNames(kchbx) = ismember(obj.sigTbl.ChName{kchbx}, obj.sigTbl.ChName(obj.chToPlot));
                end
               % "All" button
                uicontrol('Parent', dialogAveRef, ...
                    'Position', [50, 10, 50, 30], ...
                    'String', 'All', ...
                    'Callback', @(src, event) set(checkboxes, 'Value', 1));
                % "None" button
                uicontrol('Parent', dialogAveRef, ...
                    'Position', [100, 10, 50, 30], ...
                    'String', 'None', ...
                    'Callback', @(src, event) set(checkboxes, 'Value', 0));
                % OK button
                btnOK = uicontrol('Parent',dialogAveRef, 'Position',[150,10,50,30], ...
                    'String','OK', 'Callback',@okCallback);
                % Cancel button
                btnCancel = uicontrol('Parent',dialogAveRef, 'Position',[200,10,50,30], ...
                    'String','Cancel', 'Callback',@cancelCallback);
                % wait till user closes window
                uiwait(dialogAveRef);
               else
                avgRefChannelNames = [];
                disp('Average Reference Mode is OFF!!')
                obj.plotTbl.Data = obj.sigTbl.Data(obj.chToPlot);
                obj.sigUpdate;
            end
            
            % If OK button pushed
            function avgRefChannelNames = okCallback(~,~)
                selectedChannels = {};
                selectedData = {};
                for kcbx = 1:numel(checkboxes)
                    if checkboxes(kcbx).Value
                        selectedChannels{end+1} = obj.sigTbl.ChName{kcbx};
                        selectedData{end+1,1} = obj.plotTbl.Data{obj.plotTbl.ChName ==selectedChannels{end}};
                    end
                end
                obj.avgRefChannelNames = selectedChannels;
                averageSignal = mean(cell2mat(selectedData),1);
                obj.plotTbl.Data =  cellfun(@(x) x - averageSignal, obj.plotTbl.Data, 'UniformOutput', false);
                disp (['User selected channels for average refrence calculation:',strjoin(selectedChannels, ', ')])
                obj.sigUpdate;
                close(dialogAveRef);  % close windows
            end

            % If Cancel button pushed
            function cancelCallback(~,~)
                delete(dialogAveRef); % close windows
            end
            

        end
        %% Zoom
        function obj = horizontalZoomIn(obj)
            obj.controlObj.horizontalZoomIn;
        end
        function obj = horizontalZoomOut(obj)
            obj.controlObj.horizontalZoomOut;
        end
        function obj = verticalZoomIn(obj)
            obj.verticalZoom = obj.verticalZoom*obj.stg.sVertZoomStep;
            figure(obj.h.f)
            for k = 1 : length(obj.h.axSig)
                dc = mean(obj.h.l(k).YData, 'omitnan');
                rng = max(obj.plotTbl.Data{k}(1, :)) - min(obj.plotTbl.Data{k}(1, :));
                if rng == 0
                    rng = 1;
                end
                if obj.controlObj.linkVerticalZoom
                    newyl = [-1/obj.verticalZoom, 1/obj.verticalZoom] + dc;
                else
                    newyl = [(dc + min(obj.h.l(k).YData)), (dc + max(obj.h.l(k).YData))]/obj.verticalZoom + dc;
                end
                % newyl = [(dc + min(obj.h.l(k).YData)) - 0.01*rng, (dc + max(obj.h.l(k).YData))]/obj.verticalZoom + dc - 0.01*rng;
                if any(isnan(newyl))
                    newyl = [-1 1];
                    dc = 0;
                end
                if diff(newyl) == 0 % Sometimes the signal is constant and then newyl has two times the same value which causes YLim to crash.
                    newyl = newyl + [-1 1];
                end
                obj.h.axSig(k).YLim = newyl + dc - mean(newyl);
                obj.h.lNow(k).YData = mean(obj.h.axSig(k).YLim) + (obj.h.axSig(k).YLim - mean(obj.h.axSig(k).YLim))*1.2;
            end
            obj.lblVerticalZoom;
        end
        function obj = verticalZoomOut(obj)
            obj.verticalZoom = obj.verticalZoom/obj.stg.sVertZoomStep;
            figure(obj.h.f)
            for k = 1 : length(obj.h.axSig)
                dc = mean(obj.h.l(k).YData, 'omitnan');
                if obj.controlObj.linkVerticalZoom
                    newyl = [-1/obj.verticalZoom, 1/obj.verticalZoom] + dc;
                else
                    newyl = [(dc + min(obj.h.l(k).YData)), (dc + max(obj.h.l(k).YData))]/obj.verticalZoom + dc;
                end
                % newyl = [(dc + min(obj.h.l(k).YData)), (dc + max(obj.h.l(k).YData))]/obj.verticalZoom + dc;
                if any(isnan(newyl))
                    newyl = [-1 1];
                    dc = 0;
                end
                if diff(newyl) == 0 % Sometimes the signal is constant and then newyl has two times the same value which causes YLim to crash.
                    newyl = newyl + [-1 1];
                end
                obj.h.axSig(k).YLim = newyl + dc - mean(newyl);
                obj.h.lNow(k).YData = mean(obj.h.axSig(k).YLim) + (obj.h.axSig(k).YLim - mean(obj.h.axSig(k).YLim))*1.2;
            end
            obj.lblVerticalZoom;
        end
        function obj = lblVerticalZoom(obj)
            fn = {'lblLA', 'lblLS', 'lblLE','lblPa'}; % Field names (names of handles to various graphical objects such as lines and patches)
            for kf = 1 : length(fn)
                if isfield(obj.h, fn{kf})
                    for k = 1 : length(obj.h.(fn{kf}))
                        o = obj.h.(fn{kf})(k);
                        if isa(o, 'matlab.graphics.GraphicsPlaceholder')
                            continue
                        end
                        if isvalid(o)
                            o.YData = repelem(o.Parent.YLim, length(o.YData)/2);
                        end
                    end
                end
            end
        end
        
        %% Mouse zoom
        function obj = mouseZoomInDn(obj, src, ctrObj, direction) % src should be signal figure, i.e. should be equal to obj.h.f (but I did not check it)
            obj.zoomPoints(1) = src.CurrentObject.CurrentPoint(1);
            obj.zoomPoints(2) = src.CurrentObject.CurrentPoint(1);
            numch = size(obj.plotTbl, 1);
            switch direction
                case 'in'
                    col = obj.stg.sZoomInColor;
                case 'out'
                    col = obj.stg.sZoomOutColor;
            end
            for k = 1 : numch
                obj.h.pZoom(k) = patch(obj.h.axSig(k),...
                        [obj.zoomPoints(1), obj.zoomPoints(2), obj.zoomPoints(2), obj.zoomPoints(1)],...
                        repelem(mean(obj.h.axSig(k).YLim) + (obj.h.axSig(k).YLim - mean(obj.h.axSig(k).YLim))*1, 2),...
                        col, 'AlignVertexCenters', 'on', 'ZData', -200*[1 1 1 1], 'EdgeColor', col);
            end
            obj.h.f.WindowButtonMotionFcn = @ctrObj.cbSigZoomButtMotion;
            obj.h.f.WindowButtonUpFcn = {@ctrObj.cbSigZoomButtUp, direction};
        end
        function obj = mouseZoomInMotion(obj, src)
            obj.zoomPoints(2) = src.CurrentObject.CurrentPoint(1);
            numch = size(obj.plotTbl, 1);
            for k = 1 : numch
                obj.h.pZoom(k).XData = [obj.zoomPoints(1), obj.zoomPoints(2), obj.zoomPoints(2), obj.zoomPoints(1)];
            end
        end
        function obj = mouseZoomInUp(obj, ~, direction)
            delete(obj.h.pZoom); obj.h = rmfield(obj.h, 'pZoom');
            switch direction
                case 'in'
                    obj.controlObj.mouseZoomFinished(sort(obj.zoomPoints));
                case 'out'
                    a = obj.controlObj.plotLimS(1); b = obj.controlObj.plotLimS(2); % Current limits (should project into the user dragged zoomPoints)
                    e = obj.zoomPoints(1); f = obj.zoomPoints(2);
                    x = (a^2 - a*b - a*f + e*b)/(e - f); % With the help of Wolfram Alpha O:-) (e-a)/(b-a)=(a-x)/(y-x);(f-a)/(b-a)=(b-x)/(y-x)
                    y = (a*b - a*f - b^2 + e*b)/(e - f);
                    obj.controlObj.mouseZoomFinished(sort([x, y]));
            end
        end
        function obj = mouseZoomEscape(obj)
            delete(obj.h.pZoom); obj.h = rmfield(obj.h, 'pZoom');
            obj.controlObj.mouseZoomEscapeFinished;
        end
        
        %% Mouse measure
        function obj = mouseMeasureDn(obj, src, ctrObj) % src should be signal figure, i.e. should be equal to obj.h.f (but I did not check it)
            obj.measurePoints(1, [1, 2]) = src.CurrentObject.CurrentPoint(1, [1, 2]);
            obj.measurePoints(2, [1, 2]) = src.CurrentObject.CurrentPoint(1, [1, 2]);
            numch = size(obj.plotTbl, 1);
            for k = 1 : numch
                obj.h.lMeas(k) = line(obj.h.axSig(k),...
                        [obj.measurePoints(1), obj.measurePoints(1)],...
                        mean(obj.h.axSig(k).YLim) + (obj.h.axSig(k).YLim - mean(obj.h.axSig(k).YLim))*1,...
                        'AlignVertexCenters', 'off', 'ZData', 200*[1 1], 'Color', obj.stg.sMeasureColor);
            end
            hold on
            obj.h.lMeas(end + 1) = line(src.CurrentObject, src.CurrentObject.XLim, [obj.measurePoints(3) obj.measurePoints(3)], 'Color', obj.stg.sMeasureColor);
            te = ['a=', num2str(obj.measurePoints(3), '%4.1f'), 10,...
                  't=', num2str(obj.measurePoints(1), '%04.1f')];
            obj.h.tMeas = text(obj.measurePoints(1, 1) - double(diff(src.CurrentObject.XLim)/200), obj.measurePoints(1, 2) - double(diff(src.CurrentObject.YLim)/40), te,...
                'HorizontalAlignment', 'right', 'VerticalAlignment', 'top',...
                'BackgroundColor', 'w');

            obj.h.f.WindowButtonMotionFcn = @ctrObj.cbSigMeasureButtMotion;
            obj.h.f.WindowButtonUpFcn = {@ctrObj.cbSigMeasureButtUp};
        end
        function obj = mouseMeasureMotion(obj, src)
            obj.measurePoints(2, [1, 2]) = src.CurrentObject.CurrentPoint(1, [1, 2]);
            if isfield(obj.h, 'lMeas')
                delete(obj.h.lMeas)
                delete(obj.h.tMeas)
                obj.h = rmfield(obj.h, 'lMeas');
            end
            if ~isfield(obj.h, 'pMeas')
                obj.h.pMeas = patch([obj.measurePoints([1 2], 1)', obj.measurePoints([2 1], 1)'],...
                    repelem(obj.measurePoints([1 2], 2)', 2),...
                    'b', 'FaceColor', 'none', 'EdgeColor', obj.stg.sMeasureColor, 'Parent', src.CurrentObject);
                te = ['A=', num2str(diff(obj.measurePoints(:, 2)), '%04.8f'), 10,...
                      'T=', num2str(diff(obj.measurePoints(:, 1)), '%04.8f'), 10,...
                      'f=', num2str(1/diff(obj.measurePoints(:, 1)), '%04.8f')];
                obj.h.tMeas = text(obj.measurePoints(1, 1) - diff(obj.h.axSig(1).XLim/200)   , obj.measurePoints(1, 2), te,...
                    'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom',...
                    'BackgroundColor', 'w');
            else
                obj.h.pMeas.XData = [obj.measurePoints([1 2], 1)', obj.measurePoints([2 1], 1)'];
                obj.h.pMeas.YData = repelem(obj.measurePoints([1 2], 2)', 2);
                te = ['A=', num2str(diff(obj.measurePoints(:, 2)), '%0-4.2f'), 10,...
                      'T=', num2str(diff(obj.measurePoints(:, 1)), '%0-4.3f'), 10,...
                      'f=', num2str(1/diff(obj.measurePoints(:, 1)), '%0-4.2f')];
                obj.h.tMeas.String = te;
            end
        end
        function obj = mouseMeasureUp(obj, ~)
            if isfield(obj.h, 'lMeas')
                delete(obj.h.lMeas)
                obj.h = rmfield(obj.h, 'lMeas');
            end
            if isfield(obj.h, 'pMeas')
                delete(obj.h.pMeas);
                drawnow
                obj.h = rmfield(obj.h, 'pMeas');
            end
            if isfield(obj.h, 'tMeas')
                delete(obj.h.tMeas);
                drawnow
                obj.h = rmfield(obj.h, 'tMeas');
            end
        end
        
        %% Channel selection
        function obj = channels(obj)
            % Create uifigure
            obj.h.channels = uifigure('Position',obj.stg.sChannelsFigPos , 'Name', 'Channels', 'Tag', 'channels'); % Does not work with figure
            movegui(obj.h.channels,'center');
            % Check for the 'Show' column and add if necessary (same as before)
            if ~any(strcmp(obj.sigTbl.Properties.VariableNames, 'Show')) || ~any(strcmp(obj.sigTbl.Properties.VariableNames, 'Order'))
                Show = true(size(obj.sigTbl, 1), 1); % Default to true (show all channels)
                Order = (1:size(obj.sigTbl,1))'; % Default order: 1, 2, 3, ... % Add an 'Order' column to the data table
                ChnNum = (1:size(obj.sigTbl,1))';
                data = [obj.sigTbl(:, 1 : end), table(Show), table(Order), table(ChnNum)];
            else
                data = obj.sigTbl(:, 1 : end);
            end

            % Set up editable columns (only 'Show' and 'Order' column is editable)
            editable = false(1, size(data, 2));
            editable(:, strcmp(data.Properties.VariableNames, 'Show')) = true;
            editable(:, strcmp(data.Properties.VariableNames, 'Order')) = true;
            
            % Create the table in the UIfigure
            obj.h.uitChannels = uitable(obj.h.channels, 'Data', data, 'ColumnSortable', false, 'ColumnEditable', editable,...
                'Position', [20, 80, obj.stg.sChannelsFigPos(3) - 40, obj.stg.sChannelsFigPos(4) - 100], 'Tag', 'uitChannel'); % Use the class method as the callback
            sAlign = uistyle("HorizontalAlignment","center");
            addStyle(obj.h.uitChannels,sAlign,"column",[10,9,8])

            % Add buttons on the UItable
            obj.h.butt(1) = uibutton(obj.h.channels, 'push', 'Position', [20 + obj.stg.sChannelsFigPos(3)/2 - 40 - 360, 20, 80, 30],...
                'Text', 'Apply', 'ButtonPushedFcn', @obj.cbUicontrol, 'Tag', 'channelsApply'); % The callback function knows which button was pressed from the Tag
            obj.h.butt(2) = uibutton(obj.h.channels, 'push', 'Position', [20 + obj.stg.sChannelsFigPos(3)/2 - 40 - 260, 20, 80, 30],...
                'Text', 'OK', 'ButtonPushedFcn', @obj.cbUicontrol, 'Tag', 'channelsOK'); % The callback function knows which button was pressed from the Tag
            obj.h.butt(3) = uibutton(obj.h.channels, 'push', 'Position', [20 + obj.stg.sChannelsFigPos(3)/2 - 40 - 160, 20, 80, 30],...
                'Text', 'Cancel', 'ButtonPushedFcn', @obj.cbUicontrol, 'Tag', 'channelsCancel'); % The callback function knows which button was pressed from the Tag
            obj.h.butt(4) = uibutton(obj.h.channels, 'push', 'Position', [20 + obj.stg.sChannelsFigPos(3) - 330, 20, 50, 30],...
                'Text', 'All', 'ButtonPushedFcn', @obj.cbUicontrol, 'Tag', 'channelsAll'); % The callback function knows which button was pressed from the Tag
            obj.h.butt(5) = uibutton(obj.h.channels, 'push', 'Position', [20 + obj.stg.sChannelsFigPos(3) - 270, 20, 50, 30],...
                'Text', 'None', 'ButtonPushedFcn', @obj.cbUicontrol, 'Tag', 'channelsNone'); % The callback function knows which button was pressed from the Tag
            obj.h.butt(6) = uibutton(obj.h.channels, 'push', 'Position', [20 + obj.stg.sChannelsFigPos(3) - 210, 20, 80, 30],...
                'Text', 'Save Order', 'ButtonPushedFcn', @obj.cbUicontrol, 'Tag', 'channelsSaveOrder');  % The callback function knows which button was pressed from the Tag
            obj.h.butt(7) = uibutton(obj.h.channels, 'push', 'Position', [20 + obj.stg.sChannelsFigPos(3) - 120, 20, 80, 30],...
                'Text', 'Load Order', 'ButtonPushedFcn', @obj.cbUicontrol, 'Tag', 'channelsLoadOrder');  % The callback function knows which button was pressed from the Tag
        end
        
        function obj = channelsApply(obj)
            obj.chToPlot = obj.h.uitChannels.Data.Order; % Type channels number based on user's desire
            obj.chToPlot = obj.chToPlot (find(obj.h.uitChannels.Data.Show)); % Select channels
            obj.sigTbl.Show = obj.h.uitChannels.Data.Show;
            obj.sigTbl.Order = obj.h.uitChannels.Data.Order;
            obj.sigTbl.ChnNum = obj.h.uitChannels.Data.ChnNum;
            delete(obj.h.panChNm.Children); delete(obj.h.panSig.Children); delete(obj.h.panTime.Children);
            obj.h = controlWindow.clearInvalidHandles(obj.h); % A static method in controlWindow (I didn't know where I should place it)
            obj.plotSignal;
            obj.lblPlot;
            if ~isempty(obj.controlObj.labelObj)
                obj.controlObj.labelObj.lblSetUpdateView;
            end
            figure(obj.h.channels);
        end
        function obj = channelsOK(obj)
            obj.channelsApply;
            close(obj.h.channels);
        end
        function obj = channelsCancel(obj)
            close(obj.h.channels);
        end
        function obj = channelsAll(obj)
            Order = (1:size(obj.sigTbl,1))';
            Show = true(size(obj.sigTbl, 1), 1); % Show this channel?
            obj.h.uitChannels.Data.Show = Show;
            obj.h.uitChannels.Data.Order = Order;
            obj.sigTbl.Order = obj.h.uitChannels.Data.Order;
            figure(obj.h.channels);
            uistack(obj.h.channels, 'top'); 
        end
        function obj = channelsNone(obj)
            % Order = NaN(size(obj.sigTbl, 1),1);
            Show = false(size(obj.sigTbl, 1), 1); % Show this channel?
            obj.h.uitChannels.Data.Show = Show;
            % obj.h.uitChannels.Data.Order = Order;
            % obj.sigTbl.Order = obj.h.uitChannels.Data.Order;
            figure(obj.h.channels);
            uistack(obj.h.channels, 'top'); 
        end
        function obj = channelsSaveOrder(obj)
            % Extract the "Order" column
            orderData = table(obj.sigTbl.Order, 'VariableNames', {'Order'});
            % Save the updated table to a file (for now as CSV but in Future can be as a MAT file)
            [fileName, filePath] = uiputfile('channel_order.csv', 'Save Channel Order As');
            if isequal(fileName, 0)
                disp('Save operation canceled.');
                return;
            end
            % Construct the full path and save the table
            fullFilePath = fullfile(filePath, fileName);
            try
                writetable(orderData, fullFilePath);
                uialert(obj.h.channels, 'Channel order saved successfully.', 'Save Successful','Icon','success');
            catch ME
                % Handle save errors
                uialert(obj.h.channels, ['Error saving file: ', ME.message], 'Save Error','Icon','error');
            end
            figure(obj.h.channels);
        end
        function obj = channelsLoadOrder(obj)
            % Open file dialog to select a saved channel order
            [fileName, filePath, fileFilter] = uigetfile(...
                {'*.csv', 'CSV Files (*.csv)'; '*.mat', 'MAT Files (*.mat)'}, ...
                'Load Channel Order');
            % Determine full file path
            fullFilePath = fullfile(filePath, fileName);
            figure(obj.h.channels);
            uistack(obj.h.channels, 'top'); 
            % Load data based on file format as CSV for now.
            try
                switch fileFilter
                    case 1 % CSV format
                        loadedData = readtable(fullFilePath);
                        if ~any(strcmp(loadedData.Properties.VariableNames, 'Order'))
                            error('The selected CSV file does not contain an "Order" column.');
                        end
                        newOrder = loadedData.Order;
                    otherwise
                        error('Unknown file format selected.');
                end
                % Validate the loaded data
                if length(newOrder) ~= height(obj.sigTbl)
                    newOrder = [newOrder; NaN(1,height(obj.sigTbl)-length(newOrder))'];
                elseif ~isnumeric(newOrder)
                    error('The loaded order must contain valid numeric values.');
                end

                % Update the "Order" column in the table
                obj.sigTbl.Order = newOrder;
                obj.h.uitChannels.Data.Order = newOrder; % Update the UI table
                obj.h.uitChannels.Data.Show(isnan(newOrder)) = false;
                obj.h.uitChannels.Data.Show(~isnan(newOrder)) = true;
                % Notify the user
                uialert(obj.h.channels, 'Channel order loaded successfully.', 'Load Successful','Icon','success');
            catch ME
                % Handle errors during loading
                uialert(obj.h.channels, ['Error loading file: ', ME.message], 'Load Error','Icon','error');
            end
            figure(obj.h.channels);
        end
        function cbButt(obj, src, ~)
            % For UIControls
            uicontrol(obj.controlObj.h.tCurrentFile); % Give focus to text so that no uicontrol is triggered by space bar (which plays and pauses video)
            eval(['obj.', src.Tag, ';']);
        end
        function cbUicontrol(obj, src, ~)
            uicontrol(obj.controlObj.h.tCurrentFile);
            eval(['obj.', src.Tag, ';']);
        end

        %%
        function cbNow(obj, ~, ~)
            obj.controlObj.nowClicked = true;
        end
        function cbSlider(obj, src, ~)
            obj.controlObj.sliderMove(src);
        end
        function cbLbl(obj, src, evt)
           obj.controlObj.labelObj.lblClicked(src, evt);
        end
        function cbFocus(obj, ~, ~)
            obj.controlObj.cbSigFocus;
        end
        function usrFltOnOff(obj, a, ~)
            ch = str2double(a.Tag(9:end));
            if obj.fltUserSpecs.ApplyAll
                obj.fltUserSpecs.ApplyAll = false;
                if ch ~=0
                obj.whichChToFilter(ch)= false;
                end
            else
                if ch == 0
                    if sum(obj.whichChToFilter(:)==1 )>= 1 % at least one channel's filter is open.
                        obj.whichChToFilter(find(obj.whichChToFilter(:)==1)) = ~obj.whichChToFilter(find(obj.whichChToFilter(:)==1));
                    else
                        obj.whichChToFilter(:) = ~obj.whichChToFilter(:);
                    end
                else
                    obj.whichChToFilter(ch) = ~obj.whichChToFilter(ch);
                end
            end
            obj.plotSignal;
        end
       
        
        %% Label
        function obj = newLabel(obj)
            lblObj = obj.controlObj.labelObj;
            [~, whichIsCreated] = max(lblObj.lblSet.ID);
            % Data from label class definition
            dfn = lblObj.lblDef(lblObj.lblDef.ClassName == lblObj.lblSet.ClassName(whichIsCreated), :);
            c = str2num(dfn.Color); %#ok<ST2NM> % Get the basic label color
            c = 1 - (1 - c)*double(lblObj.lblSet.Value(whichIsCreated)/9); % Bleach the color according to the Value
            % Get nAx and ydata. Stretch ydata if ChannelMode is 'all'. Offset will help labels with ChannelMode 'one' to be visible over those with 'all'.
            switch dfn.ChannelMode
                case 'one'
                    ch = lblObj.lblSet.Channel(whichIsCreated);
                    nAx = find(obj.sigTbl.ChName(ch) == obj.plotTbl.ChName); % Number of the target axes
                    ydata = obj.h.axSig(nAx).YLim;
                    zOffset = 0;
                case 'all'
                    ch = find(obj.sigTbl.ChName == obj.plotTbl.ChName(1)); % We will draw the labels of ChannelMode 'all' in these axes
                    nAx = 1;
                    ydata = obj.h.axSig(nAx).YLim;
                    ydata(1) = ydata(1)  -  (size(obj.plotTbl, 1) - 1)*diff(ydata);
                    zOffset = -5;
            end
            [~, whichIsCreated] = max(lblObj.lblSet.ID);
            st = datenum(lblObj.lblSet.Start(whichIsCreated) - lblObj.sigInfo.SigStart(ch))*24*3600;
            en = datenum(lblObj.lblSet.End(whichIsCreated) - lblObj.sigInfo.SigStart(ch))*24*3600;
            % Draw the graphic objects
            switch dfn.LabelType
                case 'point'
                    obj.h.lblLA(lblObj.lblSet.ID(whichIsCreated)) = line([st st], ydata, 'Parent', obj.h.axSig(nAx),...
                        'Color', c, 'LineWidth', obj.stg.sLblRoiLineWidth, 'ZData', [-40 -40]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                        'AlignVertexCenters', 'on', 'LineJoin', 'chamfer', 'Tag', ['lblLA', num2str(lblObj.lblSet.ID(whichIsCreated))]); % Tag: label Line All
                case 'roi'
                    c = str2num(lblObj.lblDef.Color(lblObj.lblDef.ClassName == lblObj.lblSet.ClassName(whichIsCreated))); %#ok<ST2NM> % Get the basic label color
                    c = 1 - (1 - c)*double(lblObj.lblSet.Value(whichIsCreated)/9); % Bleach the color according to the Value
                    obj.h.lblLS(lblObj.lblSet.ID(whichIsCreated)) = line([st st], ydata, 'Parent', obj.h.axSig(nAx),...
                        'Color', c, 'LineWidth', obj.stg.sLblRoiLineWidth, 'ZData', [-40 -40]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                        'AlignVertexCenters', 'on', 'LineJoin', 'chamfer', 'Tag', ['lblLS', num2str(lblObj.lblSet.ID(whichIsCreated))]); % Tag: label Line Start
                    obj.h.lblLE(lblObj.lblSet.ID(whichIsCreated)) = line([en en], ydata, 'Parent', obj.h.axSig(nAx),...
                        'Color', c, 'LineWidth', obj.stg.sLblRoiLineWidth, 'ZData', [-50 -50]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                        'AlignVertexCenters', 'on', 'LineJoin', 'chamfer', 'Tag', ['lblLE', num2str(lblObj.lblSet.ID(whichIsCreated))]); % Tag: label Line End
                    obj.h.lblPa(lblObj.lblSet.ID(whichIsCreated)) = patch([st en en st], repelem(ydata, 2), c, 'Parent', obj.h.axSig(nAx),...
                        'EdgeColor', 'none', 'ZData', [-60 -60 -60 -60]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                        'AlignVertexCenters', 'on', 'Tag', ['lblPa', num2str(lblObj.lblSet.ID(whichIsCreated))]); % Tag: label Patch
            end
            obj.h.lblPa
            drawnow
%             obj.controlObj.labelObj.plottedLabelsIDs = sort([obj.controlObj.labelObj.plottedLabelsIDs; lblObj.lblSet.ID(end)]);
%             obj.controlObj.labelObj.lblSetUpdatePlotted(obj.controlObj.labelObj.plottedLabelsIDs);
        end
        function obj = lblUpdate(obj)
            if isempty(obj.controlObj.labelObj)
                return
            end
            lblObj = obj.controlObj.labelObj;
            lbl = lblObj.lblSet;
            lbl = lbl(ismember(lbl.Channel, obj.chToPlot), :); % Keep only the labels whose channel is plotted
            lbl = lbl(ismember(lbl.ClassName, lblObj.lblDef.ClassName(lblObj.lblClassesToShow)), :); % Keep only the lblClassesToShow
            if isempty(lbl)
                return
            end
            
            % The labels of ChannelMode 'all' will be drawn in the first axes. Determine which channel is in the first axes.
            nAxForAll = obj.chToPlot(1); % We will draw the labels of ChannelMode 'all' in these axes
            channels = lbl.Channel;
            channels(channels == 0) = nAxForAll; % Labels which should be drawn in all axes have channel 0
            stAll = datenum(lbl.Start - lblObj.sigInfo.SigStart(channels))*24*3600;
            enAll = datenum(lbl.End - lblObj.sigInfo.SigStart(channels))*24*3600;
            nLbl = find(enAll >= obj.controlObj.plotLimS(1) & stAll <= obj.controlObj.plotLimS(2)); % Only the labels within the plotLimS
            nID = lbl.ID(nLbl);
            obj.controlObj.labelObj.plottedLabelsIDs = nID;

            
            % Delete those not contained in nLbl
            del; % Nested function. Delete only those which are no longer in the view
            for k = 1 : length(nLbl)
                if mod(k, 30) == 0
                    drawnow
                end
                % Data from label class definition
                def = lblObj.lblDef(lblObj.lblDef.ClassName == lbl.ClassName(nLbl(k)), :);
                c = str2num(def.Color); %#ok<ST2NM> % Get the basic label color
                c = 1 - (1 - c)*double(lbl.Value(nLbl(k))/9); % Bleach the color according to the Value
                % Get channel, axes and ydata
                ch = channels(nLbl(k));
                nAx = find(obj.chToPlot == ch); % Target axes number
                ydata = obj.h.axSig(nAx).YLim;
                % Modify ydata if ChannelMode is 'all'. Offset will help labels with ChannelMode 'one' to be visible over those with 'all'.
                switch def.ChannelMode
                    case 'one'
                        zOffset = 0;
                    case 'all'
                        ydata(1) = ydata(1)  -  (size(obj.plotTbl, 1) - 1)*diff(ydata);
                        zOffset = -5;
                end
                st = datenum(lbl.Start(nLbl(k)) - lblObj.sigInfo.SigStart(ch))*24*3600;
                en = datenum(lbl.End(nLbl(k)) - lblObj.sigInfo.SigStart(ch))*24*3600;
                % If the label is displayed just make sure it fits within the x-axis limits an shorten the beginning if needed
                if isDisplayed(lbl.ID(nLbl(k))) % Nested function. Determine if given label is already displayed.
                    switch def.LabelType
                        case 'roi'
                            if st < obj.controlObj.plotLimS(1)
                                obj.h.lblLS(lbl.ID(nLbl(k))).Visible = 'off';
                            else
                                obj.h.lblLS(lbl.ID(nLbl(k))).Visible = 'on';
                            end
                            obj.h.lblPa(lbl.ID(nLbl(k))).XData(1) = max(st, obj.controlObj.plotLimS(1));
                            obj.h.lblPa(lbl.ID(nLbl(k))).XData(4) = max(st, obj.controlObj.plotLimS(1));
                    end
                        continue
                end
                
                % Draw the graphic objects
                switch def.LabelType
                    case 'point'
                        obj.h.lblLA(lbl.ID(nLbl(k))) = line([st st], ydata, 'Parent', obj.h.axSig(nAx),...
                            'Color', c, 'LineWidth', obj.stg.sLblRoiLineWidth, 'ZData', [-40 -40]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                            'AlignVertexCenters', 'on', 'LineJoin', 'chamfer', 'Tag', ['lblLA', num2str(lbl.ID(nLbl(k)))]); % Tag: label Line All
                    case 'roi'
                        obj.h.lblLS(lbl.ID(nLbl(k))) = line([st st], ydata, 'Parent', obj.h.axSig(nAx),...
                            'Color', c, 'LineWidth', obj.stg.sLblRoiLineWidth, 'ZData', [-40 -40]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                            'AlignVertexCenters', 'on', 'LineJoin', 'chamfer', 'Tag', ['lblLS', num2str(lbl.ID(nLbl(k)))]); % Tag: label Line Start
                        obj.h.lblLE(lbl.ID(nLbl(k))) = line([en en], ydata, 'Parent', obj.h.axSig(nAx),...
                            'Color', c, 'LineWidth', obj.stg.sLblRoiLineWidth, 'ZData', [-50 -50]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                            'AlignVertexCenters', 'on', 'LineJoin', 'chamfer', 'Tag', ['lblLE', num2str(lbl.ID(nLbl(k)))]); % Tag: label Line End
                        obj.h.lblPa(lbl.ID(nLbl(k))) = patch([st en en st], repelem(ydata, 2), c, 'Parent', obj.h.axSig(nAx),...
                            'EdgeColor', 'none', 'ZData', [-60 -60 -60 -60]+zOffset, 'ButtonDownFcn', @obj.cbLbl,...
                            'AlignVertexCenters', 'on', 'Tag', ['lblPa', num2str(lbl.ID(nLbl(k)))]); % Tag: label Patch

                end
            end
            drawnow
%             if ~contains(char(obj.h.f.WindowButtonMotionFcn), 'cbSigButtMotion') % Do this only if the user is not panning, since it is slow
%                 drawnow
%                 obj.controlObj.labelObj.lblSetUpdatePlotted(obj.controlObj.labelObj.plottedLabelsIDs);
%                 drawnow
%             end
            
            % Nested functions
            function del
                graphObjNm = {'lblLA', 'lblLS', 'lblLE', 'lblPa'};
                for kg = 1 : length(graphObjNm)
                    if isfield(obj.h, graphObjNm{kg})
                        if isstruct(obj.h.(graphObjNm{kg})) % Sometimes, the graphics object is not created but subsequent coded tries to modify its properties and it creates a struct.
                            obj.h = rmfield(obj.h, graphObjNm{kg});
                            continue
                        end
                        nValid = find(isvalid(obj.h.(graphObjNm{kg})));
                        toDelete = setdiff(nValid, nID);
                        if ~isempty(toDelete)
                            delete(obj.h.(graphObjNm{kg})(toDelete));
                        end
                    end
                end
            end
            function TF = isDisplayed(id)
                TF = false;
                graphObjNm = {'lblLA', 'lblLS', 'lblLE', 'lblPa'};
                for kg = 1 : length(graphObjNm)
                    if isfield(obj.h, graphObjNm{kg})
                        if length(obj.h.(graphObjNm{kg})) >= id
                            if isprop(obj.h.(graphObjNm{kg})(id), 'Tag')
%                                 tic
%                                 idg = str2double(obj.h.(graphObjNm{kg})(id).Tag(6 : end));
%                                 if double(id) == idg && isvalid(obj.h.(graphObjNm{kg})(id))
%                                     TF = true;
%                                 end
% % % % %                                 idg = str2double(obj.h.(graphObjNm{kg})(id).Tag(6 : end));
                                if isvalid(obj.h.(graphObjNm{kg})(id))
                                    TF = true;
                                end
                                
%                                 toc
                            end
                        end
                    end
                end
            end
        end
        function obj = lblUpdateOne(obj, ID) % Use this when user edits Channel, Start, End or Value of a single label
            for k = 1 : length(ID)
                lbl = obj.controlObj.labelObj.lblSet(obj.controlObj.labelObj.lblSet.ID == ID(k), :);
                clnm = obj.controlObj.labelObj.lblSet.ClassName(obj.controlObj.labelObj.lblSet.ID == ID(k), :);
                def = obj.controlObj.labelObj.lblDef(obj.controlObj.labelObj.lblDef.ClassName == clnm, :);
                % Prepare ydata
                switch def.ChannelMode
                    case 'one'
                        ch = lbl.Channel;
                        nAx = find(obj.sigTbl.ChName(ch) == obj.plotTbl.ChName); % Number of the target axes
                        ydata = obj.h.axSig(nAx).YLim;
                        zOffset = 0;
                    case 'all'
                        ch = find(obj.sigTbl.ChName == obj.plotTbl.ChName(1)); % We will draw the labels of ChannelMode 'all' in these axes
                        nAx = 1;
                        ydata = obj.h.axSig(nAx).YLim;
                        ydata(1) = ydata(1)  -  (size(obj.plotTbl, 1) - 1)*diff(ydata);
                        zOffset = -5;
                end
                sig = obj.controlObj.labelObj.sigInfo(ch, :);
                c = str2num(def.Color); %#ok<ST2NM> % Get the basic label color
                c = 1 - (1 - c)*double(lbl.Value/9); % Bleach the color according to the Value
                st = datenum(lbl.Start - sig.SigStart)*3600*24;
                en = datenum(lbl.End - sig.SigStart)*3600*24;
                switch def.LabelType
                    case 'point'
                        obj.h.lblLA(ID(k)).XData = [st st];
                        obj.h.lblLA(ID(k)).YData = ydata;
                        obj.h.lblLA(ID(k)).ZData = [-40 -40] + zOffset;
                        obj.h.lblLA(ID(k)).Color = c;
                        obj.h.lblLA(ID(k)).Parent = obj.h.axSig(nAx);
                    case 'roi'
                        obj.h.lblLS(ID(k)).XData = [st st];
                        obj.h.lblLS(ID(k)).YData = ydata;
                        obj.h.lblLS(ID(k)).ZData = [-40 -40] + zOffset;
                        obj.h.lblLS(ID(k)).Color = c;
                        obj.h.lblLS(ID(k)).Parent = obj.h.axSig(nAx);
                        obj.h.lblLE(ID(k)).XData = [en en];
                        obj.h.lblLE(ID(k)).YData = ydata;
                        obj.h.lblLE(ID(k)).ZData = [-50 -50] + zOffset;
                        obj.h.lblLE(ID(k)).Color = c;
                        obj.h.lblLE(ID(k)).Parent = obj.h.axSig(nAx);
                        obj.h.lblPa(ID(k)).XData = [st en en st];
                        obj.h.lblPa(ID(k)).YData = repelem(ydata, 2);
                        obj.h.lblPa(ID(k)).ZData = [-60 -60 -60 -60] + zOffset;
                        obj.h.lblPa(ID(k)).FaceColor = c;
                        obj.h.lblPa(ID(k)).Parent = obj.h.axSig(nAx);
                end
            end
        end
        function obj = lblDelete(obj, ID)
            for k = 1 : length(ID)
                clnm = obj.controlObj.labelObj.lblSet.ClassName(obj.controlObj.labelObj.lblSet.ID == ID(k));
                type = char(obj.controlObj.labelObj.lblDef.LabelType(obj.controlObj.labelObj.lblDef.ClassName == clnm));
                switch type
                    case 'point'
                        delete(obj.h.lblLA(ID(k)))
                    case 'roi'
%                         if isfield(obj.h, 'lblLS')
                            delete(obj.h.lblLS(ID(k)))
                            delete(obj.h.lblLE(ID(k)))
                            delete(obj.h.lblPa(ID(k)))
%                         end
                end
            end
        end
        function obj = lblPlot(obj)
            graphObjNm = {'lblLA', 'lblLS', 'lblLE', 'lblPa'};
            for kg = 1 : length(graphObjNm)
                if isfield(obj.h, graphObjNm{kg})
                    if isstruct(obj.h.(graphObjNm{kg})) % Sometimes, the graphics object is not created but subsequent code tries to modify its properties and it creates a struct.
                        obj.h = rmfield(obj.h, graphObjNm{kg});
                        continue
                    end
                    nValid = isvalid(obj.h.(graphObjNm{kg}));
                    delete(obj.h.(graphObjNm{kg})(nValid));
                    obj.h = rmfield(obj.h, graphObjNm{kg});
                end
            end
            obj.lblUpdate;
        end
        
        %% Current source density
        % function obj = showBipolarMontage(obj)
        %     obj.plotTbl = obj.plotTbl.Data{1}*0;
        % 
        %     if bipolar_checkbox == true
        %         calculations_exported;
        %         bipolar_montage
        %     end
        %     % obj.plotTbl = obj.sigTbl(obj.chToPlot, :);


            % At the end of this function, call
            % obj.plotSignal



           % Second task, full of beauty, for more distant future: try to get the colorful picture in the background
        % end
        
        %% Bipolar montage
       function obj = applyBipolar(obj)
            if obj.bipolarTF
                numCh = size(obj.sigTbl, 1);
        
                if mod(numCh, 2) ~= 0
                    warning('Bipolar montage requires even number of channels. Skipping last channel.');
                    numCh = numCh - 1;
                end
        
                newTbl = obj.sigTbl(1 : 2 : numCh - 1, :);
                for k = 1 : 2 : numCh
                    ch1Name = obj.sigTbl.ChName(k);
                    ch2Name = obj.sigTbl.ChName(k + 1);
                    sig1 = obj.sigTbl.Data{k};
                    sig2 = obj.sigTbl.Data{k + 1};
        
                    if length(sig1) ~= length(sig2)
                        warning('Skipping pair %s-%s due to length mismatch.', ch1Name, ch2Name);
                        continue
                    end
        
                    newSignal = sig1 - sig2;
                    idx = (k+1)/2;
                    newTbl.Data{idx} = newSignal;
                    newTbl.ChName(idx) = ch1Name + "-" + ch2Name;
                end
                % % % obj.bipolarTbl = newTbl;
                % % % obj.chToPlot = 1:size(obj.bipolarTbl, 1);
                % % % obj.bipolarTblTF = true;
                obj.plotTbl = newTbl;
                obj.chToPlot = 1:size(obj.plotTbl, 1);
                % % % obj.bipolarTblTF = true;
            else
                obj.chToPlot = 1:size(obj.sigTbl, 1);
                % % % obj.bipolarTblTF = false;
            end
        end

        %% General
        function obj = makeFigure(obj, ctrObj)
            % Create figure
% % %             obj.h.f = figure('MenuBar', 'none', 'ToolBar', 'none', 'Position', obj.stg.sFigPos,...
% % %                 'WindowKeyPressFcn', @ctrObj.cbKey,...
% % %                 'WindowKeyReleaseFcn', @ctrObj.cbKeyRelease,...
% % %                 'WindowButtonDownFcn', @ctrObj.cbSigButtDn,...
% % %                 'WindowButtonUpFcn', @ctrObj.cbSigButtUp,...
% % %                 'WindowScrollWheelFcn', @ctrObj.cbSigScrollWheel,...
% % %                 'CloseRequestFcn', @obj.delete,...
% % %                 'Interruptible', 'on',...
% % %                 'BusyAction', 'queue',...
% % %                 'Tag', 'signal');
            obj.h.f = ctrObj.h.f;
            % Create panels
            indent = obj.stg.sigPanIndent;
            obj.h.panChNm = uipanel('Units', 'pixels', 'Visible', 'on', 'BorderType', 'line',...
                'Position', [1, indent(2), indent(1), obj.h.f.Position(4) - indent(2) - 60], 'HitTest', 'off');
            obj.h.panChNm.Units = 'normalized';
            obj.h.panSig = uipanel('Units', 'pixels', 'Visible', 'on', 'BorderType', 'line',...
                'Position', [indent(1), indent(2), obj.h.f.Position(3) - indent(1), obj.h.f.Position(4) - indent(2) - 60]);
            obj.h.panSig.Units = 'normalized';
            obj.h.panTime = uipanel('Units', 'pixels', 'Visible', 'on', 'BorderType', 'line',...
                'Position', [indent(1), 1, obj.h.f.Position(3) - indent(1), indent(2)]);
            obj.h.panTime.Units = 'normalized';
            % Create buttons
            subsCommand = find(obj.key.Command == "horizontalZoomIn", 1); % Subscript into keyShortTbl of given command
            buttPos = [obj.stg.sigPanIndent(1)*2/3, 0, obj.stg.sigPanIndent(1)/3, obj.stg.sigPanIndent(2);
                       obj.stg.sigPanIndent(1)*1/3, 0, obj.stg.sigPanIndent(1)/3, obj.stg.sigPanIndent(2);
                       0, obj.stg.sigPanIndent(2)/2, obj.stg.sigPanIndent(1)/3, obj.stg.sigPanIndent(2)/2;
                       0, 0, obj.stg.sigPanIndent(1)/3, obj.stg.sigPanIndent(2)/2];
            buttStr = {'+', '-', '+', '-'};
            for kz = 1 : 4
                tooltipStr = (obj.key.Command(subsCommand) + ", " + obj.key.Modifier(subsCommand) + "+" + obj.key.Shortcut(subsCommand));
                tooltipStr = tooltipStr(1);
                obj.h.bZoom(kz) = uicontrol('Parent', obj.h.f, 'Style', 'pushbutton',...
                    'Units', 'pixels', 'Position', buttPos(kz, :),...
                    'String', buttStr{kz}, 'Callback', @obj.cbButt,...
                    'Tooltip', tooltipStr,...
                    'Tag', obj.key.Command(subsCommand));
                obj.h.bZoom(kz).Units = 'normalized';
                subsCommand = subsCommand + 1;
            end
            drawnow
            % Since alt key is used for measuring and also in alt+tab combination for changing windows, we need to turn of the measuring regime when
            % the window loses focus. Otherwise, when pressing alt+tab to change the window, the measuring regime would remain hanging there and when the
            % user returns to the figure it would start measuring instead of panning which would be annoying.
            % jf = get(obj.h.f, 'JavaFrame');
            % jw = handle(jf.getFigurePanelContainer.getTopLevelAncestor,'CallbackProperties');
            % set(jw, 'WindowGainedFocusCallback', @obj.cbFocus);
            % set(jw, 'WindowLostFocusCallback', @obj.cbFocus);
            % obj.h.f.WindowStateChangedFcn = @(src, evt)obj.cbFocus(src, evt);
        end
        function delete(obj, ~, ~)
            if ~isempty(obj.controlObj.videoShowObj)
                delete(obj.controlObj.videoShowObj.h.f)
                obj.controlObj.videoShowObj = [];
            end
            if ~isempty(obj.controlObj.videoObj)
                obj.controlObj.videoObj = [];
            end
            if ~isempty(obj.controlObj.labelObj)
                delete(obj.controlObj.labelObj.h.f)
                obj.controlObj.labelObj = [];
            end
            delete(obj.h.f);
        end
        
        function tbl = getCurrentTbl(obj)
            % % % if obj.bipolarTblTF
                tbl = obj.plotTbl;
            % % % else
            % % %     tbl = obj.sigTbl;
            % % % end
        end
    
        function obj = setCurrentTbl(obj, tbl)
            % % % if obj.bipolarTblTF
                obj.plotTbl = tbl;
            % % % else
                % % % obj.sigTbl = tbl;
            % % % end
        end
    end
end

