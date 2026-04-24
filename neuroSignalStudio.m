classdef neuroSignalStudio < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NeuroSignalStudioUIFigure  matlab.ui.Figure
        Image_2                    matlab.ui.control.Image
        Image                      matlab.ui.control.Image
        UIAxes                     matlab.ui.control.UIAxes
        WellcometoNeuroSignalStudioLabel  matlab.ui.control.Label
        TimeFrequencyButton        matlab.ui.control.Button
        ContourPlotCSDButton       matlab.ui.control.Button
        BipolarMontageButton       matlab.ui.control.Button
        ImportDisplayedButton      matlab.ui.control.Button
        ImportfromOSELButton       matlab.ui.control.Button
        CombFilterButton           matlab.ui.control.Button
        BandPassFilterButton       matlab.ui.control.Button
        HPFilterButton             matlab.ui.control.Button
        CSDButton                  matlab.ui.control.Button
        AverageofSpikesButton      matlab.ui.control.Button
        FindTroughsButton          matlab.ui.control.Button
        ImportNewSignalButton      matlab.ui.control.Button
    end

    properties (Access = public)
        data
        fs
        highCutoff
        filterOrder
        time          % cell array {channel}: each entry is the time vector for that channel
        offset
        locations
        userSelChn
        channelName
        troughMean
        minPeakH
        minDis
        minPeakProm
        lowCutoff
        dataOrig
        UserIn_AverageSpikes
        obj
        EEGFullData
        ax
        fig
        figChnNames
        csdMatrix
        csdMatrixSmooth
        elecDis
        recType
        sigTbl
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, obj)
            if nargin > 1
                app.obj         = obj;
                app.EEGFullData = obj.signalObj.plotTbl;
                app.channelName = obj.signalObj.plotTbl.ChName;
                nCh             = length(app.channelName);
                app.time        = cell(nCh, 1);               % FIX: explicit cell init
                for indx_ch = 1:nCh
                    app.fs(indx_ch)      = obj.signalObj.plotTbl.Fs(indx_ch);
                    app.time{indx_ch}    = 0 : 1/app.fs(indx_ch) : ...
                        seconds(obj.signalObj.sigTbl.SigEnd(indx_ch) - ...
                                obj.signalObj.sigTbl.SigStart(indx_ch)) - 1/app.fs(indx_ch);
                end
                app.dataOrig = obj.signalObj.plotTbl.Data;
                assignin('base','nss',app);
            end
        end

        % Button pushed function: ImportDisplayedButton
        function ImportDisplayedButtonPushed(app, ~)
            if nargin > 1
                app.locations  = {};
                app.troughMean = [];
                plotTbl = app.obj.signalObj.plotTbl;
                delete(app.UIAxes.Children);
                app.fig = figure('Name','Import Displayed: NeuroSignal Studio', ...
                    'NumberTitle','on','Position',[600 100 1200 800]);
                numch    = size(plotTbl, 1);
                axHeight = 0.95 / numch;
                app.time = cell(numch, 1);                    % FIX: cell array

                for kch = 1:numch
                    app.ax = axes('Parent', app.fig, ...
                        'Position',   [0.08, 1 - kch*axHeight, 0.9, axHeight], ...
                        'XLimMode',   'manual', 'YLimMode', 'manual', ...
                        'Visible',    'on', 'Clipping', 'off', 'PickableParts', 'all');

                    plotTbl.SigStart(kch) = plotTbl.SigStart(kch) + ...
                        seconds(app.obj.signalObj.controlObj.plotLimS(1));
                    lim    = int64(app.obj.signalObj.controlObj.plotLimS * plotTbl.Fs(kch) + [1 0]);
                    lim(2) = min(lim(2), int64(length(plotTbl.Data{kch})));

                    plotTbl.Data{kch} = plotTbl.Data{kch}(lim(1):lim(2));
                    plotTbl.SigEnd(kch) = plotTbl.SigStart(kch) + ...
                        seconds(numel(plotTbl.Data{kch}) / plotTbl.Fs(kch));

                    % FIX: store per-channel time in cell
                    app.time{kch} = double(lim(1))/plotTbl.Fs(kch) : ...
                                    1/plotTbl.Fs(kch) : ...
                                    double(lim(2))/plotTbl.Fs(kch);
                    plot(app.ax, app.time{kch}, plotTbl.Data{kch});

                    app.figChnNames = annotation(app.fig, 'textbox', ...
                        'String', string(plotTbl.ChName{kch}), ...
                        'Position', [0.05, (1-kch*axHeight)-axHeight/2, 0.01, axHeight], ...
                        'EdgeColor','none','FontSize',8,'HorizontalAlignment','right');
                    if kch == numch
                        xlabel(app.ax,'Time (s)','FontSize',8,'FontWeight','bold');
                    else
                        app.ax.XTickLabel = [];
                    end
                end
                linkaxes(findobj(app.fig,'Type','axes'), 'x');

                % FIX: truncate all channels to the minimum length before cell2mat
                minLen   = min(cellfun(@numel, plotTbl.Data));
                app.data = cell2mat(cellfun(@(x) single(x(1:minLen)), ...
                    plotTbl.Data, 'UniformOutput', false));
                app.dataOrig    = app.data;
                app.channelName = plotTbl.ChName;
            end
        end

        % Button pushed function: ImportfromOSELButton
        function ImportfromOSELButtonPushed(app, ~)
            app.locations  = {};
            app.troughMean = [];
            plotTbl = app.obj.signalObj.plotTbl;
            numCh   = height(plotTbl);
            app.time = cell(numCh, 1);                        % FIX: cell array
            for indx_ch = 1:numCh
                app.time{indx_ch} = 0 : 1/plotTbl.Fs(indx_ch) : ...
                    length(plotTbl.Data{indx_ch})/plotTbl.Fs(indx_ch) - 1/plotTbl.Fs(indx_ch);
            end

            delete(app.UIAxes.Children);
            figWholeFile = figure('Name','Import Whole File: NeuroSignal Studio', ...
                'NumberTitle','on','Position',[600 100 1200 800]);
            numch    = size(plotTbl, 1);
            axHeight = 0.95 / numch;

            for kch = 1:numch
                axWF = axes('Parent', figWholeFile, ...
                    'Position',  [0.08, 1-kch*axHeight, 0.9, axHeight], ...
                    'XLimMode',  'manual','YLimMode','manual', ...
                    'Visible',   'on','Clipping','off','PickableParts','all');
                plot(axWF, app.time{kch}, plotTbl.Data{kch});  % FIX: cell indexing

                app.figChnNames = annotation(figWholeFile, 'textbox', ...
                    'String', string(plotTbl.ChName{kch}), ...
                    'Position', [0.05, (1-kch*axHeight)-axHeight/2, 0.01, axHeight], ...
                    'EdgeColor','none','FontSize',8,'HorizontalAlignment','right');

                allMin = min(cell2mat(cellfun(@min, plotTbl.Data,'UniformOutput',false)));
                allMax = max(cell2mat(cellfun(@max, plotTbl.Data,'UniformOutput',false)));
                ylim(axWF, [allMin, allMax]);

                if kch == numch
                    xlabel(axWF,'Time (s)','FontSize',8,'FontWeight','bold');
                else
                    axWF.XTickLabel = [];
                end
            end

            % FIX: truncate to minimum length before cell2mat
            minLen   = min(cellfun(@numel, plotTbl.Data));
            app.data = cell2mat(cellfun(@(x) single(x(1:minLen)), ...
                plotTbl.Data, 'UniformOutput', false));
            app.dataOrig    = app.data;
            app.channelName = plotTbl.ChName;
            linkaxes(findobj(figWholeFile,'Type','axes'), 'xy');
        end

        % Button pushed function: ImportNewSignalButton
        function ImportNewSignalButtonPushed(app, ~)
            app.locations  = {};
            app.troughMean = [];
            startpath = 'k:\*.*';
            [filen, location] = uigetfile(startpath, 'Select a signal file');
            if isequal(filen,0) || isequal(location,0)
                disp('User canceled file selection.');
                uialert(app.NeuroSignalStudioUIFigure,'File selection canceled.','Notice');
                figure(app.NeuroSignalStudioUIFigure);
                return;
            end
            matname = fullfile(location, filen);
            sigTbl  = loadSignal(matname);

            prompt    = {'Please, Enter signal location (Recording Position, e.g. "A","B"...)'};
            dlgtitle  = 'Recording Position';
            definput  = {"B"};
            dims      = [1 50];
            app.recType = inputdlg(prompt, dlgtitle, dims, definput);

            if ~isempty(app.recType)
                recPos    = string(app.recType{1}) + '-';
                app.sigTbl = sigTbl(contains(sigTbl.ChName, recPos), :);
                app.data   = cell2mat(app.sigTbl.Data);
                numTimePoints   = size(app.data, 2);           % FIX: use size(...,2)
                app.channelName = app.sigTbl.ChName;           % FIX: use app.sigTbl, not sigTbl
                app.time        = cell(length(app.channelName), 1); % FIX: cell array
                for indx_ch = 1:length(app.channelName)
                    app.fs(indx_ch)   = app.sigTbl.Fs(indx_ch);
                    app.time{indx_ch} = (0:numTimePoints-1) ./ app.fs(indx_ch);
                end

                [filenChnOr, filepChnOr] = uigetfile(startpath, ...
                    'Select .csv file order channels','MultiSelect','on');
                if ~(isequal(filenChnOr,0) || isequal(filepChnOr,0))
                    channelorder = table2array(readtable(fullfile(filepChnOr, filenChnOr)));
                    app.data        = app.data(channelorder, :);
                    app.channelName = app.channelName(channelorder, :);
                else
                    disp('User canceled file selection.');
                end

                app.dataOrig  = app.data;
                disp('File loaded successfully.');

                fig = figure('Name','New Signal: NeuroSignal Studio','Position',[600 100 1200 800]);
                ax  = axes(fig);
                app.offset = 2.5 * 1500;
                data       = flipud(app.data);
                yAxisMColC = [];
                MC         = max(max(abs(data))) * 2;
                yAxisM     = MC * size(data, 1);
                delete(app.UIAxes.Children);
                hold(ax,'on');
                for i = 1:size(app.data, 1)
                    plot(ax, app.time{1}, data(i,:) + yAxisM); % FIX: cell index {1}
                    yAxisMColC(i,1) = yAxisM;
                    yAxisM = yAxisM - MC;
                end
                title(ax, filen);
                yAxisMColC = flipud(yAxisMColC)';
                set(ax,'YTick', yAxisMColC);
                axis(ax, [0, inf, MC*0.5, (MC*size(data,1)) + MC*0.5]);
                yticklabels(ax, arrayfun(@(x) ['Ch ',num2str(x)], app.channelName, 'UniformOutput',false));
                hold(ax,'off');
                app.UserIn_AverageSpikes = {};
            else
                disp('User canceled the input.');
                figure(app.NeuroSignalStudioUIFigure);
            end
            assignin('base','nss',app);
        end

        % Button pushed function: FindTroughsButton
        function FindTroughsButtonPushed(app, ~)
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end
            prompt    = {'MinPeakHeight :';'MinPeakDistance (as Sample)';'MinPeakProminence'};
            dlgtitle  = 'Input Required';
            fs_general = app.fs(1);
            if     fs_general == 2000, windowSize = round(fs_general/16);
            elseif fs_general == 5000, windowSize = round(fs_general/40);
            else,                      windowSize = 125;
            end
            definput = {'5'; string(windowSize); '0.8'};
            dims     = [1 30];
            UserIn   = inputdlg(prompt, dlgtitle, dims, definput);
            if isempty(UserIn)
                disp('User canceled the input.');
                figure(app.NeuroSignalStudioUIFigure);
                return;
            end

            app.minPeakH    = str2double(UserIn{1});
            app.minDis      = str2double(UserIn{2});
            app.minPeakProm = str2double(UserIn{3});
            troughs = {};
            for i = 1:size(app.data,1)
                [peaks, locs] = findpeaks(-app.data(i,:), ...
                    'MinPeakHeight',     app.minPeakH, ...
                    'MinPeakDistance',   app.minDis, ...
                    'MinPeakProminence', app.minPeakProm, ...
                    'WidthReference',    'halfheight');
                troughs{i,1}       = -peaks;
                app.locations{i,1} = locs;
                disp(['Ch', num2str(i), ': Troughs were found!'])
            end

            prompt   = {'Enter channel number: '};
            dlgtitle = 'Channel Required to Plot';
            definput = {'1'};
            dims     = [1 20];
            UserIn   = inputdlg(prompt, dlgtitle, dims, definput);
            if isempty(UserIn)
                disp('User canceled the input.');
                figure(app.NeuroSignalStudioUIFigure);
                return;
            end

            app.AverageofSpikesButton.BackgroundColor = [0.94 0.94 0.94];
            app.userSelChn = str2double(UserIn{1});
            disp(['User entered: ', num2str(app.userSelChn)]);

            tVec = app.time{app.userSelChn};               % FIX: cell indexing

            % FIX: safe check – app.obj may be empty when launched standalone
            standaloneMode = isempty(app.obj) || ...
                (~isstruct(app.obj) && ~isobject(app.obj));
            if standaloneMode
                app.Image_2.Visible = 'on';
                app.Image.Visible   = "off";
                app.UIAxes.Visible  = 'on';
                hold(app.UIAxes,"off");
                plot(app.UIAxes, tVec, app.data(app.userSelChn,:), 'LineWidth',1.5);
                hold(app.UIAxes,'on');
                plot(app.UIAxes, ...
                    app.locations{app.userSelChn,1} / app.fs(app.userSelChn), ...
                    troughs{app.userSelChn,1}, 'x','MarkerSize',8,'LineWidth',2);
                title(app.UIAxes,'EEG and Troughs');
                ylabel(app.UIAxes, sprintf('Chn %s', app.channelName{app.userSelChn}));
                xlabel(app.UIAxes,"Time(s)");
                app.UIAxes.YTickLabel = {};
                app.UIAxes.YTick      = [];
                hold(app.UIAxes,"off");
            else
                figure('Name','Find Troughs: NeuroSignal Studio');
                plot(tVec, app.data(app.userSelChn,:), 'LineWidth',1.5);
                hold on
                startT = tVec(1);                          % FIX: use actual start time
                plot((app.locations{app.userSelChn,1}/app.fs(app.userSelChn)) + startT, ...
                    troughs{app.userSelChn,1}, 'x','MarkerSize',8,'LineWidth',2);
                title('EEG and Troughs');
                ylabel(sprintf('Chn %s', app.channelName{app.userSelChn}));
                xlabel("Time(s)");
                hold off
            end
        end

        % Button pushed function: CSDButton
        function CSDButtonPushed(app, ~)
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end

            prompt   = {'Enter electrode spacing (in µm). For unequal distances use format: [d1 d2 d3 ... dn-1]'};
            dlgtitle = 'Input Required';
            definput = {'50'};
            dims     = [1 50];
            app.elecDis = inputdlg(prompt, dlgtitle, dims, definput);
            if isempty(app.elecDis)
                disp('User canceled the input.');
                return;
            end

            fs_general = app.fs(1);
            answer_channel_selection = questdlg( ...
                'Go to channel selection menu? (Click Yes for hemispheric laminar electrodes)', ...
                'Channel selection','Yes','No','No');
            app.ContourPlotCSDButton.BackgroundColor = [0.94 0.94 0.94];

            userValue = str2num(app.elecDis{1}); %#ok<ST2NM>
            if isempty(userValue)
                errordlg('Invalid input. Please enter numeric values in brackets.');
                return;
            end

            % FIX: initialise shared variables BEFORE any branching
            waitDialog   = [];
            channelName  = app.channelName;

            % -------------------------------------------------------
            if isscalar(userValue)   % ---- Uniform electrode spacing
            % -------------------------------------------------------
                disp(['User entered: ',num2str(userValue),'µm  >>Equal spacing CSD']);
                interElectrodeDistance = userValue * 1e-6;
                unitLength   = 1000;
                unitCurrent  = 1e6;
                conductivity = 0.3;

                if ~isempty(app.troughMean)
                    choice = questdlg('An averaged signal is available. Use it?', ...
                        'Signal Choice','Averaged','Raw','Averaged');
                    switch choice
                        case 'Averaged'
                            data_calculated = app.troughMean;
                            ttime  = (0:size(data_calculated,2)-1) / fs_general; % FIX
                            ttitle = 'CSD Map with Averaged Signals ';
                            disp('Using averaged signal for CSD...');
                        case 'Raw'
                            data_calculated = double(app.data);
                            ttime  = (0:size(data_calculated,2)-1) / fs_general; % FIX
                            ttitle = 'CSD Map with LFPs ';
                            disp('Using raw signal for CSD...');
                    end
                else
                    data_calculated = double(app.data);               % FIX: ensure double
                    ttime  = (0:size(data_calculated,2)-1) / fs_general;
                    ttitle = 'CSD Map with LFPs ';
                    disp('Using raw signal for CSD...');

                    if strcmp(answer_channel_selection,'Yes')
                        answer_hs = questdlg('Which hemisphere?', ...
                            'Hemisphere selection','Left','Right','Right');
                        switch answer_hs
                            case 'Left'
                                mask            = contains(app.channelName,'L');
                                data_calculated = data_calculated(mask,:);
                                channelName     = app.channelName(mask);
                            case 'Right'
                                mask            = contains(app.channelName,'R');
                                data_calculated = data_calculated(mask,:);
                                channelName     = app.channelName(mask);
                        end
                    end
                    waitDialog = uiprogressdlg(app.NeuroSignalStudioUIFigure, ...
                        'Title','Please Wait', ...
                        'Message','Calculating Current Source Density...', ...
                        'Indeterminate','on');
                end

                app.csdMatrix = NaN(size(data_calculated,1), size(data_calculated,2));
                for ii = 1:size(data_calculated,2)
                    for ci = 2:size(data_calculated,1)-1
                        app.csdMatrix(ci,ii) = -( ...
                            (data_calculated(ci+1,ii) - 2*data_calculated(ci,ii) + data_calculated(ci-1,ii)) ...
                            / interElectrodeDistance^2 ) * conductivity;
                    end
                end
                app.csdMatrix = app.csdMatrix(2:end-1,:);
                app.csdMatrix = app.csdMatrix / unitLength^3 * unitCurrent;

                % Simplify channel name labels
                for i = 1:length(channelName)
                    parts = split(channelName{i}, '-');      % FIX: cell{}
                    if numel(parts) > 2
                        channelName{i} = strjoin(parts(1:2),'-');
                    end
                end
                ChnCSD = channelName(2:end-1);

            % ----------------------------------------------------------
            else   % ---- Non-uniform electrode spacing
            % ----------------------------------------------------------
                disp(['User entered: ',num2str(userValue),'µm  >>Unequal spacing CSD']);
                waitDialog = uiprogressdlg(app.NeuroSignalStudioUIFigure, ...
                    'Title','Please Wait', ...
                    'Message','Calculating Current Source Density...', ...
                    'Indeterminate','on');
                interElectrodeDistance = userValue * 1e-6;
                unitLength   = 1000;
                unitCurrent  = 1e6;
                conductivity = 0.3;

                if ~isempty(app.troughMean)
                    choice = questdlg('An averaged signal is available. Use it?', ...
                        'Signal Choice','Averaged','Raw','Averaged');
                    switch choice
                        case 'Averaged'
                            data_calculated = app.troughMean;
                            ttime  = (0:size(data_calculated,2)-1) / fs_general; % FIX
                            ttitle = 'CSD Map with Averaged Signals ';
                            disp('Using averaged signal for CSD...');
                        case 'Raw'
                            data_calculated = double(app.data);
                            ttime  = (0:size(data_calculated,2)-1) / fs_general;
                            ttitle = 'CSD Map with LFPs ';
                            disp('Using raw signal for CSD...');
                    end
                else
                    data_calculated = double(app.data);
                    ttime  = (0:size(data_calculated,2)-1) / fs_general;
                    ttitle = 'CSD Map with LFPs ';
                    disp('Using raw signal for CSD...');
                end

                app.csdMatrix = NaN(size(data_calculated,1), size(data_calculated,2));
                N = size(app.csdMatrix,1);
                for ii = 1:size(app.csdMatrix,2)
                    for i = 2:N-1
                        h1  = interElectrodeDistance(i-1);
                        h2  = interElectrodeDistance(i);
                        nom = data_calculated(i+1,ii)*h1 + data_calculated(i-1,ii)*h2 ...
                            - data_calculated(i,ii)*(h1+h2);
                        den = 0.5*(h1+h2)*h1*h2;
                        app.csdMatrix(i,ii) = -conductivity * (nom/den);
                    end
                end
                app.csdMatrix = app.csdMatrix(2:end-1,:);
                app.csdMatrix = app.csdMatrix / unitLength^3 * unitCurrent;

                for i = 1:length(channelName)
                    parts = split(channelName{i}, '-');      % FIX: cell{}
                    if numel(parts) > 2
                        channelName{i} = strjoin(parts(1:2),'-');
                    end
                end
                ChnCSD = channelName(2:end-1);
            end  % end scalar / non-scalar

            % ---- Visualise CSD as stacked line plots ----
            fprintf('Plotting CSD stacked time series...\n');
            figure('Name','Current Source Density: NeuroSignal Studio','Position',[100 100 1200 800]);
            set(gcf,'OuterPosition',[43 87 557 677]);
            set(findall(gcf,'-property','FontSize'),'FontSize',10);

            subplot(1,2,1)
            varNames1 = [matlab.lang.makeValidName(channelName(:)); {'Time_s'}];
            dataTime  = [data_calculated; ttime];
            dataTbl   = array2table(dataTime','VariableNames',varNames1);
            p1 = stackedplot(dataTbl,'XVariable','Time_s'); title('LFPs')
            ax_p1 = findobj(p1.NodeChildren,'Type','Axes');
            set(ax_p1,'YLim',[min(data_calculated,[],'all'), max(data_calculated,[],'all')]);

            subplot(1,2,2)
            varNames2 = [matlab.lang.makeValidName(ChnCSD(:)); {'Time_s'}];
            csdTime   = [app.csdMatrix; ttime];
            csdTbl    = array2table(csdTime','VariableNames',varNames2);
            p2 = stackedplot(csdTbl,'XVariable','Time_s'); title('CSD')
            ax_p2 = findobj(p2.NodeChildren,'Type','Axes');  % FIX: was p1.NodeChildren
            set(ax_p2,'YLim',[min(app.csdMatrix,[],'all'), max(app.csdMatrix,[],'all')]);

            % ---- Visualise CSD as colour maps ----
            figure('Name','Current Source Density Map: NeuroSignal Studio','Position',[600 100 1200 800]);
            set(gcf,'OuterPosition',[586 87 557 677]);
            set(findall(gcf,'-property','FontSize'),'FontSize',10);

            subplot(1,2,1)
            imagesc(ttime, 1:size(data_calculated,1), flipud(data_calculated));
            colormap(jet);
            M  = max(abs(data_calculated(:)));
            cc = colorbar('SouthOutside');
            clim([-M, M]);
            cc.YTick = [-M, 0, M];
            cc.YTickLabel = {'', '\muV', ''};
            axis xy;
            xlabel('Time (s)'); ylabel('Channel');
            title('Voltage Map of LFPs');
            yticks(1:size(data_calculated,1));
            yticklabels(flipud(channelName));
            hold on;
            for ch = 1:size(data_calculated,1)
                dmin  = min(data_calculated(ch,:));
                dmax  = max(data_calculated(ch,:));
                if dmax > dmin
                    vNorm = (data_calculated(ch,:) - dmin) / (dmax - dmin);
                else
                    vNorm = zeros(1, size(data_calculated,2));
                end
                yOff = size(data_calculated,1) - ch + 1;
                plot(ttime, vNorm + yOff - 0.5,'k');
            end
            hold off;

            subplot(1,2,2)
            im1 = imagesc(ttime, 1:size(app.csdMatrix,1), flipud(app.csdMatrix));
            im1.AlphaData = 1;
            axis xy;
            set(gca,'YDir','normal');
            colormap(jet);
            xlabel('Time (s)');
            c = colorbar('SouthOutside');
            vmax = max(abs(app.csdMatrix(:)),[],'omitnan');
            clim([-vmax, vmax]);
            c.YTick = [-vmax, 0, vmax];
            c.YTickLabel = {'Sink','CSD(\muA/mm^3)','Source'};
            c.TickDirection = 'in'; c.FontSize = 10; c.FontWeight = 'normal';
            hold on;
            tSig  = data_calculated;
            tSigN = normalize(tSig(2:end-1,:), 2, 'range');
            ChnFlip = flipud(ChnCSD);
            MC    = max(abs(tSigN(:)));
            if MC == 0, MC = 1; end
            yAxisM     = MC * size(tSigN,1);
            yAxisMColC = zeros(size(tSigN,1),1);
            title([ttitle ' (\color{blue}sink,\color{red}source\color{black})']);
            for i = 1:size(tSigN,1)
                plot(ttime, tSigN(i,:) + yAxisM - MC*0.5, 'k');
                yAxisMColC(i) = yAxisM;
                yAxisM = yAxisM - MC;
            end
            yAxisMColC = flipud(yAxisMColC)';
            set(gca,'YTick',yAxisMColC,'YDir','normal');
            axis([0, inf, MC*0.5, MC*size(tSigN,1)+MC*0.5]);
            yticklabels(arrayfun(@(x) num2str(x), ChnFlip,'UniformOutput',false));
            xlim([ttime(1), ttime(end)]);
            hold off;
            disp('CSD map superimposed on time series: done.')

            disp('Plotting CSD as time series completed.');
            if ~isempty(waitDialog) && isvalid(waitDialog)  % FIX: guard close
                close(waitDialog);
            end
        end

        % Button pushed function: AverageofSpikesButton
        function AverageofSpikesButtonPushed(app, ~)
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end
            if isempty(app.userSelChn)
                warndlg('Please use the "Find Troughs" button first!','Warning');
                return;
            end

            maxDuration = min(app.locations{app.userSelChn,1}(1), ...
                              size(app.data,2) - app.locations{app.userSelChn,1}(end));
            prompt   = {['Enter duration around spikes (samples). Must be < ', num2str(maxDuration),'.']};
            dlgtitle = 'Input Required';
            definput = {'140'};
            dims     = [1 30];
            app.UserIn_AverageSpikes = inputdlg(prompt, dlgtitle, dims, definput);
            if isempty(app.UserIn_AverageSpikes)
                disp('User canceled the input.');
                return;
            end

            durationAroundSpike = str2double(app.UserIn_AverageSpikes{1});
            disp(['User entered: ', num2str(-durationAroundSpike),' - +',num2str(durationAroundSpike)]);

            troughMatrix = {};
            locs = app.locations{app.userSelChn,1};
            for troughLoc = 1:length(locs)
                idx = locs(troughLoc);
                for ci = 1:size(app.data,1)
                    troughMatrix{ci,troughLoc} = app.data(ci, idx-durationAroundSpike:idx+durationAroundSpike);
                end
            end

            app.troughMean = zeros(size(app.data,1), 2*durationAroundSpike+1);
            for i = 1:size(app.data,1)
                channelData        = cell2mat(troughMatrix(i,:)');
                app.troughMean(i,:) = mean(channelData, 1);
            end

            fs_general = app.fs(1);                          % FIX: define locally
            tAvg       = (0:size(app.troughMean,2)-1) / fs_general;

            % FIX: safe check for standalone mode
            standaloneMode = isempty(app.obj) || ...
                (~isstruct(app.obj) && ~isobject(app.obj));
            if standaloneMode
                delete(app.UIAxes.Children(1:end));
                app.Image_2.Visible = 'on';
                app.Image.Visible   = "off";
                app.UIAxes.Visible  = 'on';
                plot(app.UIAxes, tAvg, app.troughMean', 'DisplayName','troughMean');
                title(app.UIAxes,'Average troughs for all channels');
                xlabel(app.UIAxes,'Time(s)'); ylabel(app.UIAxes,'Amplitude (µV)');
            else
                figure('Name','Average Troughs: NeuroSignal Studio', ...
                    'NumberTitle','on','Position',[600 100 1200 800]);
                plot(tAvg, app.troughMean','DisplayName','troughMean');
                title('Average troughs for all channels');
                xlabel('Time(s)'); ylabel('Amplitude (µV)');
                legend(app.channelName,'Location','southoutside', ...
                    'Orientation','horizontal','NumColumns',8);
            end
        end

        % Button pushed function: HPFilterButton
        function HPFilterButtonPushed(app, ~)
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end
            prompt   = {' Enter cut off frequency (Hz): ';'Enter filter order: '};
            dlgtitle = 'Input Required';
            definput = {'2';'4'};
            dims     = [1 30];
            UserIn   = inputdlg(prompt, dlgtitle, dims, definput);
            if isempty(UserIn)
                disp('User canceled the input.');
                figure(app.NeuroSignalStudioUIFigure);
                return;
            end

            app.highCutoff  = str2double(UserIn{1});
            app.filterOrder = str2double(UserIn{2});
            disp(['HP filter: ',num2str(app.highCutoff),' Hz, order ',num2str(app.filterOrder)]);

            filteredData = zeros(size(app.dataOrig));
            for i = 1:size(app.dataOrig,1)
                d = designfilt('highpassiir','FilterOrder',app.filterOrder, ...
                    'HalfPowerFrequency',app.highCutoff,'SampleRate',app.fs(i));
                filteredData(i,:) = filtfilt(d, double(app.dataOrig(i,:))); % FIX: double
            end
            app.data = filteredData;
            disp('HP Filtering done.')

            standaloneMode = isempty(app.obj) || (~isstruct(app.obj) && ~isobject(app.obj));
            if standaloneMode
                delete(app.UIAxes.Children(1:end));
                app.Image_2.Visible = 'on'; app.Image.Visible = "off";
                app.UIAxes.Visible  = 'on';
                hold(app.UIAxes,'on');
                offset = 2500;
                for i = 1:size(app.data,1)
                    plot(app.UIAxes, app.time{i}, app.data(i,:) + offset*(i-1),'LineWidth',1.5); % FIX: cell
                end
                app.UIAxes.YTick      = offset*(0:size(app.data,1)-1);
                app.UIAxes.YTickLabel = arrayfun(@(x) ['Ch ',num2str(x)], app.channelName,'UniformOutput',false);
                hold(app.UIAxes,'off');
            else
                delete(app.fig.Children); delete(app.figChnNames);
                numch    = length(app.channelName);
                axHeight = 0.95/numch;
                for kch = 1:numch
                    app.ax = axes('Parent',app.fig, ...
                        'Position',[0.08,1-kch*axHeight,0.9,axHeight], ...
                        'XLimMode','manual','YLimMode','manual','Visible','on', ...
                        'Clipping','off','PickableParts','all');
                    plot(app.ax, app.time{kch}, app.data(kch,:));          % FIX: cell
                    app.figChnNames = annotation(app.fig,'textbox', ...
                        'String',string(app.channelName{kch}), ...
                        'Position',[0.05,(1-kch*axHeight)-axHeight/2,0.01,axHeight], ...
                        'EdgeColor','none','FontSize',8,'HorizontalAlignment','right');
                    if kch==numch, xlabel(app.ax,'Time (s)','FontSize',8,'FontWeight','bold');
                    else,          app.ax.XTickLabel = []; end
                end
                linkaxes(findobj(app.fig,'Type','axes'),'xy');
                app.fig.Name = 'High Pass Filtered Data: NeuroSignal Studio';
            end
        end

        % Button pushed function: BandPassFilterButton
        function BandPassFilterButtonPushed(app, ~)
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end
            prompt   = {' Enter low cut off frequency (Hz)';'Enter high cut off frequency (Hz)';'Enter filter order'};
            dlgtitle = 'Input Required';
            definput = {'250';'800';'4'};
            dims     = [1 30];
            isValid  = false;
            while ~isValid
                UserIn = inputdlg(prompt, dlgtitle, dims, definput);
                if isempty(UserIn)
                    disp('User canceled the input.');
                    figure(app.NeuroSignalStudioUIFigure);
                    return;
                end
                userValue1 = str2double(UserIn{1});
                userValue2 = str2double(UserIn{2});
                userValue3 = str2double(UserIn{3});
                nyquist    = app.fs(1)/2;
                if userValue2 >= nyquist
                    definput = {num2str(userValue1);num2str(userValue2);num2str(userValue3)};
                    warndlg(sprintf( ...
                        'High cut-off exceeds Nyquist (%.0f Hz). Enter a lower value.',nyquist), ...
                        'Invalid Input');
                else
                    isValid = true;
                end
            end
            disp(['BP filter: ',num2str(userValue1),'-',num2str(userValue2),' Hz, order ',num2str(userValue3)]);
            app.highCutoff  = userValue1;
            app.lowCutoff   = userValue2;
            app.filterOrder = userValue3;

            filteredData = zeros(size(app.dataOrig));
            for i = 1:size(app.dataOrig,1)
                d = designfilt('bandpassiir','FilterOrder',app.filterOrder, ...
                    'HalfPowerFrequency1',app.highCutoff, ...
                    'HalfPowerFrequency2',app.lowCutoff, ...
                    'SampleRate',app.fs(1));
                filteredData(i,:) = filtfilt(d, double(app.dataOrig(i,:))); % FIX: double
            end
            app.data = filteredData;
            disp('BP Filtering applied successfully.')

            standaloneMode = isempty(app.obj) || (~isstruct(app.obj) && ~isobject(app.obj));
            if standaloneMode
                delete(app.UIAxes.Children(1:end));
                app.Image_2.Visible = 'on'; app.Image.Visible = "off";
                app.UIAxes.Visible  = 'on';
                hold(app.UIAxes,'on');
                offset = 2500;
                for i = 1:size(app.data,1)
                    plot(app.UIAxes, app.time{i}, app.data(i,:)+offset*(i-1),'LineWidth',1.5); % FIX: cell
                end
                app.UIAxes.YTick      = offset*(0:size(app.data,1)-1);
                app.UIAxes.YTickLabel = arrayfun(@(x) ['Ch ',num2str(x)], app.channelName,'UniformOutput',false);
                hold(app.UIAxes,'off');
            else
                delete(app.fig.Children); delete(app.figChnNames);
                numch    = length(app.channelName);
                axHeight = 0.95/numch;
                for kch = 1:numch
                    app.ax = axes('Parent',app.fig, ...
                        'Position',[0.08,1-kch*axHeight,0.9,axHeight], ...
                        'XLimMode','manual','YLimMode','manual','Visible','on', ...
                        'Clipping','off','PickableParts','all');
                    plot(app.ax, app.time{kch}, app.data(kch,:));          % FIX: cell
                    app.figChnNames = annotation(app.fig,'textbox', ...
                        'String',string(app.channelName{kch}), ...
                        'Position',[0.05,(1-kch*axHeight)-axHeight/2,0.01,axHeight], ...
                        'EdgeColor','none','FontSize',8,'HorizontalAlignment','right');
                    if kch==numch, xlabel(app.ax,'Time (s)','FontSize',8,'FontWeight','bold');
                    else,          app.ax.XTickLabel = []; end
                end
                linkaxes(findobj(app.fig,'Type','axes'),'xy');
                app.fig.Name = 'Band Pass Filtered Data: NeuroSignal Studio';
            end
        end

        % Button pushed function: CombFilterButton
        function CombFilterButtonPushed(app, ~)
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end
            Q   = 35;
            foe = 50;
            filteredData = zeros(size(app.data));
            for i = 1:size(app.data,1)
                BW = 2*(foe/(app.fs(i)/2))/Q;
                [b,a] = iircomb(round(app.fs(i)/foe), BW, 'notch');
                filteredData(i,:) = filtfilt(b, a, double(app.data(i,:))); % FIX: double
            end
            app.data = filteredData;
            disp('Comb Filter applied successfully.')

            standaloneMode = isempty(app.obj) || (~isstruct(app.obj) && ~isobject(app.obj));
            if standaloneMode
                delete(app.UIAxes.Children(1:end));
                app.Image_2.Visible = 'on'; app.Image.Visible = "off";
                app.UIAxes.Visible  = 'on';
                hold(app.UIAxes,'on');
                offset = 2500;
                for i = 1:size(app.data,1)
                    plot(app.UIAxes, app.time{i}, app.data(i,:)+offset*(i-1),'LineWidth',1.5); % FIX: cell
                end
                app.UIAxes.YTick      = offset*(0:size(app.data,1)-1);
                app.UIAxes.YTickLabel = arrayfun(@(x) ['Ch ',num2str(x)], app.channelName,'UniformOutput',false);
                hold(app.UIAxes,'off');
            else
                delete(app.fig.Children); delete(app.figChnNames);
                numch    = length(app.channelName);
                axHeight = 0.95/numch;
                for kch = 1:numch
                    app.ax = axes('Parent',app.fig, ...
                        'Position',[0.08,1-kch*axHeight,0.9,axHeight], ...
                        'XLimMode','manual','YLimMode','manual','Visible','on', ...
                        'Clipping','off','PickableParts','all');
                    plot(app.ax, app.time{kch}, app.data(kch,:));          % FIX: cell
                    app.figChnNames = annotation(app.fig,'textbox', ...
                        'String',string(app.channelName{kch}), ...
                        'Position',[0.05,(1-kch*axHeight)-axHeight/2,0.01,axHeight], ...
                        'EdgeColor','none','FontSize',8,'HorizontalAlignment','right');
                    if kch==numch, xlabel(app.ax,'Time (s)','FontSize',8,'FontWeight','bold');
                    else,          app.ax.XTickLabel = []; end
                end
                linkaxes(findobj(app.fig,'Type','axes'),'xy');
                app.fig.Name = 'Comb Filtered Data: NeuroSignal Studio';
            end
        end

        % Button pushed function: BipolarMontageButton
        function BipolarMontageButtonPushed(app, ~)
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end
            bipolarEEG  = app.data(1:end-1,:) - app.data(2:end,:);
            numChannels = length(app.channelName);
            channelLabels = cell(1, numChannels-1);
            for i = 1:numChannels-1
                channelLabels{i} = strcat(string(app.channelName{i}),'-',string(app.channelName{i+1}));
            end
            figBipolar = figure('Name','Bipolar Montage: NeuroSignal Studio', ...
                'NumberTitle','on','Position',[600 100 1200 800]);
            numch    = length(channelLabels);
            axHeight = 0.95/numch;
            for kch = 1:numch
                ax = axes('Parent',figBipolar, ...
                    'Position',[0.08,1-kch*axHeight,0.9,axHeight], ...
                    'XLimMode','manual','YLimMode','manual', ...
                    'Visible','on','Clipping','off','PickableParts','all');
                plot(ax, app.time{kch}, bipolarEEG(kch,:));                % FIX: cell
                app.figChnNames = annotation(figBipolar,'textbox', ...
                    'String',string(channelLabels{kch}), ...
                    'Position',[0.05,(1-kch*axHeight)-axHeight/2,0.01,axHeight], ...
                    'EdgeColor','none','FontSize',8,'HorizontalAlignment','right');
                ylim(ax,[min(bipolarEEG,[],'all'), max(bipolarEEG,[],'all')]);
                if kch==numch, xlabel(ax,'Time (s)','FontSize',8,'FontWeight','bold');
                else,          ax.XTickLabel = []; end
            end
            linkaxes(findobj(figBipolar,'Type','axes'),'x');
        end

        % Button pushed function: ContourPlotCSDButton
        function ContourPlotCSDButtonPushed(app, ~)
            if ~isempty(app.elecDis) && ~isempty(app.csdMatrix)
                figure('Name','Contour Plot CSD: NeuroSignal Studio','Position',[600 100 1200 800]);
                set(gcf,'OuterPosition',[1128 87 306 677]);
                set(findall(gcf,'-property','FontSize'),'FontSize',10);

                nT   = size(app.csdMatrix,2);
                tCSD = app.time{1}(1:nT);                   % FIX: cell, correct length
                contourf(tCSD, 1:size(app.csdMatrix,1), flipud(app.csdMatrix), ...
                    15,'-.','edgecolor','none');
                title('Contour Plot of CSD');
                colormap('jet');
                xlabel('Time (s)');
                c = colorbar('SouthOutside');
                vmax = max(abs(app.csdMatrix(:)),[],'omitnan');
                clim([-vmax, vmax]);
                c.YTick = [-vmax, 0, vmax];
                c.YTickLabel = {'Sink','CSD(\muA/mm^3)','Source'};
                c.TickDirection = 'in'; c.FontSize = 12;

                csdNorm = normalize(app.csdMatrix, 2, 'range');
                MC = max(abs(csdNorm(:)));
                if MC == 0, MC = 1; end
                n  = size(app.csdMatrix,1);
                yAxisMColC = flipud((MC:MC:MC*n)')';
                set(gca,'YTick',yAxisMColC);
                yticklabels(arrayfun(@(x) num2str(x), ...
                    flipud(app.channelName(2:end-1)),'UniformOutput',false));
            else
                if isempty(app.data)
                    warndlg('Please load the signal first!','Warning');
                else
                    warndlg('Please use the "CSD" button first!','Warning');
                end
            end
        end

        % Button pushed function: TimeFrequencyButton (Scalogram)
        function TimeFrequencyButtonPushed(app, ~)
            if ~license('test','Wavelet_Toolbox')
                warndlg('Wavelet Toolbox is NOT installed.','Warning');
                return;
            end
            if isempty(app.data)
                warndlg('Please load the signal first!','Warning');
                return;
            end

            if max(app.fs) > 5000
                answer = questdlg(['Sampling rate is ',num2str(max(app.fs)/1000), ...
                    ' kHz. Resample to 5 kHz?'],'Confirm','Yes','No','No');
                switch answer
                    case 'Yes'
                        wdlg = uiprogressdlg(app.NeuroSignalStudioUIFigure, ...
                            'Title','Please Wait','Message','Resampling...','Indeterminate','on');
                        disp('Resampling to 5 kHz...')
                        fs_res = 5000;
                        d_res  = zeros(size(app.data,1), ...
                            ceil(size(app.data,2)*fs_res/app.fs(1)));
                        for ch = 1:size(app.data,1)
                            d_res(ch,:) = resample(double(app.data(ch,:)), fs_res, app.fs(ch), floor(app.fs(ch)/2));
                        end
                        fs  = fs_res;
                        d_res = d_res';
                        disp('Resampling done.')
                        close(wdlg);
                    case 'No'
                        d_res = double(app.data)';
                        fs    = app.fs(1);
                    otherwise
                        return;
                end
            else
                d_res = double(app.data)';
                fs    = app.fs(1);
            end

            dataL  = d_res';   % channel x samples
            prompt = {'Enter channel number:';'Enter Low Frequency:';'Enter High Frequency'};
            dlgtitle = 'Scalogram Parameters';
            definput = {'1';'80';'800'};
            dims   = [1 40];
            UserIn = inputdlg(prompt, dlgtitle, dims, definput);
            if isempty(UserIn), return; end

            wdlg = uiprogressdlg(app.NeuroSignalStudioUIFigure, ...
                'Title','Please Wait','Message','Computing scalogram...','Indeterminate','on');
            ch_num  = str2double(UserIn{1});
            fLow    = str2double(UserIn{2});
            fHigh   = str2double(UserIn{3});
            disp(['TF for channel ',num2str(ch_num),' ...']);

            nSamp   = size(d_res,1);
            tVec    = (0:nSamp-1) / fs;                     % FIX: local var, not app.time
            fb = cwtfilterbank('SignalLength',nSamp,'SamplingFrequency',fs, ...
                'VoicesPerOctave',24,'FrequencyLimits',[2 fs/2]);
            [cfs, frq] = cwt(dataL(ch_num,:), FilterBank=fb);

            figure; cwt(dataL(ch_num,:),fs); colormap jet;

            figure('Name','Scalogram: NeuroSignal Studio','NumberTitle','on','Position',[600 100 1200 800]);
            subplot(2,1,1)
            plot(tVec, dataL(ch_num,:)); axis tight;
            title("EEG Signal and Scalogram");
            xlabel("Time (s)"); ylabel({string(app.channelName{ch_num});'Amplitude'});
            subplot(2,1,2)
            surface(tVec, frq, abs(cfs));
            caxis([min(abs(cfs(:))), max(abs(cfs(:)))]);
            colormap jet; axis tight; shading flat;
            xlabel("Time (s)"); ylabel("Frequency (Hz)");
            ylim([fLow, fHigh]);
            disp(['TF for channel ',num2str(ch_num),': done.']);
            close(wdlg);
        end

        % Button pushed function: RunHFODetector
        function RunHFODetector(app, ~)
            fig          = figure('Name','HFO Detector','Position',[300 100 1000 700]);
            controlPanel = uipanel('Title','Controls','FontSize',12,'Position',[.02 .68 .28 .30]);

            uicontrol(controlPanel,'Style','pushbutton','String','Load Signal', ...
                'FontSize',10,'Position',[10 95 120 30],'Callback',@loadSignal);
            uicontrol(controlPanel,'Style','pushbutton','String','Run Ensemble', ...
                'FontSize',10,'Position',[10 50 120 30],'Callback',@runML);
            uicontrol(controlPanel,'Style','text','String','Channel Num:', ...
                'Position',[10 130 120 30],'HorizontalAlignment','left','FontSize',10);
            gtInput   = uicontrol(controlPanel,'Style','edit','String','1', ...
                'Position',[140 130 50 30],'BackgroundColor','white','FontSize',10);
            resultBox = uicontrol(controlPanel,'Style','text','String','Result: ', ...
                'FontSize',12,'FontWeight','bold','Position',[10 10 250 25], ...
                'BackgroundColor','white','ForegroundColor','black');

            axRaw       = subplot('Position',[0.35 0.55 0.6 0.35]);
            title(axRaw,'Raw Signal');
            axScalogram = subplot('Position',[0.35 0.10 0.6 0.35]);

            signalData = [];

            function loadSignal(~,~)
                chnNumber = str2double(get(gtInput,'String'));
                if isnan(chnNumber) || chnNumber > length(app.channelName) || chnNumber < 1
                    errordlg('Wrong channel number!'); return;
                end
                signalData = double(app.data(chnNumber,:));
                ChnName    = app.channelName(chnNumber,:);
                t          = (0:length(signalData)-1) / app.fs(chnNumber);
                axes(axRaw);
                plot(t, signalData,'k');
                title(['Raw Signal ', string(ChnName)]);
                xlabel('Time (s)'); ylabel('Amplitude (mV)');
                fb = cwtfilterbank('SignalLength',length(signalData), ...
                    'SamplingFrequency',app.fs(chnNumber),'VoicesPerOctave',12);
                [cfs, freq] = wt(fb, signalData);
                axes(axScalogram); cla(axScalogram);
                surface(axScalogram, t, freq, abs(cfs));
                set(axScalogram,'YDir','normal','YScale','log');
                set(axScalogram,'YTick',[10 50 100 250 500 1000 2000]);
                axis(axScalogram,'tight');
                xlabel(axScalogram,'Time (s)'); ylabel(axScalogram,'Frequency (Hz)');
                title(axScalogram,'Scalogram (Wavelet Transform)');
                colormap(axScalogram,jet); shading flat;
                set(resultBox,'String','Result: ','BackgroundColor','white','ForegroundColor','black');
            end

            function runML(~,~)
                if isempty(signalData)
                    errordlg('Load a signal first!'); return;
                end
                basePath = '\\neurodata\common stuff\OSEL\';
                oselDir  = dir(fullfile(basePath,'Open Signal Explorer and Labeler OSEL*'));
                if isempty(oselDir)
                    error('No OSEL folder found in "%s".',basePath);
                end
                modelPath = fullfile(basePath, oselDir(end).name, '\resource\','trainedModel_Ensemble.mat');
                ml   = load(modelPath);
                yfit = hfoPrediction_ML(signalData, app.fs(1), ml.trainedModel_Ensemble);
                if yfit == 0
                    result  = 'No HFO Detected';
                    bgColor = [1 0.6 0.6]; fgColor = [0 0.5 0];
                else
                    result  = 'HFO Detected!';
                    bgColor = [0.6 1 0.6]; fgColor = [0.7 0 0];
                end
                set(resultBox,'String',['Result: ',result], ...
                    'BackgroundColor',bgColor,'ForegroundColor',fgColor);
                axes(axRaw); hold on;
                yl = ylim;
                text(10,yl(2)*0.9,result,'FontSize',14,'FontWeight','bold', ...
                    'Color',fgColor,'BackgroundColor',bgColor,'EdgeColor','k','Margin',3);
                hold off;
            end

            function yfit = hfoPrediction_ML(sig, fs, trainedModel)
                filtered = func_designFilt(sig, 4, 0.1, 1000, fs, 'BPIIR');
                [KF,SkF,SeF,EeF,EF]     = Statistical_features_V2(filtered,1);
                DWT_F                    = extractDWT_V2(filtered,fs,1);
                AR_F                     = feature_AR_V2(filtered,4,1);
                [PSD_F,~,dP,tP,dtR,mP,bP,mbR,gP,frP,gfR] = feature_PSD_V2(filtered,fs);
                feats = [PSD_F dP tP dtR mP bP mbR gP frP gfR AR_F DWT_F KF SkF SeF EeF EF];
                if ismember('predictFcn',fieldnames(trainedModel))
                    [yfit,~] = trainedModel.predictFcn(feats);
                else
                    [yfit,~] = predict(trainedModel,feats);
                end
            end

            function fs = func_designFilt(sig,n,f1,f2,fs_in,type)
                switch type
                    case 'BPIIR'
                        F = designfilt('bandpassiir','FilterOrder',n, ...
                            'HalfPowerFrequency1',f1,'HalfPowerFrequency2',f2,'SampleRate',fs_in);
                    case 'HPIRR'
                        F = designfilt('highpassiir','FilterOrder',n, ...
                            'HalfPowerFrequency',f1,'SampleRate',fs_in);
                    case 'BPFIR'
                        F = designfilt('bandpassfir','FilterOrder',n, ...
                            'CutoffFrequency1',f1,'CutoffFrequency2',f2,'SampleRate',fs_in);
                    case 'HPFIR'
                        F = designfilt('highpassfir', ...
                            'StopbandFrequency',f1-150,'PassbandFrequency',f1, ...
                            'StopbandAttenuation',55,'PassbandRipple',4, ...
                            'DesignMethod','kaiserwin','ScalePassband',false,'SampleRate',fs_in);
                end
                fs = filtfilt(F, double(sig));
            end

            function [o1,o2,o3,o4,o5] = Statistical_features_V2(sig,nCh)
                [r,c] = size(sig); if c>r, sig=sig'; end
                KF=[]; SkF=[]; SeF=[]; EeF=[]; EF=[];
                for m=1:nCh
                    KF(1,m)  = kurtosis(sig(:,m));
                    SkF(1,m) = skewness(sig(:,m));
                    SeF(1,m) = wentropy(sig(:,m),'shannon');
                    EeF(1,m) = wentropy(sig(:,m),'log energy');
                    EF(1,m)  = sum(sig(:,m).^2);
                end
                o1=KF; o2=SkF; o3=SeF; o4=EeF; o5=EF;
            end

            function x = extractDWT_V2(sig,fs,nCh)
                [r,c]=size(sig); if r<c, sig=sig'; end
                x=[];
                for m=1:nCh
                    wf  = 'db4';
                    lev = wmaxlev(fs,wf);
                    [wC,L] = wavedec(sig(:,m),lev,wf);
                    ChD   = detcoef(wC,L,lev);
                    x(1,m)= sum(ChD.^2)/numel(ChD);
                end
            end

            function x = feature_AR_V2(sig,order,nCh)
                [r,c]=size(sig); if r<c, sig=sig'; end
                x=[];
                for m=1:nCh
                    c2    = arburg(sig(:,m),order);
                    x(1,m)= sum(c2.^2)/numel(c2);
                end
            end

            function [o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11] = feature_PSD_V2(sig,fs)
                [r,c]=size(sig); if r<c, sig=sig'; end
                wLen   = round(length(sig)*2/3);
                nOvlp  = round(wLen/2);
                nfft   = 2^nextpow2(wLen);
                [pxx,ff] = pwelch(sig,hamming(wLen),nOvlp,nfft,fs);
                o1  = sum(pxx(ff>=0.5 & ff<1000));
                o2  = ff;
                o3  = sum(pxx(ff>=0.5 & ff<4));
                o4  = sum(pxx(ff>=4   & ff<8));
                o5  = o3/o4;
                o6  = sum(pxx(ff>=8   & ff<=12));
                o7  = sum(pxx(ff>=13  & ff<=30));
                o8  = o6/o7;
                o9  = sum(pxx(ff>=30  & ff<250));
                o10 = sum(pxx(ff>=250 & ff<800));
                o11 = o9/o10;
            end
        end  % RunHFODetector

    end  % methods (Access = private)

    % Component initialization
    methods (Access = private)

        function createComponents(app)
            figW = 470; figH = 480;
            src  = get(0,'MonitorPositions');
            pm   = src(1,:);
            left = pm(1) + (pm(3)-figW)/2;
            bot  = pm(2) + (pm(4)-figH)/2;

            app.NeuroSignalStudioUIFigure = uifigure('Visible','off');
            app.NeuroSignalStudioUIFigure.Position = [left bot figW figH];
            app.NeuroSignalStudioUIFigure.Name     = 'NeuroSignal Studio';

            % UIAxes
            app.UIAxes = uiaxes(app.NeuroSignalStudioUIFigure);
            title(app.UIAxes,'Multichannel Raw Signals');
            xlabel(app.UIAxes,'Time (s)'); ylabel(app.UIAxes,'Channels');
            app.UIAxes.YTick      = 0:15;
            app.UIAxes.YTickLabel = arrayfun(@num2str,1:16,'UniformOutput',false);
            app.UIAxes.YMinorTick = 'on';
            app.UIAxes.Tag        = 'EEG_axis';
            app.UIAxes.Visible    = 'off';
            app.UIAxes.Position   = [10 35 440 340];

            % --- Load buttons ---
            app.ImportNewSignalButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.ImportNewSignalButton.ButtonPushedFcn = createCallbackFcn(app,@ImportNewSignalButtonPushed,true);
            app.ImportNewSignalButton.Tag      = 'ImportNewSignal_button';
            app.ImportNewSignalButton.Position = [6 449 76 23];
            app.ImportNewSignalButton.Text     = 'Load Sig.';

            app.ImportfromOSELButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.ImportfromOSELButton.ButtonPushedFcn = createCallbackFcn(app,@ImportfromOSELButtonPushed,true);
            app.ImportfromOSELButton.Tag      = 'ImportSignalOSEL_button';
            app.ImportfromOSELButton.Position = [6 423 76 23];
            app.ImportfromOSELButton.Text     = 'Load all Sig.';

            app.ImportDisplayedButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.ImportDisplayedButton.ButtonPushedFcn = createCallbackFcn(app,@ImportDisplayedButtonPushed,true);
            app.ImportDisplayedButton.Tag      = 'ImportDisplayedSignal_button';
            app.ImportDisplayedButton.Position = [6 396 76 23];
            app.ImportDisplayedButton.Text     = 'Load Disp.';

            % --- Filter buttons ---
            app.HPFilterButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.HPFilterButton.ButtonPushedFcn = createCallbackFcn(app,@HPFilterButtonPushed,true);
            app.HPFilterButton.Tag      = 'highPassFilter_button';
            app.HPFilterButton.Position = [87 449 76 23];
            app.HPFilterButton.Text     = 'HP Filter';

            app.BandPassFilterButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.BandPassFilterButton.ButtonPushedFcn = createCallbackFcn(app,@BandPassFilterButtonPushed,true);
            app.BandPassFilterButton.Tag      = 'bandPassFilter_button';
            app.BandPassFilterButton.Position = [87 423 76 23];
            app.BandPassFilterButton.Text     = 'BP Filter';

            app.CombFilterButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.CombFilterButton.ButtonPushedFcn = createCallbackFcn(app,@CombFilterButtonPushed,true);
            app.CombFilterButton.Tag      = 'combFilter_button';
            app.CombFilterButton.Position = [87 396 76 23];
            app.CombFilterButton.Text     = 'Comb Filter';

            % --- Montage / TF buttons ---
            app.BipolarMontageButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.BipolarMontageButton.ButtonPushedFcn = createCallbackFcn(app,@BipolarMontageButtonPushed,true);
            app.BipolarMontageButton.Position = [169 449 76 23];
            app.BipolarMontageButton.Text     = 'Bip.Montage';

            app.TimeFrequencyButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.TimeFrequencyButton.ButtonPushedFcn = createCallbackFcn(app,@TimeFrequencyButtonPushed,true);
            app.TimeFrequencyButton.Tag      = 'tf_button';
            app.TimeFrequencyButton.Position = [169 423 76 23];
            app.TimeFrequencyButton.Text     = 'Scalogram';

            % FIX: RunHFODetector stored as local variable – do NOT overwrite app.TimeFrequencyButton
            hfoButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            hfoButton.ButtonPushedFcn = createCallbackFcn(app,@RunHFODetector,true);
            hfoButton.Tag      = 'hfoDetector_button';
            hfoButton.Position = [169 396 76 23];
            hfoButton.Text     = 'Run Detector';

            % --- Spike / CSD buttons ---
            app.FindTroughsButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.FindTroughsButton.ButtonPushedFcn = createCallbackFcn(app,@FindTroughsButtonPushed,true);
            app.FindTroughsButton.Tag      = 'findPeaks_button';
            app.FindTroughsButton.Position = [253 449 76 23];
            app.FindTroughsButton.Text     = 'Find Troughs';

            app.AverageofSpikesButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.AverageofSpikesButton.ButtonPushedFcn = createCallbackFcn(app,@AverageofSpikesButtonPushed,true);
            app.AverageofSpikesButton.BackgroundColor = [0.8 0.8 0.8];
            app.AverageofSpikesButton.Position = [253 423 76 23];
            app.AverageofSpikesButton.Text     = 'Avg.Spikes';

            app.CSDButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.CSDButton.ButtonPushedFcn = createCallbackFcn(app,@CSDButtonPushed,true);
            app.CSDButton.Tag      = 'csd_button';
            app.CSDButton.Position = [335 449 76 23];
            app.CSDButton.Text     = 'CSD';

            app.ContourPlotCSDButton = uibutton(app.NeuroSignalStudioUIFigure,'push');
            app.ContourPlotCSDButton.ButtonPushedFcn = createCallbackFcn(app,@ContourPlotCSDButtonPushed,true);
            app.ContourPlotCSDButton.Tag             = 'contour_button';
            app.ContourPlotCSDButton.BackgroundColor = [0.8 0.8 0.8];
            app.ContourPlotCSDButton.Position        = [335 423 76 23];
            app.ContourPlotCSDButton.Text            = 'Cont.Plt.CSD';

            % --- Welcome label ---
            app.WellcometoNeuroSignalStudioLabel = uilabel(app.NeuroSignalStudioUIFigure);
            app.WellcometoNeuroSignalStudioLabel.FontName   = 'Arial';
            app.WellcometoNeuroSignalStudioLabel.FontWeight = 'bold';
            app.WellcometoNeuroSignalStudioLabel.FontColor  = [0 0.4471 0.7412];
            app.WellcometoNeuroSignalStudioLabel.Position   = [69 138 365 207];
            app.WellcometoNeuroSignalStudioLabel.Text = { ...
                'Welcome to the NeuroSignal Studio App!'; ''; ...
                'This tool is designed to assist you with EEG signal processing.'; ''; ...
                'Simply load your EEG data,'; ...
                'configure your analysis parameters,'; ...
                'and let the app do the rest!'; ''; ...
                'If you need help, please contact Nedime Karakullukcu.'; ''; ...
                'Happy analyzing!'};

            % --- Images ---
            app.Image = uiimage(app.NeuroSignalStudioUIFigure);
            app.Image.Tag      = 'neuroSignalStudio_Icon_1';
            app.Image.Position = [186 20 120 138];
            try                                            % FIX: icon may not be on path
                app.Image.ImageSource = 'iconNeuroSignalStudio.png';
            catch
                % silently skip – icon is cosmetic
            end

            app.Image_2 = uiimage(app.NeuroSignalStudioUIFigure);
            app.Image_2.Tag     = 'neuroSignalStudio_Icon_2';
            app.Image_2.Visible = 'off';
            app.Image_2.Position = [1 1 57 48];
            try
                app.Image_2.ImageSource = 'iconNeuroSignalStudio.png';
            catch
            end

            app.NeuroSignalStudioUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        function app = neuroSignalStudio(varargin)
            createComponents(app)
            registerApp(app, app.NeuroSignalStudioUIFigure)
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.NeuroSignalStudioUIFigure)
        end
    end
end