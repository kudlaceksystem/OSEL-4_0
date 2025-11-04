function s = stgs
    gr = groot;

    scrSz = gr.ScreenSize;
    % if scrSz(3)/scrSz(4) - 16/9 < 1e-10
    %     TF16to9 = true;
    % else
    %     TF16to9 = false;
    % end
    % 
    %% Control window
    % if TF16to9
        cFigSz = [NaN, NaN, 3/4*scrSz(3), scrSz(4) - 100];
    % end
% % %     s.cFigPos = int64([scrSz(3)/2 - cFigSz(3)/2, scrSz(4) - cFigSz(4) - 60, cFigSz(3), cFigSz(4)]);
    s.cFigPos = int64([scrSz(3) - cFigSz(3), scrSz(4) - cFigSz(4) - 55, cFigSz(3), cFigSz(4)]);
    s.cPanButtPos = int64([1, cFigSz(4) - 60, 360-2, 60]);
    s.cPanDisplayCtrPos = int64([360+1, cFigSz(4) - 60, 140-2, 60]);
    s.cPanFileNumberPos = int64([500+1, cFigSz(4) - 60, 140-2, 60]);
    s.cPanFilepnPos = int64([640+1, cFigSz(4) - 60, cFigSz(3) - 642, 60]);
    s.cDefaultPlotLimS = [0 60];
    s.cMove = 0.1;
    s.cNowMargin = 0.2;
    s.cPage = 0.8;
    s.cPlaySpeedChange = 1.2;
    s.cBrightnessChange = 1.2;
    s.cHorizontalZoom = 1.2;
    s.cTimerPeriod = 1/30;
    s.cDoubleClickPeriod = 0.3;
    
    
    %% Signal window
% % %     sFigSz = [NaN, NaN, scrSz(3) - 800, scrSz(4) - s.cFigPos(4) - 150 - 200];
% % %     s.sFigPos = int64([scrSz(3)/2 - sFigSz(3)/2, scrSz(4) - sFigSz(4) - s.cFigPos(4) - 60 - 40, sFigSz(3), sFigSz(4)]);
    s.sFigPos = int64([s.cFigPos(1), 50, s.cFigPos(3), scrSz(4) - s.cFigPos(4) - 140]);
    
    % Selecting channels
    s.sChannelsFigPos = int64([540 280 1000 450]);
    s.sigPanIndent = [100 80];
    
    s.sVertZoomStep = 1.1;
    
    s.sNowColor = 0.7*[1 1 1];
    s.sZoomInColor = [1 0.9 0.8];
    s.sZoomOutColor = [0.8 0.9 1];
    s.sMeasureColor = [0.6 0.5 1];
    
    s.sLblRoiLineWidth = 5;
    
    
    %% Video window
% % %     vFigSz = [NaN, NaN, 500, 400];
% % %     s.vFigPos = int64([0, scrSz(4) - vFigSz(4) - s.cFigPos(4) - 60, vFigSz(3), vFigSz(4)]);
    s.vFigPos = int64([0, scrSz(4) - 400 - 30, scrSz(3) - s.cFigPos(3), 400]);

    
    %% Label window
    s.lDefEditFigPos = int64([540 280 800 450]);
% % %     lFigSz = [NaN, NaN, 400, scrSz(4) - 100];
% % %     s.lFigPos = int64([scrSz(3) - lFigSz(3), 40, lFigSz(3), lFigSz(4)]);
    s.lFigPos = int64([0, 50, scrSz(3) - s.cFigPos(3), scrSz(4) - s.vFigPos(4) - 120]);
    
    
    s.defFigCol = [1 1 1];
    
    set(groot, 'DefaultFigureColor', s.defFigCol)
    set(groot, 'DefaultUipanelBackgroundColor', s.defFigCol)
    format compact
end
