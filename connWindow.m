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
        hPopupWin
        hPopupStep
        winSizeS = 2;
        stepSizeS = 0.5;
        currentStartS = 0;
        numBands = 5;
        hTitle
        hBandLabel   % text handles for band labels

    end

    methods
        function obj = connWindow(ctrlObj)
            obj.controlObj = ctrlObj;
            obj.stg = stgs;
            obj.key = keyShortTbl;
        
            % Figure position: use stg, but full screen height
            gr    = groot;
            scrSz = gr.ScreenSize;
            pos   = obj.stg.connFigPos;
            pos(4) = scrSz(4);    % make it as tall as the screen
        
            obj.hFig = figure('Name','Connectivity', ...
                'NumberTitle','off', ...
                'MenuBar','none', ...
                'ToolBar','none', ...
                'Position', double(pos));
        
            bg = get(obj.hFig,'Color');   % figure background
        
            % === Top control strip ===
            ctrlH = 0.12;
        
            % Window size popup (1:0.5:10)
            uicontrol('Parent',obj.hFig, 'Style','text', ...
                'Units','normalized', ...
                'Position',[0.02 1-ctrlH+0.01 0.20 0.05], ...
                'String','Window size [s]:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);
        
            winOptions = 1:0.5:10;
            winStr     = arrayfun(@(x)sprintf('%.1f',x), winOptions, 'UniformOutput',false);
        
            obj.hPopupWin = uicontrol('Parent',obj.hFig, 'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.21 1-ctrlH+0.01 0.15 0.05], ...
                'String',winStr, ...
                'Value', find(winOptions==obj.winSizeS,1), ...
                'Callback',@(src,evt)obj.cbPopupWin(src), ...
                'BackgroundColor', bg);
        
            % Step size popup (0.1:0.1:0.9)
            uicontrol('Parent',obj.hFig, 'Style','text', ...
                'Units','normalized', ...
                'Position',[0.38 1-ctrlH+0.01 0.18 0.05], ...
                'String','Step [s]:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);
        
            stepOptions = 0.1:0.1:0.9;
            stepStr     = arrayfun(@(x)sprintf('%.1f',x), stepOptions, 'UniformOutput',false);
        
            obj.hPopupStep = uicontrol('Parent',obj.hFig, 'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.50 1-ctrlH+0.01 0.18 0.05], ...
                'String',stepStr, ...
                'Value', find(abs(stepOptions-obj.stepSizeS)<1e-6,1), ...
                'Callback',@(src,evt)obj.cbPopupStep(src), ...
                'BackgroundColor', bg);
        
            % Apply and Next buttons
            obj.hButtonApply = uicontrol('Parent',obj.hFig, 'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.87 1-ctrlH+0.04 0.10 0.05], ...
                'String','Apply', ...
                'Callback',@(src,evt)obj.cbApply(), ...
                'BackgroundColor', bg);
        
            obj.hButtonNext = uicontrol('Parent',obj.hFig, 'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.87 1-ctrlH 0.10 0.05], ...
                'String','Next', ...
                'Callback',@(src,evt)obj.cbNext(), ...
                'BackgroundColor', bg);
        
            % Global title at top
            obj.hTitle = uicontrol('Parent',obj.hFig, 'Style','text', ...
                'Units','normalized', ...
                'Position',[0.25 0.96 0.50 0.03], ...
                'String','Connectivity', ...
                'FontWeight','bold', ...
                'HorizontalAlignment','center', ...
                'BackgroundColor', bg);
        
            % === Axes area for 5 bands ===
            axTop    = 1 - ctrlH - 0.02;
            axBottom = 0.02;
            axTotalH = axTop - axBottom;
            gap      = 0.05;
            axH      = (axTotalH - (obj.numBands-1)*gap) / obj.numBands;
            
            labelColWidth = 0.2;   % left column for band labels
            axLeft        = labelColWidth + 0.02;  % small gap after labels
            axWidth       = 0.80;   % keep matrices wide
            
            obj.hAx = gobjects(obj.numBands,1);
            for b = 1:obj.numBands
                y = axTop - b*(axH + gap) + gap;
                obj.hAx(b) = axes('Parent',obj.hFig, ...
                    'Units','normalized', ...
                    'Position',[axLeft y axWidth axH]);
            end
            
            % Band labels in the left column (flush to figure left)
            freq_bands = [1 4; 4 8; 8 13; 13 30; 30 80];
            bandNames  = {'Delta','Theta','Alpha','Beta','Gamma'};
            
            obj.hBandLabel = gobjects(obj.numBands,1);
            for b = 1:obj.numBands
                posAx = get(obj.hAx(b), 'Position');   % [x y w h] of axis
                xTxt  = 0.01;                          % near left edge of figure
                yTxt  = posAx(2) + posAx(4)/2 - 0.02;  % vertically centered
            
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
            fprintf('Window size set to %.1f s\n', obj.winSizeS);
        end
        
        function cbPopupStep(obj, src)
            stepOptions = 0.1:0.1:0.9;
            idx = src.Value;
            obj.stepSizeS = stepOptions(idx);
            fprintf('Step size set to %.1f s\n', obj.stepSizeS);
        end



        % Apply button callback
        function cbApply(obj)
            obj.currentStartS = 0;  % start at beginning for now
            fprintf('Apply: win = %.3f s, step = %.3f s, start = %.3f s\n', ...
                    obj.winSizeS, obj.stepSizeS, obj.currentStartS);
        
            obj.computeAndPlot(obj.currentStartS);
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
        function computeAndPlot(obj, startS)
            winLenS = obj.winSizeS;
            [winData, fs] = obj.getWindowData(startS, winLenS);
        
            Cmat = obj.compute_msc_onewindow(winData, fs);
            % numBands = size(Cmat,3);
            
            % Update global title with time window
            obj.hTitle.String = sprintf('Connectivity %.2f–%.2f s', startS, startS + winLenS);
        
            chNames = obj.controlObj.signalObj.plotTbl.ChName;
        
            for b = 1:obj.numBands
                C = Cmat(:,:,b);
                ax = obj.hAx(b);
                axes(ax); %#ok<LAXES>
                imagesc(ax, C);
                axis(ax,'image');
                colorbar(ax);
        
                % No per-axes title
                % Title info is in obj.hTitle
        
                set(ax,'XTick',1:numel(chNames),'XTickLabel',chNames, ...
                       'YTick',1:numel(chNames),'YTickLabel',chNames, ...
                       'XTickLabelRotation',90);
            end
        
            % Update band labels 
           


        end


        function cbNext(obj)
            % Move window by step and recompute
            obj.currentStartS = obj.currentStartS + obj.stepSizeS;
            fprintf('Next: win = %.3f s, step = %.3f s, new start = %.3f s\n', ...
                    obj.winSizeS, obj.stepSizeS, obj.currentStartS);
        
            obj.computeAndPlot(obj.currentStartS);
        end
    end
end
