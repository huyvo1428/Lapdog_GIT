function [varargout] = write_CALIB_MEAS_files(pearch,mp,outpath)
%
% write_CALIB_MEAS_files
%	
%   This program computes calibration files (*_CALIB_MEAS.TAB/.LBL) 
%   that can then be used by the PDS software to create the calibrated data sets.
%   Also, a separate calibration coefficient list file is created for debugging purposes
%   (and for which the output directory is hardcoded).
%   
%   ARGUMENTS
%   ---------
%   pearch  = Path to EDITED data set, e.g. '/data/LAP_ARCHIVE/RO-E-RPCLAP-2-EAR3-EDITED-V1.0'
%   mp      = ("Long") mission phase name, e.g. "COMET ESCORT 3". (Needed for LBL file keyword MISSION_PHASE_NAME.)
%   outpath = Output path (directory)
%
%   SYNTAX
%   ------
%                    write_CALIB_MEAS_files(pearch, missionphasename, outpath)
%       
%       offsetData = write_CALIB_MEAS_files(pearch, missionphasename, outpath)
%
%   ----------------------------------------------------------------------------
%   Usage: However the Swedish Institute of Space Physics sees fit.
%   Version: 1.2
%
%   Author: Martin Ulfvik 
%   Rewritten by Reine Gill
%   ----------------------------------------------------------------------------
%   Third degree polynomial solution by FKJN 28/8 2014
%
%   Added condition for only being able to label calibration data "cold" if they come before a
%   specified date OR are not the very first in the archive.
%   /Fredrik Johansson, Erik P G Johansson, 2015-02-04
%
%   Primarily added check for finding calibration data which are not useful.
%   /Erik P G Johansson, 2015-02-04
%   
%   Updated ADC20 TM-to-physical-units conversion factors in the LBL files according to calibration of
%   ADC20 relative ADC16 based on data for 2015-05-28. New values are multiples of ADC16 values
%   and are used retroactively.
%   /Erik P G Johansson 2015-06-11
%
%   Bug fix: Updated to RECORD_BYTES=31 (characters per row incl CR+LF). Was previously 7936 (file size).
%   /Erik P G Johansson 2015-07-07
%
%   Updated to INSTRUMENT_ID = RPCLAP (no quotes).
%   /Erik P G Johansson 2015-07-08
%   ----------------------------------------------------------------------------
%   NOTE: The current implementation (2015-05-08) sets START_TIME to an actual time, but sets SPACECRAFT_CLOCK_START_COUNT = "N/A". Change?
%   NOTE: As of 2016-04-07, this software is designed for MATLAB R2009A to make it possible to still run on squid.
%   BUG: As of 2017-01-23, appears to yield error if both the dataset contains no calibrations, and the return value is
%   requested.
%   BUG: As of 2017-01-23, sometimes produces CALIB_MEAS files for non-existing runs of the calibration macro.
%   

    t_start = clock;    % Script start time. NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute seconds].

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Sets hardcoded values for the basic parameters.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DATA_SESSION_RESET_TIME = 1;           % Unit: days
    MODE_SESSION_RESET_TIME = 1/(24*2);    % Unit: days
    
    MIN_GRADIENT_1 = -4.2;
    MAX_GRADIENT_1 = -3.3;
    
    MIN_INTERCEPT_1 = 410;
    MAX_INTERCEPT_1 = 600;
    
    MIN_GRADIENT_2 = -2.5;
    MAX_GRADIENT_2 = -1.7;
    
    MIN_INTERCEPT_2 = 200;
    MAX_INTERCEPT_2 = 390;
    
    MIN_CORRELATION = 0.99;
    
    CALIB_COEF_files_dir = '/data/LAP_ARCHIVE/CALIB_MEAS_files/';   % Directory path to where to save calibration coefficients files for debugging.
    %CALIB_COEF_files_dir = '~/temp/coeffs';   % Directory path to where to save calibration coefficients files for debugging.
    
    INITIAL_CALIBDATA_NEVER_COLD_AFTER_TIME = datenum('2014-06-01T00:00:00.000', 'yyyy-mm-ddTHH:MM:SS.FFF');   % Unit: days
    
    diag = 0;    % Flag for whether to display debugging plots.
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Validates the input/output arguments used.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % NOTE: "error" throws no error if the input argument is [].
    error(nargchk(3,3, nargin));
    error(nargoutchk(0, 1, nargout));
    
    % NOTE: It is useful to check for existence of directories directly since their non-existence will
    % otherwise produce an error first after a lot of processing (after delay).
    if ~exist(outpath, 'dir')
        error('Can not find directory "%s".', outpath)
    end
    if ~exist(CALIB_COEF_files_dir, 'dir')
        error('Can not find directory "%s".', CALIB_COEF_files_dir)
    end
   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Finds the relevant folders
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp('Paths');
    disp('----------------------------------------------------------------');
    epath = fullfile(pearch);        % Full Edited archive path

    fprintf(1,'Edited Archive and path: %s\r\n',epath);
    fprintf(1,'Mission phase: %s\r\n',mp);
    fprintf(1,'Output calibration file path: %s\r\n\r\n',outpath);

    ipath = fullfile(epath,'INDEX'); % Full index file path

    dpath = fullfile(epath,'DATA');  % Full data file path

    if pearch(end) == filesep        
        pearch(end) = [];    % Remove trailing file separator (slash).
    end
    [dummy, earch] = fileparts(pearch);    % Split to get DATA_SET_ID. NOTE: Sensitive to whether path ends with slash or not.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Extracts the information from the index file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %   index{1}{:} = Paths to LBL files (relative to dataset)
    %   index{2}{:} = LBL PRODUCT_ID (effectively LBL filename without suffix)
    %   index{3}{:} = START_TIME as number of days since reference date (using datenum)
    %   index{4}{:} = STOP_TIME  as number of days since reference date (using datenum)
    %   index{5}{:} = INSTRUMENT_MODE_ID as original string (e.g. 'MCID0X0204')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    filePath = fullfile(ipath,'INDEX.TAB');
    fileID   = fopen(filePath, 'r');

    if(fileID<=0)
        fprintf(1,'Could not open file: %s',filePath);
        return;
    end

    % Read contents of INDEX.TAB into an analogue 2D array
    % ----------------------------------------------------
    % Example excerpt from INDEX.TAB:
    % "DATA/EDITED/2007/SEP/D16/RPCLAP070916_00FT_REB18NS.LBL","RPCLAP070916_00FT_REB18NS",2016-04-07T07:50:48,"RO-E-RPCLAP-2-EAR2-EDITED-V0.5"
    % "DATA/EDITED/2007/SEP/D16/RPCLAP070916_001_H.LBL       ","RPCLAP070916_001_H       ",2016-04-07T07:50:48,"RO-E-RPCLAP-2-EAR2-EDITED-V0.5"
    % "DATA/EDITED/2007/SEP/D16/RPCLAP070916_00NT_REB18NS.LBL","RPCLAP070916_00NT_REB18NS",2016-04-07T07:50:48,"RO-E-RPCLAP-2-EAR2-EDITED-V0.5"
    index = textscan(fileID,'%s%s%*s%*s%*s%*s','Delimiter',','); 

    fclose(fileID);


    nfiles = length(index{1});

    fprintf(1,'Trimming quotes from LBL file paths in "index"\n');
    for ind=1:nfiles
        index{1}{ind}(1)=' ';
        index{1}{ind}(end)=' ';
        index{1}{ind}=strtrim(index{1}{ind});

        if(mod(ind,100)==0)
        fprintf(1,'\rProgress % 04.1f %%',100*ind/nfiles);
        end
    end

    fprintf(1,'\n');

    ind=1;
    fprintf(1,'Removing housekeeping (HK) files from "index"\n');
    while(ind<nfiles)
      if(index{1}{ind}(end-4)=='H')
        index{1}(ind)=[];
        index{2}(ind)=[]; 
        nfiles=nfiles-1;
      else
        ind=ind+1;
      end

      if(mod(ind,100)==0)
        fprintf(1,'\rProgress % 04.1f %%',100*ind/nfiles);
      end
    end

    fprintf(1,'\n');

    % Extract start and stop time from the data files (no longer in the index file)

    fprintf(1,'Opening each file in the index file to get the start, stop time and mode\n');

    nfiles = length(index{1});

    % Iterate over all non-HK files mentioned in INDEX.TAB.
    for ind=1:nfiles

        fname=fullfile(pearch,index{1}{ind});
        fileID=fopen(fname,'r');

        if(fileID>0)
            state=0;    % Effectively a counter for how many of the sought PDS keywords that have been found so far.
            while(~feof(fileID) && state<3)

                line = fgetl(fileID);

                if(~isempty(line))
                    % Check if BEGINNING of the line matches varying strings.

                    if(strncmp(line,'START_TIME',10))
                        start_time=line;
                        state=state+1;
                    end

                    if(strncmp(line,'STOP_TIME',9))
                        stop_time=line;
                        state=state+1;
                    end

                    if(strncmp(line,'INSTRUMENT_MODE_ID',18))
                        mode=line;
                        state=state+1;
                    end

                end   % if
            end   % while
            fclose(fileID);
        end   % if

        [tmp,str]=strread(start_time,'%s%s','delimiter','=');
        value=datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');     % NOTE: "str" is a cell containing a string, but datenum can handle that.
        index{3}{ind,1}=value;

        [tmp,str]=strread(stop_time,'%s%s','delimiter','=');
        value=datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');
        index{4}{ind,1}=value;

        [tmp,value]=strread(mode,'%s%s','delimiter','=');
        index{5}{ind,1}=char(value);     % char(value) converts (cell containing string) --> string.

        if(mod(ind,100)==0)
            fprintf(1,'\rProgress % 04.1f %%',100*ind/nfiles);
        end
    end   % for
    
    fprintf(1,'\n');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Moves the data from cell array "index" to struct "data".
    %     "data" struct fields contain data as regular NxM arrays,
    %     where rows are constant length, e.g. data.mode(i_file, j).
    %   * Start constructing structure "data" which will in the end be
    %     returned to the caller (optional; depends on caller).
    %     Each index in the fields refers to an EDITED SCI LBL file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Progress: Changing internal data format.');
    
    data = struct;
    
    
    data.pathName       = char(index{1});    
    data.fileName       = char(index{2});
    data.startTime      = [index{3}{:}]';
    data.stopTime       = [index{4}{:}]';
    data.mode           = char(index{5});
    
    data.count =  length(data.startTime);
  
    %clear index;
    

  
    clear index  % Effectively tell the reader of the source code that this variable will never be used again.



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Finds out when each data session starts.
    %   * For each offset data, it determines which probe, data session and
    %     mode session it belongs to and whether it was run in a cold state.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOTE: Judging from the code, this is what terms mean (2017-01-25):
    %   data session = A continuous sequence of LBL files (any combination of macros)
    %                  that is not uninterrupted by more time than DATA_SESSION_RESET_TIME.
    %   mode session = Either (1) ONE                      cold LBL file  with macro 104, followed by
    %                             N (N>=0)                 warm LBL files with macro 104 (but labelled with cold=true)
    %                  or     (2) a continuous sequence of warm LBL files with macro 104.
    %   Note that non-macro 104 LBL files are removed from the list in the end.
    
    % PROPOSAL: Rename mode session ==> calib session
    %                  dataSession  ==> dataSessionId
    %                  modeSession  ==> modeSessionId (calibSessionId)
    %                  dataRow      ==> iLblFile, iData (or similar)

    display('Progress: Identify calibration sessions in "index".');

    % Initialized to the largest size that could theoretically be needed. Is later reduced in size.
    % Stores the starting time of each data session, data.startTime(dataRow).
    % PRESUMED BUG: Is used for setting date of calibration files. 
    dataSessionStartTime = zeros(data.count,1);

    data.dataSession = zeros(data.count,1);    % Components will (eventually) be assigned to the value of dataSession.
    data.modeSession = zeros(data.count,1);    % Components will (eventually) be assigned to the value of modeSession.
    data.cold        = zeros(data.count,1);    % Components will (eventually) be assigned to the value of coldState.

    dataSession = 0;         % In the for loop: Index into dataSessionStartTime. Every unique value refers to a sequence of EDITED SCI
                             % files (ANY macro) without too long interruptions in time (DATA_SESSION_RESET_TIME) between the files.
    modeSession = 0;         % In the for loop: Every unique value refers to a sequence of macro 104-EDITED SCI files,
                             % that is uninterrupted by non-macro 104-EDITED SCI files.

    nextWarmDataBeginsWarmModeSession = true;   % In the for loop: Seems to refer to modeSession (is always set to false after incrementing modeSession).
    
    coldState  = true;       % In the for loop: Can only be set/changed after a new mode session has started.
                             % ==> data.cold(...) always has the same value for an entire "mode session".
    stopTimeLatest = 0;      % stopTime value of previous SCI file (all macros).
                             % Initial value zero corresponds to a time long ago (approximately year zero, "0 A.D.").
                             % ==> If the first EDITED SCI file is macro 104, then that entire mode (macro 104-) session will be "cold".
    
    removeIndex = zeros(data.count,1);    % Indices to remove, in the form of one true/false flag for every index.

    % Iterate over all SCI LBL files.
    for dataRow = 1:data.count

        if (dataRow == data.count) || (~strcmp(data.fileName(dataRow,:), data.fileName(dataRow+1,:)))
            % CASE: Last file in list, OR, this file and the next file in the list are NOT identical (why check?!!).

            if data.startTime(dataRow) - stopTimeLatest >= DATA_SESSION_RESET_TIME
                % CASE: Time between this EDITED SCI file (ANY macro) and
                % the most recent previous EDITED SCI file (ANY macro) exceeds DATA_SESSION_RESET_TIME (default 1 day).
                % ==> Start new "DATA session".

                %fprintf(1, 'Found beginning of data session. First LBL file: %s -- %s\n', ...
                %    datestr(data.startTime(dataRow), 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
                %    datestr(data.stopTime(dataRow),  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG
                
                dataSession = dataSession + 1;                                 % NOTE: This is the only place where "dataSession"          is set (inside the for loop).
                dataSessionStartTime(dataSession) = data.startTime(dataRow);   % NOTE: This is the only place where "dataSessionStartTime" is set (inside the for loop).
            end

            if strcmp(upper(data.mode(dataRow,:)),'MCID0X0104')
                % CASE: Found EDITED SCI file that is macro/mode 104.

                %fprintf(1, 'Found CALIBRATION data (LBL file) %s -- %s\n', ...
                %    datestr(data.startTime(dataRow), 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
                %    datestr(data.stopTime(dataRow),  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG

                possiblyLabelAsColdState = (data.startTime(dataRow) < INITIAL_CALIBDATA_NEVER_COLD_AFTER_TIME) || (dataRow > 1);   % Amendment Erik Johansson 2015-02-04

                if (data.startTime(dataRow) - stopTimeLatest >= MODE_SESSION_RESET_TIME) && possiblyLabelAsColdState
                    % CASE: "Cold LBL file", i.e.
                    %       time between (1) this EDITED SCI file (macro 104) and
                    %                    (2) the most recent previous EDITED SCI file (ANY macro)
                    %       exceeds MODE_SESSION_RESET_TIME (default 30 min).
                    %fprintf(1, '    LBL file is "COLD".\n')

                    % ==> Start new "MODE session"
                    modeSession = modeSession + 1;
                    nextWarmDataBeginsWarmModeSession = false;

                    % ==> Set COLD state
                    coldState = true;
                    data.cold(dataRow) = coldState;
                else
                    % CASE: "Warm LBL file" (can still be assigned cold/warm state)
                    %fprintf(1, '    LBL file is "WARM".\n')

                    if nextWarmDataBeginsWarmModeSession
                        % CASE: It has previously been "requested" to start a new mode session when encountering warm
                        % data.

                        % ==> Start new "MODE session"
                        modeSession = modeSession + 1;
                        nextWarmDataBeginsWarmModeSession = false;

                        % ==> Set WARM state
                        coldState = false;
                        data.cold(dataRow) = coldState;
                    else
                        % CASE: NOT nextWarmDataBeginsWarmModeSession

                        % ==> Reuse the previous cold/warm state.
                        data.cold(dataRow) = coldState;
                    end
                end

                data.dataSession(dataRow) = dataSession;
                data.modeSession(dataRow) = modeSession;              % NOTE: The only place where the value of modeSession is passed on.
            else
                % CASE: Found EDITED SCI file that is NOT macro/mode 104.
                % ==> Mark EDITED SCI file to (later) be removed from list.
                % ==> Request the starting of a new "mode session" if later finds another macro 104 EDITED SCI file.

                %fprintf(1, 'Found non-calibration LBL file: %s -- %s\n', ...
                %    datestr(data.startTime(dataRow), 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
                %    datestr(data.stopTime(dataRow),  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG
                
                removeIndex(dataRow) = true;
                nextWarmDataBeginsWarmModeSession = true;
            end

            % Update stopTimeLatest with latest stopTime so far, _regardless_ of the macro/mode of EDITED SCI file(s).
            %
            % NOTE: Checking if stopTime will be incremented (not decremented) seems to a precaution for files not
            % coming in exact chronological order, possibly because they only come in approximate startTime order (due
            % to varying time interval lengths for different files?).
            if data.stopTime(dataRow) > stopTimeLatest
                stopTimeLatest = data.stopTime(dataRow);       % NOTE: The only place where "stopTimeLatest" is set (inside the for loop).
            end
        else
            % CASE: Current file is identical (by filename) to the next.
            % ==> Ignore file.
            removeIndex(dataRow) = true;    % Remove data for duplicate EDITED SCI file.
        end
    end   % for
  
    dataSessionStartTime(dataSession+1:data.count) = [];    % Remove unused indices at the end of vector.
    
    % Remove indices previously (above) selected for removal (data for selected EDITED SCI files).
    indr = find(removeIndex);
    data.mode(indr,:)         = [];
    data.startTime(indr)      = [];
    data.stopTime(indr)       = [];
    data.pathName(indr,:)     = [];
    data.fileName(indr,:)     = [];
    data.dataSession(indr)    = [];
    data.modeSession(indr)    = [];
    data.cold(indr)           = [];
    
    data.count = length(data.startTime);
    
    clear removeIndex;
    
    if (data.count==0)
           disp('No calibration macros found. - Produces no calibration files.')
           return;    % EXIT
    end
    
    temp = char(data.fileName);
    data.probe = str2num(temp(:,23));
    clear temp;
   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Reads the TAB files containing the offsets.
    %   * Gets the offset parameters for each file:
    %       * Gradient
    %       * Intercept
    %       * Coefficient of correlation
    %   * First check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Progress: Working the offset data.');
    
    data.gradient    = zeros(data.count,1);
    data.intercept   = zeros(data.count,1);
    data.correlation = zeros(data.count,1);
    data.anomaly     = zeros(data.count,1);
    data.cubeg  	 = zeros(data.count,1);
    data.sqrg        = zeros(data.count,1);
    
    for dataRow = 1:data.count
        filePath = fullfile(pearch,strcat(data.pathName(dataRow,1:end-4),'.TAB'));



        fileID = fopen(filePath, 'r');

        if(fileID>0)
            scan = textscan(fileID, '%*s %*f %f %f', 'Delimiter', ',');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %   scan{1}: Units of current
            %   scan{2}: Units of voltage
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            fclose(fileID);
            
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
                data.anomaly(dataRow) = true;
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
                
                data.cubeg(dataRow)     = polyCoeffs(1);
                data.sqrg(dataRow)      = polyCoeffs(2);
                data.gradient(dataRow)  = polyCoeffs(3);
                data.intercept(dataRow) = polyCoeffs(4);
                
                n = length(voltage);
                
                numerator = n*sum(voltage.*current) - sum(voltage)*sum(current);
                
                denominator = sqrt(n*sum(voltage.^2)-(sum(voltage))^2) * sqrt(n*sum(current.^2)-(sum(current))^2);
                
                data.correlation(dataRow) = abs(numerator / denominator);
            end
        end   % if
    end   % for
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Second check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    anomalyIndices = find(((data.gradient < MIN_GRADIENT_1 | data.gradient > MAX_GRADIENT_1 | data.intercept < MIN_INTERCEPT_1 | data.intercept > MAX_INTERCEPT_1) & (data.gradient < MIN_GRADIENT_2 | data.gradient > MAX_GRADIENT_2 | data.intercept < MIN_INTERCEPT_2 | data.intercept > MAX_INTERCEPT_2)) | data.correlation < MIN_CORRELATION);
    
    data.anomaly(anomalyIndices) = true;
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines data points and associates values to be used from 
    %     actual offset data of good status.
    %   * Start constructing new data structure "dataWrite" where each index
    %     in the end represents a TAB/LBL calibration file pair. Field vectors are
    %     initialized to greatest possibly needed size (?) and will
    %     eventually be trimmed down.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    dataWriteMaxLength = length(dataSessionStartTime) + max(data.modeSession);
    
    dataWrite = struct;
    dataWrite.count      = 0;
    dataWrite.startTime  = zeros(dataWriteMaxLength,1);
    dataWrite.gradient1  = zeros(dataWriteMaxLength,2);
    dataWrite.gradient2  = zeros(dataWriteMaxLength,2);
    dataWrite.gradient3  = zeros(dataWriteMaxLength,2);
    dataWrite.intercepts = zeros(dataWriteMaxLength,2);
    
    for modeSession = 1:max(data.modeSession)
        
        % Find all indices with data for (1) the current modeSession, and (2) each probe separately.
        p1 = find(data.modeSession == modeSession & data.probe == 1 & data.cold == 0 & data.anomaly == 0);
        p2 = find(data.modeSession == modeSession & data.probe == 2 & data.cold == 0 & data.anomaly == 0);
        
        if ~(isempty(p1) || isempty(p2))
            
            dataWrite.count = dataWrite.count + 1;
            
            % Condenses multiple calibration sweeps into one by averaging fitting coefficients (for each probe).
            % NOTE:       This is likely technically wrong, although the result should be close to averaging calibration
            %             sweeps before fitting.
            % 2017-01-26: Anders Eriksson thinks it is acceptable to average fitting coefficients (although possibly
            %             slightly wrong).
            dataWrite.startTime(dataWrite.count)    = min(min(data.startTime(p1)), min(data.startTime(p2)));
            dataWrite.gradient1(dataWrite.count,:)  = [mean(data.gradient (p1)) mean(data.gradient (p2))];
            dataWrite.gradient2(dataWrite.count,:)  = [mean(data.sqrg     (p1)) mean(data.sqrg     (p2))];
            dataWrite.gradient3(dataWrite.count,:)  = [mean(data.cubeg    (p1)) mean(data.cubeg    (p2))];
            dataWrite.intercepts(dataWrite.count,:) = [mean(data.intercept(p1)) mean(data.intercept(p2))];
        end
    end

    % NOTE: At this point the "data" variable is basically never used again. Can not clear it though, since
    %       it is used for displaying the summary and for returning data.
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Amendment Erik Johansson, 2015-02-04:
    % -------------------------------------
    % Prevent function from creating calibration files if there is no usable calibration data.
    % This can happen if there is only one macro 104 in the archive (so far) and it comes first
    % in the archive (making that calibration data "cold"). Example: archive for Feb 2015.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (dataWrite.count == 0)
           disp('Found calibration macros, but all data is either labeled as cold or as having anomalies. - Produces no calibration files.')
           return;
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines data points associated with days of data session
    %     starts that are not covered by days of actual data points.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    actualData = dataWrite.count;
    
    for dataSessionCounter = 1:length(dataSessionStartTime)
        
        if isempty(find(floor(dataWrite.startTime) == floor(dataSessionStartTime(dataSessionCounter)), 1, 'first'))
            
            dataWrite.count = dataWrite.count + 1;
            
            earlyIndex = find(dataWrite.startTime <= dataSessionStartTime(dataSessionCounter) & dataWrite.startTime >  0, 1, 'first');
            lateIndex  = find(dataWrite.startTime >  dataSessionStartTime(dataSessionCounter), 1, 'first');
            
            dataWrite.startTime(dataWrite.count) = dataSessionStartTime(dataSessionCounter);
            
            if isempty(earlyIndex)
                
                dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(1,:);
                dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(1,:);
                dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(1,:);
                dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(1,:);
                
            elseif isempty(lateIndex)
                
                dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(actualData,:);
                dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(actualData,:);
                dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(actualData,:);                                
                dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(actualData,:);
                
            else
                
                fractionTime = (dataWrite.startTime(dataWrite.count)-dataWrite.startTime(earlyIndex)) / (dataWrite.startTime(lateIndex)-dataWrite.startTime(earlyIndex));
                
                dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(earlyIndex,:)  + fractionTime*(dataWrite.gradient1(lateIndex,:)  -dataWrite.gradient1(earlyIndex,:) );
                dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(earlyIndex,:)  + fractionTime*(dataWrite.gradient2(lateIndex,:)  -dataWrite.gradient2(earlyIndex,:) );
                dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(earlyIndex,:)  + fractionTime*(dataWrite.gradient3(lateIndex,:)  -dataWrite.gradient3(earlyIndex,:) );
                dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(earlyIndex,:) + fractionTime*(dataWrite.intercepts(lateIndex,:) -dataWrite.intercepts(earlyIndex,:));
            end
        end
    end
    
    dataWrite.startTime(dataWrite.count+1:dataWriteMaxLength)    = [];
    dataWrite.gradient1(dataWrite.count+1:dataWriteMaxLength,:)  = [];
    dataWrite.gradient2(dataWrite.count+1:dataWriteMaxLength,:)  = [];
    dataWrite.gradient3(dataWrite.count+1:dataWriteMaxLength,:)  = [];

    dataWrite.intercepts(dataWrite.count+1:dataWriteMaxLength,:) = [];
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Removes superfluous actual data points from same days.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    removeIndex = zeros(actualData,1);
    
    if(actualData>1)
        
        for actualDataCounter = 1:(actualData-1)
            
            if floor(dataWrite.startTime(actualDataCounter)) == floor(dataWrite.startTime(actualDataCounter+1))
                
                removeIndex(actualDataCounter+1) = true;
            end
        end
        
        dataWrite.startTime(find(removeIndex))    = [];
        dataWrite.gradient1(find(removeIndex),:)  = [];
        dataWrite.gradient2(find(removeIndex),:)  = [];
        dataWrite.gradient3(find(removeIndex),:)  = [];
        dataWrite.intercepts(find(removeIndex),:) = [];
        
    end
    
    dataWrite.count = length(dataWrite.startTime);
    
    clear removeIndex;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Writes all the CALIB_MEAS/_COEF files for each of the base folders.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for dataWriteCounter = 1:dataWrite.count
        
        startTimeString = datestr(dataWrite.startTime(dataWriteCounter), 'yyyy-mm-ddTHH:MM:SS.FFF');
        
        fileName  = strcat('RPCLAP', datestr(dataWrite.startTime(dataWriteCounter), 'yymmdd'), '_CALIB_MEAS');
        fileName2 = strcat('RPCLAP', datestr(dataWrite.startTime(dataWriteCounter), 'yymmdd'), '_CALIB_COEF');
        
        voltage = 0:1:255;
        
        currentP1 = dataWrite.intercepts(dataWriteCounter,1) + dataWrite.gradient1(dataWriteCounter,1)*voltage +dataWrite.gradient2(dataWriteCounter,1)*voltage.^2 +dataWrite.gradient3(dataWriteCounter,1)*voltage.^3;
        currentP2 = dataWrite.intercepts(dataWriteCounter,2) + dataWrite.gradient1(dataWriteCounter,2)*voltage +dataWrite.gradient2(dataWriteCounter,2)*voltage.^2 +dataWrite.gradient3(dataWriteCounter,2)*voltage.^3;
        currentP1 = floor(currentP1*1E6+0.5) / 1E6;  % Rounding after six decimals. fprintf will try to round this later, but does so incorrectly.
        currentP2 = floor(currentP2*1E6+0.5) / 1E6;
        
        
        filePathLBL = fullfile(outpath, strcat(fileName, '.LBL'));
        filePathTAB = fullfile(outpath, strcat(fileName, '.TAB'));
        
        filePath2TAB = fullfile(CALIB_COEF_files_dir, strcat(fileName2, '.TXT'));
        
        
        %%%%%%%%%%%%%%%%%%
        % Create LBL file
        %%%%%%%%%%%%%%%%%%
        fileID = fopen(filePathLBL, 'wt');
        
        fprintf(fileID, 'PDS_VERSION_ID = PDS3\r\n');
        fprintf(fileID, 'LABEL_REVISION_NOTE = "2015-06-03, EJ: Updated LAP_*_CAL_20B* calibration factors"\r\n');
        %fprintf(fileID, 'LABEL_REVISION_NOTE = "2015-07-07, EJ: RECORD_BYTES=31"\r\n');   % Use??
        fprintf(fileID, 'RECORD_TYPE = FIXED_LENGTH\r\n');
        fprintf(fileID, 'RECORD_BYTES = 31\r\n');
        fprintf(fileID, 'FILE_RECORDS = 256\r\n');
        fprintf(fileID, strcat('FILE_NAME = "', fileName, '.LBL"\r\n'));
        fprintf(fileID, strcat('^TABLE = "', fileName, '.TAB"\r\n'));
        fprintf(fileID, 'DATA_SET_ID = "%s"\r\n', earch);
        
        % DATA_SET_NAME is optional, RO-EST-TN-3372, "ROSETTA Archiving Conventions", Issue 7, Rev. 8
        %fprintf(fileID, 'DATA_SET_NAME = "ROSETTA-ORBITER EARTH RPCLAP 3 MARS CALIB V1.0"\r\n');    % Incorrect value.
        
        fprintf(fileID, 'MISSION_ID = ROSETTA\r\n');
        fprintf(fileID, 'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\r\n');
        fprintf(fileID, 'MISSION_PHASE_NAME = %s\r\n', mp);
        fprintf(fileID, 'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\r\n');
        fprintf(fileID, 'PRODUCER_ID = EJ\r\n');
        fprintf(fileID, 'PRODUCER_FULL_NAME = "ERIK P G JOHANSSON"\r\n');
        fprintf(fileID, strcat('PRODUCT_ID = "', fileName, '"\r\n'));
        fprintf(fileID, horzcat('PRODUCT_CREATION_TIME = ', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), '\r\n'));
        fprintf(fileID, 'INSTRUMENT_HOST_ID = RO\r\n');
        fprintf(fileID, 'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\r\n');
        fprintf(fileID, 'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\r\n');
        fprintf(fileID, 'INSTRUMENT_ID = RPCLAP\r\n');
        fprintf(fileID, 'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\r\n');
        fprintf(fileID, horzcat('START_TIME = ', startTimeString, '\r\n'));
        fprintf(fileID, 'SPACECRAFT_CLOCK_START_COUNT = "N/A"\r\n');
        fprintf(fileID, 'DESCRIPTION = "CONVERSION FROM TM UNITS TO AMPERES AND VOLTS"\r\n');
        
        %----------------------------------------------------------------------------------------
        fprintf(fileID, 'ROSETTA:LAP_VOLTAGE_CAL_16B = "1.22072175E-3"\r\n');
        %--------
        %fprintf(fileID, 'ROSETTA:LAP_VOLTAGE_CAL_20B = "7.62940181E-5"\r\n');   % Original value used up until ca 2015-06-11.
        fprintf(fileID, 'ROSETTA:LAP_VOLTAGE_CAL_20B = "7.534142050781250E-05"\r\n');   %  1.22072175E-3 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28.
        %--------    
        fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_16B_G1 = "3.05180438E-10"\r\n');
        %--------        
        %fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.90735045E-11"\r\n');   % Original value used up until ca 2015-06-11.
        fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.883535515781250E-11"\r\n');   % 3.05180438E-10 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28.
        %--------        
        fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_16B_G0_05 = "6.10360876E-9"\r\n');
        %--------        
        %fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.81470090E-10"\r\n');   % Original value used up until ca 2015-06-11.
        fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.767071031562500E-10"\r\n');     % 6.10360876E-9 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28.
        %----------------------------------------------------------------------------------------
        
        fprintf(fileID, 'OBJECT = TABLE\r\n');
        fprintf(fileID, 'INTERCHANGE_FORMAT = ASCII\r\n');
        fprintf(fileID, 'ROWS = 256\r\n');
        fprintf(fileID, 'COLUMNS = 3\r\n');
        fprintf(fileID, 'ROW_BYTES = 31\r\n');
        fprintf(fileID, 'DESCRIPTION = "THIRD DEGREE POLYNOMIAL OFFSET CORRECTION FOR 16 BIT DENSITY DATA"\r\n');
        
        fprintf(fileID, 'OBJECT = COLUMN\r\n');
        fprintf(fileID, 'NAME = P1P2_VOLTAGE\r\n');
        fprintf(fileID, 'DATA_TYPE = ASCII_INTEGER\r\n');
        fprintf(fileID, 'START_BYTE = 1\r\n');
        fprintf(fileID, 'BYTES = 3\r\n');
        fprintf(fileID, 'DESCRIPTION = "APPLIED VOLTAGE BIAS P1 AND P2 [TM UNITS]"\r\n');
        fprintf(fileID, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileID, 'OBJECT = COLUMN\r\n');
        fprintf(fileID, 'NAME = P1_CURRENT\r\n');
        fprintf(fileID, 'DATA_TYPE = ASCII_REAL\r\n');
        fprintf(fileID, 'START_BYTE = 5\r\n');
        fprintf(fileID, 'BYTES = 12\r\n');
        fprintf(fileID, 'DESCRIPTION = "INSTRUMENT OFFSET [TM UNITS]"\r\n');
        fprintf(fileID, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileID, 'OBJECT = COLUMN\r\n');        
        fprintf(fileID, 'NAME = P2_CURRENT\r\n');
        fprintf(fileID, 'DATA_TYPE = ASCII_REAL\r\n');
        fprintf(fileID, 'START_BYTE = 18\r\n');
        fprintf(fileID, 'BYTES = 12\r\n');
        fprintf(fileID, 'DESCRIPTION = "INSTRUMENT OFFSET [TM UNITS]"\r\n');
        fprintf(fileID, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileID, 'END_OBJECT = TABLE\r\n');
        
        fprintf(fileID, 'END\r\n');
        
        fclose(fileID);
        
        
        
        %%%%%%%%%%%%%%%%%%
        % Create TAB file
        %%%%%%%%%%%%%%%%%%
        fileID = fopen(filePathTAB, 'wt');
        fprintf(1, 'Writing %s\n', filePathTAB);
        for row = 1:256            
            fprintf(fileID, horzcat(sprintf('%03.0f', voltage(row)), ',', sprintf('%12.6f', currentP1(row)), ',', sprintf('%12.6f', currentP2(row)), '\r\n'));
        end
        fclose(fileID);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Write CEOFF file - Extra calibration coefficient files (for debugging)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        fileID = fopen(filePath2TAB, 'wt');
        fprintf(fileID,'# 3rd order polynomial fit coefficients (current = aV^3+b*V^2+c*V+d), for Probe 1 and Probe 2 in TM units.\r\n');
        fprintf(fileID,'aP1,bP1,cP1,dP1,aP2,bP2,cP2,dP2\r\n');
        fprintf(fileID,'%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e\r\n', dataWrite.gradient3(dataWriteCounter,1), dataWrite.gradient2(dataWriteCounter,1), dataWrite.gradient1(dataWriteCounter,1),dataWrite.intercepts(dataWriteCounter,1), dataWrite.gradient3(dataWriteCounter,2), dataWrite.gradient2(dataWriteCounter,2), dataWrite.gradient1(dataWriteCounter,2), dataWrite.intercepts(dataWriteCounter,2));
        fclose(fileID);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Displays the output summary.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    numberCalibration = dataWrite.count;
    numberOffset      = data.count;
    numberAnomaly     = length(find(data.anomaly));
    numberCold        = length(find(data.cold));
    numberGood        = numberOffset - numberCold - numberAnomaly;
    
    display('Progress: Work complete.   ');
    display('                           ');
    display('===========================');
    display('         SUMMARY           ');
    display('===========================');
    display('                           ');
    display([' Calibration Files:', sprintf('%7.0f', numberCalibration)]);
    display('                           ');
    display('                           ');
    display([' Offset Files:     ', sprintf('%7.0f', numberOffset)]);
    display('                           ');
    display(['    Anomalies:     ', sprintf('%7.0f', numberAnomaly)]);
    display('                           ');
    display(['         Cold:     ', sprintf('%7.0f', numberCold)]);
    display('                           ');
    display(['         Good:     ', sprintf('%7.0f', numberGood)]);
    display('                           ');
    display(sprintf('Elapsed wall time: %.0f s', etime(clock, t_start)));
    display('                           ');
    display('===========================');
    display('                           ');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines whether to supply the offset data as output argument.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargout == 1
        
        varargout(1) = {data};
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
