classdef specWindow < handle
    properties
        controlObj
        stg
        key

        hFig
        hAx
        

        hPopupChannel
        hPopupSpecWin
        hPopupOverlap

        hButtonApply
        hTitle

        selectedChannel = 1;

        % Spectrogram parameters
        specWinS   = 0.5;   % window length [s]
        specOverlap = 0.5;  % fraction (0–1)
    end

    methods
        function obj = specWindow(ctrlObj)

            obj.controlObj = ctrlObj;
            obj.stg = stgs;
            obj.key = keyShortTbl;

            pos = obj.stg.connFigPos;

            obj.hFig = figure('Name','Spectrogram', ...
                'NumberTitle','off', ...
                'MenuBar','none', ...
                'ToolBar','none', ...
                'Position', double(pos), ...
                'CloseRequestFcn', @(src,evt)obj.onClose());

            bg = get(obj.hFig,'Color');

            % === Layout ===
            rowH  = 0.05;
            gapV  = 0.015;
            topY  = 1 - gapV;

            % Title
            obj.hTitle = uicontrol('Parent',obj.hFig,'Style','text', ...
                'Units','normalized', ...
                'Position',[0.25 topY-rowH 0.5 rowH], ...
                'String','Spectrogram', ...
                'FontWeight','bold', ...
                'HorizontalAlignment','center', ...
                'BackgroundColor', bg);

            % Controls row
            y2 = topY - 2*rowH - gapV;

            tbl = obj.controlObj.signalObj.plotTbl;
            chNames = tbl.ChName;

            % Channel
            uicontrol('Parent',obj.hFig,'Style','text', ...
                'Units','normalized', ...
                'Position',[0.02 y2 0.12 rowH], ...
                'String','Channel:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);

            obj.hPopupChannel = uicontrol('Parent',obj.hFig,'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.14 y2 0.18 rowH], ...
                'String', chNames, ...
                'Value', 1, ...
                'Callback',@(src,evt)obj.cbPopupChannel(src), ...
                'BackgroundColor', bg);

            % Window length
            uicontrol('Parent',obj.hFig,'Style','text', ...
                'Units','normalized', ...
                'Position',[0.34 y2 0.18 rowH], ...
                'String','Win [s]:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);

            specWinOptions = [0.1 0.2 0.5 1 2 4];
            specWinStr = arrayfun(@(x)sprintf('%.1f',x),specWinOptions,'UniformOutput',false);

            obj.hPopupSpecWin = uicontrol('Parent',obj.hFig,'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.42 y2 0.12 rowH], ...
                'String', specWinStr, ...
                'Value', find(specWinOptions==obj.specWinS,1), ...
                'Callback',@(src,evt)obj.cbPopupSpecWin(src), ...
                'BackgroundColor', bg);

            % Overlap
            uicontrol('Parent',obj.hFig,'Style','text', ...
                'Units','normalized', ...
                'Position',[0.56 y2 0.18 rowH], ...
                'String','Overlap:', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', bg);

            overlapOptions = [0.25 0.5 0.75 0.9];
            overlapStr = arrayfun(@(x)sprintf('%.2f',x),overlapOptions,'UniformOutput',false);

            obj.hPopupOverlap = uicontrol('Parent',obj.hFig,'Style','popupmenu', ...
                'Units','normalized', ...
                'Position',[0.65 y2 0.12 rowH], ...
                'String', overlapStr, ...
                'Value', find(overlapOptions==obj.specOverlap,1), ...
                'Callback',@(src,evt)obj.cbPopupOverlap(src), ...
                'BackgroundColor', bg);

            % Apply button
            obj.hButtonApply = uicontrol('Parent',obj.hFig,'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.80 y2 0.15 rowH], ...
                'String','Apply', ...
                'Callback',@(src,evt)obj.cbApply(), ...
                'BackgroundColor', bg);

            % Axes
            obj.hAx = axes('Parent',obj.hFig, ...
                'Units','normalized', ...
                'Position',[0.08 0.1 0.85 0.65]);
        end

        % === CALLBACKS ===

        function cbPopupChannel(obj, src)
            obj.selectedChannel = src.Value;
        end

        function cbPopupSpecWin(obj, src)
            vals = [0.1 0.2 0.5 1 2 4];
            obj.specWinS = vals(src.Value);
        end

        function cbPopupOverlap(obj, src)
            vals = [0.25 0.5 0.75 0.9];
            obj.specOverlap = vals(src.Value);
        end

        function cbApply(obj)
            obj.computeAndPlot();
        end

        function onClose(obj)
            if ishghandle(obj.hFig)
                delete(obj.hFig);
            end
        end

        % === CORE ===

       function [S,F,T] = computeSpectrogram(obj)

            tbl = obj.controlObj.signalObj.plotTbl;
        
            if isempty(tbl)
                error('plotTbl is empty.');
            end
        
            ch = obj.selectedChannel;
        
            % --- Get channel-specific data ---
            x  = tbl.Data{ch};
            fs = tbl.Fs(ch);   % ✅ per-channel Fs
        
            % --- Get visible time window ---
            tLim = obj.controlObj.plotLimS;   % [tStart tEnd]
        
            if isempty(tLim) || numel(tLim) ~= 2
                error('plotLimS must be [tStart tEnd]');
            end
        
            % --- Convert time → samples ---
            k1 = max(1, floor(tLim(1) * fs) + 1);
            k2 = min(length(x), floor(tLim(2) * fs));
        
            if k2 <= k1
                error('Selected time window is invalid.');
            end
        
            xSeg = x(k1:k2);
        
            % --- Spectrogram parameters ---
            win     = round(obj.specWinS * fs);
            overlap = round(obj.specOverlap * win);
            nfft    = max(256, 2^nextpow2(win));
        
            % --- Compute spectrogram ---
            [S,F,T] = spectrogram(xSeg, hamming(win), overlap, nfft, fs);
        
            S = abs(S);
        
            % --- Shift time to match original signal timeline ---
            T = T + tLim(1);
        end
       function computeAndPlot(obj)
        
            [S,F,T] = obj.computeSpectrogram();
        
            % Limit to 0–40 Hz
            fMask = (F >= 0 & F <= 40);
            Fplot = F(fMask);
            Splot = S(fMask,:);
        
            ax = obj.hAx;
            axes(ax); %#ok<LAXES>
        
            imagesc(T, Fplot, 20*log10(Splot + eps));
            axis(ax,'xy');
        
            xlabel(ax,'Time [s]');
            ylabel(ax,'Frequency [Hz]');
        
            chName = obj.controlObj.signalObj.plotTbl.ChName{obj.selectedChannel};
        
            tLim = obj.controlObj.plotLimS;
        
            title(ax, sprintf('Spectrogram: %s (%.2f–%.2f s)', ...
                chName, tLim(1), tLim(2)));
        
            colormap(ax,"turbo");
            colorbar(ax);
        
            ylim(ax,[0 40]);
        
            set(ax,'Box','on','FontSize',10);
            yticks(ax,0:5:40);
        end
    end
end