close all
clear
filepn = '\\neurodata2\Large data\Gene therapy Misa Saly Kudlajda\FCD Opto\SK002315\Opto sessions\20240823\SK002315-240823_131037-sz_blue_h-000-ExportFromFile240823_131000.mat';
load(filepn)

hf = figure;
hf.Color = [1 1 1];
numch = size(sigTbl, 1);
% Plot signal
hax = gobjects(numch, 1); hl = gobjects(numch, 1);
for k = 1 : numch
    % Create axes
    hax(k) = axes('Parent', hf, 'Position', [0.15, 0.8*(numch - k)/numch + 0.2, 0.8, 0.8/numch],...
        'XLimMode', 'manual', 'YLimMode', 'manual',...
        'Visible', 'off', 'Clipping', 'off',...
        'PickableParts', 'all',...
        'Tag', ['axSig', num2str(k)]);
    if all(isnan(sigTbl.Data{k}))
        yl = [-1 1];
        rng = 2;
    else
        rng = max(sigTbl.Data{k}(1, :)) - min(sigTbl.Data{k}(1, :));
        if rng == 0
            rng = 2;
        end
        yl = [min(sigTbl.Data{k}(1, :)) - 0.01*rng, max(sigTbl.Data{k}(1, :)) + 0.01*rng];
    end
    hax(k).XRuler.Visible = 'off';
    hax(k).YLim = yl;
    hax(k).YRuler.Visible = 'off';
    % hax(k).Units = 'Normalized';
    hax(k).NextPlot = "add";

    % Plot signal
    x = 0 : 1/sigTbl.Fs(k) : numel(sigTbl.Data{k})/sigTbl.Fs(k) - 1/sigTbl.Fs(k);
    y = sigTbl.Data{k};
    hl(k) = line(x, y, 'Color', 'k', 'HitTest', 'off');
    hax(k).XLim = [min(x), max(x)];

    % Plot channels names
    text(-0.13*range(hax(k).XLim), mean(hax(k).YLim), sigTbl.ChName{k});

    % Plot X scale bar
    x = [1 1]*hax(k).XLim(2) - 0.08*range(hax(k).XLim);
    x(1) = x(2) - round(0.1*range(hax(k).XLim), 1, "significant");
    y = [1 1]*(hax(k).YLim(1) + 0.12*range(hax(k).YLim));
    plot(x, y, "LineWidth", 2, "Color", "k");
    text(mean(x), y(1) - 0.01*range(hax(k).YLim), [num2str(diff(x)), ' s'], "HorizontalAlignment", "center", "VerticalAlignment", "top")

    % Plot Y scale bar
    x = [1 1]*hax(k).XLim(2) - 0.08*range(hax(k).XLim);
    y = [1 1]*(hax(k).YLim(1) + 0.12*range(hax(k).YLim));
    y(2) = y(1) + round(0.12*range(hax(k).YLim), 1, "significant");
    plot(x, y, "LineWidth", 2, "Color", "k");
    text(x(1) + 0.01*range(hax(k).XLim), mean(y), [num2str(diff(y)), ' mV'], "HorizontalAlignment", "left", "VerticalAlignment", "middle")
end

drawnow
print('Suprovy indukovany zachvat aby Slaninka mela lepsi den.eps', '-depsc', '-vector' )
