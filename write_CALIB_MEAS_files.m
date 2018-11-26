%
% write_CALIB_MEAS_files
%	
%   This program computes calibration files (*_CALIB_MEAS.TAB/.LBL) 
%   that can then be used by the PDS software to create the calibrated data sets.
%   Also, a separate calibration coefficient list file is created for debugging purposes
%   (and for which the output directory is hardcoded).
%   
%
%   ARGUMENTS
%   =========
%   editedDatasetPath : Path to EDITED data set, e.g. '/data/LAP_ARCHIVE/RO-E-RPCLAP-2-EAR3-EDITED-V1.0'
%   missionPhaseName  : "Long" mission phase name, e.g. "COMET ESCORT 3". (Needed for LBL file keyword MISSION_PHASE_NAME.)
%   outDirPath        : Output path (directory)
%   coeffsDirPath     : COEF files directory path (fitting coefficients for debugging)
%
%
%   SYNTAX
%   ======
%                    write_CALIB_MEAS_files(editedDatasetPath, missionphasename, outDirPath)
%       
%       offsetData = write_CALIB_MEAS_files(editedDatasetPath, missionphasename, outDirPath)
%
%
%   SOURCE CODE TERMINOLOGY
%   =======================
%   Input (in) calibration files   : Calibration files read by this code (macro 104 EDITED TAB files).
%   Output (out) calibration files : Calibration files produced by this code.
%   Mode                           : Macro, or macro 104
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
%   - Updated ADC20 TM-to-engineering-units conversion factors in the LBL files according to calibration of
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
%
%   - Bug fix: SPACECRAFT_CLOCK_START_COUNT, START_TIME now match eachother.
%   - Added SPACECRAFT_CLOCK_STOP_COUNT+STOP_TIME. Removed commented code. Clean-up.
%     ADDED ARGUMENT coeffsDirPath.
%     /Erik P G Johansson 2017-01-30
%
%   - Added new constant ADC16_EDITED_NONNEGATIVE_OFFSET_ADC16TM to be able to remove offset from nonnegative ADC16
%     values and to be able to handle pds EDITED datasets without the corresponding modification.
%     /Erik P G Johansson 2017-05-31
%
%   - Removed PDS keywords for ADC20 calibration factors, i.e.
%        ROSETTA:LAP_VOLTAGE_CAL_20B
%        ROSETTA:LAP_CURRENT_CAL_20B_G1
%        ROSETTA:LAP_CURRENT_CAL_20B_G0_05
%     since their values are hereafter (1) different for P1 and P2, and (2) derived from the respective ADC16 values.
%     The old values also did not account for the moving average bug (factor) in the calibration data for 2015-05-28.
%     /Erik P G Johansson 2017-07-11
%
%   - Removed PDS keywords for ADC16 calibration factors, i.e.
%        ROSETTA:LAP_VOLTAGE_CAL_16B
%        ROSETTA:LAP_CURRENT_CAL_16B_G1
%        ROSETTA:LAP_CURRENT_CAL_16B_G0_05
%     since their values are hereafter hardcoded in pds. pds will not read them. CALIB_MEAS files will also NOT be
%     part of official datasets in the future.
%     /Erik P G Johansson 2017-08-23
%
%   ----------------------------------------------------------------------------
%   NOTE: As of 2016-04-07, this software is designed for MATLAB R2009A to make it possible to still run on squid.
%   NOTE: As of 2017-01-26, it appears that the part of the execution that takes the most time is the reading of LBL
%   files.
%   NOTE: As of 2017-01-30: If there are multiple mode (macro) sessions for the same day, then only one of them will be chosen.
%         This means that calibration files for a given day may differ depending on how this (input) calibration is chosen.
%   NOTE: The code assumes that the EDITED dataset uses the DATA_SET_ID as a directory name.
%   NOTE: The code uses PRODUCT_ID to derive the probe number.
%
%   BUG: As of 2017-01-23, appears to yield error if both the dataset contains no calibrations, and the return value is
%   requested.
%
function [varargout] = write_CALIB_MEAS_files(editedDatasetPath, missionPhaseName, outDirPath, coeffsDirPath)
%
%   PROPOSAL: Print estimated time left (for reading LBL files).
%   PROPOSAL: Better way of handling "double calibrations" within a single day. Use all calibrations somehow.
%       NOTE: According to commands (pds.bias), all instances of multiple macro 104 commands occurred years <=2010.
%       PROPOSAL: Select base filename instead of time directly for each mode session. Create one file for all
%                 input calibrations with the same base filename.
%   PROPOSAL: Divide source code into functions.
%   PROPOSAL: Some way of saving the information on read LBL files, then reading it to speed up test runs.
%       NOTE: Would need it to work for multiple datasets to work with scripts calling multiple times.
%   PROPOSAL: Divide algorithm into two steps.
%             STEP 1: Identify and copy ALL macro 104 input calibration files (TAB+LBL, incl. anomalous, incl. ones
%                     with missing probes etc.) to temporary directory.
%             STEP 2: Read the copied files and continue.
%       PRO: Can modify step 2-code and run it without running step 1. ==> Speeds up debugging & development.
%       CON: Algorithm is unaware of the surrounding non-macro 104 runs.
%           PRO: Algorithm can not strictly group input calibrations into continous macro 104 runs.
%           PRO: Can not even in principle detect cold input calibrations.
%   PROPOSAL: Change term "mode" to something else.
%   PROPOSAL: Some kind of optional (informal?) detection of cold input calibrations. Detection results as separate
%             list?!
%   PROPOSAL: Separate code for generating LBL files.
%       PRO: Useful for regenerating (modifying) LBL files without processing TAB files.
%       PRO: Useful for regenerating LBL file RPCLAP030101_CALIB_MEAS.LBL which TAB file is not generated like other CALIB_MEAS files.

    scriptStartTimeVector = clock;    % Script start time. NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute second].


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set miscellaneous constants
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    FILES_PER_PROGRESS_STEP = 3000;   % Number of files to process before updating the progress percentage (log message).
    
    % Value which is SUBTRACTED from all non-negative measured ADC16 values in ADC16 TM units.
    % NOTE: The pds s/w contains a similar constants which affects the EDITED values. That constant must be compatible
    % (but not automatically identical!) with the value here.
    ADC16_EDITED_NONNEGATIVE_OFFSET_ADC16TM = -2.5;
    %ADC16_EDITED_NONNEGATIVE_OFFSET_ADC16TM = -0.5;
    %ADC16_EDITED_NONNEGATIVE_OFFSET_ADC16TM = 0;

    diag = 0;    % Flag for whether to display debugging plots.

    % Directory path to where to save calibration COEFFICIENTS files for debugging (i.e. not LBL+TAB).
    %coeffsDirPath = '/data/LAP_ARCHIVE/CALIB_MEAS_files/';    % Default value on squid.
    %coeffsDirPath = '~/temp/coeffs';   % For debugging.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Set limits used for classifying input calibration data as "anomaly".
    % 
    %     NOTE: It is unknown why there are two versions of constants (one for each probe?).
    %           The actual implementation uses both versions of constants to check all input calibrations
    %           (i.e. treats both probes the same!).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    MIN_GRADIENT_1 = -4.2;
    MAX_GRADIENT_1 = -3.3;

    MIN_GRADIENT_2 = -2.5;
    MAX_GRADIENT_2 = -1.7;

    MIN_INTERCEPT_1 = 410;
    MAX_INTERCEPT_1 = 600;

    MIN_INTERCEPT_2 = 200;
    MAX_INTERCEPT_2 = 390;

    MIN_CORRELATION = 0.99;

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * ASSERTIONS: Validates the input/output arguments used.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % NOTE: "error" throws no error if the input argument (to "error") is [].
    error(nargchk(   4, 4, nargin));
    error(nargoutchk(0, 1, nargout));
    
    % NOTE: It is useful to check for existence of directories directly since their non-existence will
    %       otherwise produce an error first after a lot of processing, i.e. after a potentially long delay.
    if ~exist(outDirPath, 'dir')
        error('Can not find directory "%s".', outDirPath)
    end
    if ~exist(coeffsDirPath, 'dir')
        error('Can not find directory "%s".', coeffsDirPath)
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Log and adjust relevant folders
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp('Paths');
    disp('----------------------------------------------------------------');
    fprintf(1,'Edited Archive and path:      %s\r\n',     editedDatasetPath);
    fprintf(1,'Mission phase:                %s\r\n',     missionPhaseName);
    fprintf(1,'Output calibration file path: %s\r\n\r\n', outDirPath);

    if editedDatasetPath(end) == filesep        
        editedDatasetPath(end) = [];    % Remove trailing file separator (slash).
    end
    [junk, editedDatasetDirName] = fileparts(editedDatasetPath);    % Split path to get DATA_SET_ID. IMPORTANT NOTE: "fileparts" only works for string NOT ending with slash.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Extracts the information from the INDEX.TAB file
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
    indexFileData = textscan(fileId,'%s%s%*s%*s%*s%*s','Delimiter',','); 
    fclose(fileId);
    
    
    relativeFilePathList = strtrim(strrep(indexFileData{1}, '"', ''));   % Removes quotes.
    productIdList        = strtrim(strrep(indexFileData{2}, '"', ''));   % Removes quotes.
    clear indexFileData
    inFilesData = struct('relativeFilePath', relativeFilePathList, 'productId', productIdList);
    
    
    % Remove HK files from list.
    for iFile = 1:length(inFilesData)
        isHk(iFile) = (inFilesData(iFile).relativeFilePath(end-4) == 'H');
    end
    inFilesData(isHk) = [];



    fprintf(1,'Reading (non-HK) LBL files in INDEX.TAB: start time, stop time, and mode (macro)\n');

    %=======================================================
    % Iterate over all non-HK files mentioned in INDEX.TAB.
    %=======================================================
    nFiles = length(inFilesData);
    for iFile=1:nFiles

        % Read LBL file
        % -------------
        % IMPLEMENTATION NOTE: Reads list of rows with textscan, but does NOT use textscan to split up (parse)
        % PDS keyword assignments
        %   (1) since I am guessing that it is faster this way (this is the slowest part of the code)
        %   (2) to be able to reuse old code.
        lblFilePath  = fullfile(editedDatasetPath, inFilesData(iFile).relativeFilePath);
        fileId = fopen(lblFilePath,'r');
        if ~(fileId>0)
            warning('write_MEAS_CALIB_file:CanNotReadFile', 'Can not open file %s', lblFilePath)
            continue
        end
        temp = textscan(fileId, '%s', 'delimiter', '\n', 'whitespace', '');
        linesList = temp{1};
        fclose(fileId);

        startTime    = linesList{strncmpi(linesList, 'START_TIME',                   10)};
        startTimeScc = linesList{strncmpi(linesList, 'SPACECRAFT_CLOCK_START_COUNT', 28)};
        stopTime     = linesList{strncmpi(linesList, 'STOP_TIME',                     9)};
        stopTimeScc  = linesList{strncmpi(linesList, 'SPACECRAFT_CLOCK_STOP_COUNT',  27)};
        mode         = linesList{strncmpi(linesList, 'INSTRUMENT_MODE_ID',           18)};

        [tmp,str] = strread(startTime,'%s%s','delimiter','=');
        value     = datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');     % NOTE: "str" is a cell containing a string, but datenum can handle that.
        inFilesData(iFile).startTime = value;

        [tmp,str] = strread(stopTime, '%s%s','delimiter','=');
        value     = datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');
        inFilesData(iFile).stopTime = value;

        [tmp,value] = strread(startTimeScc,'%s%s','delimiter','=');
        inFilesData(iFile).startTimeScc = value{1};          % Stores quoted value, whitespace trimmed (outside of quotes). Example: "1/0149643274.1600"
        
        [tmp,value] = strread(stopTimeScc, '%s%s','delimiter','=');
        inFilesData(iFile).stopTimeScc = value{1};           % Stores quoted value, whitespace trimmed (outside of quotes). Example: "1/0149643274.1600"
        
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



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find macro 104 calibration files and group them into "sessions" (continuous runs) - new algorithm
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ASSUMPTION: Sorting of files by time (e.g. start time) does not split up continuous runs of the same macro.
    % This assumption could in principle be violated if multiple files have the same time but different macros.
    
    removeIndex = zeros(length(inFilesData), 1);         % Indices to remove, in the form of one true/false flag for every index.
    previousModeSessionId = '';    % Default value represent a non-existing macro which is different from any existing macro.
    modeSessionId = 0;    % Identifies the session that the current file should belong to (not relevant for non-macro 104 files).
    
    for iFile = 1:length(inFilesData)
        instrumentModeId = inFilesData(iFile).instrumentModeId;
        if strcmpi(instrumentModeId, 'MCID0X0104')
            % CASE: Found EDITED SCI file that is macro/mode 104.
            
            fprintf(1, 'Found CALIBRATION data (LBL file) %s -- %s\n', ...
                datestr(inFilesData(iFile).startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'), ...
                datestr(inFilesData(iFile).stopTime,  'yyyy-mm-ddTHH:MM:SS.FFF'));   % DEBUG

            if ~strcmp(previousModeSessionId, instrumentModeId)
                % CASE: Found macro 104 file that was NOT preceeded by a macro 104 file.
                modeSessionId = modeSessionId + 1;
            end
            removeIndex(iFile) = false;
        else
            removeIndex(iFile) = true;
        end
        inFilesData(iFile).modeSessionId = modeSessionId;
        
        previousModeSessionId = instrumentModeId;
    end



    inFilesData(find(removeIndex)) = [];    % IMPORTANT NOTE: Using "find" seems necessary despite MATLAB R2009a telling us we do not need it.
    clear removeIndex;

    if (isempty(inFilesData))
           disp('No calibration macros found. - Produces no calibration files.')
           return;    % EXIT
    end
    
    % Derive probe number from PRODUCT_ID.
    for iFile = 1:length(inFilesData)
        inFilesData(iFile).probeNbr = str2double(inFilesData(iFile).relativeFilePath(end-7));
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Reads the TAB files containing the offsets.
    %   * Gets the offset parameters for each file:
    %       * Fitting coefficients
    %       * Coefficient of correlation
    %   * First check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf(1, 'Progress: Working the offset data.');
    
    for iFile = 1:length(inFilesData)
        inFilesData(iFile).intercept   = 0;       % Default value.
        inFilesData(iFile).gradient    = 0;       % Default value.
        inFilesData(iFile).sqrg        = 0;       % Default value.
        inFilesData(iFile).cubeg       = 0;       % Default value.
        inFilesData(iFile).correlation = 0;       % Default value.
        inFilesData(iFile).anomaly     = false;   % Default value.

        tabFilePath = fullfile(editedDatasetPath, strcat(inFilesData(iFile).relativeFilePath(1:end-4),'.TAB'));   % Exchange .LBL for .TAB.
        fileId = fopen(tabFilePath, 'r');
        if ~(fileId>0)
            warning('write_MEAS_CALIB_file:CanNotReadFile', 'Can not open file %s', tabFilePath)
            continue
        end
        
        inputCalibrationFileData = textscan(fileId, '%*s %*f %f %f', 'Delimiter', ',');
        fclose(fileId);
        currentTm = inputCalibrationFileData{1};
        voltageTm = inputCalibrationFileData{2};
        
        % If there are multiple identical initial voltage bias values, keep only the last one.
        % (Removes samples which are not part of the sweep.)
        firstVoltageValue = voltageTm(1);
        starterValueCounter = 1;
        while voltageTm(starterValueCounter+1) == firstVoltageValue
            starterValueCounter = starterValueCounter + 1;
        end
        voltageTm(1:starterValueCounter) = [];
        currentTm(1:starterValueCounter) = [];
        
        % Subtract offset for non-negative values.
        % See definition of ADC16_EDITED_NONNEGATIVE_OFFSET_ADC16TM.
        currentTm(currentTm >= 0) = currentTm(currentTm >= 0) - ADC16_EDITED_NONNEGATIVE_OFFSET_ADC16TM;

        if isempty(voltageTm)
            inFilesData(iFile).anomaly = true;
        else
            % polyCoeffs = polyfit(voltageTm, currentTm, 1);     % Use first-order polynomial fit.
            polyCoeffs = polyfit(voltageTm, currentTm, 3);     % Use third-order polynomial fit. FKJN edit 28/8 2014
            
            if diag
                polyCoeffs2 = polyfit(voltageTm, currentTm, 1);
                figure(22);
                plot(voltageTm,currentTm,'b',voltageTm,(polyCoeffs(1)*voltageTm.^3+polyCoeffs(2)*voltageTm.^2+polyCoeffs(3)*voltageTm+polyCoeffs(4)),'g',voltageTm,(polyCoeffs2(1)*voltageTm+polyCoeffs2(2)),'r')
                
                figure(23);
                plot(voltageTm,currentTm-(polyCoeffs(1)*voltageTm.^3+polyCoeffs(2)*voltageTm.^2+polyCoeffs(3)*voltageTm+polyCoeffs(4)),'g',voltageTm,currentTm-(polyCoeffs2(1)*voltageTm+polyCoeffs2(2)),'r')
            end
            
            inFilesData(iFile).cubeg     = polyCoeffs(1);
            inFilesData(iFile).sqrg      = polyCoeffs(2);
            inFilesData(iFile).gradient  = polyCoeffs(3);
            inFilesData(iFile).intercept = polyCoeffs(4);
            
            n = length(voltageTm);
            
            numerator = n*sum(voltageTm.*currentTm) - sum(voltageTm)*sum(currentTm);
            
            denominator = sqrt(n*sum(voltageTm.^2)-(sum(voltageTm))^2) * sqrt(n*sum(currentTm.^2)-(sum(currentTm))^2);
            
            inFilesData(iFile).correlation = abs(numerator / denominator);
        end

    end   % for



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Second check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    anomalyIndices = find( ...
        ( ...
            ([inFilesData.gradient] < MIN_GRADIENT_1 | [inFilesData.gradient] > MAX_GRADIENT_1 | [inFilesData.intercept] < MIN_INTERCEPT_1 | [inFilesData.intercept] > MAX_INTERCEPT_1) ...
          & ([inFilesData.gradient] < MIN_GRADIENT_2 | [inFilesData.gradient] > MAX_GRADIENT_2 | [inFilesData.intercept] < MIN_INTERCEPT_2 | [inFilesData.intercept] > MAX_INTERCEPT_2) ...
        ) ...
        | [inFilesData.correlation] < MIN_CORRELATION);

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
    outFilesData = [];

    for modeSessionId = 1:max([inFilesData.modeSessionId])
        
        % Find all indices with data for (1) the current modeSession, and (2) each probe separately.
        p1 = find([inFilesData.modeSessionId] == modeSessionId & [inFilesData.probeNbr] == 1 & [inFilesData.anomaly] == 0);
        p2 = find([inFilesData.modeSessionId] == modeSessionId & [inFilesData.probeNbr] == 2 & [inFilesData.anomaly] == 0);
        
        if ~(isempty(p1) || isempty(p2))
            % CASE: There is good data for BOTH probe 1 AND probe 2.
            
            % Condenses multiple calibration sweeps into one by averaging fitting coefficients (for each probe)
            % -------------------------------------------------------------------------------------------------
            % NOTE:       This is likely technically wrong, although the result should be close to averaging calibration
            %             sweeps before fitting.
            % 2017-01-26: Anders Eriksson thinks it is acceptable to average fitting coefficients (although possibly
            %             slightly wrong).
            
            % NOTE: Expanding struct array (e.g. inFilesData) fields (e.g. startTime) to array always yields a row
            % array.
            p12 = union(p1,p2);
            [minStartTime, iMin] = min([inFilesData(p12).startTime]);
            [maxStopTime,  iMax] = max([inFilesData(p12).stopTime ]);
            
            % Time to use for the filename. This is chosen here since it is needed in two different locations later:
            % (1) for handling (eliminating, choosing) output calibration files with the same filename,
            % (2) for writing the output calibration file to disk.
            outFilesData(end+1).fileNameTime = (minStartTime + maxStopTime) / 2;    % NOTE: Expands size of struct: Add another calibration file.
            
            outFilesData(end  ).startTime    = minStartTime;
            outFilesData(end  ).stopTime     = maxStopTime;
            outFilesData(end  ).startTimeScc = inFilesData(p12(iMin)).startTimeScc;
            outFilesData(end  ).stopTimeScc  = inFilesData(p12(iMax)).stopTimeScc;
            outFilesData(end  ).gradient1    = [mean([inFilesData(p1).gradient ]), mean([inFilesData(p2).gradient ])];
            outFilesData(end  ).gradient2    = [mean([inFilesData(p1).sqrg     ]), mean([inFilesData(p2).sqrg     ])];
            outFilesData(end  ).gradient3    = [mean([inFilesData(p1).cubeg    ]), mean([inFilesData(p2).cubeg    ])];
            outFilesData(end  ).intercepts   = [mean([inFilesData(p1).intercept]), mean([inFilesData(p2).intercept])];
        end
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Handle the case of multiple output calibration data within the same day.
    %     ACTION: Remove all but the LAST one during that day.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    removeIndex = zeros(length(outFilesData),1);
    
    for iFile = 1:(length(outFilesData)-1)
        
        % ALGORITHM: Remove the NEXT calibration iff the CURRENT and the NEXT calibration have the same (filename) time label.
        %removeIndex(iFile+1) = floor(outFilesData(iFile).fileNameTime) == floor(outFilesData(iFile+1).fileNameTime);
        
        % ALGORITHM: Remove the CURRENT calibration iff the CURRENT and the NEXT calibration have the same (filename) time label
        % -----------------------------------------------------------------------------------------------------------
        % Anders Eriksson 2017-01-31 suggests using this default since multiple macro 104 runs during the same day could
        % imply that it was a test to compare the difference between a cold and warm instrument, and that the later
        % calibration is therefore "warm" and therefore more reliable.
        removeIndex(iFile  ) = floor(outFilesData(iFile).fileNameTime) == floor(outFilesData(iFile+1).fileNameTime);
    end
    
    outFilesData(find(removeIndex)) = [];    % Using "find" seems necessary despite the MATLAB R2009a editor telling us we do not need it.
    
    clear removeIndex;
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Write LBL+TAB file pairs
    %   * Writes all the CALIB_MEAS/_COEF files for each of the base folders.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for iFile = 1:length(outFilesData)
  
        outFileNameDateStr = datestr(outFilesData(iFile).fileNameTime, 'yymmdd');
        outFileNameBase   = strcat('RPCLAP', outFileNameDateStr, '_CALIB_MEAS');
        coeffFileNameBase = strcat('RPCLAP', outFileNameDateStr, '_CALIB_COEF');
        
        voltage = 0:1:255;
        
        currentP1 = outFilesData(iFile).intercepts(1) + outFilesData(iFile).gradient1(1)*voltage + outFilesData(iFile).gradient2(1)*voltage.^2 + outFilesData(iFile).gradient3(1)*voltage.^3;
        currentP2 = outFilesData(iFile).intercepts(2) + outFilesData(iFile).gradient1(2)*voltage + outFilesData(iFile).gradient2(2)*voltage.^2 + outFilesData(iFile).gradient3(2)*voltage.^3;
        currentP1 = floor(currentP1*1E6+0.5) / 1E6;  % Rounding after six decimals. fprintf will try to round this later, but does so incorrectly.
        currentP2 = floor(currentP2*1E6+0.5) / 1E6;
        
        lblFilePath   = fullfile(outDirPath,    strcat(outFileNameBase,   '.LBL'));
        tabFilePath   = fullfile(outDirPath,    strcat(outFileNameBase,   '.TAB'));
        coeffFilePath = fullfile(coeffsDirPath, strcat(coeffFileNameBase, '.TXT'));
        
        write_LBL_TAB_file_pair(lblFilePath, tabFilePath, outFileNameBase, editedDatasetDirName, missionPhaseName, outFilesData(iFile), voltage, currentP1, currentP2);



        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Write CEOFF file - Extra calibration coefficient files (for debugging)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        fileId = fopen(coeffFilePath, 'wt');
        fprintf(fileId,'# 3rd order polynomial fit coefficients (current = aV^3+b*V^2+c*V+d), for Probe 1 and Probe 2 in TM units.\r\n');
        fprintf(fileId,'aP1,bP1,cP1,dP1,aP2,bP2,cP2,dP2\r\n');
        fprintf(fileId,'%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e\r\n', ...
            outFilesData(iFile).gradient3(1), outFilesData(iFile).gradient2(1), outFilesData(iFile).gradient1(1), outFilesData(iFile).intercepts(1), ...
            outFilesData(iFile).gradient3(2), outFilesData(iFile).gradient2(2), outFilesData(iFile).gradient1(2), outFilesData(iFile).intercepts(2));
        fclose(fileId);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Displays the output summary.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    nOutCalibrationFiles = length(outFilesData);
    nInFiles      = length(inFilesData);
    nInFileAnomalies     = length(find([inFilesData.anomaly]));
    nInFilesGood        = nInFiles - nInFileAnomalies;

    fprintf(1, 'Progress: Work complete.\n');
    fprintf(1, '\n');
    fprintf(1, '=============================================\n');
    fprintf(1, '                   SUMMARY                   \n');
    fprintf(1, '=============================================\n');
    fprintf(1, '\n');
    % Printing the EDITED directory is useful when using a script to automatically call write_CALIB_MEAS_files multiple
    % times, since it is then difficult to distinguish the results of separate runs.
    fprintf(1, ' Input EDITED directory:               %s\n', editedDatasetPath);   
    fprintf(1, '\n');
    fprintf(1, ' Input offset files:                   %3.0f\n', nInFiles);
    fprintf(1, '\n');
    fprintf(1, '    Input offset files with anomalies: %3.0f\n', nInFileAnomalies);
    fprintf(1, '\n');
    fprintf(1, '    Good input offset files:           %3.0f\n', nInFilesGood);
    fprintf(1, '\n');
    fprintf(1, ' Output calibration files:             %3.0f\n', nOutCalibrationFiles);
    fprintf(1, '\n');
    fprintf(1, '\n');
    fprintf(1, ' Elapsed wall time:                 %6.0f s\n', etime(clock, scriptStartTimeVector));
    fprintf(1, '\n');
    fprintf(1, '=============================================\n');
    fprintf(1, '\n');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines whether to supply the offset data as output argument.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargout == 1
        varargout(1) = {inFilesData};
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end



% Write one pair of TAB and LBL files.
%
% outFileData : struct with fields
%   .startTime
%   .startTimeScc : Must be quoted string.
%   .stopTime
%   .stopTimeScc  : Must be quoted string.
function write_LBL_TAB_file_pair(lblFilePath, tabFilePath, outFileNameBase, editedDatasetDirName, missionPhaseName, outFileData, voltage, currentP1, currentP2)
        %%%%%%%%%%%%%%%%%%
        % Create LBL file
        %%%%%%%%%%%%%%%%%%
        fileId = fopen(lblFilePath, 'wt');
        
        fprintf(fileId, 'PDS_VERSION_ID = PDS3\r\n');
        %fprintf(fileId, 'LABEL_REVISION_NOTE = "2015-06-03, EJ: Updated LAP_*_CAL_20B* calibration factors"\r\n');
        %fprintf(fileId, 'LABEL_REVISION_NOTE = "2015-07-07, EJ: RECORD_BYTES=31"\r\n');   % Use??
        %fprintf(fileId, 'LABEL_REVISION_NOTE = "2017-01-27, EJ: Updated metadata; start/stop times, DESCRIPTION, UNIT"\r\n');
        %fprintf(fileId, 'LABEL_REVISION_NOTE = "2017-07-11, EJ: Removed ADC20 calibration factors ROSETTA:LAP_*_CAL_20B*"\r\n');
        %fprintf(fileId, 'LABEL_REVISION_NOTE = "2017-07-11?, EJ: Removed ADC16 calibration factors ROSETTA:LAP_*_CAL_16B*"\r\n');
        fprintf(fileId, 'LABEL_REVISION_NOTE = "2018-10-19, EJ: Lowercase descriptions"\r\n');
        fprintf(fileId, 'RECORD_TYPE = FIXED_LENGTH\r\n');
        fprintf(fileId, 'RECORD_BYTES = 31\r\n');
        fprintf(fileId, 'FILE_RECORDS = 256\r\n');
        fprintf(fileId, strcat('FILE_NAME = "', outFileNameBase, '.LBL"\r\n'));
        fprintf(fileId, strcat('^TABLE = "',    outFileNameBase, '.TAB"\r\n'));
        fprintf(fileId, 'DATA_SET_ID = "%s"\r\n', editedDatasetDirName);
        
        % DATA_SET_NAME is optional, RO-EST-TN-3372, "ROSETTA Archiving Conventions", Issue 7, Rev. 8
        %fprintf(fileId, 'DATA_SET_NAME = "ROSETTA-ORBITER EARTH RPCLAP 3 MARS CALIB V1.0"\r\n');    % Incorrect value.

        fprintf(fileId, 'MISSION_ID = ROSETTA\r\n');
        fprintf(fileId, 'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\r\n');
        fprintf(fileId, 'MISSION_PHASE_NAME = "%s"\r\n', missionPhaseName);
        fprintf(fileId, 'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\r\n');
        fprintf(fileId, 'PRODUCER_ID = EJ\r\n');
        fprintf(fileId, 'PRODUCER_FULL_NAME = "ERIK P G JOHANSSON"\r\n');
        fprintf(fileId, 'PRODUCT_ID = "%s"\r\n', outFileNameBase);
        fprintf(fileId, 'PRODUCT_CREATION_TIME = %s\r\n', datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
        fprintf(fileId, 'INSTRUMENT_HOST_ID = RO\r\n');
        fprintf(fileId, 'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\r\n');
        fprintf(fileId, 'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\r\n');
        fprintf(fileId, 'INSTRUMENT_ID = RPCLAP\r\n');
        fprintf(fileId, 'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\r\n');
        fprintf(fileId, 'START_TIME = %s\r\n',                   datestr(outFileData.startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(fileId, 'SPACECRAFT_CLOCK_START_COUNT = %s\r\n',         outFileData.startTimeScc);                 % NOTE: Spacecraft clock time is quoted. Field value is already quoted.
        fprintf(fileId, 'STOP_TIME = %s\r\n',                    datestr(outFileData.stopTime,  'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(fileId, 'SPACECRAFT_CLOCK_STOP_COUNT = %s\r\n',          outFileData.stopTimeScc);                  % NOTE: Spacecraft clock time is quoted. Field value is already quoted.
        %fprintf(fileId, 'DESCRIPTION = "CONVERSION FROM TM UNITS TO AMPERES AND VOLTS"\r\n');
        fprintf(fileId, 'DESCRIPTION = "ADC16 current offsets. Conversion from TM units to ampere and volt."\r\n');
        
        %----------------------------------------------------------------------------------------
        %fprintf(fileId, 'ROSETTA:LAP_VOLTAGE_CAL_16B = "1.22072175E-3"\r\n');
        %--------
        %fprintf(fileId, 'ROSETTA:LAP_VOLTAGE_CAL_20B = "7.62940181E-5"\r\n');   % Original value used up until ca 2015-06-11.
        %fprintf(fileId, 'ROSETTA:LAP_VOLTAGE_CAL_20B = "7.534142050781250E-05"\r\n');   %  1.22072175E-3 * 1/16 *
        %0.9875; ADC20 calibration from data for 2015-05-28. Disabled 2017-07-11.
        %--------    
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_16B_G1 = "3.05180438E-10"\r\n');
        %--------        
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.90735045E-11"\r\n');   % Original value used up until ca 2015-06-11.
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.883535515781250E-11"\r\n');   % 3.05180438E-10 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28. Disabled 2017-07-11.
        %--------        
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_16B_G0_05 = "6.10360876E-9"\r\n');
        %--------        
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.81470090E-10"\r\n');   % Original value used up until ca 2015-06-11.
        %fprintf(fileId, 'ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.767071031562500E-10"\r\n');     % 6.10360876E-9 * 1/16 * 0.9875; ADC20 calibration from data for 2015-05-28. Disabled 2017-07-11.
        %----------------------------------------------------------------------------------------
        
        fprintf(fileId, 'OBJECT = TABLE\r\n');
        fprintf(fileId, 'INTERCHANGE_FORMAT = ASCII\r\n');
        fprintf(fileId, 'ROWS = 256\r\n');
        fprintf(fileId, 'COLUMNS = 3\r\n');
        fprintf(fileId, 'ROW_BYTES = 31\r\n');
        fprintf(fileId, 'DESCRIPTION = "Third degree polynomial offset correction for ADC16 density data."\r\n');
        
        fprintf(fileId, 'OBJECT = COLUMN\r\n');
        fprintf(fileId, 'NAME = P1P2_VOLTAGE\r\n');
        fprintf(fileId, 'DATA_TYPE = ASCII_INTEGER\r\n');
        fprintf(fileId, 'UNIT = "TM UNITS"\r\n');
        fprintf(fileId, 'START_BYTE = 1\r\n');
        fprintf(fileId, 'BYTES = 3\r\n');
        fprintf(fileId, 'DESCRIPTION = "Voltage applied to bias P1 and P2."\r\n');
        fprintf(fileId, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileId, 'OBJECT = COLUMN\r\n');
        fprintf(fileId, 'NAME = P1_CURRENT\r\n');
        fprintf(fileId, 'DATA_TYPE = ASCII_REAL\r\n');
        fprintf(fileId, 'UNIT = "TM UNITS"\r\n');
        fprintf(fileId, 'START_BYTE = 5\r\n');
        fprintf(fileId, 'BYTES = 12\r\n');
        fprintf(fileId, 'DESCRIPTION = "Probe 1 instrument offset."\r\n');
        fprintf(fileId, 'END_OBJECT = COLUMN\r\n');
        
        fprintf(fileId, 'OBJECT = COLUMN\r\n');        
        fprintf(fileId, 'NAME = P2_CURRENT\r\n');
        fprintf(fileId, 'DATA_TYPE = ASCII_REAL\r\n');
        fprintf(fileId, 'UNIT = "TM UNITS"\r\n');
        fprintf(fileId, 'START_BYTE = 18\r\n');
        fprintf(fileId, 'BYTES = 12\r\n');
        fprintf(fileId, 'DESCRIPTION = "Probe 2 instrument offset."\r\n');
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
end

