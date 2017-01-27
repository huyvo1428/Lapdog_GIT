%
% write_CALIB_MEAS_files
%	
%   This program computes calibration files (*_CALIB_MEAS.TAB/.LBL) 
%   that can then be used by the PDS software to create the calibrated data sets.
%   Also, a separate calibration coefficient list file is created for debugging purposes
%   (and for which the output directory is hardcoded).
%   
%   ARGUMENTS
%   =========
%   editedDatasetPath = Path to EDITED data set, e.g. '/data/LAP_ARCHIVE/RO-E-RPCLAP-2-EAR3-EDITED-V1.0'
%   missionPhaseName  = ("Long") mission phase name, e.g. "COMET ESCORT 3". (Needed for LBL file keyword MISSION_PHASE_NAME.)
%   outDirPath        = Output path (directory)
%
%   SYNTAX
%   ======
%                    write_CALIB_MEAS_files(editedDatasetPath, missionphasename, outDirPath)
%       
%       offsetData = write_CALIB_MEAS_files(editedDatasetPath, missionphasename, outDirPath)
%
%   ----------------------------------------------------------------------------
%   Usage: However the Swedish Institute of Space Physics sees fit.
%   Version: 1.2
%
%   Author: Martin Ulfvik 
%   Rewritten by Reine Gill, Erik P G Johansson
%   ----------------------------------------------------------------------------
%   - Third degree polynomial solution by FKJN 28/8 2014
%
%   - Added condition for only being able to label calibration data "cold" if they come before a
%     specified date OR are not the very first in the archive.
%     /Fredrik Johansson, Erik P G Johansson, 2015-02-04
%
%   - Primarily added check for finding calibration data which are not useful.
%     /Erik P G Johansson, 2015-02-04
%   
%   - Updated ADC20 TM-to-physical-units conversion factors in the LBL files according to calibration of
%     ADC20 relative ADC16 based on data for 2015-05-28. New values are multiples of ADC16 values
%     and are used retroactively.
%     /Erik P G Johansson 2015-06-11
%
%   - Bug fix: Updated to RECORD_BYTES=31 (characters per row incl CR+LF). Was previously 7936 (file size).
%     /Erik P G Johansson 2015-07-07
%
%   - Updated to INSTRUMENT_ID = RPCLAP (no quotes).
%     /Erik P G Johansson 2015-07-08
%
%   - Bug fix: Added time sorting of INDEX.TAB files. Should not produce erroneous additional calibration files.
%     Now generates calibration files for every block of macro 104 (including cold calibrations).
%     Sped up the reading of files. Clean-up and rewriting of much code. Renamed many variables.
%     Updated the LBL file: Set SPACECRAFT_CLOCK_START_COUNT, added stop times. Misc. hardcoded updates.
%     /Erik P G Johansson 2017-01-26/27
%   ----------------------------------------------------------------------------
%   NOTE: The current implementation (2015-05-08) sets START_TIME to an actual time, but sets SPACECRAFT_CLOCK_START_COUNT = "N/A". Change?
%   NOTE: As of 2016-04-07, this software is designed for MATLAB R2009A to make it possible to still run on squid.
%   NOTE: As of 2017-01-26, it appears that the part of the execution that takes the most time is the reading of LBL
%   files.
%   NOTE: As of 2017-01-27: If there are multiple mode sessions for the same day, then only one of them will be chosen.
%         This means that calibration files for a given day may differ depending on how this date is chosen.
%   BUG: As of 2017-01-23, appears to yield error if both the dataset contains no calibrations, and the return value is
%   requested.
function [varargout] = write_CALIB_MEAS_files(editedDatasetPath, missionPhaseName, outDirPath)
%
%   PROPOSAL: Print estimated time left (for reading LBL files).

    scriptStartTimeVector = clock;    % Script start time. NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute seconds].

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Sets hardcoded values for the basic parameters.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %DATA_SESSION_RESET_TIME = 1;           % Unit: days
    %MODE_SESSION_RESET_TIME = 1/(24*2);    % Unit: days    
    %INITIAL_CALIBDATA_NEVER_COLD_AFTER_TIME = datenum('2014-06-01T00:00:00.000', 'yyyy-mm-ddTHH:MM:SS.FFF');   % Unit: days
    
    MIN_GRADIENT_1 = -4.2;
    MAX_GRADIENT_1 = -3.3;
    
    MIN_INTERCEPT_1 = 410;
    MAX_INTERCEPT_1 = 600;
    
    MIN_GRADIENT_2 = -2.5;
    MAX_GRADIENT_2 = -1.7;
    
    MIN_INTERCEPT_2 = 200;
    MAX_INTERCEPT_2 = 390;
    
    MIN_CORRELATION = 0.99;
    
    FILES_PER_PROGRESS_STEP = 500;   % Number of files to process before updating the progress percentage (log message).
        
    % Directory path to where to save calibration COEFFICIENTS files for debugging (i.e. not LBL+TAB).
    CALIB_COEF_files_dir = '/data/LAP_ARCHIVE/CALIB_MEAS_files/';    % Default value on squid.
    %CALIB_COEF_files_dir = '~/temp/coeffs';   % For debugging.
    
    diag = 0;    % Flag for whether to display debugging plots.
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Validates the input/output arguments used.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % NOTE: "error" throws no error if the input argument is [].
    error(nargchk(3,3, nargin));
    error(nargoutchk(0, 1, nargout));
    
    % NOTE: It is useful to check for existence of directories directly since their non-existence will
    %       otherwise produce an error first after a lot of processing, i.e. after a potentially long delay.
    if ~exist(outDirPath, 'dir')
        error('Can not find directory "%s".', outDirPath)
    end
    if ~exist(CALIB_COEF_files_dir, 'dir')
        error('Can not find directory "%s".', CALIB_COEF_files_dir)
    end
   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Finds the relevant folders
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp('Paths');
    disp('----------------------------------------------------------------');
    fprintf(1,'Edited Archive and path: %s\r\n',editedDatasetPath);
    fprintf(1,'Mission phase: %s\r\n',missionPhaseName);
    fprintf(1,'Output calibration file path: %s\r\n\r\n',outDirPath);

    %indexDirPath = fullfile(editedDatasetPath,'INDEX'); % Full index file path

    if editedDatasetPath(end) == filesep        
        editedDatasetPath(end) = [];    % Remove trailing file separator (slash).
    end
    [junk, datasetDirName] = fileparts(editedDatasetPath);    % Split to get DATA_SET_ID. IMPORTANT NOTE: Only works for string NOT ending with slash.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Extracts the information from the index file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %   index{1}{:} = Paths to LBL files (relative to dataset)
    %   index{2}{:} = LBL PRODUCT_ID (effectively LBL filename without suffix)
    %   index{3}{:} = START_TIME as number of days since reference date (using datenum)
    %   index{4}{:} = STOP_TIME  as number of days since reference date (using datenum)
    %   index{5}{:} = INSTRUMENT_MODE_ID as original string (e.g. 'MCID0X0204')
    %   index{6}{:} = SPACECRAFT_CLOCK_TIME as original quoted(!) string (e.g. 1/0149643274.1600")
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    indexFilePath = fullfile(editedDatasetPath,'INDEX', 'INDEX.TAB');
    fileId = fopen(indexFilePath, 'r');

    if(fileId<=0)
        error('Could not open file: %s', indexFilePath);
        return;
    end

    % Read contents of INDEX.TAB into an analogue 2D array
    % ----------------------------------------------------
    % Example excerpt from INDEX.TAB:
    % "DATA/EDITED/2007/SEP/D16/RPCLAP070916_00FT_REB18NS.LBL","RPCLAP070916_00FT_REB18NS",2016-04-07T07:50:48,"RO-E-RPCLAP-2-EAR2-EDITED-V0.5"
    % "DATA/EDITED/2007/SEP/D16/RPCLAP070916_001_H.LBL       ","RPCLAP070916_001_H       ",2016-04-07T07:50:48,"RO-E-RPCLAP-2-EAR2-EDITED-V0.5"
    % "DATA/EDITED/2007/SEP/D16/RPCLAP070916_00NT_REB18NS.LBL","RPCLAP070916_00NT_REB18NS",2016-04-07T07:50:48,"RO-E-RPCLAP-2-EAR2-EDITED-V0.5"
    index = textscan(fileId,'%s%s%*s%*s%*s%*s','Delimiter',','); 
    fclose(fileId);
    
    
    relativeFilePathList  = strtrim(strrep(index{1}, '"', ''));
    productIdList = strtrim(strrep(index{2}, '"', ''));
    clear index
    inFilesData = struct('relativeFilePath', relativeFilePathList, 'productId', productIdList);
    
    
    
    for iFile = 1:length(inFilesData)
        isHk(iFile) = (inFilesData(iFile).relativeFilePath(end-4) == 'H');
    end
    inFilesData(isHk) = [];

    fprintf(1,'Reading LBL files in INDEX.TAB: start time, stop time and mode (macro)\n');

    % Iterate over all non-HK files mentioned in INDEX.TAB.
    nFiles = length(inFilesData);
    for iFile=1:nFiles

        % Read LBL file
        % -------------
        % IMPLEMENTATION NOTE: Does not use textscan to split up (parse) PDS keyword assignments since
        %   (1) I am guessing that it is faster this way (this is the slowest part of the code)
        %   (2) to be able to reuse old code.
        fname  = fullfile(editedDatasetPath, inFilesData(iFile).relativeFilePath);
        fileId = fopen(fname,'r');
        if ~(fileId>0)
            warning('write_MEAS_CALIB_file:CanNotReadFile', 'Can not open file %s', fname)
            continue
        end
        temp = textscan(fileId, '%s', 'delimiter', '\n', 'whitespace', '');
        linesList = temp{1};
        fclose(fileId);

        startTime   = linesList{strncmpi(linesList, 'START_TIME',                  10)};
        startTimeSc = linesList{strncmpi(linesList, 'SPACECRAFT_CLOCK_START_COUNT',28)};
        stopTime    = linesList{strncmpi(linesList, 'STOP_TIME',                    9)};
        stopTimeSc  = linesList{strncmpi(linesList, 'SPACECRAFT_CLOCK_STOP_COUNT', 27)};
        mode        = linesList{strncmpi(linesList, 'INSTRUMENT_MODE_ID',          18)};

        [tmp,str] = strread(startTime,'%s%s','delimiter','=');
        value     = datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');     % NOTE: "str" is a cell containing a string, but datenum can handle that.
        inFilesData(iFile).startTime = value;

        [tmp,str] = strread(stopTime,'%s%s','delimiter','=');
        value     = datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');
        inFilesData(iFile).stopTime = value;

        [tmp,value] = strread(startTimeSc,'%s%s','delimiter','=');
        inFilesData(iFile).startTimeSc = value{1};          % Stores quoted value, whitespace trimmed (outside of quotes). Example: "1/0149643274.1600"
        
        [tmp,value] = strread(stopTimeSc,'%s%s','delimiter','=');
        inFilesData(iFile).stopTimeSc = value{1};           % Stores quoted value, whitespace trimmed (outside of quotes). Example: "1/0149643274.1600"
        
        [tmp,value] = strread(mode,'%s%s','delimiter','=');
        inFilesData(iFile).instrumentModeId = char(value);     % char(value) converts (cell containing string) --> string.

        if(mod(iFile,FILES_PER_PROGRESS_STEP)==0)
            fprintf(1,'    Completed %4.1f %% of LBL files.\n', 100*iFile/nFiles);
        end
    end   % for
    
    fprintf(1,'\n');



    % Sort files by time (start time)
    % -------------------------------
    % From experience, INDEX.TAB is only sorted in time in a very approximate way. The code does not seem to handle
    % files not being sorted in a waterproof way.  /Erik P G Johansson 2017-01-26
    [junk, sortingIndices] = sort([inFilesData.startTime]);
    inFilesData = inFilesData(sortingIndices);
    
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Moves the data from cell array "index" to struct "data".
    %     "data" struct fields contain data as regular NxM arrays,
    %     where rows are constant length, e.g. data.mode(i_file, j).
    %   * Start constructing structure "data" which will in the end be
    %     returned to the caller (optional; depends on caller).
    %     Each index in the fields refers to an EDITED SCI LBL file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Progress: Changing internal data format.');
    
    %data = struct;
    
    
    %data.pathName       = char(inFilesData.relativeFilePath);
    %data.fileName       = char(inFilesData.productId);
    %data.startTime      = [inFilesData.startTime];
    %data.startTimeSc    = [inFilesData.startTimeSc];  % Unreliable since requires that strings have same length. Rest of code has not been adapted to make use of startTimeSc yet.
    %data.stopTime       = [inFilesData.stopTime]';
    %data.mode           = char(inFilesData.instrumentModeId);
    %data.count = length(data.startTime);
    

  
    clear index  % Effectively tell the reader of the source code that this variable will never be used again.



%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %   * Finds out when each data session starts.
%     %   * For each offset data, it determines which probe, data session and
%     %     mode session it belongs to and whether it was run in a cold state.
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % NOTE: Judging from the code, this is what terms mean (2017-01-25):
%     %   data session = A continuous sequence of LBL files (any combination of macros)
%     %                  that is not uninterrupted by more time than DATA_SESSION_RESET_TIME.
%     %   mode session = Either (1) ONE                      cold LBL file  with macro 104, followed by
%     %                             N (N>=0)                 warm LBL files with macro 104 (but labelled with cold=true)
%     %                  or     (2) a continuous sequence of warm LBL files with macro 104.
%     %   Note that non-macro 104 LBL files are removed from the list in the end.
%     
%     % PROPOSAL: Rename mode session ==> calib session
%     %                  dataSession  ==> dataSessionId
%     %                  modeSession  ==> modeSessionId (calibSessionId)
%     %                  dataRow      ==> iLblFile, iData (or similar)
% 
%     display('Progress: Identify calibration sessions in "index".');
% 
%     % Initialized to the largest size that could theoretically be needed. Is later reduced in size.
%     % Stores the starting time of each data session, data.startTime(dataRow).
%     % PRESUMED BUG: Is used for setting date of calibration files. 
%     dataSessionStartTime = zeros(data.count,1);
% 
%     data.dataSession = zeros(data.count,1);    % Components will (eventually) be assigned to the value of dataSession.
%     data.modeSession = zeros(data.count,1);    % Components will (eventually) be assigned to the value of modeSession.
%     data.cold        = zeros(data.count,1);    % Components will (eventually) be assigned to the value of coldState.
% 
%     dataSession = 0;         % In the for loop: Index into dataSessionStartTime. Every unique value refers to a sequence of EDITED SCI
%                              % files (ANY macro) without too long interruptions in time (DATA_SESSION_RESET_TIME) between the files.
%     modeSession = 0;         % In the for loop: Every unique value refers to a sequence of macro 104-EDITED SCI files,
%                              % that is uninterrupted by non-macro 104-EDITED SCI files.
% 
%     nextWarmDataBeginsWarmModeSession = true;   % In the for loop: Seems to refer to modeSession (is always set to false after incrementing modeSession).
%     
%     coldState  = true;       % In the for loop: Can only be set/changed after a new mode session has started.
%                              % ==> data.cold(...) always has the same value for an entire "mode session".
%     stopTimeLatest = 0;      % stopTime value of previous SCI file (all macros).
%                              % Initial value zero corresponds to a time long ago (approximately year zero, "0 A.D.").
%                              % ==> If the first EDITED SCI file is macro 104, then that entire mode (macro 104-) session will be "cold".
%     
%     removeIndex = zeros(data.count,1);    % Indices to remove, in the form of one true/false flag for every index.
% 
%     % Iterate over all SCI LBL files.
%     for dataRow = 1:data.count
% 
%         if (dataRow == data.count) || (~strcmp(data.fileName(dataRow,:), data.fileName(dataRow+1,:)))
%             % CASE: Last file in list, OR, this file and the next file in the list are NOT identical (why check?!!).
% 
%             if data.startTime(dataRow) - stopTimeLatest >= DATA_SESSION_RESET_TIME
%                 % CASE: Time between this EDITED SCI file (ANY macro) and
%                 % the most recent previous EDITED SCI file (ANY macro) exceeds DATA_SESSION_RESET_TIME (default 1 day).
%                 % ==> Start new "DATA session".
% 
%                 %fprintf(1, 'Found beginning of data session. First LBL file: %s -- %s\n', ...
%                 %    datestr(data.startTime(dataRow), 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
%                 %    datestr(data.stopTime(dataRow),  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG
%                 
%                 dataSession = dataSession + 1;                                 % NOTE: This is the only place where "dataSession"          is set (inside the for loop).
%                 dataSessionStartTime(dataSession) = data.startTime(dataRow);   % NOTE: This is the only place where "dataSessionStartTime" is set (inside the for loop).
%             end
% 
%             if strcmp(upper(data.mode(dataRow,:)),'MCID0X0104')
%                 % CASE: Found EDITED SCI file that is macro/mode 104.
% 
%                 %fprintf(1, 'Found CALIBRATION data (LBL file) %s -- %s\n', ...
%                 %    datestr(data.startTime(dataRow), 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
%                 %    datestr(data.stopTime(dataRow),  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG
% 
%                 possiblyLabelAsColdState = (data.startTime(dataRow) < INITIAL_CALIBDATA_NEVER_COLD_AFTER_TIME) || (dataRow > 1);   % Amendment Erik Johansson 2015-02-04
% 
%                 if (data.startTime(dataRow) - stopTimeLatest >= MODE_SESSION_RESET_TIME) && possiblyLabelAsColdState
%                     % CASE: "Cold LBL file", i.e.
%                     %       time between (1) this EDITED SCI file (macro 104) and
%                     %                    (2) the most recent previous EDITED SCI file (ANY macro)
%                     %       exceeds MODE_SESSION_RESET_TIME (default 30 min).
%                     %fprintf(1, '    LBL file is "COLD".\n')
% 
%                     % ==> Start new "MODE session"
%                     modeSession = modeSession + 1;
%                     nextWarmDataBeginsWarmModeSession = false;
% 
%                     % ==> Set COLD state
%                     coldState = true;
%                     data.cold(dataRow) = coldState;
%                 else
%                     % CASE: "Warm LBL file" (can still be assigned cold/warm state)
%                     %fprintf(1, '    LBL file is "WARM".\n')
% 
%                     if nextWarmDataBeginsWarmModeSession
%                         % CASE: It has previously been "requested" to start a new mode session when encountering warm
%                         % data.
% 
%                         % ==> Start new "MODE session"
%                         modeSession = modeSession + 1;
%                         nextWarmDataBeginsWarmModeSession = false;
% 
%                         % ==> Set WARM state
%                         coldState = false;
%                         data.cold(dataRow) = coldState;
%                     else
%                         % CASE: NOT nextWarmDataBeginsWarmModeSession
% 
%                         % ==> Reuse the previous cold/warm state.
%                         data.cold(dataRow) = coldState;
%                     end
%                 end
% 
%                 data.dataSession(dataRow) = dataSession;
%                 data.modeSession(dataRow) = modeSession;              % NOTE: The only place where the value of modeSession is passed on.
%             else
%                 % CASE: Found EDITED SCI file that is NOT macro/mode 104.
%                 % ==> Mark EDITED SCI file to (later) be removed from list.
%                 % ==> Request the starting of a new "mode session" if later finds another macro 104 EDITED SCI file.
% 
%                 %fprintf(1, 'Found non-calibration LBL file: %s -- %s\n', ...
%                 %    datestr(data.startTime(dataRow), 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
%                 %    datestr(data.stopTime(dataRow),  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG
%                 
%                 removeIndex(dataRow) = true;
%                 nextWarmDataBeginsWarmModeSession = true;
%             end
% 
%             % Update stopTimeLatest with latest stopTime so far, _regardless_ of the macro/mode of EDITED SCI file(s).
%             %
%             % NOTE: Checking if stopTime will be incremented (not decremented) seems to a precaution for files not
%             % coming in exact chronological order, possibly because they only come in approximate startTime order (due
%             % to varying time interval lengths for different files?).
%             if data.stopTime(dataRow) > stopTimeLatest
%                 stopTimeLatest = data.stopTime(dataRow);       % NOTE: The only place where "stopTimeLatest" is set (inside the for loop).
%             end
%         else
%             % CASE: Current file is identical (by filename) to the next.
%             % ==> Ignore file.
%             removeIndex(dataRow) = true;    % Remove data for duplicate EDITED SCI file.
%         end
%     end   % for
    
    %===================================================================================================================
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find macro 104 calibration files and group them into "sessions" (continuous runs) - new algorithm
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ASSUMPTION: Sorting of files by time (e.g. start time) does not split up continuous runs of the same macro.
    % Assumption could in principle be violated if multiple files have the same time but different macros.
    clear dataRow
    %data.modeSession = zeros(data.count,1);    % Components will (eventually) be assigned to the value of modeSession.
    removeIndex = zeros(length(inFilesData), 1);         % Indices to remove, in the form of one true/false flag for every index.
    previousModeSessionId = '';    % Default value represent a non-existing macro which is different from any existing macro.
    modeSessionId = 0;    % Identifies the session that the current file should belong to (not relevant for non-macro 104 files).
    
    for iFile = 1:length(inFilesData)
        %mode = data.mode(iFile,:);
        modeId = inFilesData(iFile).instrumentModeId;
        if strcmpi(modeId, 'MCID0X0104')
            % CASE: Found EDITED SCI file that is macro/mode 104.
            
            fprintf(1, 'Found CALIBRATION data (LBL file) %s -- %s\n', ...
                datestr(inFilesData(iFile).startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
                datestr(inFilesData(iFile).stopTime,  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG

            if ~strcmp(previousModeSessionId, modeId)
                % CASE: Found macro 104 file that was NOT preceeded by a macro 104 file.
                modeSessionId = modeSessionId + 1;
            end
            removeIndex(iFile) = false;
        else
            removeIndex(iFile) = true;
        end
        %data.modeSession(iFile) = modeSessionId;
        inFilesData(iFile).modeSessionId = modeSessionId;
        
        previousModeSessionId = modeId;
    end
    %===================================================================================================================
  
    %dataSessionStartTime(dataSession+1:data.count) = [];    % Remove unused indices at the end of vector.
    
    % Remove indices previously (above) selected for removal (data for selected EDITED SCI files).
%     indr = find(removeIndex);
%     data.mode(indr,:)         = [];
%     data.startTime(indr)      = [];
%     data.stopTime(indr)       = [];
%     data.pathName(indr,:)     = [];
%     data.fileName(indr,:)     = [];
%     %data.dataSession(indr)    = [];
%     data.modeSession(indr)    = [];
%     %data.cold(indr)           = [];
    inFilesData(find(removeIndex)) = [];    % Using "find" seems necessary despite MATLAB telling me I don't need it.
    
    %data.count = length(data.startTime);
    
    clear removeIndex;
    
    if (length(inFilesData)==0)
           disp('No calibration macros found. - Produces no calibration files.')
           return;    % EXIT
    end
    
    % Derive probe number from "filename" (really PRODUCT_ID)
    %temp = char(data.fileName);
    %data.probe = str2num(temp(:,22));
    %clear temp;
    for iFile = 1:length(inFilesData)
        inFilesData(iFile).probeNbr = str2double(inFilesData(iFile).relativeFilePath(end-7));
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Reads the TAB files containing the offsets.
    %   * Gets the offset parameters for each file:
    %       * Gradient
    %       * Intercept
    %       * Coefficient of correlation
    %   * First check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Progress: Working the offset data.');
    
%     data.gradient    = zeros(data.count,1);
%     data.intercept   = zeros(data.count,1);
%     data.correlation = zeros(data.count,1);
%     data.anomaly     = zeros(data.count,1);
%     data.cubeg  	 = zeros(data.count,1);
%     data.sqrg        = zeros(daxta.count,1);    

    for iFile = 1:length(inFilesData)
        %tabFilePath = fullfile(editedDatasetPath,strcat(data.pathName(iFile,1:end-4),'.TAB'));
        tabFilePath = fullfile(editedDatasetPath, strcat(inFilesData(iFile).relativeFilePath(1:end-4),'.TAB'));   % Exchange .LBL for .TAB.



        fileId = fopen(tabFilePath, 'r');
        
        inFilesData(iFile).intercept   = 0;       % Default value.
        inFilesData(iFile).gradient    = 0;       % Default value.
        inFilesData(iFile).sqrg        = 0;       % Default value.
        inFilesData(iFile).cubeg       = 0;       % Default value.
        inFilesData(iFile).correlation = 0;       % Default value.
        inFilesData(iFile).anomaly     = false;   % Default value.

        if ~(fileId>0)
            warning('write_MEAS_CALIB_file:CanNotReadFile', 'Can not open file %s', fname)
            continue
        end
        
        scan = textscan(fileId, '%*s %*f %f %f', 'Delimiter', ',');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   scan{1}: Units of current
        %   scan{2}: Units of voltage
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        fclose(fileId);
        
        voltage = scan{2};
        current = scan{1};
        
        clear scan;   % Effectively tell reader of code that this variable is not used later.
        
        firstVoltageValue = voltage(1);
        
        starterValueCounter = 1;
        
        while voltage(starterValueCounter+1) == firstVoltageValue
            
            starterValueCounter = starterValueCounter + 1;
        end
        
        voltage(1:starterValueCounter) = [];
        current(1:starterValueCounter) = [];
        
        if isempty(voltage)
            %data.anomaly(iFile) = true;
            inFilesData(iFile).anomaly = true;
        else
            % polyCoeffs = polyfit(voltage, current, 1);
            polyCoeffs = polyfit(voltage, current, 3);
            % FKJN edit 28/8 2014
            
            
            if diag
                polyCoeffs2 = polyfit(voltage, current, 1);
                figure(22);
                plot(voltage,current,'b',voltage,(polyCoeffs(1)*voltage.^3+polyCoeffs(2)*voltage.^2+polyCoeffs(3)*voltage+polyCoeffs(4)),'g',voltage,(polyCoeffs2(1)*voltage+polyCoeffs2(2)),'r')
                
                figure(23);
                plot(voltage,current-(polyCoeffs(1)*voltage.^3+polyCoeffs(2)*voltage.^2+polyCoeffs(3)*voltage+polyCoeffs(4)),'g',voltage,current-(polyCoeffs2(1)*voltage+polyCoeffs2(2)),'r')
            end
            
            %data.cubeg(iFile)     = polyCoeffs(1);
            %data.sqrg(iFile)      = polyCoeffs(2);
            %data.gradient(iFile)  = polyCoeffs(3);
            %data.intercept(iFile) = polyCoeffs(4);
            inFilesData(iFile).cubeg     = polyCoeffs(1);
            inFilesData(iFile).sqrg      = polyCoeffs(2);
            inFilesData(iFile).gradient  = polyCoeffs(3);
            inFilesData(iFile).intercept = polyCoeffs(4);
            
            n = length(voltage);
            
            numerator = n*sum(voltage.*current) - sum(voltage)*sum(current);
            
            denominator = sqrt(n*sum(voltage.^2)-(sum(voltage))^2) * sqrt(n*sum(current.^2)-(sum(current))^2);
            
            %data.correlation(iFile) = abs(numerator / denominator);
            inFilesData(iFile).correlation = abs(numerator / denominator);
        end

    end   % for



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Second check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     anomalyIndices = find( ...
%         ( ...
%             (data.gradient < MIN_GRADIENT_1 | data.gradient > MAX_GRADIENT_1 | data.intercept < MIN_INTERCEPT_1 | data.intercept > MAX_INTERCEPT_1) ...
%           & (data.gradient < MIN_GRADIENT_2 | data.gradient > MAX_GRADIENT_2 | data.intercept < MIN_INTERCEPT_2 | data.intercept > MAX_INTERCEPT_2) ...
%         ) ...
%         | data.correlation < MIN_CORRELATION);
    anomalyIndices = find( ...
        ( ...
            ([inFilesData.gradient] < MIN_GRADIENT_1 | [inFilesData.gradient] > MAX_GRADIENT_1 | [inFilesData.intercept] < MIN_INTERCEPT_1 | [inFilesData.intercept] > MAX_INTERCEPT_1) ...
          & ([inFilesData.gradient] < MIN_GRADIENT_2 | [inFilesData.gradient] > MAX_GRADIENT_2 | [inFilesData.intercept] < MIN_INTERCEPT_2 | [inFilesData.intercept] > MAX_INTERCEPT_2) ...
        ) ...
        | [inFilesData.correlation] < MIN_CORRELATION);

    %data.anomaly(anomalyIndices) = true;
    for iFile = anomalyIndices(:)'    % NOTE: MUST use ROW VECTOR for values to iterate over.
        inFilesData(iFile).anomaly = true;
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines data points and associates values to be used from
    %     actual offset data of good status.
    %   * Start constructing new data structure "dataWrite" where each index
    %     in the end represents a TAB/LBL calibration file pair. Field vectors are
    %     initialized to greatest possibly needed size (?) and will
    %     eventually be trimmed down.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %dataWriteMaxLength = length(dataSessionStartTime) + max(data.modeSession);
    %dataWriteMaxLength = max(data.modeSession);
%     dataWriteMaxLength = max([inFilesData.modeSessionId]);
%     
%     dataWrite = struct;
%     dataWrite.count      = 0;
%     dataWrite.startTime  = zeros(dataWriteMaxLength,1);
%     dataWrite.gradient1  = zeros(dataWriteMaxLength,2);   % 2 = 2 probes.
%     dataWrite.gradient2  = zeros(dataWriteMaxLength,2);
%     dataWrite.gradient3  = zeros(dataWriteMaxLength,2);
%     dataWrite.intercepts = zeros(dataWriteMaxLength,2);
    outFilesData = [];
    
%    for modeSession = 1:max(data.modeSession)
    for modeSessionId = 1:max([inFilesData.modeSessionId])
        
        % Find all indices with data for (1) the current modeSession, and (2) each probe separately.
        %p1 = find(data.modeSession == modeSession & data.probe == 1 & data.cold == 0 & data.anomaly == 0);
        %p2 = find(data.modeSession == modeSession & data.probe == 2 & data.cold == 0 & data.anomaly == 0);
%         p1 = find(data.modeSession == modeSession & data.probe == 1 & data.anomaly == 0);
%         p2 = find(data.modeSession == modeSession & data.probe == 2 & data.anomaly == 0);
        p1 = find([inFilesData.modeSessionId] == modeSessionId & [inFilesData.probeNbr] == 1 & [inFilesData.anomaly] == 0);
        p2 = find([inFilesData.modeSessionId] == modeSessionId & [inFilesData.probeNbr] == 2 & [inFilesData.anomaly] == 0);
        
        if ~(isempty(p1) || isempty(p2))
            
            %dataWrite.count = dataWrite.count + 1;
            
            % Condenses multiple calibration sweeps into one by averaging fitting coefficients (for each probe)
            % -------------------------------------------------------------------------------------------------
            % NOTE:       This is likely technically wrong, although the result should be close to averaging calibration
            %             sweeps before fitting.
            % 2017-01-26: Anders Eriksson thinks it is acceptable to average fitting coefficients (although possibly
            %             slightly wrong).
            %minStartTime = min(min(data.startTime(p1)), min(data.startTime(p2)));
            %maxStartTime = max(max(data.startTime(p1)), max(data.startTime(p2)));
            %minStartTime = min(min([inFilesData(p1).startTime]), min([inFilesData(p2).startTime]));
            %maxStopTime  = max(max([inFilesData(p1).startTime]), max([inFilesData(p2).startTime]));
            
            % NOTE: Expanding struct array (e.g. inFilesData) fields (e.g. startTime) to array always yields a row
            % array.
            [minStartTime, iMin] = min([inFilesData(p1).startTime, inFilesData(p2).startTime]);
            [maxStopTime,  iMax] = max([inFilesData(p1).stopTime , inFilesData(p2).stopTime ]);
            
            % Time to use for the filename. This is chosen here since it is needed in two different locations later:
            % (1) for handling (eliminating) doubles, (2) for writing the file.
            fileNameTime = (minStartTime + maxStopTime) / 2; 
            
            %dataWrite.startTime (dataWrite.count)   = min(min(data.startTime(p1)), min(data.startTime(p2)));
            %outFilesData(end+1).startTime   = middleStartTime;                                             % NOTE: Expand size of struct: Add another calibration file.
            outFilesData(end+1).fileNameTime = fileNameTime;                                                % NOTE: Expands size of struct: Add another calibration file.
            outFilesData(end  ).startTime    = minStartTime;
            outFilesData(end  ).stopTime     = maxStopTime;
            outFilesData(end  ).startTimeSc  = inFilesData(iMin).startTimeSc;
            outFilesData(end  ).stopTimeSc   = inFilesData(iMax).stopTimeSc;
%             dataWrite.gradient1 (dataWrite.count,:) = [mean(data.gradient (p1)) mean(data.gradient (p2))];
%             dataWrite.gradient2 (dataWrite.count,:) = [mean(data.sqrg     (p1)) mean(data.sqrg     (p2))];
%             dataWrite.gradient3 (dataWrite.count,:) = [mean(data.cubeg    (p1)) mean(data.cubeg    (p2))];
%             dataWrite.intercepts(dataWrite.count,:) = [mean(data.intercept(p1)) mean(data.intercept(p2))];
            outFilesData(end).gradient1  = [mean([inFilesData(p1).gradient ]), mean([inFilesData(p2).gradient ])];
            outFilesData(end).gradient2  = [mean([inFilesData(p1).sqrg     ]), mean([inFilesData(p2).sqrg     ])];
            outFilesData(end).gradient3  = [mean([inFilesData(p1).cubeg    ]), mean([inFilesData(p2).cubeg    ])];
            outFilesData(end).intercepts = [mean([inFilesData(p1).intercept]), mean([inFilesData(p2).intercept])];
        end
    end

    % Delete indices which have never been used for data.
%     dataWrite.startTime (dataWrite.count+1:dataWriteMaxLength)   = [];
%     dataWrite.gradient1 (dataWrite.count+1:dataWriteMaxLength,:) = [];
%     dataWrite.gradient2 (dataWrite.count+1:dataWriteMaxLength,:) = [];
%     dataWrite.gradient3 (dataWrite.count+1:dataWriteMaxLength,:) = [];
%     dataWrite.intercepts(dataWrite.count+1:dataWriteMaxLength,:) = [];
    % NOTE: dataWrite.count is already correct.

    % NOTE: At this point the "data" variable is basically never used again. Can not clear it though, since
    %       it is used for displaying the summary and for returning data.
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Amendment Erik Johansson, 2015-02-04:
    % -------------------------------------
    % Prevent function from creating calibration files if there is no usable calibration data.
    % This can happen if there is only one macro 104 in the archive (so far) and it comes first
    % in the archive (making that calibration data "cold"). Example: archive for Feb 2015.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %if (dataWrite.count == 0)
    %       disp('Found calibration macros, but all data is either labeled as cold or as having anomalies. - Produces no calibration files.')
    %       return;
    %end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines data points associated with days of data session
    %     starts that are not covered by days of actual data points.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOTE: Uncertain what this algorithm actually does.
    %       It seems to add data to dataWrite in new indices (thus increasing dataWrite.count; adds new calibration
    %       files) for data sessions where the data session and mode session do NOT begin on the same day. Some kind of
    %       special case? Should be unnecessary since algorithms have been changed and "data sessions" have been abolished.
    %       /Erik P G Johansson 2017-01-26
%     actualData = dataWrite.count;
%     
%     for dataSessionCounter = 1:length(dataSessionStartTime)
%         
%         if isempty(find(floor(dataWrite.startTime) == floor(dataSessionStartTime(dataSessionCounter)), 1, 'first'))
%             % CASE: Mode session start time and data session start time DO NOT occur in the same day (?).
%             
%             dataWrite.count = dataWrite.count + 1;
%             
%             earlyIndex = find(dataWrite.startTime <= dataSessionStartTime(dataSessionCounter) & dataWrite.startTime >  0, 1, 'first');
%             lateIndex  = find(dataWrite.startTime >  dataSessionStartTime(dataSessionCounter), 1, 'first');
%             
%             dataWrite.startTime(dataWrite.count) = dataSessionStartTime(dataSessionCounter);
%             
%             if isempty(earlyIndex)
%                 
%                 dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(1,:);
%                 dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(1,:);
%                 dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(1,:);
%                 dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(1,:);
%                 
%             elseif isempty(lateIndex)
%                 
%                 dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(actualData,:);
%                 dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(actualData,:);
%                 dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(actualData,:);                                
%                 dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(actualData,:);
%                 
%             else
%                 
%                 % Derive time into the data session as a fraction.
%                 fractionTime = (dataWrite.startTime(dataWrite.count)-dataWrite.startTime(earlyIndex)) ...
%                              / (dataWrite.startTime(lateIndex      )-dataWrite.startTime(earlyIndex));
%                 
%                 % Extrapolate calibrations to a time for which there is no calibration data?!!  /Erik P G Johansson 2017-01-26
%                 dataWrite.gradient1 (dataWrite.count,:) = dataWrite.gradient1 (earlyIndex,:) + fractionTime*(dataWrite.gradient1 (lateIndex,:) - dataWrite.gradient1 (earlyIndex,:));
%                 dataWrite.gradient2 (dataWrite.count,:) = dataWrite.gradient2 (earlyIndex,:) + fractionTime*(dataWrite.gradient2 (lateIndex,:) - dataWrite.gradient2 (earlyIndex,:));
%                 dataWrite.gradient3 (dataWrite.count,:) = dataWrite.gradient3 (earlyIndex,:) + fractionTime*(dataWrite.gradient3 (lateIndex,:) - dataWrite.gradient3 (earlyIndex,:));
%                 dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(earlyIndex,:) + fractionTime*(dataWrite.intercepts(lateIndex,:) - dataWrite.intercepts(earlyIndex,:));
%             end
%         end
%     end
%
%     % Delete indices which have never been used for data.
%     dataWrite.startTime (dataWrite.count+1:dataWriteMaxLength)   = [];
%     dataWrite.gradient1 (dataWrite.count+1:dataWriteMaxLength,:) = [];
%     dataWrite.gradient2 (dataWrite.count+1:dataWriteMaxLength,:) = [];
%     dataWrite.gradient3 (dataWrite.count+1:dataWriteMaxLength,:) = [];
%     dataWrite.intercepts(dataWrite.count+1:dataWriteMaxLength,:) = [];

%    actualData = dataWrite.count;   % Make old code compatible with new code without renaming old variable.

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * In case of multiple calibration data for the same day, remove all but the FIRST one during that day.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    removeIndex = zeros(length(outFilesData),1);
    
%    if(actualData>1)
        
        %for iFile = 1:(actualData-1)
        for iFile = 1:(length(outFilesData)-1)
            
            %if floor(dataWrite.startTime(iFile)) == floor(dataWrite.startTime(iFile+1))
                % CASE: Same start time as the calibration data after it.
                
                %removeIndex(iFile+1) = floor(outFilesData(iFile).startTime) == floor(outFilesData(iFile+1).startTime);
            %end
            
            % CASE: True iff same time as the calibration data after it.
            %removeIndex(iFile+1) = floor(outFilesData(iFile).startTime) == floor(outFilesData(iFile+1).startTime);
            removeIndex(iFile+1) = floor(outFilesData(iFile).fileNameTime) == floor(outFilesData(iFile+1).fileNameTime);
        end
        
%         dataWrite.startTime( find(removeIndex))   = [];
%         dataWrite.gradient1( find(removeIndex),:) = [];
%         dataWrite.gradient2( find(removeIndex),:) = [];
%         dataWrite.gradient3( find(removeIndex),:) = [];
%         dataWrite.intercepts(find(removeIndex),:) = [];
        outFilesData(find(removeIndex)) = [];    % Using "find" seems necessary despite MATLAB telling me I don't need it.

%    end
    
    %dataWrite.count = length(dataWrite.startTime);
    
    clear removeIndex;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Writes all the CALIB_MEAS/_COEF files for each of the base folders.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %for dataWriteCounter = 1:dataWrite.count
    for iFile = 1:length(outFilesData)
  
        %fileName  = strcat('RPCLAP', datestr(dataWrite.startTime(dataWriteCounter), 'yymmdd'), '_CALIB_MEAS');
        %coeffFileNameBase = strcat('RPCLAP', datestr(dataWrite.startTime(dataWriteCounter), 'yymmdd'), '_CALIB_COEF');        
        outFileNameDateStr = datestr(outFilesData(iFile).fileNameTime, 'yymmdd');
        outFileNameBase   = strcat('RPCLAP', outFileNameDateStr, '_CALIB_MEAS');
        coeffFileNameBase = strcat('RPCLAP', outFileNameDateStr, '_CALIB_COEF');
        
        voltage = 0:1:255;
        
        %currentP1 = dataWrite.intercepts(dataWriteCounter,1) + dataWrite.gradient1(dataWriteCounter,1)*voltage +dataWrite.gradient2(dataWriteCounter,1)*voltage.^2 +dataWrite.gradient3(dataWriteCounter,1)*voltage.^3;
        %currentP2 = dataWrite.intercepts(dataWriteCounter,2) + dataWrite.gradient1(dataWriteCounter,2)*voltage +dataWrite.gradient2(dataWriteCounter,2)*voltage.^2 +dataWrite.gradient3(dataWriteCounter,2)*voltage.^3;
        currentP1 = outFilesData(iFile).intercepts(1) + outFilesData(iFile).gradient1(1)*voltage + outFilesData(iFile).gradient2(1)*voltage.^2 + outFilesData(iFile).gradient3(1)*voltage.^3;
        currentP2 = outFilesData(iFile).intercepts(2) + outFilesData(iFile).gradient1(2)*voltage + outFilesData(iFile).gradient2(2)*voltage.^2 + outFilesData(iFile).gradient3(2)*voltage.^3;
        currentP1 = floor(currentP1*1E6+0.5) / 1E6;  % Rounding after six decimals. fprintf will try to round this later, but does so incorrectly.
        currentP2 = floor(currentP2*1E6+0.5) / 1E6;
        
        
        lblFilePath = fullfile(outDirPath, strcat(outFileNameBase, '.LBL'));
        tabFilePath = fullfile(outDirPath, strcat(outFileNameBase, '.TAB'));
        
        coeffFilePath = fullfile(CALIB_COEF_files_dir, strcat(coeffFileNameBase, '.TXT'));
        
        
        %%%%%%%%%%%%%%%%%%
        % Create LBL file
        %%%%%%%%%%%%%%%%%%
        fileId = fopen(lblFilePath, 'wt');
        
        fprintf(fileId, 'PDS_VERSION_ID = PDS3\r\n');
        %fprintf(fileId, 'LABEL_REVISION_NOTE = "2015-06-03, EJ: Updated LAP_*_CAL_20B* calibration factors"\r\n');
        %fprintf(fileId, 'LABEL_REVISION_NOTE = "2015-07-07, EJ: RECORD_BYTES=31"\r\n');   % Use??
        fprintf(fileId, 'LABEL_REVISION_NOTE = "2017-01-27, EJ: Updated metadata; start/stop times, DESCRIPTION, UNIT"\r\n');
        fprintf(fileId, 'RECORD_TYPE = FIXED_LENGTH\r\n');
        fprintf(fileId, 'RECORD_BYTES = 31\r\n');
        fprintf(fileId, 'FILE_RECORDS = 256\r\n');
        fprintf(fileId, strcat('FILE_NAME = "', outFileNameBase, '.LBL"\r\n'));
        fprintf(fileId, strcat('^TABLE = "',    outFileNameBase, '.TAB"\r\n'));
        fprintf(fileId, 'DATA_SET_ID = "%s"\r\n', datasetDirName);
        
        % DATA_SET_NAME is optional, RO-EST-TN-3372, "ROSETTA Archiving Conventions", Issue 7, Rev. 8
        %fprintf(fileId, 'DATA_SET_NAME = "ROSETTA-ORBITER EARTH RPCLAP 3 MARS CALIB V1.0"\r\n');    % Incorrect value.
        
        fprintf(fileId, 'MISSION_ID = ROSETTA\r\n');
        fprintf(fileId, 'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\r\n');
        fprintf(fileId, 'MISSION_PHASE_NAME = "%s"\r\n', missionPhaseName);
        fprintf(fileId, 'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\r\n');
        fprintf(fileId, 'PRODUCER_ID = EJ\r\n');
        fprintf(fileId, 'PRODUCER_FULL_NAME = "ERIK P G JOHANSSON"\r\n');
        fprintf(fileId, strcat('PRODUCT_ID = "', outFileNameBase, '"\r\n'));
        fprintf(fileId, horzcat('PRODUCT_CREATION_TIME = ', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), '\r\n'));
        fprintf(fileId, 'INSTRUMENT_HOST_ID = RO\r\n');
        fprintf(fileId, 'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\r\n');
        fprintf(fileId, 'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\r\n');
        fprintf(fileId, 'INSTRUMENT_ID = RPCLAP\r\n');
        fprintf(fileId, 'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\r\n');
        fprintf(fileId, 'START_TIME = %s\r\n',                   datestr(outFilesData(iFile).startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(fileId, 'SPACECRAFT_CLOCK_START_COUNT = %s\r\n', outFilesData(iFile).startTimeSc);                 % NOTE: Spacecraft clock time is quoted. Field value is already quoted.
        fprintf(fileId, 'STOP_TIME = %s\r\n',                    datestr(outFilesData(iFile).stopTime, 'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(fileId, 'SPACECRAFT_CLOCK_STOP_COUNT = %s\r\n',  outFilesData(iFile).stopTimeSc);                  % NOTE: Spacecraft clock time is quoted. Field value is already quoted.
        %fprintf(fileId, 'DESCRIPTION = "CONVERSION FROM TM UNITS TO AMPERES AND VOLTS"\r\n');
        fprintf(fileId, 'DESCRIPTION = "ADC16 CURRENT OFFSETS. CONVERSION FROM TM UNITS TO AMPERES AND VOLTS."\r\n');
        
        %----------------------------------------------------------------------------------------
        fprintf(fileId, 'ROSETTA:LAP_VOLTAGE_CAL_16B = "1.22072175E-3"\r\n');
        %--------
        %fprintf(fileId, 'ROSETTA:LAP_VOLTAGE_CAL_20B = "7.62940181E-5"\r\n');   % Original value used up until ca 2015-06-11.
        fprintf(fileId, 'ROSETTA:LAP_VOLTAGE_CAL_20B = "7.534142050781250E-05"\r\n');   %  1.22072175E-3 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28.
        %--------    
        fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_16B_G1 = "3.05180438E-10"\r\n');
        %--------        
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.90735045E-11"\r\n');   % Original value used up until ca 2015-06-11.
        fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.883535515781250E-11"\r\n');   % 3.05180438E-10 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28.
        %--------        
        fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_16B_G0_05 = "6.10360876E-9"\r\n');
        %--------        
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.81470090E-10"\r\n');   % Original value used up until ca 2015-06-11.
        fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.767071031562500E-10"\r\n');     % 6.10360876E-9 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28.
        %----------------------------------------------------------------------------------------
        
        fprintf(fileId, 'OBJECT = TABLE\r\n');
        fprintf(fileId, 'INTERCHANGE_FORMAT = ASCII\r\n');
        fprintf(fileId, 'ROWS = 256\r\n');
        fprintf(fileId, 'COLUMNS = 3\r\n');
        fprintf(fileId, 'ROW_BYTES = 31\r\n');
        fprintf(fileId, 'DESCRIPTION = "THIRD DEGREE POLYNOMIAL OFFSET CORRECTION FOR ADC16 DENSITY DATA"\r\n');
        
        fprintf(fileId, 'OBJECT = COLUMN\r\n');
        fprintf(fileId, 'NAME = P1P2_VOLTAGE\r\n');
        fprintf(fileId, 'DATA_TYPE = ASCII_INTEGER\r\n');
        fprintf(fileId, 'UNIT = "TM UNITS"\r\n');
        fprintf(fileId, 'START_BYTE = 1\r\n');
        fprintf(fileId, 'BYTES = 3\r\n');
        fprintf(fileId, 'DESCRIPTION = "VOLTAGE APPLIED TO BIAS P1 AND P2"\r\n');
        fprintf(fileId, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileId, 'OBJECT = COLUMN\r\n');
        fprintf(fileId, 'NAME = P1_CURRENT\r\n');
        fprintf(fileId, 'DATA_TYPE = ASCII_REAL\r\n');
        fprintf(fileId, 'UNIT = "TM UNITS"\r\n');
        fprintf(fileId, 'START_BYTE = 5\r\n');
        fprintf(fileId, 'BYTES = 12\r\n');
        fprintf(fileId, 'DESCRIPTION = "INSTRUMENT OFFSET"\r\n');
        fprintf(fileId, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileId, 'OBJECT = COLUMN\r\n');        
        fprintf(fileId, 'NAME = P2_CURRENT\r\n');
        fprintf(fileId, 'DATA_TYPE = ASCII_REAL\r\n');
        fprintf(fileId, 'UNIT = "TM UNITS"\r\n');
        fprintf(fileId, 'START_BYTE = 18\r\n');
        fprintf(fileId, 'BYTES = 12\r\n');
        fprintf(fileId, 'DESCRIPTION = "INSTRUMENT OFFSET"\r\n');
        fprintf(fileId, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileId, 'END_OBJECT = TABLE\r\n');
        
        fprintf(fileId, 'END\r\n');
        
        fclose(fileId);
        
        
        
        %%%%%%%%%%%%%%%%%%
        % Create TAB file
        %%%%%%%%%%%%%%%%%%
        fileId = fopen(tabFilePath, 'wt');
        fprintf(1, 'Writing %s\n', tabFilePath);
        for iRow = 1:256            
            fprintf(fileId, horzcat(sprintf('%03.0f', voltage(iRow)), ',', sprintf('%12.6f', currentP1(iRow)), ',', sprintf('%12.6f', currentP2(iRow)), '\r\n'));
        end
        fclose(fileId);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Write CEOFF file - Extra calibration coefficient files (for debugging)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        fileId = fopen(coeffFilePath, 'wt');
        fprintf(fileId,'# 3rd order polynomial fit coefficients (current = aV^3+b*V^2+c*V+d), for Probe 1 and Probe 2 in TM units.\r\n');
        fprintf(fileId,'aP1,bP1,cP1,dP1,aP2,bP2,cP2,dP2\r\n');
%         fprintf(fileId,'%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e\r\n', ...
%             dataWrite.gradient3(dataWriteCounter,1), dataWrite.gradient2(dataWriteCounter,1), dataWrite.gradient1(dataWriteCounter,1), dataWrite.intercepts(dataWriteCounter,1), ...
%             dataWrite.gradient3(dataWriteCounter,2), dataWrite.gradient2(dataWriteCounter,2), dataWrite.gradient1(dataWriteCounter,2), dataWrite.intercepts(dataWriteCounter,2));
        fprintf(fileId,'%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e\r\n', ...
            outFilesData(iFile).gradient3(1), outFilesData(iFile).gradient2(1), outFilesData(iFile).gradient1(1), outFilesData(iFile).intercepts(1), ...
            outFilesData(iFile).gradient3(2), outFilesData(iFile).gradient2(2), outFilesData(iFile).gradient1(2), outFilesData(iFile).intercepts(2));
        fclose(fileId);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Displays the output summary.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %nOutCalibrationFiles = dataWrite.count;
    nOutCalibrationFiles = length(outFilesData);
    nInFiles      = length(inFilesData);
    %nInFileAnomalies     = length(find(data.anomaly));
    nInFileAnomalies     = length(find([inFilesData.anomaly]));
    %numberCold        = length(find(data.cold));
    %nInFilesGood        = nInFiles - numberCold - nInFileAnomalies;
    nInFilesGood        = nInFiles - nInFileAnomalies;

    display('Progress: Work complete.   ');
    display('                           ');
    display('=============================================');
    display('                   SUMMARY                   ');
    display('=============================================');
    display('                           ');
    display([' Output calibration files:             ', sprintf('%3.0f', nOutCalibrationFiles)]);
    display('                           ');
    display('                           ');
    display([' Input offset files:                   ', sprintf('%3.0f', nInFiles)]);
    display('                           ');
    display(['    Input offset files with anomalies: ', sprintf('%3.0f', nInFileAnomalies)]);
    display('                           ');
    display(['    Good input offset files:           ', sprintf('%3.0f', nInFilesGood)]);
    display('                           ');
    display(sprintf(' Elapsed wall time: %6.0f s', etime(clock, scriptStartTimeVector)));
    display('                           ');
    display('=============================================');
    display('                           ');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines whether to supply the offset data as output argument.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargout == 1
        
        %varargout(1) = {data};
        varargout(1) = {inFilesData};
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
