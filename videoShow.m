classdef videoShow < handle
    properties
        frame
        frameDrop % Modulo arithmetics counter. If zero, don't drop the frame and draw it.
        brightnessMult
        imge % The image object. When playing the video we only update CData in this object. It should be faster.
        
        stg % Settings created by stgs function
        key % Table of keyboard shortcuts created by keyShortTbl function
        h % Handles to graphic objects
        
        controlObj % controlPanel object stored here
    end
    
    methods
        function obj = videoShow(ctrPan) % controlObj passes filepn to the constructor in the fpn
            obj.controlObj = ctrPan;
            obj.stg = stgs;
            obj.key = keyShortTbl;
            obj = obj.makeFigure(ctrPan);
            [obj.controlObj.signalObj.h.lNow.Visible] = deal('on');
            obj.frameDrop = 0;
            obj.brightnessMult = 1;
        end
        function obj = makeFigure(obj, ctrPan)
            obj.h.f = figure; % Figure
            obj.h.f.WindowKeyPressFcn = @ctrPan.cbKey;
%             obj.h.f.WindowKeyPressFcn = @obj.ctr.cbKey; % Do not know why this does not work
            obj.h.f.WindowKeyReleaseFcn = @ctrPan.cbKeyRelease;
            obj.h.f.MenuBar = 'none';
            obj.h.f.ToolBar = 'none';
            obj.h.f.Position = obj.stg.vFigPos;
            obj.h.f.GraphicsSmoothing = 'off'; % Maybe turn this off
            obj.h.f.Interruptible = 'on'; % Not sure
            obj.h.f.BusyAction = 'queue'; % Not sure
            obj.h.f.CloseRequestFcn = @obj.closeReq;
            obj.h.ax = axes('Position', [0 0 1 1], 'Parent', obj.h.f); % Axes
        end
        function obj = nowUpdate(obj)
            if obj.frameDrop == 0
                obj.frame = double(obj.controlObj.videoObj.frame);
                obj.frame = uint8(obj.frame*obj.brightnessMult);
%                 tic
                obj.imge.CData = obj.frame;
%                 drawnow % When using obj.imge.CData = obj.frame;, the drawnow is not needed which improves speed a lot
%                 toc
            end
            obj.frameDrop = rem(obj.frameDrop + 1, ceil(obj.controlObj.playSpeed)); % Used for playing at faster speeds
        end
        function obj = updateStreams(obj)
            he = []; wi = [];
            for k = 1 : length(obj.controlObj.videoObj)
                he(k) = obj.controlObj.videoObj(k).height; %#ok<AGROW>
                wi(k) = obj.controlObj.videoObj(k).width; %#ok<AGROW>
            end
            sz = [max(he), sum(wi), 3];
            obj.frame = zeros(sz, 'uint8');
            for k = 1 : length(obj.controlObj.videoObj)
                obj.frame(1 : size(obj.controlObj.videoObj(k).frame, 1),...
                    (k-1)*obj.controlObj.videoObj(k).width + 1 : k*obj.controlObj.videoObj(k).width,...
                    1 : size(obj.controlObj.videoObj(k).frame, 3))...
                    = obj.controlObj.videoObj(k).frame;
            end
            obj.frame = double(obj.frame);
            obj.frame = uint8(obj.frame*obj.brightnessMult);
            obj.imge = imshow(obj.frame, 'Parent', obj.h.ax);
        end
        function delete(obj)
            delete(obj.h.f)
            obj.controlObj.videoShowObj = [];
            if isempty(obj.controlObj.videoObj)
                [obj.controlObj.signalObj.h.lNow.Visible] = deal('off');
            end
            for k = 1 : length(obj.controlObj.videoObj)
                delete(obj.controlObj.videoObj(k))
            end
            delete(obj)
        end
        function closeReq(obj, ~, ~)
            delete(obj)
        end
    end
end

