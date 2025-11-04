classdef calculations_exported_V250205 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NeuroSignalStudioUIFigure  matlab.ui.Figure
        Image_2                    matlab.ui.control.Image
        Image                      matlab.ui.control.Image
        UIAxes                     matlab.ui.control.UIAxes
        WellcometoNeuroSignalStudioLabel  matlab.ui.control.Label
        TimeFrequencyButton       matlab.ui.control.Button
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
        data % Description
        fs
        highCutoff
        filterOrder
        time
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
        obj % obj.signalObj
        EEGFullData % obj.signalObj.plotTbl
        ax
        fig
        figChnNames
        csdMatrix
        elecDis
        % EEGSegmentData % Stores selected segment
    end


    % Callbacks that handle onomponent events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, obj)
            % Store the imported EEG signal data
            if nargin > 1 % Check if data is passed
                app.obj=obj;
                app.EEGFullData = obj.signalObj.plotTbl;
                app.fs = obj.signalObj.plotTbl.Fs(1);
                app.channelName = app.EEGFullData.ChName;
                app. dataOrig = app.EEGFullData.Data;
                app.time = 0:1/app.fs:seconds(obj.signalObj.sigTbl.SigEnd(1)-obj.signalObj.sigTbl.SigStart(1))-1/app.fs;
            end
        end
        
        % Button pushed function: ImportDisplayedButton
        function ImportDisplayedButtonPushed(app, event)
            % Store the imported EEG signal data
            if nargin > 1 % Check if data is passed
                sigTbl = app.obj.signalObj.plotTbl;
           
                delete(app.UIAxes.Children);
                app.fig = figure('Name', 'Import Displayed: NeuroSignal Studio',...
                    'NumberTitle', 'on','Position', [600, 100, 1200, 800]);
                
                numch = size(sigTbl, 1); % Number of Channel

                height = 0.95/numch;
                % Truncate each channel to plot limits
                for kch = 1 : numch
                    % Add new axes in fig
                    app.ax =  axes('Parent', app.fig, 'Position', [0.08, 1 - kch * height, 0.9, height],...
                        'XLimMode', 'manual', 'YLimMode', 'manual', ...
                        'Visible', 'on','Clipping', 'off',...
                        'PickableParts', 'all');

                    % Import displayed signal from OSEL
                    sigTbl.SigStart(kch) = sigTbl.SigStart(kch) + seconds(app.obj.signalObj.controlObj.plotLimS(1));

                    lim = int64(app.obj.signalObj.controlObj.plotLimS*sigTbl.Fs(kch) + [1 0]);
                    lim(2) = min(lim(2), length(sigTbl.Data{kch}));
                    sigTbl.Data{kch} = sigTbl.Data{kch}(lim(1) : lim(2));
                    sigTbl.SigEnd(kch) = sigTbl.SigStart(kch) + seconds(numel(sigTbl.Data{kch})/sigTbl.Fs(kch));
                    app.time = double(lim(1))/sigTbl.Fs(kch):1/sigTbl.Fs(kch):double(lim(2))/sigTbl.Fs(kch);
                    % Plot signals
                    plot( app.ax, app.time, sigTbl.Data{kch});
                    % Add Channels name to axes
                    app.figChnNames = annotation(app.fig, 'textbox', ...
                        'String', string(sigTbl.ChName{kch}), ...
                        'Position', [0.05,  (1 - kch * height)-height/2, 0.01, height], ...
                        'EdgeColor', 'none', ...
                        'FontSize', 8, ...
                        'HorizontalAlignment', 'right');

                    if kch == numch
                        xlabel(app.ax, 'Time (s)', 'FontSize', 8, 'FontWeight', 'bold');
                    else
                        app.ax.XTickLabel = [];
                    end
                end
                linkaxes(findobj(app.fig, 'Type', 'axes'), 'x');
                app.data = cell2mat(cellfun(@single, sigTbl.Data, "UniformOutput", false));
                app.dataOrig = app.data;
                app.channelName = sigTbl.ChName;


            end
        end
        
        % Button pushed function: ImportfromOSELButton
        function ImportfromOSELButtonPushed(app, event)
            
            sigTbl = app.obj.signalObj.plotTbl;
            app.time = 0:1/sigTbl.Fs(1):length(sigTbl.Data{1})/sigTbl.Fs(1)-1/sigTbl.Fs(1);
            delete(app.UIAxes.Children);
            
            figWholeFile = figure('Name', 'Import Whole File: NeuroSignal Studio',...
                'NumberTitle', 'on','Position', [600, 100, 1200, 800]);
            numch = size(sigTbl, 1); % Number of Channel
            height = 0.95/numch;

            for kch = 1 : numch
                % Add new axes in fig
              
                axWholeFile =  axes('Parent', figWholeFile, 'Position', [0.08, 1 - kch * height, 0.9, height],...
                    'XLimMode', 'manual', 'YLimMode', 'manual', ...
                    'Visible', 'on','Clipping', 'off',...
                    'PickableParts', 'all');
                % Plot signals
                plot( axWholeFile, app.time, sigTbl.Data{kch});
                
                % Add Channels name to axes
                app.figChnNames = annotation(figWholeFile, 'textbox', ...
                    'String', string(sigTbl.ChName{kch}), ...
                    'Position', [0.05,  (1 - kch * height)-height/2, 0.01, height], ...
                    'EdgeColor', 'none', ...
                    'FontSize', 8, ...
                    'HorizontalAlignment', 'right');
                ylim(axWholeFile,[min(cell2mat(cellfun(@min, sigTbl.Data, 'UniformOutput', false))) max(cell2mat(cellfun(@max, sigTbl.Data, 'UniformOutput', false)))]);
                if kch == numch
                    xlabel(axWholeFile, 'Time (s)', 'FontSize', 8, 'FontWeight', 'bold');
                else
                    axWholeFile.XTickLabel = [];
                end

            end
            app.data = cell2mat(cellfun(@single, sigTbl.Data, "UniformOutput", false));
            app.dataOrig = app.data;
            app.channelName = sigTbl.ChName;
            linkaxes(findobj(figWholeFile, 'Type', 'axes'), 'xy');

        end

        % Button pushed function: ImportNewSignalButton
        function ImportNewSignalButtonPushed(app, event)

            % Open file dialog
            startpath = 'k:\*.*';
            [filen, location] = uigetfile(startpath, 'Select a signal file');
            matname = fullfile(location, filen);
            ImportFile = load(matname);  % Load the file
            % Check if 'sigTbl' exists in the loaded data
            % Turn off the specific warning
            
            if ~isfield(ImportFile, 'sigTbl')
                warning('The variable "sigtbl" was not found in the file.');
            else
                disp('File loaded successfully.');
                fig = figure('Name', 'New Signal: NeuroSignal Studio','Position', [600, 100, 1200, 800]);
                ax =axes(fig);
                app.data = cell2mat(ImportFile.sigTbl.Data); % Simulated multichannel signals
                app.fs = ImportFile.sigTbl.Fs(1,1);
                numTimePoints = length(ImportFile.sigTbl.Data{1}); % Number of time points (1214)
                app.channelName = ImportFile.sigTbl.ChName;
                filename = 'resource/FB003854_channel_order.csv';
                channelorder = readtable(filename);
                if ImportFile.sigTbl.Subject(1) == "FB003854"
                    if ~strcmp(app.channelName(1), 'A-008')
                        channelorder = table2array(channelorder);
                        app.data = app.data(channelorder,:);
                        app.channelName = app.channelName(channelorder,:);
                    end
                end
                app.dataOrig = app.data;
                numChannels = size(app.data,1);
                app.offset = 2.5*1500; % Offset between channels for better visibility
                app.time = (0:numTimePoints-1) / app.fs; % Time in seconds
                data = flipud(app.data);
                yAxisMColC =[];
                MC = max(max(abs(data)))*2; % absolute maximum CSD
                yAxisM = MC*(size(data,1)); % starting baseline for plots
                delete(app.UIAxes.Children)

                hold (ax,'on');
                for i = 1:size(app.data,1)
                    plot(ax,app.time, data(i, :) + yAxisM); % Plot each signal with an offset
                    yAxisMColC(i,1) = yAxisM;
                    yAxisM = yAxisM-MC;
                end
                g2 = get(gca,'YTickLabel');
                yAxisMColC = flipud(yAxisMColC)';
                set(gca,'Ytick',[yAxisMColC]);
                ax=gca; ExC = ax.YRuler.Exponent;
                axis([0,inf,MC*0.5,(MC*(size(data,1)))+(MC*0.5)]);
                % ax.YTick(app.offset * (0:numChannels-1)); % Set y-ticks to match the channel offsets
                % YTickLabel = (arrayfun(@(x) ['Ch ', num2str(x)],app.channelName, 'UniformOutput', false)); % Label y-ticks
                yticklabels(arrayfun(@(x) ['Ch ', num2str(x)],app.channelName, 'UniformOutput', false)); % Label y-ticks

                hold (ax,'off');
                app.UserIn_AverageSpikes ={};  % To delete if previously pressed, because it affects the CSD calculation, it determines whether CSD button calculates troughs or signal directly.
            end

        end

        % Button pushed function: FindTroughsButton
        function FindTroughsButtonPushed(app, event)
            prompt = {'MinPeakHeight :'; 'MinPeakDistance (as Sample)';'MinPeakProminence'};
            dlgtitle = 'Input Required';
            if app.fs == 2000
                windowSize = round(app.fs /16);
            elseif app.fs == 5000
                windowSize = round(app.fs /40);
            end
            definput = {'300';string(windowSize);'0.8'};
            dims = [1 30];
            UserIn = inputdlg(prompt,dlgtitle, dims, definput);
            if ~isempty(UserIn) % Check if the user clicked 'OK'
                
                app.minPeakH = str2double(UserIn{1}); % Convert to numeric
                app.minDis = str2double(UserIn{2}); % Convert to numeric
                app.minPeakProm = str2double(UserIn{3}); % Convert to numeric
                % Find Peaks/ Troughs
                troughs = {};
                for i = 1:size(app.data,1)
                    [peaks, locs] = findpeaks(-app.data(i,:), ...
                        'MinPeakHeight', app.minPeakH, ...               % Minimum peak height
                        'MinPeakDistance', app.minDis, ...               % Minimum distance (125 samples)
                        'MinPeakProminence', app.minPeakProm, ...        % Minimum prominence
                        'WidthReference', 'halfheight');                 % Width range
                    troughs{i,1} = -peaks;
                    app.locations{i,1} = locs;
                    disp('Troughs were found!')
                end

                prompt = {'Enter channel number: '};
                dlgtitle = 'Channel Required to Plot';
                definput = {'1'};
                dims = [1 20];
                UserIn = inputdlg(prompt,dlgtitle, dims, definput);
                if ~isempty(UserIn) % Check if the user clicked 'OK'
                    app.AverageofSpikesButton.BackgroundColor = [0.94 0.94 0.94];
                    app.userSelChn = str2double(UserIn{1}); % Convert to numeric
                    disp(['User entered: ', num2str(app.userSelChn)]);
                    % Do something with userValue
                    if isempty(app.obj.signalObj)
                        % Visualize detected troughs
                        app.Image_2.Visible = 'on';
                        app.Image.Visible ="off";
                        app.UIAxes.Visible = 'on';
                        hold(app.UIAxes, "off");
                        plot(app.UIAxes,app.time,app.data(app.userSelChn,:), 'LineWidth', 1.5);
                        hold(app.UIAxes, 'on');
                        plot(app.UIAxes,app.locations{app.userSelChn,1}/app.fs, troughs{app.userSelChn,1}, 'x','MarkerSize', 8, 'LineWidth', 2);title(app.UIAxes,'EEG and Troughs'); ylabel (app.UIAxes,sprintf('Chn %s', app.channelName{app.userSelChn}));xlabel("Time(s)");
                        app.UIAxes.YTickLabel = {};
                        app.UIAxes.YTick = [];
                        hold(app.UIAxes, "off");
                    else
                        figure('Name', 'Find Troughs: NeuroSignal Studio');
                        plot(app.time,app.data(app.userSelChn,:), 'LineWidth', 1.5);
                        hold on
                        plot((app.locations{app.userSelChn,1}/app.fs) + app.time(1), troughs{app.userSelChn,1}, 'x','MarkerSize', 8, 'LineWidth', 2);title('EEG and Troughs'); ylabel (sprintf('Chn %s', app.channelName{app.userSelChn})); xlabel("Time(s)");
                        hold off
                    end
                end
            else
                disp('User canceled the input.');
                figure(app.NeuroSignalStudioUIFigure);
            end
        end

        % Button pushed function: CSDButton
        function CSDButtonPushed(app, event)
            prompt = {' Enter elecrode distance as µm.'};
            dlgtitle = 'Input Required';
            definput = {'50'}; % as micrometer
            dims = [1 50];
            app.elecDis = inputdlg(prompt, dlgtitle, dims, definput);
            if ~isempty(app.elecDis) % Check if the user clicked 'OK'
                app.ContourPlotCSDButton.BackgroundColor = [0.94 0.94 0.94];
                button rengi
                userValue = str2double(app.elecDis{1}); % Convert to numeric
                disp(['User entered: ', num2str(userValue)]);
                % Do something with userValue
                interElectrodeDistance = userValue*10^-6; % meter  this is the spacing between two adjacent electrodes.
                unitLength = 1000; % unit length 1 mm : % converts CSD units to mm as default
                unitCurrent = 10^6; % specifies the units of current for the CSD output. Unit is as default microamps
                conductivity = 1; % conductivity = 0.3; % S.m^-1
                app.UserIn_AverageSpikes
                if ~isempty(app.UserIn_AverageSpikes)
                    data_calculated = app.troughMean;
                else
                    data_calculated = app.data;
                end
                app.csdMatrix = repmat(NaN,size(data_calculated,1),size(data_calculated,2)); % matrix of NaNs
                for ii =  1:size(data_calculated,2)
                    for channelIndx = 2:size(data_calculated,1)-1
                        app.csdMatrix(channelIndx,ii) = -(((data_calculated(channelIndx+1,ii) - 2*data_calculated(channelIndx,ii) + data_calculated(channelIndx-1,ii)) / (interElectrodeDistance^2))*conductivity);
                    end
                end
                % Set CSD at edges to NaN (not defined due to boundary effects)
                app.csdMatrix = app.csdMatrix(2:end,:);
                app.csdMatrix = app.csdMatrix / unitLength^3;
                app.csdMatrix = app.csdMatrix * unitCurrent;
                ChnCSD = app.channelName(2:end-1);

                % Visualize CSD as colormap
                fprintf('CSD color map with superimposing its time series ploting......')
                figure('Name', 'Current Source Density: NeuroSignal Studio','Position', [600, 100, 1200, 800]);

                % Plot CSD as Map
                im1 = imagesc(app.time(1,1:length(app.csdMatrix)), 1:size(app.csdMatrix,1), app.csdMatrix);
                im1.AlphaData = 1; % change this value to change the foreground image transparency
                set(gca, 'YDir', 'normal');
                colormap('jet')
                xlabel('Time (s)');
                % Add colorbar
                c=colorbar( 'east');
                clim([-round(max(app.csdMatrix, [], 'all')) round(max(app.csdMatrix, [], 'all'))])
                c.YTick =  [-max(app.csdMatrix, [], 'all') max(app.csdMatrix, [], 'all')];
                c.YTickLabel = {'Sink', 'Source'};
                c.TickDirection = 'in';
                c.FontSize = 12;
                c.FontWeight = 'normal';


                hold on
                % For Plotting Raw data as stacked plot with offset
                timeSeriesSignal = data_calculated;
                timeSeriesSignalNorm = normalize(timeSeriesSignal(2:end-1,:),2,"range"); % Normalize data between 0-1
                ChnNamesSubset14 = flipud(ChnCSD);
                numChannels = size(ChnNamesSubset14,1);
                title('Multichannel raw signals overlaid on their CSD map');
                yAxisMColC =[];
                data = timeSeriesSignalNorm;
                MC = max(max(abs(data))); % absolute maximum CSD
                yAxisM = MC*(size(data,1)); % starting baseline for plots
                delete(app.UIAxes.Children)
                hold on;
                
                for i = 1:size(data,1)
                    plot(app.time, data(i, :) + yAxisM-(MC*0.5),'k'); % Plot each signal with an offset
                    yAxisMColC(i,1) = yAxisM;
                    yAxisM = yAxisM-MC;
                end
                app.time(1)
                g2 = get(gca,'YTickLabel');
                yAxisMColC = flipud(yAxisMColC)';
                set(gca,'Ytick',[yAxisMColC]);
                axis([0,inf,MC*0.5,(MC*(size(data,1)))+(MC*0.5)]);
                yticklabels(arrayfun(@(x) ['Ch ', num2str(x)],ChnNamesSubset14, 'UniformOutput', false)); % Label y-ticks
                xlim([app.time(1) app.time(end)])
                hold off;
                disp('Plotting the CSD map superimposed on the time series is done!')

            else
                disp('User canceled the input.');
            end
            disp('Ploting CSD as time series were completed.');
        end

        % Button pushed function: AverageofSpikesButton
        function AverageofSpikesButtonPushed(app, event)
           if ~isempty(app.userSelChn)
            maxDuration = length(app.data) - app.locations{app.userSelChn,1}(end);
            prompt = {['Enter duration around spikes. It should be less than ', num2str(maxDuration),'.']};
            dlgtitle = 'Input Required';
            definput = {'140'};
            dims = [1 30];
            app.UserIn_AverageSpikes = inputdlg(prompt,dlgtitle, dims, definput);
            if ~isempty(app.UserIn_AverageSpikes) % Check if the user clicked 'OK'
                durationAroundSpike = str2double(app.UserIn_AverageSpikes{1}); % Convert to numeric
                disp(['User entered: ', num2str(-durationAroundSpike) ,' - +', num2str(durationAroundSpike)]);
                % Do something with userValue
                troughMatrix = {};
                for troughLoc = 1:length(app.locations{app.userSelChn,1})
                    for channelIndx = 1:size(app.data,1)
                        troughMatrix{channelIndx,troughLoc} = app.data(channelIndx,app.locations{app.userSelChn,1}(troughLoc)-durationAroundSpike:app.locations{app.userSelChn,1}(troughLoc)+durationAroundSpike);
                    end
                end

                % Take average of the spikes for each channels
                app.troughMean = [];
                for i = 1:size(app.data,1)   % channels
                    % Combine all the cells of the channel into a matrix.
                    channelData = cell2mat(troughMatrix(i, :)'); % Size: 39x281
                    app.troughMean(i, :) = mean(channelData, 1); % 1x281
                end

                % Third: Visualize averaged troughs
                if isempty(app.obj.signalObj)
                    delete(app.UIAxes.Children(1:end))
                    app.Image_2.Visible = 'on';
                    app.Image.Visible ="off";
                    app.UIAxes.Visible = 'on';
                    plot(app.UIAxes,app.time(1,1:length(app.troughMean)),app.troughMean','DisplayName','troughMean'); title(app.UIAxes,'Average troughs for all channels'); xlabel(app.UIAxes,'Time(s)'); ylabel(app.UIAxes,'Amplitude (µV)');
                else
                    figure('Name', 'Average Troughs : NeuroSignal Studio', 'NumberTitle', 'on','Position', [600, 100, 1200, 800]);
                    plot(app.time(1,1:length(app.troughMean)),app.troughMean','DisplayName','troughMean'); title('Average troughs for all channels'); xlabel('Time(s)'); ylabel('Amplitude (µV)');
                    legend(app.channelName, 'Location', 'southoutside', 'Orientation', 'horizontal','NumColumns', 8);
                end
            else
                disp('User canceled the input.');
            end
           else
               fprintf(2, '!! Warning: Please use the "Find Troughs" button first!\n');

           end
        end

        % Button pushed function: HPFilterButton
        function HPFilterButtonPushed(app, event)
            prompt = {' Enter cut off frequency as Hz: '; 'Enter filter order: '};
            dlgtitle = 'Input Required';
            definput = {'2';'4'};
            dims = [1 30];
            UserIn = inputdlg(prompt,dlgtitle, dims, definput);
            if ~isempty(UserIn) % Check if the user clicked 'OK'
                userValue1 = str2double(UserIn{1}); % Convert to numeric
                userValue2 = str2double(UserIn{2}); % Convert to numeric

                disp(['User entered: ', num2str(userValue1),'Hz cut off frequency and ', ' Filter Order:', num2str(userValue2)]);
                % Do something with userValue
                app.highCutoff = userValue1;    % Upper cutoff frequency in Hz
                app.filterOrder = userValue2;   % Filter order
                d = designfilt('highpassiir','FilterOrder',app.filterOrder,'HalfPowerFrequency',app.highCutoff,'SampleRate',app.fs);
                filteredData = [];
                for i = 1:size(app.data,1)
                    filteredData(i,:) = filtfilt(d, app.dataOrig(i,:)); % Zero-phase filtering
                end
                app.data =filteredData;
                disp('HP Filtering was done!')
                if isempty(app.obj.signalObj)
                    delete(app.UIAxes.Children(1:end))
                    app.Image_2.Visible = 'on';
                    app.Image.Visible ="off";
                    app.UIAxes.Visible = 'on';
                    hold(app.UIAxes,'on');
                    offset = 2500;
                    for i = 1:size(app.data,1)
                        plot(app.UIAxes,app.time, app.data(i, :) + offset * (i - 1), 'LineWidth', 1.5); % Plot each signal with an offset
                    end
                    app.UIAxes.YTick = (offset * (0:size(app.data,1)-1)); % Set y-ticks to match the channel offsets
                    app.UIAxes.YTickLabel = (arrayfun(@(x) ['Ch ', num2str(x)],app.channelName, 'UniformOutput', false)); % Label y-ticks
                    hold(app.UIAxes,'off');
                else
                    delete(app.fig.Children)
                    delete(app.figChnNames)
                    numch = length(app.channelName);
                    height = 0.95/numch;
                    
                
                    for kch = 1 : numch
                        % Add new axes in fig
                        app.ax =  axes('Parent', app.fig, 'Position', [0.08, 1 - kch * height, 0.9, height], 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'on','Clipping', 'off', 'PickableParts', 'all');
                        plot( app.ax, app.time, app.data(kch,:));
                        % Add Channels name to axes
                        app.figChnNames = annotation(app.fig, 'textbox', 'String', string(app.channelName{kch}), 'Position', [0.05,  (1 - kch * height)-height/2, 0.01, height], 'EdgeColor', 'none', 'FontSize', 8, 'HorizontalAlignment', 'right');
                        if kch == numch
                            xlabel(app.ax, 'Time (s)', 'FontSize', 8, 'FontWeight', 'bold');
                        else
                            app.ax.XTickLabel = [];
                        end
                    end
                    linkaxes(findobj(app.fig, 'Type', 'axes'), 'xy');
                    app.fig.Name =  'High Pass Filtered Data: NeuroSignal Studio';
                end
            else
                disp('User canceled the input.');
                figure(app.NeuroSignalStudioUIFigure);

                % % Baseline correction
                % windowSize = round(app.fs /16); % 125 samples window, adjust as needed
                % baseline = movmean(app.data, windowSize,2); % Estimate the baseline using moving average
                % % Subtract the baseline
                % correctedData = app.data - baseline;
                % app.data = correctedData;
                % disp('Baseline Correction with MAV was done!')
                % HP Filtering
            end
        end

        % Button pushed function: BandPassFilterButton
        function BandPassFilterButtonPushed(app, event)
            prompt = {' Enter low cut off frequency as Hz '; 'Enter high cut off frequency as Hz';'Enter filter order '};
            dlgtitle = 'Input Required';
            definput = {'250';'800';'4'};
            dims = [1 30];
            UserIn = inputdlg(prompt,dlgtitle, dims, definput);
            if ~isempty(UserIn) % Check if the user clicked 'OK'
                userValue1 = str2double(UserIn{1}); % Convert to numeric
                userValue2 = str2double(UserIn{2}); % Convert to numeric
                userValue3 = str2double(UserIn{3}); % Convert to numeric

                
                disp(['User entered: ', num2str(userValue1),'Hz cut off frequency and ', ' Filter Order:', num2str(userValue2)]);
                % Do something with userValue
                app.highCutoff = userValue1;    % Upper cutoff frequency in Hz
                app.lowCutoff = userValue2;
                app.filterOrder = userValue3;   % Filter order
                d = designfilt('bandpassiir','FilterOrder',app.filterOrder,'HalfPowerFrequency1',app.highCutoff,'HalfPowerFrequency2',app.lowCutoff,'SampleRate',app.fs);
                filteredData = [];
                for i = 1:size(app.data,1)
                    filteredData(i,:) = filtfilt(d, app.dataOrig(i,:)); % Zero-phase filtering
                end
                app.data =filteredData;
                disp('BP Filtering was applied successfully!')
                if isempty(app.obj.signalObj) % If signal imported with import new signal button
                    delete(app.UIAxes.Children(1:end))
                    app.Image_2.Visible = 'on';
                    app.Image.Visible ="off";
                    app.UIAxes.Visible = 'on';
                    hold(app.UIAxes,'on');
                    offset = 2500;
                    for i = 1:size(app.data,1)
                        plot(app.UIAxes,app.time, app.data(i, :) + offset * (i - 1), 'LineWidth', 1.5); % Plot each signal with an offset
                    end
                    app.UIAxes.YTick = (offset * (0:size(app.data,1)-1)); % Set y-ticks to match the channel offsets
                    app.UIAxes.YTickLabel = (arrayfun(@(x) ['Ch ', num2str(x)],app.channelName, 'UniformOutput', false)); % Label y-ticks
                    hold(app.UIAxes,'off');
                else % If the signal comes from the OSEL
                    delete(app.fig.Children)
                    delete(app.figChnNames)
                    numch = length(app.channelName);
                    height = 0.95/numch;
                    for kch = 1 : numch
                        % Add new axes in fig
                        app.ax =  axes('Parent', app.fig, 'Position', [0.08, 1 - kch * height, 0.9, height], 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'on','Clipping', 'off', 'PickableParts', 'all');
                        plot( app.ax, app.time, app.data(kch,:));
                        % Add Channels name to axes
                        app.figChnNames = annotation(app.fig, 'textbox', 'String', string(app.channelName{kch}), 'Position', [0.05,  (1 - kch * height)-height/2, 0.01, height], 'EdgeColor', 'none', 'FontSize', 8, 'HorizontalAlignment', 'right');
                        if kch == numch
                            xlabel(app.ax, 'Time (s)', 'FontSize', 8, 'FontWeight', 'bold');
                        else
                            app.ax.XTickLabel = [];
                        end
                    end
                    linkaxes(findobj(app.fig, 'Type', 'axes'), 'xy');
                    app.fig.Name =  'Band Pass Filtered Data: NeuroSignal Studio';
                end
            else
                disp('User canceled the input.');
                figure(app.NeuroSignalStudioUIFigure);
            end
        end

        % Button pushed function: CombFilterButton
        function CombFilterButtonPushed(app, event)
            Q = 35;
            foe = 50; %the frequency to remove from the signal.
            BW = 2*(foe/(app.fs/2))/Q;
            [b,a] = iircomb(round(app.fs/foe),BW, 'notch');
            filteredData = [];
            for i = 1:size(app.data,1)
                filteredData(i,:) = filtfilt(b,a,app.data(i,:));
            end
            app.data =filteredData;
            disp('Comb Filter was applied successfully!')
            if isempty(app.obj.signalObj) % If signal imported with import new signal button
                delete(app.UIAxes.Children(1:end))
                app.Image_2.Visible = 'on';
                app.Image.Visible ="off";
                app.UIAxes.Visible = 'on';
                hold(app.UIAxes,'on');
                offset = 2500;
                for i = 1:size(app.data,1)
                    plot(app.UIAxes,app.time, app.data(i, :) + offset * (i - 1), 'LineWidth', 1.5); % Plot each signal with an offset
                end
                app.UIAxes.YTick = (offset * (0:size(app.data,1)-1)); % Set y-ticks to match the channel offsets
                app.UIAxes.YTickLabel = (arrayfun(@(x) ['Ch ', num2str(x)],app.channelName, 'UniformOutput', false)); % Label y-ticks
                hold(app.UIAxes,'off');
            else % If the signal comes from the OSEL
                delete(app.fig.Children)
                delete(app.figChnNames)
                numch = length(app.channelName);
                for kch = 1 : numch
                    % Add new axes in fig
                    app.ax =  axes('Parent', app.fig, 'Position', [0.08, (numch - kch+1)/(numch+1), 0.9, 0.8/numch], 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'on','Clipping', 'off', 'PickableParts', 'all');
                    plot( app.ax, app.time, app.data(kch,:));
                    % Add Channels name to axes
                    app.figChnNames = annotation(app.fig, 'textbox', 'String', string(app.channelName{kch}), 'Position', [0.05, (numch - kch+1)/(numch+1), 0.01, 0.035], 'EdgeColor', 'none', 'FontSize', 8,'HorizontalAlignment', 'right');
                    if kch == numch
                        xlabel(app.ax, 'Time (s)', 'FontSize', 8, 'FontWeight', 'bold');
                    else
                        app.ax.XTickLabel = [];
                    end
                end
                linkaxes(findobj(app.fig, 'Type', 'axes'), 'xy');
                app.fig.Name =  'Comb Filtered Data: NeuroSignal Studio';
            end
        end

        

        % Button pushed function: BipolarMontageButton
        function BipolarMontageButtonPushed(app, event)

            bipolarEEG = app.data(1:end-1, :) - app.data(2:end, :);
            numChannels = length(app.channelName);
            channelLabels = cell(1, numChannels - 1);
            for i = 1:numChannels-1
                channelLabels{i} = strcat(string(app.channelName{i}), "-", string(app.channelName{i+1}));
            end

            figBipolar = figure('Name', 'Bipolar Montage: NeuroSignal Studio',...
                'NumberTitle', 'on','Position', [600, 100, 1200, 800]);
            numch = length(channelLabels); % Number of Channel
            height = 0.95/numch;
           
 
            % Add Channels name to axes
            for kch = 1:numch
                % Add new axes in fig
                ax =  axes('Parent', figBipolar, 'Position', [0.08,1 - kch * height, 0.9, height],...
                    'XLimMode', 'manual', 'YLimMode', 'manual', ...
                    'Visible', 'on','Clipping', 'off',...
                    'PickableParts', 'all');
                % Plot signals
                plot(ax, app.time, bipolarEEG(kch,:));
                app.figChnNames = annotation(figBipolar, 'textbox', ...
                    'String', string(channelLabels{kch}), ...
                    'Position', [0.05,  (1 - kch * height)-height/2, 0.01, height], ...
                    'EdgeColor', 'none', ...
                    'FontSize', 8, ...
                    'HorizontalAlignment', 'right');
                ylim(ax,[min(bipolarEEG,[],'all') max(bipolarEEG,[],'all')]);
                if kch == numch
                    xlabel(ax, 'Time (s)', 'FontSize', 8, 'FontWeight', 'bold');
                else
                    ax.XTickLabel = [];
                end
            end
            % app.data = bipolarEEG;
            % app.channelName = string(channelLabels');
            linkaxes(findobj(figBipolar, 'Type', 'axes'), 'x');
        end

        

        % Button pushed function: ContourPlotCSDButton
        function ContourPlotCSDButtonPushed(app, event)
            if ~isempty(app.elecDis)
            figure('Name', 'Contour Plot of the Current Source Density: NeuroSignal Studio','Position', [600, 100, 1200, 800]);
            contourf(app.time(1,1:length(app.csdMatrix)), 1:size(app.csdMatrix,1), app.csdMatrix,15, '-.', 'edgecolor','none'); % 'k' for black contour lines
            % Add colorbar
            colormap('jet')
            xlabel('Time (s)');
            c=colorbar( 'east');
            clim([-round(max(app.csdMatrix, [], 'all')) round(max(app.csdMatrix, [], 'all'))])
            c.YTick =  [-max(app.csdMatrix, [], 'all') max(app.csdMatrix, [], 'all')];
            c.YTickLabel = {'Sink', 'Source'};
            c.TickDirection = 'in';
            c.FontSize = 12;
            c.FontWeight = 'normal';
            set(gca,'Ytick',1:length(app.channelName(2:end-1)));
            yticklabels(arrayfun(@(x) ['Ch ', num2str(x)],flipud(app.channelName(2:end-1)), 'UniformOutput', false)); % Label y-ticks
            ylim([0.5 length(app.channelName(2:end-1))+0.5])
            else
               fprintf(2, '!! Warning: Please use the "CSD" button first!\n');

           end
        end

        % Button pushed function: TimeFrequencyButton
        function TimeFrequencyButtonPushed(app, event)
            if license('test', 'Wavelet_Toolbox')
                if app.fs> 5000
                    disp('Resampling the data to 5kHz....Please wait....')
                    d = app.data; % d should be chn x sample
                    fs_resampled = 5000;
                    tic
                    d_res = [];
                    for ch=1:size(d,1)
                        d_res(ch,:)=resample(d(ch,:),fs_resampled,app.fs,floor(app.fs/2));
                    end
                    toc

                    fs = fs_resampled;
                    d_res = d_res'; % d_res = Samp x channel
                    disp('Resampling (to 5kHz) is done!')
                else
                    d_res =  app.data';
                    fs = app.fs;
                end
                time =  (0:length(d_res)-1) / fs; % Time in seconds

                % d_res = [d_res time'];
                dataL = d_res';  % dataL = channel x samp

                prompt = {'Enter channel number: '; 'Enter Low Frequency:'; 'Enter High Frequency'};
                dlgtitle = 'Scalogram Parameters';
                definput = {'1';'80';'800'};
                dims = [1 40];
                UserIn = inputdlg(prompt,dlgtitle, dims, definput);
                if ~isempty(UserIn) % Check if the user clicked 'OK'

                    userValue1 = str2double(UserIn{1}); % Convert to numeric
                    userValue2 = str2double(UserIn{2}); % Convert to numeric
                    userValue3 = str2double(UserIn{3}); % Convert to numeric
                    disp(['TF Representation for Channel: ', num2str(userValue1),' is been calculating.....']);

                    channel_num =userValue1;
                    signalLength = size(d_res,1);
                    fb = cwtfilterbank('SignalLength',signalLength,'SamplingFrequency',fs,'VoicesPerOctave',24, ...
                        'FrequencyLimits',[2 fs/2]);
                    [cfs,frq] = cwt(dataL(channel_num,:),FilterBank=fb);
                    figure,cwt(dataL(channel_num,:),fs);
                    figure('Name', 'Scalogram: NeuroSignal Studio',...
                        'NumberTitle', 'on','Position', [600, 100, 1200, 800]);
                    subplot(2,1,1)
                    plot(time,dataL(channel_num,:))
                    axis tight
                    title("EEG Signal and Scalogram")
                    xlabel("Time (s)")
                    ylabel({string(app.channelName{channel_num});'Amplitude'})
                    subplot(2,1,2)
                    surface(time,frq,abs(cfs))
                    axis tight
                    shading flat
                    xlabel("Time (s)")
                    ylabel("Frequency (Hz)")
                    ylim([userValue2 userValue3])
                    % set(gca,"yscale","log")
                    disp(['TF Representation for Channel: ', num2str(userValue1),' is calculated. Figures are been creating...']);
                else
                    disp('Warning: Wavelet Toolbox is NOT installed. Please Install Wavelet Toolbox using MATLAB Add-Ons');
                end
                

            end
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            src = get(0,'MonitorPositions');
            primaryMonitor = src(1,:);  % [x, y, width, height]
            xPos = primaryMonitor(1);
            yPos = primaryMonitor(2) + primaryMonitor(4) - 480;
            % Create NeuroSignalStudioUIFigure and hide until all components are created
            app.NeuroSignalStudioUIFigure = uifigure('Visible', 'off');
            app.NeuroSignalStudioUIFigure.Position = [xPos+5 yPos-30 470 480]; %  [left bottom width height]
            app.NeuroSignalStudioUIFigure.Name = 'NeuroSignal Studio';

            % Create UIAxes
            app.UIAxes = uiaxes(app.NeuroSignalStudioUIFigure);
            title(app.UIAxes, 'Multichannel Raw Signals')
            xlabel(app.UIAxes, 'Time (s)')
            ylabel(app.UIAxes, 'Channels')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.YTick = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15];
            app.UIAxes.YTickLabel = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; '10'; '11'; '12'; '13'; '14'; '15'; '16'};
            app.UIAxes.YMinorTick = 'on';
            app.UIAxes.Tag = 'EEG_axis';
            app.UIAxes.Visible = 'off';
            app.UIAxes.Position = [10 35 440 340];

            % Create ImportNewSignalButton
            app.ImportNewSignalButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.ImportNewSignalButton.ButtonPushedFcn = createCallbackFcn(app, @ImportNewSignalButtonPushed, true);
            app.ImportNewSignalButton.Tag = 'ImportNewSignal_button';
            app.ImportNewSignalButton.Position = [6 449 76 23];
            app.ImportNewSignalButton.Text = 'Load Sig.';

            % Create FindTroughsButton
            app.FindTroughsButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.FindTroughsButton.ButtonPushedFcn = createCallbackFcn(app, @FindTroughsButtonPushed, true);
            app.FindTroughsButton.Tag = 'findPeaks_button';
            app.FindTroughsButton.Position = [253 449 76 23];
            app.FindTroughsButton.Text = 'Find Troughs';

            % Create AverageofSpikesButton
            app.AverageofSpikesButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.AverageofSpikesButton.ButtonPushedFcn = createCallbackFcn(app, @AverageofSpikesButtonPushed, true);
            app.AverageofSpikesButton.BackgroundColor = [0.8 0.8 0.8];
            app.AverageofSpikesButton.Position = [253 422 76 23];
            app.AverageofSpikesButton.Text = 'Avg.Spikes';

            % Create CSDButton
            app.CSDButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.CSDButton.ButtonPushedFcn = createCallbackFcn(app, @CSDButtonPushed, true);
            app.CSDButton.Tag = 'csd_button';
            app.CSDButton.Position = [335 449 76 23];
            app.CSDButton.Text = 'CSD';

            % Create HPFilterButton
            app.HPFilterButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.HPFilterButton.ButtonPushedFcn = createCallbackFcn(app, @HPFilterButtonPushed, true);
            app.HPFilterButton.Tag = 'highPassFilter_button';
            app.HPFilterButton.Position = [87 449 76 23];
            app.HPFilterButton.Text = 'HP Filter';

            % Create BandPassFilterButton
            app.BandPassFilterButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.BandPassFilterButton.ButtonPushedFcn = createCallbackFcn(app, @BandPassFilterButtonPushed, true);
            app.BandPassFilterButton.Tag = 'bandPassFilter_button';
            app.BandPassFilterButton.Position = [87 423 76 23];
            app.BandPassFilterButton.Text = 'BP Filter';

            % Create CombFilterButton
            app.CombFilterButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.CombFilterButton.ButtonPushedFcn = createCallbackFcn(app, @CombFilterButtonPushed, true);
            app.CombFilterButton.Tag = 'combFilter_button';
            app.CombFilterButton.Position =  [87 396 76 23];
            app.CombFilterButton.Text = 'Comb Filter';

            % Create WellcometoNeuroSignalStudioLabel
            app.WellcometoNeuroSignalStudioLabel = uilabel(app.NeuroSignalStudioUIFigure);
            app.WellcometoNeuroSignalStudioLabel.FontName = 'Arial';
            app.WellcometoNeuroSignalStudioLabel.FontWeight = 'bold';
            app.WellcometoNeuroSignalStudioLabel.FontColor = [0 0.4471 0.7412];
            app.WellcometoNeuroSignalStudioLabel.Position =  [69 138 365 207];
            app.WellcometoNeuroSignalStudioLabel.Text = {'Welcome to the NeuroSignal Studio App!'; ''; 'This tool is designed to assist you with EEG signal processing.';''; 'Simply load your EEG data,';'configure your analysis parameters,';'and let the app do the rest!'; ''; 'If you need help, please contact with Nedime Karakullukcu.'; ''; 'Happy analyzing!'};

            % Create Image
            app.Image = uiimage(app.NeuroSignalStudioUIFigure);
            app.Image.Tag = 'neuroSignalStudio_Icon_1';
            app.Image.Position = [186 20 120 138];
            app.Image.ImageSource = 'pics/iconNeuroSignalStudio.png';

            % Create Image_2
            app.Image_2 = uiimage(app.NeuroSignalStudioUIFigure);
            app.Image_2.Tag = 'neuroSignalStudio_Icon_2';
            app.Image_2.Visible = 'off';
            app.Image_2.Position = [1 1 57 48];
            app.Image_2.ImageSource = 'pics/iconNeuroSignalStudio.png';

            % Create ImportfromOSELButton
            app.ImportfromOSELButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.ImportfromOSELButton.ButtonPushedFcn = createCallbackFcn(app, @ImportfromOSELButtonPushed, true);
            app.ImportfromOSELButton.Tag = 'ImportSignalOSEL_button';
            app.ImportfromOSELButton.Position = [6 423 76 23];
            app.ImportfromOSELButton.Text = 'Load all Sig.';

            % Create ImportDisplayedButton
            app.ImportDisplayedButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.ImportDisplayedButton.ButtonPushedFcn = createCallbackFcn(app, @ImportDisplayedButtonPushed, true);
            app.ImportDisplayedButton.Tag = 'ImportDisplayedSignal_button';
            app.ImportDisplayedButton.Position = [6 396 76 23];
            app.ImportDisplayedButton.Text = 'Load Disp.';

            % Create BipolarMontageButton
            app.BipolarMontageButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.BipolarMontageButton.ButtonPushedFcn = createCallbackFcn(app, @BipolarMontageButtonPushed, true);
            app.BipolarMontageButton.Position = [169 449 76 23];
            app.BipolarMontageButton.Text = 'Bip.Montage';

            % Create ContourPlotCSDButton
            app.ContourPlotCSDButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.ContourPlotCSDButton.ButtonPushedFcn = createCallbackFcn(app, @ContourPlotCSDButtonPushed, true);
            app.ContourPlotCSDButton.Tag = 'contour_button';
            app.ContourPlotCSDButton.BackgroundColor = [0.8 0.8 0.8];
            app.ContourPlotCSDButton.Position = [335 423 76 23];
            app.ContourPlotCSDButton.Text = 'Cont.Plt.CSD';

            % Create TimeFrequencyButton
            app.TimeFrequencyButton = uibutton(app.NeuroSignalStudioUIFigure, 'push');
            app.TimeFrequencyButton.ButtonPushedFcn = createCallbackFcn(app, @TimeFrequencyButtonPushed, true);
            app.TimeFrequencyButton.Tag = 'tf_button';
            app.TimeFrequencyButton.Position = [169 423 76 23];
            app.TimeFrequencyButton.Text = 'Scalogram';

            % Show the figure after all components are created
            app.NeuroSignalStudioUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = calculations_exported_V250205(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.NeuroSignalStudioUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.NeuroSignalStudioUIFigure)
        end
    end
end