classdef connWindow < handle
    properties
        controlObj
        stg
        key
        hFig
        hAx          % 5×1 array of axes
        hSliderWin
        hSliderStep
        hTextWin
        hTextStep
        hButtonApply
        hButtonNext
        hButtonPrev
        hPopupWin
        hPopupStep
        winSizeS = 2;
        stepSizeS = 0.5;
        currentStartS = 0;
        numBands = 5;
        hTitle
        hBandLabel   % text handles for band labels
        method = 'MSC';   % 'MSC' or 'PSI'
        hPopupMethod

    end

    methods
        function obj = connWindow(ctrlObj)
            obj.controlObj = ctrlObj;
            obj.stg = stgs;
            obj.key = keyShortTbl;
        
            % Figure position from settings
            pos = obj.stg.connFigPos;
        
            obj.hFig = figure('Name','Connectivity', ...
                'NumberTitle','off', ...
                'MenuBar','none', ...
                'ToolBar','none', ...
                'Position', double(pos), ...
                'CloseRequestFcn', @(src,evt)obj.onClose());
        
            bg = get(obj.hFig,'Color');
        
            % === Top layout: 3 rows ===
            rowH  = 0.025;    % height for each row
            gapV  = 0.01;    % vertical gap between rows
            topY  = 1 - gapV;
        
            % 1) Row 1: global title
            obj.hTitle = uicontrol('Parent',obj.hFig, 'Style','text', ...
                'Units','normalized', ...
                'Position',[0.25 topY-rowH 0.50 rowH], ...
                'String','Connectivity', ...
                'FontWeight','bold', ...
                'HorizontalAlignment','center', ...
                'BackgroundColor', bg);
        
            % 2) Row 2: window + step + method
            y2 = topY - rowH - gapV - rowH;
            
            % Window size popup
            uicontrol('Parent',obj.hFig, 'Style','text', ...
                'Units','normalized', ...
                'Position',[0.02 y2 0.20 rowH], ...
                'String','Window size [s]:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);
            
            winOptions = 1:0.5:10;
            winStr     = arrayfun(@(x)sprintf('%.1f',x), winOptions, 'UniformOutput',false);
            
            obj.hPopupWin = uicontrol('Parent',obj.hFig, 'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.21 y2 0.15 rowH], ...
                'String',winStr, ...
                'Value', find(winOptions==obj.winSizeS,1), ...
                'Callback',@(src,evt)obj.cbPopupWin(src), ...
                'BackgroundColor', bg);
            
            % Step size popup
            uicontrol('Parent',obj.hFig, 'Style','text', ...
                'Units','normalized', ...
                'Position',[0.40 y2 0.18 rowH], ...
                'String','Step size [s]:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);
            
            stepOptions = [0.1:0.1:0.9, 1:0.5:10];
            stepStr     = arrayfun(@(x)sprintf('%.1f',x), stepOptions, 'UniformOutput',false);
            [~,idx0]    = min(abs(stepOptions - obj.stepSizeS));
            
            obj.hPopupStep = uicontrol('Parent',obj.hFig, 'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.55 y2 0.15 rowH], ...
                'String',stepStr, ...
                'Value', idx0, ...
                'Callback',@(src,evt)obj.cbPopupStep(src), ...
                'BackgroundColor', bg);
            
            % Method popup (MSC / PSI) in place of old Apply
            uicontrol('Parent',obj.hFig, 'Style','text', ...
                'Units','normalized', ...
                'Position',[0.72 y2 0.10 rowH], ...
                'String','Method:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);
            
            obj.hPopupMethod = uicontrol('Parent',obj.hFig, 'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.82 y2 0.16 rowH], ...
                'String',{'MSC','PSI'}, ...
                'Value',1, ...                 % default MSC
                'Callback',@(src,evt)obj.cbPopupMethod(src), ...
                'BackgroundColor', bg);
            
            % 3) Row 3: Previous, Apply, Next
            y3 = y2 - rowH - gapV;
            
            obj.hButtonPrev = uicontrol('Parent',obj.hFig, 'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.21, y3, 0.15, rowH + 0.01], ...
                'String', {'Previous', '(ctrl+k)'}, ...
                'Callback',@(src,evt)obj.cbPrev(), ...
                'BackgroundColor', bg);
     
            
            obj.hButtonNext = uicontrol('Parent',obj.hFig, 'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.55, y3, 0.15, rowH + 0.01], ...
                'String',{'Next','(k)'}, ...
                'Callback',@(src,evt)obj.cbNext(), ...
                'BackgroundColor', bg);
                   
            obj.hButtonApply = uicontrol('Parent',obj.hFig, 'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.82, y3, 0.15, rowH + 0.01], ...
                'String','Apply', ...
                'Callback',@(src,evt)obj.cbApply(), ...
                'BackgroundColor', bg);


        
            % === Axes area for 5 bands ===
            axTop    = y3 - gapV;   % top of matrices area
            axBottom = 0.02;
            axTotalH = axTop - axBottom;
            gapAx    = 0.01;
            axH      = (axTotalH - (obj.numBands-1)*gapAx) / obj.numBands;
        
            labelColWidth = 0.2;
            axLeft        = labelColWidth + 0.02;
            axWidth       = 0.80;
        
            obj.hAx = gobjects(obj.numBands,1);
            for b = 1:obj.numBands
                y = axTop - b*(axH + gapAx) + gapAx;
                obj.hAx(b) = axes('Parent',obj.hFig, ...
                    'Units','normalized', ...
                    'Position',[axLeft y axWidth axH]);
            end
        
            % Band labels in the left column (flush to figure left)
            freq_bands = [1 4; 4 8; 8 13; 13 30; 30 80];
            bandNames  = {'Delta','Theta','Alpha','Beta','Gamma'};
        
            obj.hBandLabel = gobjects(obj.numBands,1);
            for b = 1:obj.numBands
                posAx = get(obj.hAx(b), 'Position');  % [x y w h]
                xTxt  = 0.01;
                yTxt  = posAx(2) + posAx(4)/2 - 0.02;
        
                obj.hBandLabel(b) = uicontrol('Parent',obj.hFig,'Style','text', ...
                    'Units','normalized', ...
                    'Position',[xTxt yTxt labelColWidth-0.02 0.05], ...
                    'String',sprintf('%s\n%.0f–%.0f Hz', ...
                                     bandNames{b}, freq_bands(b,1), freq_bands(b,2)), ...
                    'HorizontalAlignment','right', ...
                    'FontSize',9, ...
                    'BackgroundColor', bg);
            end
        end

        function cbPopupWin(obj, src)
            winOptions = 1:0.5:10;
            idx = src.Value;
            obj.winSizeS = winOptions(idx);
        
            % Ensure step is at least 0.5 and at most winSizeS
            obj.stepSizeS = min(max(obj.stepSizeS, 0.5), obj.winSizeS);
        
            fprintf('Window size set to %.1f s, current step = %.3f s\n', ...
                    obj.winSizeS, obj.stepSizeS);
        end

        function onClose(obj)
            % 1) Clear reference in controlWindow
            if ~isempty(obj.controlObj) && isprop(obj.controlObj,'connObj')
                if isequal(obj.controlObj.connObj, obj)
                    obj.controlObj.connObj = [];
                end
            end
        
            % 2) Hide now line and connectivity window rectangle in signal view
            sigObj = obj.controlObj.signalObj;
        
            % Hide rectangles
            if isfield(sigObj.h,'pConn')
                for k = 1:numel(sigObj.h.pConn)
                    if ishghandle(sigObj.h.pConn(k))
                        sigObj.h.pConn(k).Visible = 'off';
                    end
                end
            end
        
            % Optionally hide now line as well
            if isfield(sigObj.h,'lNow')
                for k = 1:numel(sigObj.h.lNow)
                    if ishghandle(sigObj.h.lNow(k))
                        sigObj.h.lNow(k).Visible = 'off';
                    end
                end
            end
        
            % 3) Finally delete the figure
            if ishghandle(obj.hFig)
                delete(obj.hFig);
            end
        end

       function cbPopupStep(obj, src)
            stepOptions = [0.1:0.1:1, 1:0.5:10];      % absolute step sizes
            idx = src.Value;
            step = stepOptions(idx);
        
            % Clamp to [0.5, winSizeS]
            step = min(max(step,0.5), obj.winSizeS);
            obj.stepSizeS = step;
        
            fprintf('Step size set to %.3f s (window %.1f s)\n', ...
                    obj.stepSizeS, obj.winSizeS);
        end

        function cbPopupMethod(obj, src)
            methods = {'MSC','PSI'};
            idx = src.Value;
            obj.method = methods{idx};
            fprintf('Connectivity method set to %s\n', obj.method);
        end



        % Apply button callback
        function cbApply(obj)
            obj.currentStartS = obj.controlObj.nowS;
            obj.computeAndPlot(obj.currentStartS);
        
            % Update rectangle on signal
            obj.controlObj.signalObj.connWindowUpdate;
        end
        function [winData, fs] = getWindowData(obj, startS, winLenS)
            % Uses controlObj.signalObj.plotTbl
            sigObj = obj.controlObj.signalObj;
            tbl    = sigObj.plotTbl;
    
            if isempty(tbl)
                error('plotTbl is empty – compute connectivity after plotting the signal.');
            end
    
            fs = tbl.Fs(1);  % assume same Fs for all plotted channels
    
            % Convert times to sample indices (1-based)
            k1 = max(1, floor(startS * fs) + 1);
            k2 = floor((startS + winLenS) * fs);
    
            % Make sure we do not exceed the data length
            sigLen = length(tbl.Data{1});
            k2 = min(k2, sigLen);
            if k2 <= k1
                error('Requested window is empty or out of bounds.');
            end
    
            numCh   = height(tbl);
            winData = zeros(numCh, k2 - k1 + 1);
    
            for ch = 1:numCh
                x = tbl.Data{ch};
                winData(ch,:) = x(k1:k2);
            end
        end
        function Cmat = compute_msc_onewindow(obj, window_data, fs)
            % Simple settings – you can later expose these or load from stg
            settings.freq_bands = [1 4; 4 8; 8 13; 13 30; 30 80];
            settings.window_length_hamm = 1.0;
            settings.overlap_len_hamm  = 0.5;
            settings.nfft = 2^10;
        
            num_channels = size(window_data, 1);
            num_bands    = size(settings.freq_bands, 1);
            Cmat = zeros(num_channels, num_channels, num_bands);
                    num_channels = size(window_data, 1);
            
            window_length = round(settings.window_length_hamm * fs);
            overlap       = round(settings.overlap_len_hamm * fs);
            nfft          = settings.nfft;
    
            for i = 1:num_channels-1
                for j = i+1:num_channels
                    [Cxy, f] = mscohere(window_data(i,:)', window_data(j,:)', ...
                        hamming(window_length), overlap, nfft, fs);
                    for b = 1:num_bands
                        f1 = settings.freq_bands(b,1);
                        f2 = settings.freq_bands(b,2);
                        idx = (f >= f1 & f <= f2);
                        Cval = mean(Cxy(idx));
                        Cmat(i,j,b) = Cval;
                        Cmat(j,i,b) = Cval;
                    end
                end
            end
        end

        function Cmat = compute_psi_onewindow(obj, window_data, fs)
            % Settings for PSI
            settings.freq_bands    = [1 4; 4 8; 8 13; 13 30; 30 80];
            settings.psi_tapsmofrq = 2;    % example; tune as needed
            settings.psi_bandwidth = 5;    % example
        
            [nChan, nSamp] = size(window_data);
            nBands         = size(settings.freq_bands,1);
        
            % Build FieldTrip-like data
            data_ft            = [];
            data_ft.fsample    = fs;
            data_ft.trial      = {double(window_data)};
            data_ft.time       = {(0:nSamp-1)/fs};
            data_ft.label      = arrayfun(@(k) sprintf('ch%d',k), 1:nChan, 'uni', 0);
        
            % Spectral estimation
            cfg           = [];
            cfg.method    = 'mtmfft';
            cfg.output    = 'fourier';
            cfg.taper     = 'dpss';
            cfg.foilim    = [min(settings.freq_bands(:)) max(settings.freq_bands(:))];
            cfg.tapsmofrq = settings.psi_tapsmofrq;
            cfg.pad       = 'nextpow2';
        
            freq = ft_freqanalysis(cfg, data_ft);
        
            % PSI
            cfgc            = [];
            cfgc.method     = 'psi';
            cfgc.bandwidth  = settings.psi_bandwidth;
            conn            = ft_connectivityanalysis(cfgc, freq);
        
            % Assume conn.psispctrm is [nChan x nChan x nFreq]
            psi_freq = conn.psispctrm;
            if ndims(psi_freq) ~= 3 || size(psi_freq,1) ~= nChan
                error('Unexpected PSI output size; adjust compute_psi_onewindow.');
            end
        
            freqs   = conn.freq(:);
            Cmat    = zeros(nChan, nChan, nBands);
        
            for b = 1:nBands
                f_lo = settings.freq_bands(b,1);
                f_hi = settings.freq_bands(b,2);
                mask = freqs >= f_lo & freqs <= f_hi;
                if ~any(mask), continue; end
                Cmat(:,:,b) = mean(psi_freq(:,:,mask), 3, 'omitnan');
            end
        end


        function computeAndPlot(obj, startS)
            winLenS = obj.winSizeS;
            [winData, fs] = obj.getWindowData(startS, winLenS);
            
            switch obj.method
                case 'MSC'
                    Cmat = obj.compute_msc_onewindow(winData, fs);
                    lims = [0 1];
                case 'PSI'
                    Cmat = obj.compute_psi_onewindow(winData, fs);  % to be implemented
                    lims = [-1 1];
                otherwise
                    error('Unknown connectivity method: %s', obj.method);
            end
            
        
            % Update global title with time window
            obj.hTitle.String = sprintf('Connectivity %.2f–%.2f s', startS, startS + winLenS);
        
            chNames = obj.controlObj.signalObj.plotTbl.ChName;
            nCh     = numel(chNames);
        
            for b = 1:obj.numBands
                C  = Cmat(:,:,b);
                ax = obj.hAx(b);
        
                axes(ax); %#ok<LAXES>
                imagesc(ax, C);
                axis(ax,'image');
                colormap(ax,"turbo");
                colorbar(ax);
                clim(ax, lims);
        
                % Y‑axis labels for every matrix, smaller font
                set(ax,'YTick',1:nCh, ...
                       'YTickLabel',chNames, ...
                       'FontSize',5);   % smaller text
            end
        
            % X‑axis labels only on the last matrix to save space
            for b = 1:obj.numBands-1
                ax = obj.hAx(b);
                set(ax,'XTick',[],'XTickLabel',[]);
            end
        
            axLast = obj.hAx(obj.numBands);
            set(axLast,'XTick',1:nCh, ...
                       'XTickLabel',chNames, ...
                       'XTickLabelRotation',90, ...
                       'FontSize',5);   % smaller text for bottom labels
        end


       function cbNext(obj)
            obj.currentStartS = obj.currentStartS + obj.stepSizeS;
            obj.controlObj.nowS = obj.currentStartS;
        
            obj.computeAndPlot(obj.currentStartS);
            obj.controlObj.signalObj.connWindowUpdate;
            obj.controlObj.signalObj.nowUpdate;  % keep now line in sync
        
            if isfield(obj.controlObj.h,'f') && ishghandle(obj.controlObj.h.f)
                figure(obj.controlObj.h.f);
            end
        end

        function cbPrev(obj)
            % Move window backwards by step
            obj.currentStartS = obj.currentStartS - obj.stepSizeS;
        
            % Do not go before 0
            if obj.currentStartS < 0
                obj.currentStartS = 0;
            end
        
            % Update nowS and now line
            obj.controlObj.nowS = obj.currentStartS;
            obj.controlObj.signalObj.nowUpdate;
        
            fprintf('Previous: win = %.3f s, step = %.3f s, new start = %.3f s (nowS)\n', ...
                    obj.winSizeS, obj.stepSizeS, obj.currentStartS);
        
            % Recompute connectivity
            obj.computeAndPlot(obj.currentStartS);
        
            % Return keyboard focus to control window
            if isfield(obj.controlObj.h,'f') && ishghandle(obj.controlObj.h.f)
                figure(obj.controlObj.h.f);
            end
        end

    end
end
