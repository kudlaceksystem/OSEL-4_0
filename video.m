classdef video < handle
    
    properties
        filepn % Files' paths and names
        currentFile
        
        vidRdr % Video reader object
        vidLenS % Video length in seconds
        speedOffset % Sometimes the video file shows different duration than the EEG file although they were recorded synchronously with physically same time.
        
        frame
        height
        width
        
        stg % Settings created by stgs function
        key % Table of keyboard shortcuts created by keyShortTbl function
        
        controlObj % controlPanel object stored here
    end
    
    methods
        function obj = video(ctrObj, fpn) % controlObj passes filepn to the constructor in the fpn
            obj.filepn = fpn;
            obj.controlObj = ctrObj;
            obj.stg = stgs;
            obj.key = keyShortTbl;
            obj = obj.initializeReader;
        end
        function obj = initializeReader(obj)
%             whichFileToRead = obj.controlObj.currentFile; % This works only if there is one-one relationship between the signal and video files
            whichFileToRead = obj.controlObj.findCorrespondingFile(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile}, obj.filepn); % Find video file using date of the file specified in the file name. May be safer.
            obj.currentFile = whichFileToRead; % For control window
whichFileToRead
            if isempty(whichFileToRead)
                obj.frame = 0;
                obj.vidLenS = 0;
                obj.height = 1;
                obj.width = 1;
                obj.speedOffset = 1;
            else
                obj.vidRdr = VideoReader(obj.filepn{whichFileToRead});
                obj.vidLenS = obj.vidRdr.Duration;
                whichFrame = round(obj.vidRdr.FrameRate*obj.controlObj.nowS) + 1; % May be inaccurate if there are e.g. dropped frames.
                obj.frame = read(obj.vidRdr, whichFrame);
                obj.height = obj.vidRdr.Height;
                obj.width = obj.vidRdr.Width;
                obj.speedOffset = obj.vidRdr.Duration/obj.controlObj.signalObj.sigLenS;
%                 obj.speedOffset = 1;
            end
        end
        function obj = updateNow(obj)
            if obj.controlObj.nowS > obj.vidLenS
                obj.frame = 0;
            else
                set(obj.vidRdr, 'CurrentTime', obj.controlObj.nowS*obj.speedOffset)
                obj.frame = readFrame(obj.vidRdr);
                obj.controlObj.nowS = get(obj.vidRdr, 'CurrentTime')/obj.speedOffset;
                obj.controlObj.signalObj.nowUpdate;
                obj.controlObj.videoShowObj.nowUpdate;
            end
        end
        function obj = nextFrame(obj)
            if obj.controlObj.nowS > obj.vidLenS
                obj.frame = 0;
                obj.controlObj.signalObj.nowUpdate;
                obj.controlObj.videoShowObj.nowUpdate;
            else
                obj.frame = readFrame(obj.vidRdr);
                obj.controlObj.nowS = get(obj.vidRdr, 'CurrentTime')/obj.speedOffset;
                obj.controlObj.signalObj.nowUpdate;
                obj.controlObj.videoShowObj.nowUpdate;
            end
        end
        function obj = fileUpdate(obj)
            if isempty(obj.vidRdr)
                obj = initializeReader(obj);
                if isempty(obj.vidRdr)
                    return
                end
            end
            if ~isvalid(obj.vidRdr)
                obj = initializeReader(obj);
            end
            obj.vidRdr = [];
%             whichFileToRead = obj.controlObj.currentFile; % This works only if there is one-one relationship between the signal and video files
            whichFileToRead = obj.controlObj.findCorrespondingFile(obj.controlObj.signalObj.filepn{obj.controlObj.currentFile}, obj.filepn); % Find video file using date of the file specified in the file name. May be safer.
            obj.currentFile = whichFileToRead; % For control window
            if isempty(whichFileToRead)
                obj.frame = 0;
                obj.vidLenS = 0;
                obj.height = 1;
                obj.width = 1;
                obj.speedOffset = 1;
                obj.controlObj.tmr.Period = 1/30;
            else
                obj.vidRdr = VideoReader(obj.filepn{whichFileToRead});
                obj.vidLenS = obj.vidRdr.Duration;
                obj.frame = readFrame(obj.vidRdr);
                obj.height = obj.vidRdr.Height;
                obj.width = obj.vidRdr.Width;
                obj.speedOffset = obj.vidRdr.Duration/obj.controlObj.signalObj.sigLenS;
                obj.controlObj.tmr.Period = 1/obj.vidRdr.FrameRate/obj.controlObj.playSpeed;
            end
        end
        function delete(obj)
            if isempty(obj.controlObj.videoObj)
                [obj.controlObj.signalObj.h.lNow.Visible] = deal('off');
            end
            obj.controlObj.videoObj = [];
            delete(obj.vidRdr)
            delete(obj)
        end
    end
end

