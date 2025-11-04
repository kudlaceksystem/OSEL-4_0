classdef (Abstract) smr
    %SMR Provides basic properties and methods for subclasses working with
    %smr files
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function [chanNames, chanNNames, smrChN, comments] = smrLoadChanNames(filepn) % Input argument is file path and name
            smrChListFID = fopen(filepn);
            chanList = smr.SONChanList(smrChListFID); % Structure
            smrChN = [chanList.number]';
            chanNames = {chanList.title};
            chanNames = chanNames(1 : end - 2);
            chanNames = chanNames(:);
            numCh = length(chanNames);
            numsSpaces = [num2str((1 : numCh)', '%02d\n'), char(32*ones(numCh, 1))]; % Numbers with spaces
            chanNNames = cell(numCh, 1);
            for k = 1 : numCh
                chanNNames{k} = [numsSpaces(k, :), chanNames{k}];
            end
            comments = {chanList.comment};
            comments = comments(1 : end - 2);
            comments = comments(:);
            fclose(smrChListFID);
        end
        function fs = smrLoadFs(filepn, ch)
            fid = fopen(filepn);
            fs = 1/smr.SONGetSampleInterval(fid, ch);
            fclose(fid);
        end
        function sch = smrLoadChannel(filepn, ch, varargin) % File path and name, channel, beginning, end
            % If beginning and end are not specified the whole signal is
            % loaded
            if length(varargin) == 2
                be = varargin{1}; % In seconds
                en = varargin{2}; % In seconds
            elseif isempty(varargin)
                be = 0; % In seconds
                en = inf;
            else
                error(['Length of varargin is ' num2str(length(varargin))...
                    '. You must specify beginning and end of the signal you wish to load'...
                    ' (4 input arguments to the function) or nothing'...
                    ' (2 input arguments to the function).'])
            end
            
            fid = fopen(filepn);
            fs = smr.smrLoadFs(filepn, ch);
            
            if be ~= 0 || en ~= inf
                beSa = be*fs; enSa = en*fs;
                bLen = smr.loadBlockLen(filepn, ch);
                
                bBe = uint64(floor(be/bLen) + 1); % Blocks where beginning appears
                bEn = uint64(floor(be/bLen) + 1); % Blocks where end appears
                
                sbBeSa = beSa - bLen.*(bBe - 1); % Howmanyeth sample the beginning is within its block
%                 sbEn = enSa - bLen.*(bEn - 1); % Howmanyeth sample the end is within its block
                
                sch = single(smr.SONGetChannel(fid, ch, bBe, bEn, 'scale'));
                sch = sch(sbBe, sbBeSa + enSa - beSa);
            else
                sch = single(smr.SONGetChannel(fid, ch, 'scale'));
            end
        end
        function bLen = smrLoadBlockLen(filepn, ch)
            % Returns vector of SON block lengths in each channel. For each channel the
            % block length is supposed to be constant, else errormsg appears.
            % Uses SON library
            fid = fopen(filepn);
            B = smr.SONGetBlockHeaders(fid, ch);
            bLen = max(B(5, :));
            if min(B(5, 1 : end-1)) ~= bLen(r)
                errordlg(['Block lenghts not constant in channel No. ' num2str(nCh(r))]);
                return;
            end
            fclose(fid);
        end
        borec
        chanList = SONChanList(fid)
        Ts = SONGetSampleInterval(fid, ch)
        s = SONGetChannel(fid, ch, bBe, bEn, scaling)
        B = SONGetBlockHeaders(fid, ch)
        h = SONFileHeader(fid)
        c = SONChannelInfo(fid,i)
        [data,header] = SONGetADCChannel(fid,chan,varargin)
        [data,h] = SONADCToDouble(data,h)
        [time, TimeUnits] = SONTicksToSeconds(fid,start,varargin)
    end
end

